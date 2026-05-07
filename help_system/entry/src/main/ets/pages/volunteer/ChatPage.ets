import router from '@ohos.router';
import { NavBackButton } from '../../components/NavBackButton';
import { DateUtil } from '../../utils/DateUtil';
import { MessageApi, RequestApi } from '../../services/ApiService';
import { WebSocketConnectionStatus, WebSocketService } from '../../services/WebSocketService';
import { StorageUtil } from '../../utils/StorageUtil';
import type { ChatMessage, ChatReadReceiptEvent, HelpRequest, UserProfile } from '../../models';

interface ChatViewMessage {
  id: number;
  sender: 'me' | 'other';
  text: string;
  time: string;
  isRead: boolean;
}

@Entry
@Component
struct ChatPage {
  @StorageLink('accessibility_large_font') largeFontEnabled: boolean = false;
  @StorageLink('accessibility_high_contrast') highContrastEnabled: boolean = false;

  @State requestId: string = '';
  @State currentUserId: string = '';
  @State currentUserRole: string = '';
  @State targetUserId: string = '';
  @State targetUserName: string = '\u804a\u5929';
  @State messages: ChatViewMessage[] = [];
  @State inputText: string = '';
  @State isLoading: boolean = true;
  @State isSending: boolean = false;
  @State pageTitle: string = '\u804a\u5929';
  @State connectionStatus: WebSocketConnectionStatus = 'disconnected';

  private webSocketService = WebSocketService.getInstance();
  private hasConnectedOnce: boolean = false;

  aboutToAppear() {
    const params = router.getParams() as Record<string, string>;
    if (params) {
      if (params['requestId']) {
        this.requestId = params['requestId'] as string;
      } else if (params['id']) {
        this.requestId = params['id'] as string;
      }
      if (params['volunteerId']) {
        this.targetUserId = params['volunteerId'] as string;
      }
      if (params['volunteerName']) {
        this.targetUserName = params['volunteerName'] as string;
      }
    }
    this.loadChatData();
  }

  aboutToDisappear() {
    if (this.requestId) {
      this.webSocketService.offMessage(this.requestId);
      this.webSocketService.offReadReceipt(this.requestId);
      this.webSocketService.offStatusChange(this.getStatusHandlerKey());
    }
    this.webSocketService.disconnect();
  }

  private async loadChatData(): Promise<void> {
    if (!this.requestId) {
      this.isLoading = false;
      return;
    }

    this.isLoading = true;

    try {
      const currentUser: UserProfile | null = await StorageUtil.get<UserProfile>('user');
      if (!currentUser || !currentUser.id) {
        throw new Error('\u7528\u6237\u767b\u5f55\u72b6\u6001\u5f02\u5e38');
      }

      this.currentUserId = currentUser.id;
      this.currentUserRole = currentUser.role;

      const request: HelpRequest = await RequestApi.getRequestDetail(this.requestId);
      this.resolveChatTarget(request);

      const history: ChatMessage[] = await MessageApi.getChatHistory(this.requestId, 1);
      this.messages = history.map((message: ChatMessage) => this.mapMessage(message));
      await this.markUnreadMessagesAsRead(history);
      await this.connectRealtimeChannel();
    } catch (err) {
      const error = err as Error;
      console.error('load chat data failed:', error.message || error);
    } finally {
      this.isLoading = false;
    }
  }

  private resolveChatTarget(request: HelpRequest): void {
    if (this.currentUserRole === 'help-seeker' || this.currentUserId === request.userId) {
      if (!this.targetUserId) {
        this.targetUserId = request.volunteerId ? request.volunteerId : '';
      }
      if (!this.targetUserName || this.targetUserName === '\u804a\u5929') {
        this.targetUserName = request.volunteerName ? request.volunteerName : '\u5fd7\u613f\u8005';
      }
      this.pageTitle = this.targetUserName;
      return;
    }

    this.targetUserId = request.userId ? request.userId : '';
    this.targetUserName = request.userName ? request.userName : '\u6c42\u52a9\u8005';
    this.pageTitle = this.targetUserName;
  }

  private async markUnreadMessagesAsRead(history: ChatMessage[]): Promise<void> {
    const unreadIds: number[] = history
      .filter((message: ChatMessage) => !message.isRead && message.receiverId === this.currentUserId)
      .map((message: ChatMessage) => message.id);

    if (unreadIds.length === 0) {
      return;
    }

    try {
      await MessageApi.markAsRead(unreadIds);
    } catch (err) {
      console.error('mark messages as read failed:', err);
    }
  }

  private mapMessage(message: ChatMessage): ChatViewMessage {
    return {
      id: message.id,
      sender: message.senderId === this.currentUserId ? 'me' : 'other',
      text: message.text,
      time: message.createdAt ? DateUtil.format(message.createdAt, 'HH:mm') : message.time,
      isRead: !!message.isRead
    };
  }

  private async connectRealtimeChannel(): Promise<void> {
    const token = await StorageUtil.getString('token');
    if (!token) {
      return;
    }

    this.webSocketService.onStatusChange(this.getStatusHandlerKey(), (status: WebSocketConnectionStatus) => {
      this.handleConnectionStatusChange(status);
    });

    const connected = await this.webSocketService.connect(token);
    if (!connected) {
      console.error('connect realtime channel failed');
      return;
    }

    this.webSocketService.onMessage(this.requestId, (message: ChatMessage) => {
      this.handleRealtimeMessage(message);
    });
    this.webSocketService.onReadReceipt(this.requestId, (event: ChatReadReceiptEvent) => {
      this.handleReadReceipt(event);
    });
  }

  private handleConnectionStatusChange(status: WebSocketConnectionStatus): void {
    const previousStatus = this.connectionStatus;
    this.connectionStatus = status;

    if (status === 'connected') {
      if (this.hasConnectedOnce
        && (previousStatus === 'reconnecting' || previousStatus === 'error' || previousStatus === 'disconnected')) {
        this.syncLatestMessages();
      }
      this.hasConnectedOnce = true;
    }
  }

  private async syncLatestMessages(): Promise<void> {
    try {
      const history: ChatMessage[] = await MessageApi.getChatHistory(this.requestId, 1);
      this.messages = history.map((message: ChatMessage) => this.mapMessage(message));
      await this.markUnreadMessagesAsRead(history);
    } catch (err) {
      console.error('sync latest messages failed:', err);
    }
  }

  private handleRealtimeMessage(message: ChatMessage): void {
    if (message.requestId !== this.requestId) {
      return;
    }

    const exists = this.messages.some((item: ChatViewMessage) => item.id === message.id);
    if (exists) {
      return;
    }

    const nextMessages: ChatViewMessage[] = this.messages.slice();
    nextMessages.push(this.mapMessage(message));
    this.messages = nextMessages;

    if (!message.isRead && message.receiverId === this.currentUserId) {
      MessageApi.markAsRead([message.id]).catch((err: Error) => {
        console.error('mark realtime message as read failed:', err);
      });
    }
  }

  private handleReadReceipt(event: ChatReadReceiptEvent): void {
    if (event.requestId !== this.requestId || !event.messageIds || event.messageIds.length === 0) {
      return;
    }

    const targetIds = new Set<number>(event.messageIds);
    let changed = false;

    const nextMessages: ChatViewMessage[] = this.messages.map((message: ChatViewMessage) => {
      if (message.sender !== 'me' || message.isRead || !targetIds.has(message.id)) {
        return message;
      }

      changed = true;
      return {
        id: message.id,
        sender: message.sender,
        text: message.text,
        time: message.time,
        isRead: true
      };
    });

    if (changed) {
      this.messages = nextMessages;
    }
  }

  private getStatusHandlerKey(): string {
    return `chat-status-${this.requestId}`;
  }

  private getConnectionStatusLabel(): string {
    switch (this.connectionStatus) {
      case 'connected':
        return '\u5df2\u8fde\u63a5';
      case 'connecting':
        return '\u8fde\u63a5\u4e2d';
      case 'reconnecting':
        return '\u91cd\u8fde\u4e2d';
      case 'error':
        return '\u8fde\u63a5\u5f02\u5e38';
      default:
        return '\u5df2\u65ad\u5f00';
    }
  }

  private getConnectionStatusColor(): string {
    switch (this.connectionStatus) {
      case 'connected':
        return '#10b981';
      case 'connecting':
      case 'reconnecting':
        return '#f59e0b';
      case 'error':
        return '#ef4444';
      default:
        return '#9ca3af';
    }
  }

  goBack() {
    router.back();
  }

  handleSend() {
    const text: string = this.inputText.trim();
    if (!text || !this.targetUserId || this.isSending) {
      return;
    }

    this.isSending = true;
    MessageApi.sendMessage({
      requestId: this.requestId,
      receiverId: this.targetUserId,
      text: text,
      type: 'text'
    }).then((message: ChatMessage) => {
      const nextMessages: ChatViewMessage[] = this.messages.slice();
      nextMessages.push(this.mapMessage(message));
      this.messages = nextMessages;
      this.inputText = '';
    }).catch((err: Error) => {
      console.error('send message failed:', err.message || err);
    }).finally(() => {
      this.isSending = false;
    });
  }

  @Builder
  MessageBubble(message: ChatViewMessage) {
    Row({ space: 12 }) {
      if (message.sender === 'other') {
        Row() {
          Text('O')
            .fontSize(this.largeFontEnabled ? 18 : 14)
            .fontColor(this.highContrastEnabled ? '#000000' : '#ffffff')
            .fontWeight(FontWeight.Bold)
        }
        .width(this.largeFontEnabled ? 48 : 40)
        .height(this.largeFontEnabled ? 48 : 40)
        .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#10b981')
        .borderRadius(this.largeFontEnabled ? 24 : 20)
        .border(this.highContrastEnabled ? { width: 3, color: '#000000' } : undefined)
        .justifyContent(FlexAlign.Center)
      }

      Column({ space: 6 }) {
        Text(message.text)
          .fontSize(this.largeFontEnabled ? 18.75 : 15)
          .fontColor(this.highContrastEnabled ? '#000000' :
            (message.sender === 'me' ? '#ffffff' : '#1a1a1a'))
          .fontWeight(this.highContrastEnabled ? FontWeight.Bold : FontWeight.Normal)
          .lineHeight(this.largeFontEnabled ? 27.5 : 22)
          .padding({ left: 16, right: 16, top: 12, bottom: 12 })
          .backgroundColor(this.highContrastEnabled ? '#ffff00' :
            (message.sender === 'me' ? '#3b82f6' : '#ffffff'))
          .borderRadius(message.sender === 'me' ?
            { topLeft: 16, topRight: 16, bottomLeft: 16, bottomRight: 4 } :
            { topLeft: 16, topRight: 16, bottomLeft: 4, bottomRight: 16 })
          .border(this.highContrastEnabled ? { width: 3, color: '#000000' } : undefined)

        Text(message.time)
          .fontSize(this.largeFontEnabled ? 13.75 : 11)
          .fontColor(this.highContrastEnabled ? '#000000' : '#9ca3af')
          .fontWeight(this.highContrastEnabled ? FontWeight.Bold : FontWeight.Normal)
          .alignSelf(message.sender === 'me' ? ItemAlign.End : ItemAlign.Start)

        if (message.sender === 'me') {
          Text(message.isRead ? '\u5df2\u8bfb' : '\u672a\u8bfb')
            .fontSize(this.largeFontEnabled ? 13.75 : 11)
            .fontColor(this.highContrastEnabled ? '#000000' : '#9ca3af')
            .fontWeight(this.highContrastEnabled ? FontWeight.Bold : FontWeight.Normal)
            .alignSelf(ItemAlign.End)
        }
      }
      .constraintSize({ maxWidth: '72%' })
      .alignItems(message.sender === 'me' ? HorizontalAlign.End : HorizontalAlign.Start)
      .layoutWeight(1)

      if (message.sender === 'me') {
        Row() {
          Text('M')
            .fontSize(this.largeFontEnabled ? 18 : 14)
            .fontColor(this.highContrastEnabled ? '#000000' : '#ffffff')
            .fontWeight(FontWeight.Bold)
        }
        .width(this.largeFontEnabled ? 48 : 40)
        .height(this.largeFontEnabled ? 48 : 40)
        .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#3b82f6')
        .borderRadius(this.largeFontEnabled ? 24 : 20)
        .border(this.highContrastEnabled ? { width: 3, color: '#000000' } : undefined)
        .justifyContent(FlexAlign.Center)
      }
    }
    .width('100%')
    .justifyContent(message.sender === 'me' ? FlexAlign.End : FlexAlign.Start)
    .alignItems(VerticalAlign.Top)
  }

  build() {
    Column() {
      Row({ space: 12 }) {
        NavBackButton()

        Column({ space: 2 }) {
          Text(this.pageTitle)
            .fontSize(this.largeFontEnabled ? 20 : 16)
            .fontWeight(this.highContrastEnabled ? FontWeight.Bold : FontWeight.Medium)
            .fontColor(this.highContrastEnabled ? '#000000' : '#1a1a1a')

          Row({ space: 6 }) {
            Row()
              .width(8)
              .height(8)
              .backgroundColor(this.highContrastEnabled ? '#000000' : this.getConnectionStatusColor())
              .borderRadius(4)
              .margin({ top: 2 })

            Text(this.getConnectionStatusLabel())
              .fontSize(this.largeFontEnabled ? 15 : 12)
              .fontColor(this.highContrastEnabled ? '#000000' : this.getConnectionStatusColor())
              .fontWeight(this.highContrastEnabled ? FontWeight.Bold : FontWeight.Normal)
          }
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')
      .padding(12)
      .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#ffffff')
      .border(this.highContrastEnabled ?
        { width: 3, color: '#000000' } :
        { width: { bottom: 1 }, color: '#e5e7eb' }
      )

      if (this.isLoading) {
        Column({ space: 16 }) {
          LoadingProgress()
            .width(36)
            .height(36)
          Text('\u52a0\u8f7d\u804a\u5929\u4e2d...')
            .fontSize(this.largeFontEnabled ? 20 : 16)
            .fontColor(this.highContrastEnabled ? '#000000' : '#6b7280')
        }
        .layoutWeight(1)
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        Scroll() {
          Column({ space: 16 }) {
            Row() {
              Text(DateUtil.format(new Date(), 'MM-DD'))
                .fontSize(this.largeFontEnabled ? 15 : 12)
                .fontColor(this.highContrastEnabled ? '#000000' : '#9ca3af')
                .fontWeight(this.highContrastEnabled ? FontWeight.Bold : FontWeight.Normal)
                .padding({ left: 12, right: 12, top: 4, bottom: 4 })
                .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#f3f4f6')
                .borderRadius(12)
                .border(this.highContrastEnabled ? { width: 2, color: '#000000' } : undefined)
            }
            .width('100%')
            .justifyContent(FlexAlign.Center)
            .margin({ top: 8, bottom: 8 })

            if (this.messages.length === 0) {
              Text('\u6682\u65e0\u6d88\u606f\uff0c\u73b0\u5728\u53ef\u4ee5\u5f00\u59cb\u804a\u5929')
                .fontSize(this.largeFontEnabled ? 17.5 : 14)
                .fontColor(this.highContrastEnabled ? '#000000' : '#9ca3af')
                .textAlign(TextAlign.Center)
                .width('100%')
            } else {
              ForEach(this.messages, (message: ChatViewMessage) => {
                this.MessageBubble(message)
              })
            }

            Row()
              .height(8)
          }
          .width('100%')
          .justifyContent(FlexAlign.Start)
          .padding({ left: 12, right: 12, top: 12 })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .align(Alignment.TopStart)
        .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#f9fafb')
      }

      Column() {
        Row({ space: 10 }) {
          TextInput({
            placeholder: '\u8bf4\u70b9\u4ec0\u4e48...',
            text: this.inputText
          })
            .layoutWeight(1)
            .height(this.largeFontEnabled ? 52 : 44)
            .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#f3f4f6')
            .borderRadius(this.largeFontEnabled ? 26 : 22)
            .padding({ left: 16, right: 16 })
            .fontSize(this.largeFontEnabled ? 18.75 : 15)
            .fontColor(this.highContrastEnabled ? '#000000' : undefined)
            .fontWeight(this.highContrastEnabled ? FontWeight.Bold : FontWeight.Normal)
            .placeholderColor(this.highContrastEnabled ? '#000000' : '#9ca3af')
            .type(InputType.Normal)
            .enterKeyType(EnterKeyType.Send)
            .border(this.highContrastEnabled ? { width: 3, color: '#000000' } : undefined)
            .onChange((value: string) => {
              this.inputText = value;
            })
            .onSubmit(() => {
              this.handleSend();
            })

          Button() {
            Text(this.isSending ? '...' : '\u53d1\u9001')
              .fontSize(this.largeFontEnabled ? 17.5 : 14)
              .fontColor(this.highContrastEnabled ? '#000000' : '#ffffff')
              .fontWeight(FontWeight.Bold)
          }
          .height(this.largeFontEnabled ? 52 : 44)
          .padding({ left: 16, right: 16 })
          .linearGradient(this.highContrastEnabled ?
            { angle: 90, colors: [[0xffff00, 0.0], [0xffff00, 1.0]] } :
            { angle: 90, colors: [[0x3b82f6, 0.0], [0x6366f1, 1.0]] }
          )
          .borderRadius(this.largeFontEnabled ? 26 : 22)
          .border(this.highContrastEnabled ? { width: 3, color: '#000000' } : undefined)
          .enabled(!this.isSending && this.inputText.trim().length > 0)
          .onClick(() => {
            this.handleSend();
          })
        }
        .padding({ left: 12, right: 12, top: 12, bottom: 12 })
      }
      .width('100%')
      .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#ffffff')
      .border(this.highContrastEnabled ?
        { width: 3, color: '#000000' } :
        { width: { top: 1 }, color: '#e5e7eb' }
      )
    }
    .width('100%')
    .height('100%')
  }
}

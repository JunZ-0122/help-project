import webSocket from '@ohos.net.webSocket';
import type { ChatMessage, ChatReadReceiptEvent } from '../models';

// 使用电脑IP地址，模拟器才能访问
// 如果在真实设备上测试，需要确保设备和电脑在同一网络
const WS_BASE_URL = 'ws://172.31.32.1:8080/ws/chat';

type MessageHandler = (message: ChatMessage) => void;
type ReadReceiptHandler = (event: ChatReadReceiptEvent) => void;
export type WebSocketConnectionStatus = 'connecting' | 'connected' | 'reconnecting' | 'disconnected' | 'error';
type StatusHandler = (status: WebSocketConnectionStatus) => void;

export class WebSocketService {
  private static instance: WebSocketService;
  private connection: webSocket.WebSocket | null = null;
  private messageHandlers: Map<string, MessageHandler> = new Map();
  private readHandlers: Map<string, ReadReceiptHandler> = new Map();
  private statusHandlers: Map<string, StatusHandler> = new Map();
  private isConnected: boolean = false;
  private isConnecting: boolean = false;
  private currentToken: string = '';
  private reconnectTimer: number = -1;
  private shouldReconnect: boolean = false;
  private connectPromise: Promise<boolean> | null = null;
  private currentStatus: WebSocketConnectionStatus = 'disconnected';

  private constructor() {}

  static getInstance(): WebSocketService {
    if (!WebSocketService.instance) {
      WebSocketService.instance = new WebSocketService();
    }
    return WebSocketService.instance;
  }

  async connect(token: string): Promise<boolean> {
    if (!token) {
      return false;
    }

    if (this.isConnected && this.currentToken === token && this.connection) {
      return true;
    }

    if (this.isConnecting && this.connectPromise) {
      return this.connectPromise;
    }

    this.clearReconnectTimer();
    this.currentToken = token;
    this.shouldReconnect = true;
    this.isConnecting = true;
    this.emitStatus('connecting');
    this.connection = webSocket.createWebSocket();

    const socket: webSocket.WebSocket = this.connection;
    const connectUrl = `${WS_BASE_URL}?token=${encodeURIComponent(token)}`;

    this.bindSocketEvents(socket);

    this.connectPromise = socket.connect(connectUrl).then(() => {
      return true;
    }).catch((err: Error) => {
      console.error('websocket connect failed:', err);
      this.isConnecting = false;
      this.isConnected = false;
      this.connection = null;
      this.emitStatus('error');
      if (this.shouldReconnect && this.currentToken) {
        this.scheduleReconnect();
      }
      return false;
    }).finally(() => {
      this.isConnecting = false;
      this.connectPromise = null;
    });

    return this.connectPromise;
  }

  disconnect(): void {
    this.shouldReconnect = false;
    this.clearReconnectTimer();

    if (this.connection) {
      try {
        this.connection.close();
      } catch (err) {
        console.error('websocket close failed:', err);
      }
    }

    this.connection = null;
    this.isConnected = false;
    this.isConnecting = false;
    this.currentToken = '';
    this.emitStatus('disconnected');
    this.messageHandlers.clear();
    this.readHandlers.clear();
    this.statusHandlers.clear();
  }

  onMessage(requestId: string, handler: MessageHandler): void {
    this.messageHandlers.set(requestId, handler);
  }

  offMessage(requestId: string): void {
    this.messageHandlers.delete(requestId);
  }

  onReadReceipt(requestId: string, handler: ReadReceiptHandler): void {
    this.readHandlers.set(requestId, handler);
  }

  offReadReceipt(requestId: string): void {
    this.readHandlers.delete(requestId);
  }

  onStatusChange(key: string, handler: StatusHandler): void {
    this.statusHandlers.set(key, handler);
    handler(this.currentStatus);
  }

  offStatusChange(key: string): void {
    this.statusHandlers.delete(key);
  }

  isConnectionActive(): boolean {
    return this.isConnected;
  }

  private bindSocketEvents(socket: webSocket.WebSocket): void {
    socket.on('open', () => {
      this.isConnected = true;
      this.isConnecting = false;
      this.clearReconnectTimer();
      this.emitStatus('connected');
      console.info('websocket connected');
    });

    socket.on('message', (_err: Error, value: string | ArrayBuffer) => {
      this.handleMessage(value);
    });

    socket.on('close', () => {
      const shouldReconnect: boolean = this.shouldReconnect && this.currentToken.length > 0;
      this.connection = null;
      this.isConnected = false;
      this.isConnecting = false;
      console.info('websocket closed');

      if (shouldReconnect) {
        this.emitStatus('reconnecting');
        this.scheduleReconnect();
      } else {
        this.emitStatus('disconnected');
      }
    });

    socket.on('error', (err: Error) => {
      console.error('websocket error:', err);
      this.emitStatus('error');
    });
  }

  private handleMessage(value: string | ArrayBuffer): void {
    try {
      let payload: string = '';
      
      if (typeof value === 'string') {
        payload = value;
      } else {
        // ArrayBuffer: convert to string using util.TextDecoder
        const uint8Array = new Uint8Array(value);
        const charArray: string[] = [];
        for (let i = 0; i < uint8Array.length; i++) {
          charArray.push(String.fromCharCode(uint8Array[i]));
        }
        payload = charArray.join('');
      }
      
      if (!payload) {
        return;
      }

      const parsedData = JSON.parse(payload) as Record<string, Object>;
      const requestId = parsedData['requestId'] as string;
      if (!requestId) {
        return;
      }

      if (parsedData['eventType'] === 'read') {
        const readHandler = this.readHandlers.get(requestId);
        if (readHandler) {
          const readEvent: ChatReadReceiptEvent = {
            eventType: 'read',
            requestId: parsedData['requestId'] as string,
            readerId: parsedData['readerId'] as string,
            messageIds: parsedData['messageIds'] as number[]
          };
          readHandler(readEvent);
        }
        return;
      }

      const messageHandler = this.messageHandlers.get(requestId);
      if (messageHandler) {
        const message: ChatMessage = {
          id: parsedData['id'] as number,
          requestId: parsedData['requestId'] as string,
          senderId: parsedData['senderId'] as string,
          senderName: parsedData['senderName'] as string,
          senderAvatar: parsedData['senderAvatar'] as string | undefined,
          receiverId: parsedData['receiverId'] as string,
          sender: parsedData['sender'] as 'me' | 'other',
          text: parsedData['text'] as string,
          time: parsedData['time'] as string,
          type: parsedData['type'] as 'text' | 'voice' | 'image' | 'location',
          voiceUrl: parsedData['voiceUrl'] as string | undefined,
          voiceDuration: parsedData['voiceDuration'] as number | undefined,
          imageUrl: parsedData['imageUrl'] as string | undefined,
          latitude: parsedData['latitude'] as number | undefined,
          longitude: parsedData['longitude'] as number | undefined,
          isRead: parsedData['isRead'] as boolean,
          isPlaying: parsedData['isPlaying'] as boolean | undefined,
          createdAt: parsedData['createdAt'] as string
        };
        messageHandler(message);
      }
    } catch (err) {
      console.error('parse websocket message failed:', err);
    }
  }

  private scheduleReconnect(): void {
    if (this.reconnectTimer >= 0) {
      return;
    }

    this.emitStatus('reconnecting');
    const timerId: number = setTimeout(() => {
      this.reconnectTimer = -1;
      if (!this.shouldReconnect || !this.currentToken) {
        return;
      }

      this.connect(this.currentToken).catch((err: Error) => {
        console.error('websocket reconnect failed:', err);
      });
    }, 3000);
    this.reconnectTimer = timerId;
  }

  private clearReconnectTimer(): void {
    if (this.reconnectTimer >= 0) {
      clearTimeout(this.reconnectTimer);
      this.reconnectTimer = -1;
    }
  }

  private emitStatus(status: WebSocketConnectionStatus): void {
    this.currentStatus = status;
    this.statusHandlers.forEach((handler: StatusHandler) => {
      handler(status);
    });
  }
}

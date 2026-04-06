export interface ChatMessage {
  id: number;
  requestId: string;
  senderId: string;
  senderName: string;
  senderAvatar?: string;
  receiverId: string;
  sender: 'me' | 'other';
  text: string;
  time: string;
  type: 'text' | 'voice' | 'image' | 'location';
  voiceUrl?: string;
  voiceDuration?: number;
  imageUrl?: string;
  latitude?: number;
  longitude?: number;
  isRead: boolean;
  isPlaying?: boolean;
  createdAt: string;
}

export interface ChatReadReceiptEvent {
  eventType: 'read';
  requestId: string;
  readerId: string;
  messageIds: number[];
}

export interface Conversation {
  id: string;
  requestId: string;
  userId: string;
  userName: string;
  userAvatar?: string;
  lastMessage: string;
  lastMessageTime: string;
  unreadCount: number;
  isOnline: boolean;
  createdAt: string;
}

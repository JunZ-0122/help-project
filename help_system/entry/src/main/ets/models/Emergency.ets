/**
 * 紧急求助相关实体
 */

/**
 * 紧急求助请求
 */
export interface EmergencyRequest {
  id: string;
  userId: string;
  userName: string;
  userPhone: string;
  type: 'medical' | 'accident' | 'fire' | 'other';
  description: string;
  location: string;
  latitude: number;
  longitude: number;
  status: 'pending' | 'dispatched' | 'in-progress' | 'resolved' | 'cancelled';
  priority: 'critical' | 'high' | 'medium';
  createdAt: string;
  dispatchedAt?: string;
  resolvedAt?: string;
  responderId?: string;
  responderName?: string;
  responderPhone?: string;
  estimatedArrivalTime?: string;
  images?: string[];
  audioUrl?: string;
}

/**
 * 紧急联系人
 */
export interface EmergencyContact {
  id: string;
  userId: string;
  name: string;
  phone: string;
  relationship: string;
  isPrimary: boolean;
  createdAt: string;
}

/**
 * 紧急响应记录
 */
export interface EmergencyResponse {
  id: string;
  requestId: string;
  responderId: string;
  responderName: string;
  responseTime: string;
  arrivalTime?: string;
  completionTime?: string;
  status: 'dispatched' | 'on-the-way' | 'arrived' | 'completed';
  notes?: string;
}

/**
 * 创建紧急求助请求
 */
export interface CreateEmergencyRequest {
  type: 'medical' | 'accident' | 'fire' | 'other';
  description: string;
  location: string;
  latitude: number;
  longitude: number;
  images?: string[];
  audioUrl?: string;
}

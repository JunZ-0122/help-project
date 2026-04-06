/**
 * 求助请求实体
 */
export interface HelpRequest {
  id: string;
  userId: string;
  userName: string;
  userPhone: string;
  type: 'medical' | 'shopping' | 'repair' | 'companion' | 'emergency' | 'other';
  title: string;
  description: string;
  location: string;
  latitude?: number;
  longitude?: number;
  urgency: 'low' | 'medium' | 'high' | 'emergency';
  status: 'pending' | 'assigned' | 'in-progress' | 'completed' | 'cancelled';
  createdAt: string;
  updatedAt?: string;
  scheduledTime?: string;
  estimatedDuration?: number;
  images?: string[];
  volunteerId?: string;
  volunteerName?: string;
  completedAt?: string;
  rating?: number;
  feedback?: string;
}

/**
 * 求助类型
 */
export interface RequestType {
  id: string;
  name: string;
  icon: string;
  description: string;
  color: string;
  enabled: boolean;
}

/**
 * 求助统计
 */
export interface RequestStatistics {
  total: number;
  pending: number;
  inProgress: number;
  completed: number;
  cancelled: number;
  todayCount: number;
  weekCount: number;
  monthCount: number;
}

/**
 * 志愿者订单实体
 */
export interface VolunteerOrder {
  id: string;
  requestId: string;
  volunteerId: string;
  volunteerName: string;
  helpSeekerId: string;
  helpSeekerName: string;
  helpSeekerPhone: string;
  type: 'medical' | 'shopping' | 'repair' | 'companion' | 'emergency' | 'other';
  title: string;
  description: string;
  location: string;
  latitude?: number;
  longitude?: number;
  status: 'accepted' | 'in-progress' | 'completed' | 'cancelled';
  acceptedAt: string;
  startedAt?: string;
  completedAt?: string;
  estimatedDuration?: number;
  actualDuration?: number;
  distance?: number;
  rating?: number;
  feedback?: string;
  images?: string[];
  /** \u6c42\u52a9\u8005\u662f\u5426\u5df2\u5bf9\u5fd7\u613f\u8005\u8bc4\u4ef7\uff08\u540e\u7aef\u5217\u8868/\u8be6\u60c5\u586b\u5145\uff09 */
  seekerReviewed?: boolean;
}

/**
 * 订单进度
 */
export interface OrderProgress {
  orderId: string;
  status: 'accepted' | 'on-the-way' | 'arrived' | 'in-service' | 'completed';
  currentStep: number;
  totalSteps: number;
  steps: ProgressStep[];
  updatedAt: string;
}

/**
 * 进度步骤
 */
export interface ProgressStep {
  id: number;
  title: string;
  description: string;
  status: 'pending' | 'in-progress' | 'completed';
  time?: string;
  location?: string;
}

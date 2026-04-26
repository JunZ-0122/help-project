/**
 * 用户实体
 */
export interface User {
  id: string;
  name: string;
  phone: string;
  avatar?: string;
  role: 'default' | 'help-seeker' | 'volunteer' | 'community';
  status: 'online' | 'offline' | 'busy';
  createdAt?: string;
}

/**
 * 用户资料
 */
export interface UserProfile extends User {
  age?: number;
  gender?: 'male' | 'female' | 'other';
  address?: string;
  emergencyContact?: string;
  emergencyPhone?: string;
  disabilities?: string[];
  certifications?: string[];
  volunteerHours?: number;
  rating?: number;
}

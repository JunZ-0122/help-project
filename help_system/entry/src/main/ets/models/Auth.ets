/**
 * Auth-related models.
 */

export interface LoginRequest {
  phone: string;
  password: string;
  verificationCode?: string;
  loginType: 'password' | 'sms';
}

export interface LoginResponse {
  token: string;
  refreshToken: string;
  expiresIn: number;
  user: UserInfo;
}

export interface UserInfo {
  id: string;
  name: string;
  phone: string;
  avatar?: string;
  role: 'default' | 'help-seeker' | 'volunteer' | 'community';
  status: 'active' | 'inactive' | 'banned' | 'online' | 'offline' | 'busy';
}

export interface RegisterRequest {
  phone: string;
  password: string;
  verificationCode: string;
  name: string;
  role: 'default' | 'help-seeker' | 'volunteer' | 'community';
}

export interface VerificationCodeRequest {
  phone: string;
  type: 'login' | 'register' | 'reset-password';
}

export interface SendVerificationCodeResponse {
  cooldownSeconds: number;
  expiresInSeconds: number;
  reused: boolean;
  mockMessage?: string;
  debugCode?: string;
}

export interface ResetPasswordRequest {
  phone: string;
  verificationCode: string;
  newPassword: string;
}

export interface RefreshTokenRequest {
  refreshToken: string;
}

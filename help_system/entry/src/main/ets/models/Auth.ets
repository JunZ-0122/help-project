/**
 * 认证相关实体
 */

/**
 * 登录请求
 */
export interface LoginRequest {
  phone: string;
  password: string;
  verificationCode?: string;
  loginType: 'password' | 'sms';
}

/**
 * 登录响应
 */
export interface LoginResponse {
  token: string;
  refreshToken: string;
  expiresIn: number;
  user: UserInfo;
}

/**
 * 用户信息
 */
export interface UserInfo {
  id: string;
  name: string;
  phone: string;
  avatar?: string;
  role: 'default' | 'help-seeker' | 'volunteer' | 'community';
  status: 'active' | 'inactive' | 'banned';
}

/**
 * 注册请求
 */
export interface RegisterRequest {
  phone: string;
  password: string;
  verificationCode: string;
  name: string;
  role: 'default' | 'help-seeker' | 'volunteer' | 'community';
}

/**
 * 验证码请求
 */
export interface VerificationCodeRequest {
  phone: string;
  type: 'login' | 'register' | 'reset-password';
}

/**
 * 密码重置请求
 */
export interface ResetPasswordRequest {
  phone: string;
  verificationCode: string;
  newPassword: string;
}

/**
 * Token 刷新请求
 */
export interface RefreshTokenRequest {
  refreshToken: string;
}

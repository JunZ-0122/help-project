/**
 * Authentication service.
 */

import {
  LoginRequest,
  LoginResponse,
  RegisterRequest,
  VerificationCodeRequest,
  SendVerificationCodeResponse,
  ResetPasswordRequest
} from '../models';
import { HttpClient } from './ApiService';
import { StorageUtil } from '../utils/StorageUtil';

interface LoginRequestData {
  phone: string;
  password?: string;
  verificationCode?: string;
  loginType?: 'password' | 'sms';
}

interface RegisterRequestData {
  phone: string;
  password: string;
  verificationCode: string;
  name: string;
  role: string;
}

interface SendCodeData {
  phone: string;
  type: 'login' | 'register' | 'reset-password';
}

interface RefreshTokenData {
  refreshToken: string;
}

interface EmptyRequestData {
}

export class AuthService {
  private static async persistLogin(response: LoginResponse): Promise<void> {
    await StorageUtil.set('token', response.token);
    await StorageUtil.set('refreshToken', response.refreshToken);
    await StorageUtil.set('user', response.user);
  }

  static async login(request: LoginRequest): Promise<LoginResponse> {
    try {
      const loginData: LoginRequestData = request.loginType === 'sms'
        ? {
            phone: request.phone,
            verificationCode: request.verificationCode || request.password,
            loginType: 'sms'
          }
        : {
            phone: request.phone,
            password: request.password,
            loginType: 'password'
          };

      const response = await HttpClient.post<LoginResponse>('/auth/login', loginData);
      if (response.data) {
        await AuthService.persistLogin(response.data);
      }
      return response.data;
    } catch (err) {
      const error = err instanceof Error ? err : new Error(String(err));
      console.error('登录失败:', error);
      throw new Error(error.message || '登录失败');
    }
  }

  static async register(request: RegisterRequest): Promise<LoginResponse> {
    try {
      const registerData: RegisterRequestData = {
        phone: request.phone,
        password: request.password,
        verificationCode: request.verificationCode,
        name: request.name,
        role: request.role
      };
      const response = await HttpClient.post<LoginResponse>('/auth/register', registerData);
      if (response.data) {
        await AuthService.persistLogin(response.data);
      }
      return response.data;
    } catch (err) {
      const error = err instanceof Error ? err : new Error(String(err));
      console.error('注册失败:', error);
      throw new Error(error.message || '注册失败');
    }
  }

  static async sendVerificationCode(request: VerificationCodeRequest): Promise<SendVerificationCodeResponse> {
    try {
      const codeData: SendCodeData = {
        phone: request.phone,
        type: request.type
      };
      const response = await HttpClient.post<SendVerificationCodeResponse>('/auth/send-code', codeData);
      return response.data;
    } catch (err) {
      const error = err instanceof Error ? err : new Error(String(err));
      console.error('发送验证码失败:', error);
      throw new Error(error.message || '发送验证码失败');
    }
  }

  static async resetPassword(_request: ResetPasswordRequest): Promise<boolean> {
    return false;
  }

  static async logout(): Promise<boolean> {
    try {
      const emptyData: EmptyRequestData = {};
      await HttpClient.post<void>('/auth/logout', emptyData);
    } catch (err) {
      const error = err instanceof Error ? err : new Error(String(err));
      console.error('退出登录失败:', error);
    } finally {
      await StorageUtil.remove('token');
      await StorageUtil.remove('refreshToken');
      await StorageUtil.remove('user');
    }
    return true;
  }

  static async refreshToken(refreshToken: string): Promise<LoginResponse> {
    try {
      const tokenData: RefreshTokenData = { refreshToken };
      const response = await HttpClient.post<LoginResponse>('/auth/refresh-token', tokenData);
      if (response.data) {
        await StorageUtil.set('token', response.data.token);
        await StorageUtil.set('refreshToken', response.data.refreshToken);
      }
      return response.data;
    } catch (err) {
      const error = err instanceof Error ? err : new Error(String(err));
      console.error('刷新 Token 失败:', error);
      throw new Error(error.message || '刷新 Token 失败');
    }
  }

  static async getCurrentUser(): Promise<Object | null> {
    return await StorageUtil.get('user');
  }

  static async isLoggedIn(): Promise<boolean> {
    const token = await StorageUtil.get<string>('token');
    return !!token;
  }
}

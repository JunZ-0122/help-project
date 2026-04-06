/**
 * 认证服务
 */

import { 
  LoginRequest, 
  LoginResponse, 
  RegisterRequest, 
  VerificationCodeRequest,
  ResetPasswordRequest,
  ApiResponse 
} from '../models';
import { HttpClient } from './ApiService';
import { StorageUtil } from '../utils/StorageUtil';

/**
 * 登录请求数据接口
 */
interface LoginRequestData {
  phone: string;
  password: string;
}

/**
 * 注册请求数据接口
 */
interface RegisterRequestData {
  phone: string;
  password: string;
  verificationCode: string;
  name: string;
  role: string;
}

/**
 * 发送验证码数据接口
 */
interface SendCodeData {
  phone: string;
}

/**
 * 刷新Token数据接口
 */
interface RefreshTokenData {
  refreshToken: string;
}

/**
 * 空请求数据接口
 */
interface EmptyRequestData {
}

export class AuthService {
  /**
   * 用户登录
   */
  static async login(request: LoginRequest): Promise<LoginResponse> {
    try {
      // 根据登录类型调用不同的接口
      if (request.loginType === 'sms') {
        // 验证码登录（当前后端使用验证码注册/登录）
        const loginData: LoginRequestData = {
          phone: request.phone,
          password: request.verificationCode || '123456' // 临时使用固定密码
        };
        const response = await HttpClient.post<LoginResponse>('/auth/login', loginData);
        
        // 保存 Token
        if (response.data) {
          console.info('[AuthService] 开始保存 Token...');
          await StorageUtil.set('token', response.data.token);
          console.info('[AuthService] Token 保存完成');
          
          await StorageUtil.set('refreshToken', response.data.refreshToken);
          console.info('[AuthService] RefreshToken 保存完成');
          
          await StorageUtil.set('user', response.data.user);
          console.info('[AuthService] User 保存完成');
          
          // 立即验证保存结果（使用 getString 而不是 get）
          const verifyToken = await StorageUtil.getString('token');
          console.info('[AuthService] Token 保存验证:', verifyToken ? '成功' : '失败');
        }
        
        return response.data;
      } else {
        // 密码登录
        const loginData: LoginRequestData = {
          phone: request.phone,
          password: request.password
        };
        const response = await HttpClient.post<LoginResponse>('/auth/login', loginData);
        
        // 保存 Token
        if (response.data) {
          console.info('[AuthService] 开始保存 Token...');
          await StorageUtil.set('token', response.data.token);
          console.info('[AuthService] Token 保存完成');
          
          await StorageUtil.set('refreshToken', response.data.refreshToken);
          console.info('[AuthService] RefreshToken 保存完成');
          
          await StorageUtil.set('user', response.data.user);
          console.info('[AuthService] User 保存完成');
          
          // 立即验证保存结果（使用 getString 而不是 get）
          const verifyToken = await StorageUtil.getString('token');
          console.info('[AuthService] Token 保存验证:', verifyToken ? '成功' : '失败');
        }
        
        return response.data;
      }
    } catch (err) {
      const error = err as Error;
      console.error('登录失败:', error);
      throw new Error(error.message || '登录失败');
    }
  }

  /**
   * 用户注册
   */
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
      
      // 保存 Token
      if (response.data) {
        await StorageUtil.set('token', response.data.token);
        await StorageUtil.set('refreshToken', response.data.refreshToken);
        await StorageUtil.set('user', response.data.user);
      }
      
      return response.data;
    } catch (err) {
      const error = err as Error;
      console.error('注册失败:', error);
      throw new Error(error.message || '注册失败');
    }
  }

  /**
   * 发送验证码
   */
  static async sendVerificationCode(request: VerificationCodeRequest): Promise<boolean> {
    try {
      const codeData: SendCodeData = {
        phone: request.phone
      };
      const response = await HttpClient.post<void>('/auth/send-code', codeData);
      return response.code === 200;
    } catch (err) {
      const error = err as Error;
      console.error('发送验证码失败:', error);
      throw new Error(error.message || '发送验证码失败');
    }
  }

  /**
   * 重置密码
   */
  static async resetPassword(request: ResetPasswordRequest): Promise<boolean> {
    try {
      // TODO: 后端暂未实现此接口
      return false;
    } catch (err) {
      const error = err as Error;
      console.error('重置密码失败:', error);
      throw new Error(error.message || '重置密码失败');
    }
  }

  /**
   * 退出登录
   */
  static async logout(): Promise<boolean> {
    try {
      const emptyData: EmptyRequestData = {};
      await HttpClient.post<void>('/auth/logout', emptyData);
      
      // 清除本地存储
      await StorageUtil.remove('token');
      await StorageUtil.remove('refreshToken');
      await StorageUtil.remove('user');
      
      return true;
    } catch (err) {
      const error = err as Error;
      console.error('退出登录失败:', error);
      // 即使接口失败，也清除本地数据
      await StorageUtil.remove('token');
      await StorageUtil.remove('refreshToken');
      await StorageUtil.remove('user');
      return true;
    }
  }

  /**
   * 刷新 Token
   */
  static async refreshToken(refreshToken: string): Promise<LoginResponse> {
    try {
      const tokenData: RefreshTokenData = {
        refreshToken: refreshToken
      };
      const response = await HttpClient.post<LoginResponse>('/auth/refresh-token', tokenData);
      
      // 更新 Token
      if (response.data) {
        await StorageUtil.set('token', response.data.token);
        await StorageUtil.set('refreshToken', response.data.refreshToken);
      }
      
      return response.data;
    } catch (err) {
      const error = err as Error;
      console.error('刷新 Token 失败:', error);
      throw new Error(error.message || '刷新 Token 失败');
    }
  }

  /**
   * 获取当前用户信息
   */
  static async getCurrentUser(): Promise<Object | null> {
    return await StorageUtil.get('user');
  }

  /**
   * 检查是否已登录
   */
  static async isLoggedIn(): Promise<boolean> {
    const token = await StorageUtil.get<string>('token');
    return !!token;
  }
}

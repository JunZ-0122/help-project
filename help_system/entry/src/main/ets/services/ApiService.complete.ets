/**
 * API 服务层 - 完整实现版本
 * 
 * 所有后端接口调用都通过这里统一管理
 * 使用方法：将此文件内容复制到 ApiService.ets 替换原有内容
 */

import http from '@ohos.net.http';
import { 
  ApiResponse, 
  HelpRequest, 
  ChatMessage, 
  VolunteerOrder,
  UserProfile,
  CommunityRequest,
  VolunteerInfo,
  CommunityStatistics,
  PageResponse
} from '../models';
import { StorageUtil } from '../utils/StorageUtil';

// 后端 API 地址
const API_BASE_URL = 'http://localhost:8080/api';

/**
 * HTTP 请求封装
 */
class HttpClient {
  /**
   * 创建 HTTP 请求
   */
  private static createRequest(): http.HttpRequest {
    return http.createHttp();
  }

  /**
   * 获取请求头
   */
  private static async getHeaders(): Promise<Record<string, string>> {
    const headers: Record<string, string> = {
      'Content-Type': 'application/json; charset=utf-8'
    };

    // 添加 Token
    const token = await StorageUtil.get<string>('token');
    if (token) {
      headers['Authorization'] = `Bearer ${token}`;
    }

    return headers;
  }

  /**
   * 处理响应
   */
  private static async handleResponse<T>(response: http.HttpResponse): Promise<ApiResponse<T>> {
    const result = response.result as string;
    const data = JSON.parse(result) as ApiResponse<T>;
    
    if (data.code !== 200) {
      throw new Error(data.message || '请求失败');
    }
    
    return data;
  }

  /**
   * GET 请求
   */
  static async get<T>(url: string, params?: Record<string, string | number>): Promise<ApiResponse<T>> {
    const httpRequest = this.createRequest();
    const headers = await this.getHeaders();
    
    // 构建查询参数
    let fullUrl = `${API_BASE_URL}${url}`;
    if (params) {
      const queryString = Object.keys(params)
        .map(key => `${key}=${encodeURIComponent(params[key])}`)
        .join('&');
      fullUrl += `?${queryString}`;
    }

    try {
      const response = await httpRequest.request(fullUrl, {
        method: http.RequestMethod.GET,
        header: headers,
        readTimeout: 10000,
        connectTimeout: 10000
      });

      return await this.handleResponse<T>(response);
    } finally {
      httpRequest.destroy();
    }
  }

  /**
   * POST 请求
   */
  static async post<T>(url: string, data?: Object): Promise<ApiResponse<T>> {
    const httpRequest = this.createRequest();
    const headers = await this.getHeaders();

    try {
      const response = await httpRequest.request(`${API_BASE_URL}${url}`, {
        method: http.RequestMethod.POST,
        header: headers,
        extraData: data ? JSON.stringify(data) : undefined,
        readTimeout: 10000,
        connectTimeout: 10000
      });

      return await this.handleResponse<T>(response);
    } finally {
      httpRequest.destroy();
    }
  }

  /**
   * PUT 请求
   */
  static async put<T>(url: string, data?: Object): Promise<ApiResponse<T>> {
    const httpRequest = this.createRequest();
    const headers = await this.getHeaders();

    try {
      const response = await httpRequest.request(`${API_BASE_URL}${url}`, {
        method: http.RequestMethod.PUT,
        header: headers,
        extraData: data ? JSON.stringify(data) : undefined,
        readTimeout: 10000,
        connectTimeout: 10000
      });

      return await this.handleResponse<T>(response);
    } finally {
      httpRequest.destroy();
    }
  }

  /**
   * DELETE 请求
   */
  static async delete<T>(url: string): Promise<ApiResponse<T>> {
    const httpRequest = this.createRequest();
    const headers = await this.getHeaders();

    try {
      const response = await httpRequest.request(`${API_BASE_URL}${url}`, {
        method: http.RequestMethod.DELETE,
        header: headers,
        readTimeout: 10000,
        connectTimeout: 10000
      });

      return await this.handleResponse<T>(response);
    } finally {
      httpRequest.destroy();
    }
  }
}

export { HttpClient };

/**
 * 求助请求相关 API
 */
export class RequestApi {
  /**
   * 获取求助列表（分页）
   */
  static async getRequests(
    page: number = 1, 
    pageSize: number = 10,
    type?: string,
    status?: string,
    urgency?: string
  ): Promise<PageResponse<HelpRequest>> {
    const params: Record<string, string | number> = { page, pageSize };
    if (type) params.type = type;
    if (status) params.status = status;
    if (urgency) params.urgency = urgency;
    
    const response = await HttpClient.get<PageResponse<HelpRequest>>('/requests', params);
    return response.data;
  }

  /**
   * 创建求助请求
   */
  static async createRequest(request: Partial<HelpRequest>): Promise<HelpRequest> {
    const response = await HttpClient.post<HelpRequest>('/requests', request);
    return response.data;
  }

  /**
   * 获取求助详情
   */
  static async getRequestDetail(id: string): Promise<HelpRequest> {
    const response = await HttpClient.get<HelpRequest>(`/requests/${id}`);
    return response.data;
  }

  /**
   * 更新求助请求
   */
  static async updateRequest(id: string, request: Partial<HelpRequest>): Promise<HelpRequest> {
    const response = await HttpClient.put<HelpRequest>(`/requests/${id}`, request);
    return response.data;
  }

  /**
   * 删除求助请求
   */
  static async deleteRequest(id: string): Promise<boolean> {
    const response = await HttpClient.delete<void>(`/requests/${id}`);
    return response.code === 200;
  }

  /**
   * 获取我的求助列表
   */
  static async getMyRequests(page: number = 1, pageSize: number = 10): Promise<PageResponse<HelpRequest>> {
    const response = await HttpClient.get<PageResponse<HelpRequest>>('/requests/my', { page, pageSize });
    return response.data;
  }
}

/**
 * 聊天消息相关 API
 */
export class MessageApi {
  /**
   * 获取聊天历史（分页）
   */
  static async getChatHistory(
    requestId: string, 
    page: number = 1,
    pageSize: number = 20
  ): Promise<PageResponse<ChatMessage>> {
    const response = await HttpClient.get<PageResponse<ChatMessage>>('/messages/history', {
      requestId,
      page,
      pageSize
    });
    return response.data;
  }

  /**
   * 发送消息
   */
  static async sendMessage(message: Partial<ChatMessage>): Promise<ChatMessage> {
    const response = await HttpClient.post<ChatMessage>('/messages', message);
    return response.data;
  }

  /**
   * 标记消息已读
   */
  static async markAsRead(messageIds: number[]): Promise<boolean> {
    const response = await HttpClient.put<void>('/messages/read', { messageIds });
    return response.code === 200;
  }

  /**
   * 获取未读消息数量
   */
  static async getUnreadCount(requestId: string): Promise<number> {
    const response = await HttpClient.get<number>('/messages/unread', { requestId });
    return response.data;
  }
}

/**
 * 志愿者订单相关 API
 */
export class OrderApi {
  /**
   * 获取我的订单列表（分页）
   */
  static async getMyOrders(
    page: number = 1,
    pageSize: number = 10,
    status?: string
  ): Promise<PageResponse<VolunteerOrder>> {
    const params: Record<string, string | number> = { page, pageSize };
    if (status) params.status = status;
    
    const response = await HttpClient.get<PageResponse<VolunteerOrder>>('/orders/my', params);
    return response.data;
  }

  /**
   * 接受订单
   */
  static async acceptOrder(requestId: string): Promise<VolunteerOrder> {
    const response = await HttpClient.post<VolunteerOrder>('/orders/accept', { requestId });
    return response.data;
  }

  /**
   * 获取订单详情
   */
  static async getOrderDetail(orderId: string): Promise<VolunteerOrder> {
    const response = await HttpClient.get<VolunteerOrder>(`/orders/${orderId}`);
    return response.data;
  }

  /**
   * 开始服务
   */
  static async startOrder(orderId: string): Promise<boolean> {
    const response = await HttpClient.put<void>(`/orders/${orderId}/start`);
    return response.code === 200;
  }

  /**
   * 完成服务
   */
  static async completeOrder(orderId: string, feedback?: string): Promise<boolean> {
    const response = await HttpClient.put<void>(`/orders/${orderId}/complete`, { feedback });
    return response.code === 200;
  }

  /**
   * 取消订单
   */
  static async cancelOrder(orderId: string, reason?: string): Promise<boolean> {
    const response = await HttpClient.put<void>(`/orders/${orderId}/cancel`, { reason });
    return response.code === 200;
  }

  /**
   * 根据求助ID获取订单
   */
  static async getOrderByRequestId(requestId: string): Promise<VolunteerOrder> {
    const response = await HttpClient.get<VolunteerOrder>(`/orders/request/${requestId}`);
    return response.data;
  }
}

/**
 * 用户相关 API
 */
export class UserApi {
  /**
   * 获取当前用户资料
   */
  static async getCurrentProfile(): Promise<UserProfile> {
    const response = await HttpClient.get<UserProfile>('/users/profile');
    return response.data;
  }

  /**
   * 根据ID获取用户资料
   */
  static async getUserProfile(userId: string): Promise<UserProfile> {
    const response = await HttpClient.get<UserProfile>(`/users/${userId}`);
    return response.data;
  }

  /**
   * 更新用户资料
   */
  static async updateUserProfile(profile: Partial<UserProfile>): Promise<UserProfile> {
    const response = await HttpClient.put<UserProfile>('/users/profile', profile);
    return response.data;
  }
}

/**
 * 评价相关 API
 */
export class ReviewApi {
  /**
   * 创建评价
   */
  static async createReview(review: {
    orderId: string;
    revieweeId: string;
    rating: number;
    content: string;
  }): Promise<boolean> {
    const response = await HttpClient.post<void>('/reviews', review);
    return response.code === 200;
  }

  /**
   * 获取订单评价
   */
  static async getOrderReview(orderId: string): Promise<any> {
    const response = await HttpClient.get<any>(`/reviews/order/${orderId}`);
    return response.data;
  }

  /**
   * 获取志愿者评价列表
   */
  static async getVolunteerReviews(
    volunteerId: string,
    page: number = 1,
    pageSize: number = 10
  ): Promise<PageResponse<any>> {
    const response = await HttpClient.get<PageResponse<any>>(`/reviews/volunteer/${volunteerId}`, {
      page,
      pageSize
    });
    return response.data;
  }

  /**
   * 获取求助者评价列表
   */
  static async getSeekerReviews(
    seekerId: string,
    page: number = 1,
    pageSize: number = 10
  ): Promise<PageResponse<any>> {
    const response = await HttpClient.get<PageResponse<any>>(`/reviews/seeker/${seekerId}`, {
      page,
      pageSize
    });
    return response.data;
  }

  /**
   * 获取我收到的评价
   */
  static async getMyReceivedReviews(
    page: number = 1,
    pageSize: number = 10
  ): Promise<PageResponse<any>> {
    const response = await HttpClient.get<PageResponse<any>>('/reviews/my-received', {
      page,
      pageSize
    });
    return response.data;
  }

  /**
   * 获取我给出的评价
   */
  static async getMyGivenReviews(
    page: number = 1,
    pageSize: number = 10
  ): Promise<PageResponse<any>> {
    const response = await HttpClient.get<PageResponse<any>>('/reviews/my-given', {
      page,
      pageSize
    });
    return response.data;
  }
}

/**
 * 社区管理相关 API
 */
export class CommunityApi {
  /**
   * 获取所有求助请求（分页）
   */
  static async getAllRequests(
    page: number = 1,
    pageSize: number = 10,
    status?: string
  ): Promise<PageResponse<CommunityRequest>> {
    const params: Record<string, string | number> = { page, pageSize };
    if (status) params.status = status;
    
    const response = await HttpClient.get<PageResponse<CommunityRequest>>('/community/requests', params);
    return response.data;
  }

  /**
   * 分配志愿者
   */
  static async assignVolunteer(requestId: string, volunteerId: string): Promise<boolean> {
    const response = await HttpClient.post<void>('/community/assign', {
      requestId,
      volunteerId
    });
    return response.code === 200;
  }

  /**
   * 获取统计数据
   */
  static async getStatistics(): Promise<CommunityStatistics> {
    const response = await HttpClient.get<CommunityStatistics>('/community/statistics');
    return response.data;
  }

  /**
   * 审核求助请求
   */
  static async reviewRequest(requestId: string, status: 'approved' | 'rejected'): Promise<boolean> {
    const response = await HttpClient.put<void>(`/community/review/${requestId}`, { status });
    return response.code === 200;
  }
}

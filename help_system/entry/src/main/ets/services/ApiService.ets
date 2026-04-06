import http from '@ohos.net.http';
import {
  ApiResponse,
  ChatMessage,
  CommunityRequest,
  CommunityStatistics,
  HelpRequest,
  PageResponse,
  QuickDispatchPayload,
  Review,
  SeekerRequestDetail,
  UserProfile,
  VolunteerInfo,
  VolunteerManagementPayload,
  VolunteerOrder,
  VolunteerStatistics
} from '../models';
import { StorageUtil } from '../utils/StorageUtil';

// Previewer 预览可改为 127.0.0.1；真机/模拟器用本机局域网 IP
const API_BASE_URL = 'http://192.168.1.104:8080/api';

interface RequestHeaders {
  'Content-Type': string;
  Authorization?: string;
}

interface QueryParam {
  key: string;
  value: string | number;
}

class HttpClient {
  private static createRequest(): http.HttpRequest {
    return http.createHttp();
  }

  private static async getHeaders(): Promise<RequestHeaders> {
    const headers: RequestHeaders = {
      'Content-Type': 'application/json'
    };

    const token = await StorageUtil.getString('token');
    if (token) {
      headers.Authorization = `Bearer ${token}`;
    }

    return headers;
  }

  private static async handleResponse<T>(response: http.HttpResponse): Promise<ApiResponse<T>> {
    console.info('[HttpClient] responseCode=' + response.responseCode);
    if (response.responseCode === 401) {
      await StorageUtil.remove('token');
      await StorageUtil.remove('refreshToken');
      await StorageUtil.remove('user');
      throw new Error('登录已失效，请重新登录');
    }

    const result = response.result as string;
    console.info('[HttpClient] responseBody=' + result);
    if (!result || result.trim() === '') {
      throw new Error('empty response');
    }

    const data = JSON.parse(result) as ApiResponse<T>;
    if (data.code !== 200) {
      throw new Error(data.message || 'request failed');
    }

    return data;
  }

  private static buildQueryString(params?: QueryParam[]): string {
    if (!params || params.length === 0) {
      return '';
    }

    return params
      .map((item: QueryParam) => `${item.key}=${encodeURIComponent(item.value)}`)
      .join('&');
  }

  static async get<T>(url: string, params?: QueryParam[]): Promise<ApiResponse<T>> {
    const httpRequest = HttpClient.createRequest();
    const headers = await HttpClient.getHeaders();

    let fullUrl = `${API_BASE_URL}${url}`;
    const queryString = HttpClient.buildQueryString(params);
    if (queryString.length > 0) {
      fullUrl += `?${queryString}`;
    }

    console.info('[HttpClient][GET] url=' + fullUrl);

    try {
      const response = await httpRequest.request(fullUrl, {
        method: http.RequestMethod.GET,
        header: headers,
        readTimeout: 10000,
        connectTimeout: 10000
      });

      return await HttpClient.handleResponse<T>(response);
    } catch (err) {
      const error = err as Error;
      throw new Error(error.message ? error.message : 'get request failed');
    } finally {
      httpRequest.destroy();
    }
  }

  static async post<T>(url: string, data?: object): Promise<ApiResponse<T>> {
    const httpRequest = HttpClient.createRequest();
    const headers = await HttpClient.getHeaders();
    const fullUrl: string = `${API_BASE_URL}${url}`;
    console.info('[HttpClient][POST] url=' + fullUrl);
    console.info('[HttpClient][POST] body=' + (data ? JSON.stringify(data) : ''));

    try {
      const response = await httpRequest.request(fullUrl, {
        method: http.RequestMethod.POST,
        header: headers,
        extraData: data ? JSON.stringify(data) : undefined,
        readTimeout: 10000,
        connectTimeout: 10000
      });

      return await HttpClient.handleResponse<T>(response);
    } catch (err) {
      const error = err as Error;
      throw new Error(error.message ? error.message : 'post request failed');
    } finally {
      httpRequest.destroy();
    }
  }

  static async put<T>(url: string, data?: object): Promise<ApiResponse<T>> {
    const httpRequest = HttpClient.createRequest();
    const headers = await HttpClient.getHeaders();
    const fullUrl: string = `${API_BASE_URL}${url}`;
    console.info('[HttpClient][PUT] url=' + fullUrl);
    console.info('[HttpClient][PUT] body=' + (data ? JSON.stringify(data) : ''));

    try {
      const response = await httpRequest.request(fullUrl, {
        method: http.RequestMethod.PUT,
        header: headers,
        extraData: data ? JSON.stringify(data) : undefined,
        readTimeout: 10000,
        connectTimeout: 10000
      });

      return await HttpClient.handleResponse<T>(response);
    } catch (err) {
      const error = err as Error;
      throw new Error(error.message ? error.message : 'put request failed');
    } finally {
      httpRequest.destroy();
    }
  }

  static async delete<T>(url: string): Promise<ApiResponse<T>> {
    const httpRequest = HttpClient.createRequest();
    const headers = await HttpClient.getHeaders();
    const fullUrl: string = `${API_BASE_URL}${url}`;
    console.info('[HttpClient][DELETE] url=' + fullUrl);

    try {
      const response = await httpRequest.request(fullUrl, {
        method: http.RequestMethod.DELETE,
        header: headers,
        readTimeout: 10000,
        connectTimeout: 10000
      });

      return await HttpClient.handleResponse<T>(response);
    } catch (err) {
      const error = err as Error;
      throw new Error(error.message ? error.message : 'delete request failed');
    } finally {
      httpRequest.destroy();
    }
  }
}

function requireData<T>(response: ApiResponse<T>, message: string): T {
  if (response.data !== undefined && response.data !== null) {
    return response.data;
  }
  throw new Error(message);
}

interface MarkReadPayload {
  messageIds: number[];
}

interface RequestIdPayload {
  requestId: string;
}

interface OrderStatusPayload {
  status: string;
}

interface CompleteOrderPayload {
  feedback: string;
}

interface EmptyPayload {
}

interface LoginPayload {
  phone: string;
  password: string;
}

interface AssignVolunteerPayload {
  requestId: string;
  volunteerId: string;
}

interface ReviewRequestPayload {
  status: string;
}

export interface CreateEmergencyRequestPayload {
  type: string;
  description: string;
  location: string;
  contactPhone: string;
  /** 与定位一致时一并提交，后端写入 help_requests 供附近匹配 */
  latitude?: number;
  longitude?: number;
}

interface ReviewCreateRequestPayload {
  orderId: string;
  revieweeId: string;
  rating: number;
  tags: string[];
  content: string;
  isAnonymous: boolean;
}

/** 提交评价时请求体：后端 Review 实体 tags 为 String，需传字符串 */
interface ReviewCreateRequestBody {
  orderId: string;
  revieweeId: string;
  rating: number;
  tags: string;
  content: string;
  isAnonymous: boolean;
}

export interface RequestListFilters {
  type?: string;
  status?: string;
  urgency?: string;
}

/** 用户位置（上报/查询） */
export interface UserLocationResponse {
  id: string;
  userId: string;
  latitude: number;
  longitude: number;
  address?: string;
  source?: string;
  createdAt?: string;
}

/** 附近求助项：求助 + 距离(km) */
export interface HelpRequestWithDistance {
  request: HelpRequest;
  distance: number;
}

/** 上报位置请求体 */
export interface ReportLocationBody {
  latitude: number;
  longitude: number;
  address?: string;
  source?: string;
}

/** 获取可用志愿者可选参数（按距离排序） */
export interface GetAvailableVolunteersOptions {
  requestId?: string;
  latitude?: number;
  longitude?: number;
}

export { HttpClient };

export class VolunteerApi {
  static async getStatistics(): Promise<VolunteerStatistics> {
    const response = await HttpClient.get<VolunteerStatistics>('/volunteer/statistics');
    return requireData(response, 'get volunteer statistics failed');
  }
}

export class RequestApi {
  static async getRequests(
    page: number = 1,
    pageSize: number = 10,
    filters?: RequestListFilters
  ): Promise<PageResponse<HelpRequest>> {
    const params: QueryParam[] = [
      { key: 'page', value: page },
      { key: 'pageSize', value: pageSize }
    ];
    if (filters && filters.type) {
      params.push({ key: 'type', value: filters.type });
    }
    if (filters && filters.status) {
      params.push({ key: 'status', value: filters.status });
    }
    if (filters && filters.urgency) {
      params.push({ key: 'urgency', value: filters.urgency });
    }
    const response = await HttpClient.get<PageResponse<HelpRequest>>('/requests', params);
    return requireData(response, 'get requests failed');
  }

  static async getMyRequests(page: number = 1, pageSize: number = 10): Promise<PageResponse<HelpRequest>> {
    const params: QueryParam[] = [
      { key: 'page', value: page },
      { key: 'pageSize', value: pageSize }
    ];
    const response = await HttpClient.get<PageResponse<HelpRequest>>('/requests/my', params);
    return requireData(response, 'get my requests failed');
  }

  /** 首页「最近求助」：按最近更新时间，默认 3 条 */
  static async getRecentMyRequests(limit: number = 3): Promise<HelpRequest[]> {
    const params: QueryParam[] = [{ key: 'limit', value: limit }];
    const response = await HttpClient.get<HelpRequest[]>('/requests/my/recent', params);
    return requireData(response, 'get recent my requests failed');
  }

  /** 附近求助列表（按距离排序，需先上报位置或传经纬度） */
  static async getNearbyRequests(
    page: number = 1,
    pageSize: number = 10,
    latitude?: number,
    longitude?: number
  ): Promise<PageResponse<HelpRequestWithDistance>> {
    const params: QueryParam[] = [
      { key: 'page', value: page },
      { key: 'pageSize', value: pageSize }
    ];
    if (latitude !== undefined && longitude !== undefined) {
      params.push({ key: 'latitude', value: latitude });
      params.push({ key: 'longitude', value: longitude });
    }
    const response = await HttpClient.get<PageResponse<HelpRequestWithDistance>>('/volunteer/nearby-requests', params);
    return requireData(response, 'get nearby requests failed');
  }

  static async createRequest(request: Partial<HelpRequest>): Promise<HelpRequest> {
    const response = await HttpClient.post<HelpRequest>('/requests', request);
    return requireData(response, 'create request failed');
  }

  static async getRequestDetail(id: string): Promise<HelpRequest> {
    const response = await HttpClient.get<HelpRequest>(`/requests/${id}`);
    return requireData(response, 'get request detail failed');
  }

  /** 求助者本人：详情聚合（时间线、横幅、志愿者距离等） */
  static async getSeekerRequestDetail(id: string): Promise<SeekerRequestDetail> {
    const response = await HttpClient.get<SeekerRequestDetail>(`/requests/${id}/seeker-detail`);
    return requireData(response, 'get seeker request detail failed');
  }

  static async cancelRequest(id: string): Promise<boolean> {
    const response = await HttpClient.delete<void>(`/requests/${id}`);
    return response.code === 200;
  }
}

export class EmergencyApi {
  static async createEmergencyRequest(request: CreateEmergencyRequestPayload): Promise<HelpRequest> {
    const response = await HttpClient.post<HelpRequest>('/emergency/requests', request);
    return requireData(response, 'create emergency request failed');
  }
}

export class MessageApi {
  static async getChatHistory(requestId: string, page: number = 1): Promise<ChatMessage[]> {
    const params: QueryParam[] = [
      { key: 'page', value: page }
    ];
    const response = await HttpClient.get<PageResponse<ChatMessage>>(`/chat/${requestId}`, params);
    return requireData(response, 'get chat history failed').items;
  }

  static async sendMessage(message: Partial<ChatMessage>): Promise<ChatMessage> {
    const response = await HttpClient.post<ChatMessage>('/chat/', message);
    return requireData(response, 'send message failed');
  }

  static async markAsRead(messageIds: number[]): Promise<boolean> {
    const payload: MarkReadPayload = { messageIds: messageIds };
    const response = await HttpClient.put<void>('/chat/read', payload);
    return response.code === 200;
  }

  static async countUnread(requestId: string): Promise<number> {
    const response = await HttpClient.get<number>(`/chat/${requestId}/unread`);
    return requireData(response, 'count unread failed');
  }
}

export class OrderApi {
  static async getMyOrders(status?: string): Promise<VolunteerOrder[]> {
    let params: QueryParam[] | undefined = undefined;
    if (status) {
      params = [
        { key: 'status', value: status }
      ];
    }
    const response = await HttpClient.get<VolunteerOrder[]>('/volunteer/orders/my', params);
    return requireData(response, 'get my orders failed');
  }

  /** \u5206\u9875\u8ba2\u5355\u5217\u8868\uff08\u4e0e\u540e\u7aef PageResult \u5bf9\u9f50\uff09 */
  static async getMyOrdersPage(
    page: number = 1,
    pageSize: number = 10,
    status?: string
  ): Promise<PageResponse<VolunteerOrder>> {
    const params: QueryParam[] = [
      { key: 'page', value: page },
      { key: 'pageSize', value: pageSize }
    ];
    if (status) {
      params.push({ key: 'status', value: status });
    }
    const response = await HttpClient.get<PageResponse<VolunteerOrder>>('/volunteer/orders/my', params);
    return requireData(response, 'get my orders page failed');
  }

  static async acceptOrder(requestId: string): Promise<VolunteerOrder> {
    const payload: RequestIdPayload = { requestId: requestId };
    const response = await HttpClient.post<VolunteerOrder>('/volunteer/orders/accept', payload);
    return requireData(response, 'accept order failed');
  }

  static async getOrderDetail(orderId: string): Promise<VolunteerOrder> {
    const response = await HttpClient.get<VolunteerOrder>(`/volunteer/orders/${orderId}`);
    return requireData(response, 'get order detail failed');
  }

  static async updateOrderStatus(orderId: string, status: string): Promise<boolean> {
    const payload: OrderStatusPayload = { status: status };
    const response = await HttpClient.put<void>(`/volunteer/orders/${orderId}/status`, payload);
    return response.code === 200;
  }

  static async completeOrder(orderId: string, feedback?: string): Promise<boolean> {
    if (feedback) {
      const payload: CompleteOrderPayload = { feedback: feedback };
      const response = await HttpClient.post<void>(`/volunteer/orders/${orderId}/complete`, payload);
      return response.code === 200;
    }

    const payload: EmptyPayload = {};
    const response = await HttpClient.post<void>(`/volunteer/orders/${orderId}/complete`, payload);
    return response.code === 200;
  }
}

export class ReviewApi {
  static async createReview(
    orderId: string,
    revieweeId: string,
    rating: number,
    content: string,
    tags: string[] = [],
    isAnonymous: boolean = false
  ): Promise<boolean> {
    const body: ReviewCreateRequestBody = {
      orderId: orderId,
      revieweeId: revieweeId,
      rating: rating,
      tags: tags.length > 0 ? tags.join(',') : '',
      content: content,
      isAnonymous: isAnonymous
    };
    const response = await HttpClient.post<void>('/reviews/', body);
    return response.code === 200;
  }

  /** \u5f53\u524d\u7528\u6237\u5bf9\u8be5\u8ba2\u5355\u53d1\u8d77\u7684\u8bc4\u4ef7\uff08\u6211\u8bc4\u4ed6\u4eba\uff09 */
  static async getOrderReview(orderId: string): Promise<Review | null> {
    const response = await HttpClient.get<Review | null>(`/reviews/order/${orderId}`);
    if (response.data === undefined) {
      throw new Error('get order review failed');
    }
    return response.data;
  }

  /** \u5f53\u524d\u7528\u6237\u6536\u5230\u7684\u8bc4\u4ef7\uff08\u5982\u6c42\u52a9\u8005\u8bc4\u5fd7\u613f\u8005\uff09 */
  static async getReviewReceived(orderId: string): Promise<Review | null> {
    const response = await HttpClient.get<Review | null>(`/reviews/order/${orderId}/received`);
    if (response.data === undefined) {
      throw new Error('get review received failed');
    }
    return response.data;
  }
}

interface UpdateRoleData {
  role: string;
}

export class UserApi {
  static async getCurrentProfile(): Promise<UserProfile> {
    const response = await HttpClient.get<UserProfile>('/users/me');
    return requireData(response, 'get current profile failed');
  }

  static async getUserProfile(userId: string): Promise<UserProfile> {
    const response = await HttpClient.get<UserProfile>(`/users/${userId}`);
    return requireData(response, 'get user profile failed');
  }

  static async updateUserProfile(profile: Partial<UserProfile>): Promise<UserProfile> {
    const response = await HttpClient.put<UserProfile>('/users/me', profile);
    return requireData(response, 'update user profile failed');
  }

  static async updateUserRole(role: string): Promise<UserProfile> {
    const requestData: UpdateRoleData = { role };
    const response = await HttpClient.put<UserProfile>('/users/me/role', requestData);
    return requireData(response, 'update user role failed');
  }

  static async switchUserRole(role: string): Promise<UserProfile> {
    const requestData: UpdateRoleData = { role };
    const response = await HttpClient.put<UserProfile>('/users/me/role/switch', requestData);
    return requireData(response, 'switch user role failed');
  }

  /** 上报当前用户位置（用于附近求助距离、志愿者匹配） */
  static async reportLocation(
    latitude: number,
    longitude: number,
    address?: string,
    source?: string
  ): Promise<UserLocationResponse> {
    const body: ReportLocationBody = { latitude: latitude, longitude: longitude };
    if (address !== undefined) {
      body.address = address;
    }
    if (source !== undefined) {
      body.source = source;
    }
    const response = await HttpClient.post<UserLocationResponse>('/users/me/location', body);
    return requireData(response, 'report location failed');
  }

  /** 查询当前用户最近一次位置 */
  static async getMyLocation(): Promise<UserLocationResponse> {
    const response = await HttpClient.get<UserLocationResponse>('/users/me/location');
    return requireData(response, 'get my location failed');
  }

  static async login(phone: string, password: string): Promise<LoginResult> {
    const payload: LoginPayload = { phone: phone, password: password };
    const response = await HttpClient.post<LoginResult>('/auth/login', payload);
    return requireData(response, 'login failed');
  }
}

export interface LoginResult {
  token: string;
  user: UserProfile;
}

/** 社区求助列表：all | pending | assigned（已分配含进行中） */
export interface CommunityRequestsQuery {
  status?: 'all' | 'pending' | 'assigned';
  page?: number;
  pageSize?: number;
}

export class CommunityApi {
  static async getRequestsPage(query?: CommunityRequestsQuery): Promise<PageResponse<CommunityRequest>> {
    const params: QueryParam[] = [
      { key: 'page', value: query?.page ?? 1 },
      { key: 'pageSize', value: query?.pageSize ?? 100 }
    ];
    const st = query?.status ?? 'all';
    params.push({ key: 'status', value: st });
    const response = await HttpClient.get<PageResponse<CommunityRequest>>('/community/requests', params);
    return requireData(response, 'get community requests failed');
  }

  static async getRequests(query?: CommunityRequestsQuery): Promise<CommunityRequest[]> {
    const page = await CommunityApi.getRequestsPage(query);
    return page.items;
  }

  static async getPendingRequests(): Promise<CommunityRequest[]> {
    return CommunityApi.getRequests({ status: 'pending', pageSize: 100 });
  }

  /** 可选 requestId 或 latitude+longitude，用于按与求助点距离排序 */
  static async getAvailableVolunteers(options?: GetAvailableVolunteersOptions): Promise<VolunteerInfo[]> {
    const params: QueryParam[] = [];
    if (options?.requestId) {
      params.push({ key: 'requestId', value: options.requestId });
    }
    if (options?.latitude !== undefined && options?.longitude !== undefined) {
      params.push({ key: 'latitude', value: options.latitude });
      params.push({ key: 'longitude', value: options.longitude });
    }
    const response = await HttpClient.get<VolunteerInfo[]>('/community/volunteers/available', params.length > 0 ? params : undefined);
    return requireData(response, 'get available volunteers failed');
  }

  static async assignVolunteer(requestId: string, volunteerId: string): Promise<boolean> {
    const payload: AssignVolunteerPayload = {
      requestId: requestId,
      volunteerId: volunteerId
    };
    const response = await HttpClient.post<void>('/community/assign', payload);
    return response.code === 200;
  }

  static async getStatistics(): Promise<CommunityStatistics> {
    const response = await HttpClient.get<CommunityStatistics>('/community/statistics');
    return requireData(response, 'get statistics failed');
  }

  static async getVolunteerManagement(keyword?: string): Promise<VolunteerManagementPayload> {
    const params: QueryParam[] = [];
    if (keyword !== undefined && keyword !== null && keyword.trim().length > 0) {
      params.push({ key: 'keyword', value: keyword.trim() });
    }
    const response = await HttpClient.get<VolunteerManagementPayload>(
      '/community/volunteers/management',
      params.length > 0 ? params : undefined
    );
    return requireData(response, 'get volunteer management failed');
  }

  static async getQuickDispatchRecommendations(volunteerId: string): Promise<QuickDispatchPayload> {
    const response = await HttpClient.get<QuickDispatchPayload>(
      `/community/volunteers/${volunteerId}/dispatch-recommendations`
    );
    return requireData(response, 'get dispatch recommendations failed');
  }

  /** 审核求助请求：approved 通过，rejected 拒绝 */
  static async reviewRequest(requestId: string, status: 'approved' | 'rejected'): Promise<boolean> {
    const payload: ReviewRequestPayload = { status: status };
    const response = await HttpClient.post<void>(`/community/requests/${requestId}/review`, payload);
    return response.code === 200;
  }
}

/** 逆地理编码返回（经纬度 → 地址） */
export interface RegeoResponse {
  address: string;
}

export class GeocodeApi {
  /** 根据经纬度获取格式化地址（用于「获取当前位置」自动填充） */
  static async getAddressFromCoordinates(latitude: number, longitude: number): Promise<string> {
    const params: QueryParam[] = [
      { key: 'latitude', value: latitude },
      { key: 'longitude', value: longitude }
    ];
    const response = await HttpClient.get<RegeoResponse>('/geocode/regeo', params);
    const data = requireData(response, 'get address failed');
    return data.address ? data.address : '';
  }
}

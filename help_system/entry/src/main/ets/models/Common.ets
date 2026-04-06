/**
 * 通用响应实体
 */
export interface ApiResponse<T> {
  code: number;
  message: string;
  data: T;
  timestamp: string;
}

/**
 * 分页请求参数
 */
export interface PageRequest {
  page: number;
  pageSize: number;
  sortBy?: string;
  sortOrder?: 'asc' | 'desc';
}

/**
 * 分页响应
 */
export interface PageResponse<T> {
  items: T[];
  total: number;
  page: number;
  pageSize: number;
  totalPages: number;
}

/** GET /api/volunteer/statistics */
export interface VolunteerStatistics {
  serviceCount: number;
  satisfactionPercent: number | null;
  serviceHoursTotal: number;
}

/**
 * 位置信息
 */
export interface Location {
  latitude: number;
  longitude: number;
  address: string;
  city?: string;
  district?: string;
}

/**
 * 文件上传响应
 */
export interface UploadResponse {
  fileId: string;
  fileName: string;
  fileUrl: string;
  fileSize: number;
  mimeType: string;
  uploadedAt: string;
}

/**
 * 通知消息
 */
export interface Notification {
  id: string;
  userId: string;
  type: 'request' | 'assignment' | 'message' | 'system';
  title: string;
  content: string;
  isRead: boolean;
  relatedId?: string;
  createdAt: string;
}

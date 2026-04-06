/**
 * 数据模型统一导出
 * 
 * 使用方式：
 * import { User, HelpRequest, ChatMessage } from '../models';
 */

// 用户相关
export { User, UserProfile } from './User';

// 认证相关
export { 
  LoginRequest, 
  LoginResponse, 
  UserInfo,
  RegisterRequest, 
  VerificationCodeRequest, 
  ResetPasswordRequest,
  RefreshTokenRequest 
} from './Auth';

// 求助请求相关
export { HelpRequest, RequestType, RequestStatistics } from './Request';
export {
  SeekerRequestDetail,
  SeekerTimelineItem,
  SeekerVolunteerBlock,
  SeekerBanner
} from './SeekerRequestDetail';

// 紧急求助相关
export { 
  EmergencyRequest, 
  EmergencyContact, 
  EmergencyResponse,
  CreateEmergencyRequest 
} from './Emergency';

// 消息相关
export { ChatMessage, ChatReadReceiptEvent, Conversation } from './Message';

// 订单相关
export { VolunteerOrder, OrderProgress, ProgressStep } from './Order';

// 评价相关
export { 
  Review, 
  ReviewReply, 
  ReviewTag, 
  ReviewStatistics,
  CreateReviewRequest 
} from './Review';

// 社区管理相关
export { 
  CommunityRequest, 
  VolunteerInfo, 
  AssignmentRecord, 
  CommunityStatistics,
  RequestTypeStat,
  WeeklyTrendItem,
  TopVolunteerItem,
  VolunteerSkillTag,
  VolunteerMgmtSummary,
  VolunteerMgmtRow,
  VolunteerManagementPayload,
  DispatchVolunteerProfile,
  DispatchScoredRequest,
  QuickDispatchPayload
} from './Community';

// 设置相关
export { 
  UserSettings, 
  NotificationSettings, 
  PrivacySettings, 
  AccessibilitySettings,
  SystemConfig 
} from './Settings';

// 通用类型
export { 
  ApiResponse, 
  PageRequest, 
  PageResponse, 
  VolunteerStatistics,
  Location, 
  UploadResponse, 
  Notification 
} from './Common';

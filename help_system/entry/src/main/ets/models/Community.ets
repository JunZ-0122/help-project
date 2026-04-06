/**
 * 社区管理实体
 */
export interface CommunityRequest {
  id: string;
  userId: string;
  userName: string;
  userPhone: string;
  type: 'medical' | 'shopping' | 'repair' | 'companion' | 'emergency' | 'other';
  title: string;
  description: string;
  location: string;
  urgency: 'low' | 'medium' | 'high' | 'emergency';
  status: 'pending' | 'assigned' | 'in-progress' | 'completed' | 'cancelled';
  volunteerId?: string;
  volunteerName?: string;
  createdAt: string;
  assignedAt?: string;
  completedAt?: string;
}

/**
 * 志愿者信息
 */
export interface VolunteerInfo {
  id: string;
  name: string;
  phone: string;
  avatar?: string;
  status: 'available' | 'busy' | 'offline';
  rating: number;
  completedOrders: number;
  currentOrders: number;
  skills: string[];
  location?: string;
  distance?: number;
}

/**
 * 分配记录
 */
export interface AssignmentRecord {
  id: string;
  requestId: string;
  volunteerId: string;
  volunteerName: string;
  assignedBy: string;
  assignedAt: string;
  status: 'pending' | 'accepted' | 'rejected' | 'completed';
  reason?: string;
}

/**
 * 社区统计
 */
export interface CommunityStatistics {
  totalRequests: number;
  pendingRequests: number;
  inProgressRequests: number;
  completedRequests: number;
  totalVolunteers: number;
  availableVolunteers: number;
  busyVolunteers: number;
  todayRequests: number;
  todayCompleted: number;
  averageResponseTime: number;
  averageCompletionTime: number;
  satisfactionRate: number;
  /** 本月已完成帮扶单数 */
  monthlyHelpCount?: number;
  /** 环比上月 %，如 12 表示 +12% */
  monthlyHelpTrendPercent?: number;
  /** 本月评价满意度 0–100（来自 reviews 平均分） */
  monthlySatisfactionPercent?: number;
  /** 较上月百分点变化，如 +3 表示 +3 个百分点 */
  monthlySatisfactionDeltaPoints?: number;
  /** 本月有完成单的志愿者人数 */
  activeVolunteersMonth?: number;
  /** 环比上月 % */
  activeVolunteersTrendPercent?: number;
  /** 较上月人数增减（用于展示 +8） */
  activeVolunteersMomDelta?: number;
  requestTypes?: RequestTypeStat[];
  weeklyTrend?: WeeklyTrendItem[];
  topVolunteers?: TopVolunteerItem[];
}

/**
 * 求助类型统计
 */
export interface RequestTypeStat {
  rank: number;
  name: string;
  type: string;
  count: number;
  percentage: number;
}

/**
 * 每周趋势数据
 */
export interface WeeklyTrendItem {
  date: string;
  dayOfWeek: string;
  count: number;
}

/**
 * 优秀志愿者
 */
export interface TopVolunteerItem {
  rank: number;
  id: string;
  name: string;
  avatar?: string;
  serviceCount: number;
  satisfaction: number;
}

/** 志愿者技能标签 */
export interface VolunteerSkillTag {
  code: string;
  label: string;
}

/** 志愿者管理页顶部汇总 */
export interface VolunteerMgmtSummary {
  totalVolunteers: number;
  onlineCount: number;
  inServiceCount: number;
  weekServices: number;
  avgRating: number;
}

/** 志愿者管理列表行 */
export interface VolunteerMgmtRow {
  id: string;
  name: string;
  avatar?: string;
  phoneMasked: string;
  location: string;
  uiStatus: 'online' | 'in_service' | 'offline';
  serviceCount: number;
  satisfaction: number;
  skills: VolunteerSkillTag[];
  quickDispatchEnabled: boolean;
}

/** 志愿者管理接口整体 */
export interface VolunteerManagementPayload {
  summary: VolunteerMgmtSummary;
  volunteers: VolunteerMgmtRow[];
}

/** 快速派单 — 志愿者卡片 */
export interface DispatchVolunteerProfile {
  id: string;
  name: string;
  avatar?: string;
  location: string;
  satisfaction: number;
  skills: VolunteerSkillTag[];
}

/** 快速派单 — 带匹配分的待派单 */
export interface DispatchScoredRequest {
  requestId: string;
  type: string;
  typeLabel: string;
  title: string;
  description: string;
  seekerName: string;
  location: string;
  urgency: string;
  emergency: boolean;
  createdAt: string;
  matchScore: number;
  distanceKm?: number;
  skillMatched: boolean;
}

/** 快速派单接口整体 */
export interface QuickDispatchPayload {
  volunteer: DispatchVolunteerProfile;
  smartMatches: DispatchScoredRequest[];
  otherPending: DispatchScoredRequest[];
}

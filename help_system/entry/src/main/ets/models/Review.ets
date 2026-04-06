/**
 * 评价相关实体
 */

/**
 * 评价实体
 */
export interface Review {
  id: string;
  orderId: string;
  requestId: string;
  reviewerId: string;
  reviewerName: string;
  reviewerAvatar?: string;
  revieweeId: string;
  revieweeName: string;
  rating: number;
  tags: string[];
  content: string;
  images?: string[];
  isAnonymous: boolean;
  createdAt: string;
  reply?: ReviewReply;
}

/**
 * 评价回复
 */
export interface ReviewReply {
  id: string;
  reviewId: string;
  content: string;
  createdAt: string;
}

/**
 * 评价标签
 */
export interface ReviewTag {
  id: string;
  name: string;
  type: 'positive' | 'negative' | 'neutral';
  icon?: string;
  count: number;
}

/**
 * 评价统计
 */
export interface ReviewStatistics {
  totalReviews: number;
  averageRating: number;
  ratingDistribution: RatingDistribution;
  tags: ReviewTag[];
}

/**
 * 评分分布
 */
export interface RatingDistribution {
  star1: number;
  star2: number;
  star3: number;
  star4: number;
  star5: number;
}

/**
 * 创建评价请求
 */
export interface CreateReviewRequest {
  orderId: string;
  rating: number;
  tags: string[];
  content: string;
  images?: string[];
  isAnonymous: boolean;
}

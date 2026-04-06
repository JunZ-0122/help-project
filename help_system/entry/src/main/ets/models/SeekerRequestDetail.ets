/**
 * GET /api/requests/{id}/seeker-detail 聚合结构
 */
import type { HelpRequest } from './Request';

export interface SeekerTimelineItem {
  label: string;
  time: string;
  state: 'done' | 'current' | 'upcoming';
}

export interface SeekerVolunteerBlock {
  id: string;
  name: string;
  phoneMasked: string;
  phone?: string;
  distanceKm?: number;
  avatarUrl?: string;
}

export interface SeekerBanner {
  tone: 'blue' | 'orange';
  title: string;
  subtitle: string;
}

export interface SeekerRequestDetail {
  request: HelpRequest;
  badgeLabel: string;
  badgeTone: string;
  headerTimeDisplay: string;
  volunteer?: SeekerVolunteerBlock;
  banner?: SeekerBanner;
  etaMinutes?: number;
  timeline: SeekerTimelineItem[];
}

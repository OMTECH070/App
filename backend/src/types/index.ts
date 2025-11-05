// User types
export interface User {
  id: string;
  email: string;
  displayName?: string;
  profilePhotoUrl?: string;
  studyGoalHours: number;
  timezone: string;
  isPremium: boolean;
  preferences: UserPreferences;
  createdAt: Date;
  updatedAt: Date;
}

export interface UserPreferences {
  notifications: NotificationPreferences;
  studyTimes: StudyTimePreferences;
  appearance: AppearancePreferences;
}

export interface NotificationPreferences {
  studyReminders: boolean;
  breakReminders: boolean;
  achievementNotifications: boolean;
  dailyProgressUpdates: boolean;
  reminderMinutes: number[];
}

export interface StudyTimePreferences {
  preferredStudyHours: {
    start: string; // HH:mm format
    end: string;   // HH:mm format
  };
  defaultSessionDuration: number; // in minutes
  defaultBreakDuration: number;   // in minutes
  studyStyle: 'pomodoro' | 'deep_work' | 'revision' | 'mixed';
}

export interface AppearancePreferences {
  theme: 'light' | 'dark' | 'system';
  accentColor: string;
}

// Subject types
export interface Subject {
  id: string;
  userId: string;
  name: string;
  color: string;
  difficulty: 1 | 2 | 3 | 4; // Easy, Medium, Hard, Very Hard
  priority: 1 | 2 | 3 | 4 | 5;
  isActive: boolean;
  masteryLevel: number; // 0.0 - 1.0
  totalStudyTime: number; // in seconds
  createdAt: Date;
  updatedAt: Date;
}

// Study Session types
export interface StudySession {
  id: string;
  userId: string;
  subjectId: string;
  subject: string;
  topics?: string;
  scheduledFor: Date;
  duration: number; // in seconds
  isCompleted: boolean;
  completedAt?: Date;
  qualityRating?: 1 | 2 | 3 | 4 | 5;
  notes?: string;
  createdAt: Date;
  updatedAt: Date;
}

// Study Task types
export interface StudyTask {
  id: string;
  userId: string;
  subjectId: string;
  title: string;
  description?: string;
  dueDate?: Date;
  estimatedDuration?: number; // in seconds
  priority: 1 | 2 | 3 | 4 | 5;
  isCompleted: boolean;
  completedAt?: Date;
  createdAt: Date;
  updatedAt: Date;
}

// Analytics types
export interface StudyProgress {
  userId: string;
  date: Date;
  totalStudyTime: number; // in seconds
  completedSessions: number;
  totalSessions: number;
  subjectsStudied: string[];
}

export interface WeeklyAnalytics {
  userId: string;
  weekStart: Date;
  weekEnd: Date;
  totalStudyTime: number; // in seconds
  completedSessions: number;
  subjectBreakdown: SubjectBreakdown[];
  averageDailyTime: number; // in seconds
  streakDays: number;
}

export interface SubjectBreakdown {
  subject: string;
  time: number; // in seconds
  percentage: number;
  sessions: number;
}

// AI types
export interface AIInsight {
  id: string;
  userId: string;
  type: 'productivity' | 'pattern' | 'recommendation' | 'warning';
  title: string;
  description: string;
  actionableTip?: string;
  priority: 'low' | 'medium' | 'high';
  createdAt: Date;
}

export interface StudyRecommendation {
  userId: string;
  recommendedSchedule: ScheduleRecommendation[];
  reasoning: string;
  confidence: number; // 0.0 - 1.0
  createdAt: Date;
}

export interface ScheduleRecommendation {
  subject: string;
  duration: number; // in minutes
  startTime: Date;
  topics: string[];
  priority: number;
  reasoning: string;
}

// Achievement types
export interface Achievement {
  id: string;
  title: string;
  description: string;
  icon: string;
  category: 'streak' | 'time' | 'sessions' | 'subjects' | 'special';
  requirement: AchievementRequirement;
  points: number;
}

export interface AchievementRequirement {
  type: 'total_hours' | 'streak_days' | 'sessions_completed' | 'subject_mastery';
  value: number;
  subject?: string; // For subject-specific achievements
}

export interface UserAchievement {
  userId: string;
  achievementId: string;
  unlockedAt: Date;
  progress: number; // 0.0 - 1.0
}

// Subscription types
export interface Subscription {
  userId: string;
  tier: 'free' | 'premium' | 'student_plus';
  status: 'active' | 'cancelled' | 'expired' | 'past_due';
  currentPeriodStart: Date;
  currentPeriodEnd: Date;
  cancelAtPeriodEnd: boolean;
  stripeSubscriptionId?: string;
  createdAt: Date;
  updatedAt: Date;
}

export interface SubscriptionPlan {
  id: string;
  name: string;
  tier: 'premium' | 'student_plus';
  price: number; // in cents
  currency: string;
  interval: 'month' | 'year';
  features: string[];
  isActive: boolean;
}

// API Response types
export interface ApiResponse<T = any> {
  success: boolean;
  data?: T;
  error?: ApiError;
  meta?: {
    pagination?: PaginationMeta;
    timestamp: string;
  };
}

export interface ApiError {
  code: string;
  message: string;
  details?: any;
}

export interface PaginationMeta {
  page: number;
  limit: number;
  total: number;
  totalPages: number;
  hasNext: boolean;
  hasPrev: boolean;
}

// Request types
export interface AuthenticatedRequest extends Request {
  user?: User;
}

// Notification types
export interface NotificationData {
  userId: string;
  type: 'study_reminder' | 'break_reminder' | 'achievement' | 'insight';
  title: string;
  body: string;
  data?: Record<string, any>;
  scheduledFor?: Date;
}
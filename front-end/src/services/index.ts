// Export de tous les services
export { default as AuthService } from './authService';
export { default as DocumentService } from './documentService';
export { default as RecipientService } from './recipientService';
export { default as SendService } from './sendService';
export { default as StatsService } from './statsService';
export { default as AccessService } from './accessService';
export { default as SubscriberService } from './subscriberService';
export { default as UserProfileService } from './userProfileService';
export { adminService } from './adminService';

// Export des types et utilitaires de base
export * from './api';

// Instances des services (singleton)
import AuthService from './authService';
import DocumentService from './documentService';
import RecipientService from './recipientService';
import SendService from './sendService';
import StatsService from './statsService';
import AccessService from './accessService';
import SubscriberService from './subscriberService';
import UserProfileService from './userProfileService';
import { adminService } from './adminService';

// Export des instances
export const authService = AuthService.getInstance();
export const documentService = new DocumentService();
export const recipientService = new RecipientService();
export const sendService = new SendService();
export const statsService = new StatsService();
export const accessService = new AccessService();
export const subscriberService = new SubscriberService();
export const userProfileService = new UserProfileService();

export type { 
  LoginCredentials, 
  RegisterData, 
  AuthState 
} from './authService';

export type { 
  Document, 
  DocumentMetadata 
} from './documentService';

export type { 
  Recipient 
} from './recipientService';

export type { 
  SendData, 
  SendResponse 
} from './sendService';

export type { 
  GlobalStats, 
  DocumentStats, 
  RecipientStats, 
  TimeSeriesData, 
  ActivityStats 
} from './statsService';

export type { 
  Subscriber, 
  SubscriberStats, 
  SubscribersResponse, 
  CreateSubscriberData, 
  UpdateSubscriberData 
} from './subscriberService';

export type { 
  UserProfile, 
  UpdateProfileData, 
  ChangePasswordData 
} from './userProfileService'; 

export type {
  AdminUser,
  AdminSubscription,
  AdminStats,
  CreateUserData,
  CreateSubscriptionData,
  DetailedStats
} from './adminService'; 
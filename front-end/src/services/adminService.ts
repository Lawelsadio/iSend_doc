import { ApiClient, ApiResponse, API_BASE_URL } from './api';

export interface AdminUser {
  id: number;
  nom: string;
  prenom: string;
  email: string;
  role: 'user' | 'admin';
  status: 'actif' | 'inactif';
  date_inscription: string;
  derniere_connexion?: string;
}

export interface AdminSubscription {
  id: number;
  abonne_id: number;
  type: 'gratuit' | 'premium' | 'entreprise' | 'illimite';
  status: 'actif' | 'expire' | 'annule';
  limite_documents: number;
  limite_destinataires: number;
  date_debut: string;
  date_fin?: string;
  date_creation: string;
}

export interface AdminStats {
  total_users: number;
  active_users: number;
  total_subscriptions: number;
  active_subscriptions: number;
  total_documents: number;
  total_views: number;
  documents_this_month: number;
  revenue_this_month: number;
}

export interface CreateUserData {
  nom: string;
  prenom: string;
  email: string;
  password: string;
  role: 'user' | 'admin';
}

export interface CreateSubscriptionData {
  abonne_id: number;
  type: 'gratuit' | 'premium' | 'entreprise' | 'illimite';
  status: 'actif' | 'expire' | 'annule';
  limite_documents: number;
  limite_destinataires: number;
  date_debut: string;
  date_fin?: string;
}

export interface DetailedStats {
  period: string;
  data: Array<{
    date: string;
    documents: number;
    views: number;
    users: number;
  }>;
}

class AdminService {
  // Récupérer tous les utilisateurs
  async getUsers(): Promise<ApiResponse<AdminUser[]>> {
    return ApiClient.get<AdminUser[]>('admin-users.php');
  }

  // Créer un nouvel utilisateur
  async createUser(userData: CreateUserData): Promise<ApiResponse<AdminUser>> {
    return ApiClient.post<AdminUser>('admin-users.php', userData as unknown as Record<string, unknown>);
  }

  // Mettre à jour un utilisateur
  async updateUser(userId: number, userData: Partial<CreateUserData>): Promise<ApiResponse<AdminUser>> {
    return ApiClient.put<AdminUser>(`admin-users.php`, { id: userId, ...userData } as unknown as Record<string, unknown>);
  }

  // Basculer le statut d'un utilisateur
  async toggleUserStatus(userId: number, currentStatus: string): Promise<ApiResponse<AdminUser>> {
    const newStatus = currentStatus === 'actif' ? 'inactif' : 'actif';
    return ApiClient.put<AdminUser>(`admin-users.php`, { id: userId, status: newStatus });
  }

  // Supprimer un utilisateur
  async deleteUser(userId: number): Promise<ApiResponse<void>> {
    return ApiClient.delete<void>(`admin-users.php?id=${userId}`);
  }

  // Récupérer tous les abonnements
  async getSubscriptions(): Promise<ApiResponse<AdminSubscription[]>> {
    return ApiClient.get<AdminSubscription[]>('admin-subscriptions.php');
  }

  // Créer un nouvel abonnement
  async createSubscription(subscriptionData: CreateSubscriptionData): Promise<ApiResponse<AdminSubscription>> {
    return ApiClient.post<AdminSubscription>('admin-subscriptions.php', subscriptionData as unknown as Record<string, unknown>);
  }

  // Mettre à jour un abonnement
  async updateSubscription(subscriptionId: number, subscriptionData: Partial<CreateSubscriptionData>): Promise<ApiResponse<AdminSubscription>> {
    return ApiClient.put<AdminSubscription>(`admin-subscriptions.php`, { id: subscriptionId, ...subscriptionData } as unknown as Record<string, unknown>);
  }

  // Basculer le statut d'un abonnement
  async toggleSubscriptionStatus(subscriptionId: number, currentStatus: string): Promise<ApiResponse<AdminSubscription>> {
    const newStatus = currentStatus === 'actif' ? 'annule' : 'actif';
    return ApiClient.put<AdminSubscription>(`admin-subscriptions.php`, { id: subscriptionId, status: newStatus });
  }

  // Supprimer un abonnement
  async deleteSubscription(subscriptionId: number): Promise<ApiResponse<void>> {
    return ApiClient.delete<void>(`admin-subscriptions.php?id=${subscriptionId}`);
  }

  // Récupérer les statistiques globales
  async getGlobalStats(): Promise<ApiResponse<AdminStats>> {
    return ApiClient.get<AdminStats>('admin-stats.php?action=global');
  }

  // Récupérer les statistiques détaillées
  async getDetailedStats(period: 'day' | 'week' | 'month' | 'year' = 'month'): Promise<ApiResponse<DetailedStats>> {
    return ApiClient.get<DetailedStats>(`admin-stats.php?action=detailed&period=${period}`);
  }

  // Valider les données utilisateur
  validateUserData(userData: CreateUserData): { isValid: boolean; errors: string[] } {
    const errors: string[] = [];

    if (!userData.nom?.trim()) errors.push('Le nom est requis');
    if (!userData.prenom?.trim()) errors.push('Le prénom est requis');
    if (!userData.email?.trim()) errors.push('L\'email est requis');
    if (!userData.password?.trim()) errors.push('Le mot de passe est requis');
    if (userData.password && userData.password.length < 6) errors.push('Le mot de passe doit contenir au moins 6 caractères');

    // Validation email
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (userData.email && !emailRegex.test(userData.email)) {
      errors.push('Format d\'email invalide');
    }

    return {
      isValid: errors.length === 0,
      errors
    };
  }

  // Valider les données d'abonnement
  validateSubscriptionData(subscriptionData: CreateSubscriptionData): { isValid: boolean; errors: string[] } {
    const errors: string[] = [];

    if (!subscriptionData.abonne_id) errors.push('L\'utilisateur est requis');
    if (!subscriptionData.type) errors.push('Le type d\'abonnement est requis');
    if (!subscriptionData.date_debut) errors.push('La date de début est requise');
    if (subscriptionData.limite_documents < 0) errors.push('La limite de documents doit être positive');
    if (subscriptionData.limite_destinataires < 0) errors.push('La limite de destinataires doit être positive');

    // Validation des dates
    if (subscriptionData.date_fin && subscriptionData.date_debut) {
      const dateDebut = new Date(subscriptionData.date_debut);
      const dateFin = new Date(subscriptionData.date_fin);
      if (dateFin <= dateDebut) {
        errors.push('La date de fin doit être postérieure à la date de début');
      }
    }

    return {
      isValid: errors.length === 0,
      errors
    };
  }
}

export const adminService = new AdminService(); 
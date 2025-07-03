import { ApiClient, ApiResponse, API_BASE_URL } from './api';

export interface UserProfile {
  id: number;
  email: string;
  nom: string;
  prenom: string;
  nom_complet: string;
  role: string;
  status: string;
  created_at: string;
  derniere_connexion: string;
}

export interface UpdateProfileData {
  nom: string;
  prenom: string;
  email: string;
}

export interface ChangePasswordData {
  current_password: string;
  new_password: string;
  confirm_password: string;
}

class UserProfileService {
  // Récupérer le profil utilisateur
  async getProfile(): Promise<ApiResponse<UserProfile>> {
    return ApiClient.get<UserProfile>('user-profile.php?action=get');
  }

  // Mettre à jour le profil utilisateur
  async updateProfile(data: UpdateProfileData): Promise<ApiResponse<{ message: string }>> {
    return ApiClient.put<{ message: string }>('user-profile.php?action=profile', data);
  }

  // Changer le mot de passe
  async changePassword(data: ChangePasswordData): Promise<ApiResponse<{ message: string }>> {
    return ApiClient.post<{ message: string }>('user-profile.php?action=password', data);
  }

  // Récupérer les informations de sécurité
  async getSecurityInfo(): Promise<ApiResponse<{
    derniere_connexion: string;
    nombre_connexions: number;
    tentatives_echouees: number;
    statut_compte: string;
  }>> {
    return ApiClient.get<{
      derniere_connexion: string;
      nombre_connexions: number;
      tentatives_echouees: number;
      statut_compte: string;
    }>('user-profile.php?action=security');
  }
}

export default UserProfileService; 
import { ApiClient, ApiResponse, API_BASE_URL } from './api';

export interface AccessValidation {
  valid: boolean;
  document_id?: number;
  document_nom?: string;
  destinataire_email?: string;
  date_expiration?: string;
  statut: 'actif' | 'expiré' | 'non_autorisé';
  message?: string;
}

export interface DocumentAccess {
  id: number;
  nom_fichier: string;
  titre: string;
  description?: string;
  date_upload: string;
  date_expiration?: string;
  taille: number;
  url_download: string;
  url_preview: string;
}

export interface AccessLog {
  id: number;
  document_id: number;
  destinataire_email: string;
  date_acces: string;
  type_acces: 'preview' | 'download';
  ip_address?: string;
  user_agent?: string;
}

export interface AccessStats {
  total_acces: number;
  acces_aujourd_hui: number;
  acces_cette_semaine: number;
  acces_ce_mois: number;
  documents_populaires: Array<{
    id: number;
    nom: string;
    acces: number;
  }>;
}

class AccessService {
  // Valider un token d'accès
  async validateAccessToken(token: string, email?: string): Promise<ApiResponse<AccessValidation>> {
    const endpoint = email 
      ? `access.php?token=${token}&email=${encodeURIComponent(email)}`
      : `access.php?token=${token}`;
    return ApiClient.get<AccessValidation>(endpoint);
  }

  // Récupérer les informations du document accessible
  async getDocumentAccess(token: string, email: string): Promise<ApiResponse<DocumentAccess>> {
    return ApiClient.get<DocumentAccess>(`access.php?token=${token}&email=${encodeURIComponent(email)}&action=document`);
  }

  // Télécharger le document
  async downloadDocument(token: string, email: string): Promise<Blob | null> {
    try {
      const url = `${API_BASE_URL}/access.php?token=${token}&email=${encodeURIComponent(email)}&action=download`;
      
      const response = await fetch(url);

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}`);
      }

      return await response.blob();
    } catch (error) {
      console.error('Erreur lors du téléchargement:', error);
      return null;
    }
  }

  // Obtenir l'URL de prévisualisation
  getPreviewUrl(token: string, email: string): string {
    return `${API_BASE_URL}/access.php?token=${token}&email=${encodeURIComponent(email)}&action=preview`;
  }

  // Enregistrer un accès (pour les statistiques)
  async logAccess(token: string, email: string, type: 'preview' | 'download'): Promise<ApiResponse<{ message: string }>> {
    return ApiClient.post<{ message: string }>('access.php', {
      token,
      email,
      action: 'log',
      type
    } as unknown as Record<string, unknown>);
  }

  // Récupérer l'historique des accès pour un document
  async getAccessHistory(documentId: number): Promise<ApiResponse<AccessLog[]>> {
    return ApiClient.get<AccessLog[]>(`access.php?action=history&document_id=${documentId}`);
  }

  // Récupérer les statistiques d'accès
  async getAccessStats(period?: 'day' | 'week' | 'month'): Promise<ApiResponse<AccessStats>> {
    const endpoint = period 
      ? `access.php?action=stats&period=${period}`
      : 'access.php?action=stats';
    return ApiClient.get<AccessStats>(endpoint);
  }

  // Vérifier si un email est autorisé pour un document
  async checkEmailAuthorization(token: string, email: string): Promise<ApiResponse<{
    authorized: boolean;
    message?: string;
  }>> {
    return ApiClient.post<{
      authorized: boolean;
      message?: string;
    }>('access.php', {
      token,
      email,
      action: 'check_authorization'
    } as unknown as Record<string, unknown>);
  }

  // Demander un nouveau lien d'accès
  async requestNewAccess(documentId: number, email: string, reason?: string): Promise<ApiResponse<{
    success: boolean;
    message: string;
    new_token?: string;
  }>> {
    return ApiClient.post<{
      success: boolean;
      message: string;
      new_token?: string;
    }>('access.php', {
      document_id: documentId,
      email,
      action: 'request_new',
      reason
    } as unknown as Record<string, unknown>);
  }

  // Signaler un problème d'accès
  async reportAccessIssue(token: string, email: string, issue: string): Promise<ApiResponse<{ message: string }>> {
    return ApiClient.post<{ message: string }>('access.php', {
      token,
      email,
      action: 'report_issue',
      issue
    } as unknown as Record<string, unknown>);
  }

  // Récupérer les informations de sécurité du document
  async getDocumentSecurityInfo(token: string): Promise<ApiResponse<{
    watermark_enabled: boolean;
    download_allowed: boolean;
    print_allowed: boolean;
    copy_allowed: boolean;
    expiration_date?: string;
    access_count: number;
    max_access_count?: number;
  }>> {
    return ApiClient.get<{
      watermark_enabled: boolean;
      download_allowed: boolean;
      print_allowed: boolean;
      copy_allowed: boolean;
      expiration_date?: string;
      access_count: number;
      max_access_count?: number;
    }>(`access.php?token=${token}&action=security`);
  }

  // Confirmer la lecture du document
  async confirmReading(token: string, email: string): Promise<ApiResponse<{ message: string }>> {
    return ApiClient.post<{ message: string }>('access.php', {
      token,
      email,
      action: 'confirm_reading'
    } as unknown as Record<string, unknown>);
  }

  // Récupérer les métadonnées du document (sans le contenu)
  async getDocumentMetadata(token: string): Promise<ApiResponse<{
    titre: string;
    description?: string;
    date_upload: string;
    taille: number;
    format: string;
    tags?: string[];
  }>> {
    return ApiClient.get<{
      titre: string;
      description?: string;
      date_upload: string;
      taille: number;
      format: string;
      tags?: string[];
    }>(`access.php?token=${token}&action=metadata`);
  }
}

export default AccessService; 
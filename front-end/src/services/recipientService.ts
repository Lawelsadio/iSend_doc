import { ApiClient, ApiResponse } from './api';

export interface Recipient {
  id: number;
  nom: string;
  prenom: string;
  email: string;
  numero?: string;
  statut: 'actif' | 'inactif' | 'expiré';
  date_creation: string;
  utilisateur_id: number;
  documents_recus?: number;
}

export interface CreateRecipientData {
  nom: string;
  prenom: string;
  email: string;
  numero?: string;
}

export interface UpdateRecipientData {
  id: number;
  nom?: string;
  prenom?: string;
  email?: string;
  numero?: string;
  statut?: 'actif' | 'inactif' | 'expiré';
}

export interface RecipientStats {
  total: number;
  actifs: number;
  inactifs: number;
  expires: number;
  nouveaux_ce_mois: number;
}

class RecipientService {
  // Récupérer tous les destinataires
  async getRecipients(): Promise<ApiResponse<Recipient[]>> {
    return ApiClient.get<Recipient[]>('destinataires-crud.php');
  }

  // Récupérer un destinataire spécifique
  async getRecipient(id: number): Promise<ApiResponse<Recipient>> {
    return ApiClient.get<Recipient>(`destinataires-crud.php?id=${id}`);
  }

  // Créer un nouveau destinataire
  async createRecipient(data: CreateRecipientData): Promise<ApiResponse<Recipient>> {
    return ApiClient.post<Recipient>('destinataires-crud.php', data as unknown as Record<string, unknown>);
  }

  // Mettre à jour un destinataire
  async updateRecipient(data: UpdateRecipientData): Promise<ApiResponse<Recipient>> {
    return ApiClient.put<Recipient>('destinataires-crud.php', data as unknown as Record<string, unknown>);
  }

  // Supprimer un destinataire
  async deleteRecipient(id: number): Promise<ApiResponse<{ message: string }>> {
    return ApiClient.delete<{ message: string }>(`destinataires-crud.php?id=${id}`);
  }

  // Rechercher des destinataires
  async searchRecipients(query: string): Promise<ApiResponse<Recipient[]>> {
    return ApiClient.get<Recipient[]>(`destinataires-crud.php?search=${encodeURIComponent(query)}`);
  }

  // Récupérer les statistiques des destinataires
  async getRecipientStats(): Promise<ApiResponse<RecipientStats>> {
    return ApiClient.get<RecipientStats>('stats.php?type=recipients');
  }

  // Activer/Désactiver un destinataire
  async toggleRecipientStatus(id: number, statut: 'actif' | 'inactif'): Promise<ApiResponse<Recipient>> {
    return ApiClient.put<Recipient>('destinataires-crud.php', {
      id,
      statut
    } as unknown as Record<string, unknown>);
  }

  // Récupérer les destinataires par statut
  async getRecipientsByStatus(statut: 'actif' | 'inactif' | 'expiré'): Promise<ApiResponse<Recipient[]>> {
    return ApiClient.get<Recipient[]>(`destinataires-crud.php?statut=${statut}`);
  }

  // Importer des destinataires en lot (CSV)
  async importRecipients(file: File): Promise<ApiResponse<{ imported: number; errors: string[] }>> {
    return ApiClient.uploadFile<{ imported: number; errors: string[] }>('destinataires-crud.php?action=import', file);
  }

  // Exporter les destinataires (CSV)
  async exportRecipients(): Promise<Blob | null> {
    try {
      const token = localStorage.getItem('authToken');
      const url = `${ApiClient['API_BASE_URL']}/destinataires-crud.php?action=export`;
      
      const response = await fetch(url, {
        headers: {
          ...(token && { 'Authorization': `Bearer ${token}` })
        }
      });

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}`);
      }

      return await response.blob();
    } catch (error) {
      console.error('Erreur lors de l\'export:', error);
      return null;
    }
  }

  // Valider un email de destinataire
  async validateEmail(email: string): Promise<ApiResponse<{ valid: boolean; exists: boolean }>> {
    return ApiClient.get<{ valid: boolean; exists: boolean }>(`destinataires-crud.php?action=validate&email=${encodeURIComponent(email)}`);
  }

  // Récupérer l'historique des envois d'un destinataire
  async getRecipientHistory(id: number): Promise<ApiResponse<Array<{
    document_id: number;
    document_nom: string;
    date_envoi: string;
    statut: 'envoyé' | 'lu' | 'expiré';
  }>>> {
    return ApiClient.get<Array<{
      document_id: number;
      document_nom: string;
      date_envoi: string;
      statut: 'envoyé' | 'lu' | 'expiré';
    }>>(`destinataires-crud.php?action=history&id=${id}`);
  }
}

export default RecipientService; 
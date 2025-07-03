import { ApiClient, ApiResponse } from './api';

export interface SendData {
  document_id: number;
  destinataires: string[]; // emails des destinataires
  message?: string;
  expiration?: string; // date d'expiration YYYY-MM-DD
  notification_email?: boolean;
  send_pdf?: boolean; // Nouveau paramètre pour indiquer l'envoi de PDF sécurisé
  send_normal_pdf?: boolean; // Nouveau paramètre pour indiquer l'envoi de PDF normal
}

export interface SendResponse {
  success: boolean;
  message: string;
  links: Array<{
    email: string;
    access_token: string;
    access_url: string;
  }>;
  failed_emails?: string[];
}

export interface SendHistory {
  id: number;
  document_id: number;
  document_nom: string;
  destinataire_email: string;
  date_envoi: string;
  statut: 'envoyé' | 'lu' | 'expiré' | 'erreur';
  date_lecture?: string;
  date_expiration?: string;
}

export interface SendStats {
  total_envoyes: number;
  total_lus: number;
  total_expires: number;
  taux_lecture: number; // pourcentage
  moyenne_temps_lecture: number; // en heures
}

class SendService {
  // Envoyer un document aux destinataires
  async sendDocument(data: SendData): Promise<ApiResponse<SendResponse>> {
    return ApiClient.post<SendResponse>('send.php', data as unknown as Record<string, unknown>);
  }

  // Envoyer un PDF sécurisé avec mot de passe aux destinataires
  async sendSecurePDF(data: SendData): Promise<ApiResponse<SendResponse>> {
    return ApiClient.post<SendResponse>('send-secure-pdf.php', data as unknown as Record<string, unknown>);
  }

  // Envoyer un PDF normal aux destinataires
  async sendNormalPDF(data: {
    destinataires: Array<{ email: string; nom: string }>;
    nom_document: string;
    chemin_fichier: string;
    metadata: Record<string, string>;
  }): Promise<ApiResponse<SendResponse>> {
    // Récupérer le token d'authentification
    const token = localStorage.getItem('authToken');
    
    // Ajouter le token aux données
    const dataWithToken = {
      ...data,
      token: token
    };
    
    return ApiClient.post<SendResponse>('send-normal-pdf.php', dataWithToken as unknown as Record<string, unknown>);
  }

  // Récupérer l'historique des envois
  async getSendHistory(documentId?: number): Promise<ApiResponse<SendHistory[]>> {
    const endpoint = documentId 
      ? `send.php?action=history&document_id=${documentId}`
      : 'send.php?action=history';
    return ApiClient.get<SendHistory[]>(endpoint);
  }

  // Récupérer les statistiques d'envoi
  async getSendStats(period?: 'day' | 'week' | 'month' | 'year'): Promise<ApiResponse<SendStats>> {
    const endpoint = period 
      ? `stats.php?type=send&period=${period}`
      : 'stats.php?type=send';
    return ApiClient.get<SendStats>(endpoint);
  }

  // Récupérer les détails d'un envoi spécifique
  async getSendDetails(sendId: number): Promise<ApiResponse<SendHistory>> {
    return ApiClient.get<SendHistory>(`send.php?action=details&id=${sendId}`);
  }

  // Renvoyer un document à un destinataire
  async resendDocument(sendId: number): Promise<ApiResponse<SendResponse>> {
    return ApiClient.post<SendResponse>('send.php', {
      action: 'resend',
      send_id: sendId
    } as unknown as Record<string, unknown>);
  }

  // Annuler un envoi (si pas encore lu)
  async cancelSend(sendId: number): Promise<ApiResponse<{ message: string }>> {
    return ApiClient.delete<{ message: string }>(`send.php?id=${sendId}`);
  }

  // Prolonger l'expiration d'un envoi
  async extendExpiration(sendId: number, newExpiration: string): Promise<ApiResponse<SendHistory>> {
    return ApiClient.put<SendHistory>('send.php', {
      action: 'extend',
      send_id: sendId,
      expiration: newExpiration
    } as unknown as Record<string, unknown>);
  }

  // Récupérer les liens d'accès pour un document
  async getAccessLinks(documentId: number): Promise<ApiResponse<Array<{
    email: string;
    access_token: string;
    access_url: string;
    statut: 'actif' | 'expiré' | 'lu';
  }>>> {
    return ApiClient.get<Array<{
      email: string;
      access_token: string;
      access_url: string;
      statut: 'actif' | 'expiré' | 'lu';
    }>>(`send.php?action=links&document_id=${documentId}`);
  }

  // Envoyer un rappel à un destinataire
  async sendReminder(sendId: number): Promise<ApiResponse<{ message: string }>> {
    return ApiClient.post<{ message: string }>('send.php', {
      action: 'reminder',
      send_id: sendId
    } as unknown as Record<string, unknown>);
  }

  // Valider les emails avant envoi
  async validateEmails(emails: string[]): Promise<ApiResponse<{
    valid: string[];
    invalid: string[];
    existing: string[];
  }>> {
    return ApiClient.post<{
      valid: string[];
      invalid: string[];
      existing: string[];
    }>('send.php', {
      action: 'validate',
      emails
    } as unknown as Record<string, unknown>);
  }

  // Récupérer les modèles de messages
  async getMessageTemplates(): Promise<ApiResponse<Array<{
    id: number;
    nom: string;
    contenu: string;
    categorie: string;
  }>>> {
    return ApiClient.get<Array<{
      id: number;
      nom: string;
      contenu: string;
      categorie: string;
    }>>('send.php?action=templates');
  }

  // Créer un modèle de message
  async createMessageTemplate(data: {
    nom: string;
    contenu: string;
    categorie: string;
  }): Promise<ApiResponse<{ id: number; message: string }>> {
    return ApiClient.post<{ id: number; message: string }>('send.php', {
      action: 'create_template',
      ...data
    } as unknown as Record<string, unknown>);
  }

  // Générer un rapport d'envoi (PDF)
  async generateSendReport(documentId: number): Promise<Blob | null> {
    try {
      const token = localStorage.getItem('authToken');
      const url = `${ApiClient['API_BASE_URL']}/send.php?action=report&document_id=${documentId}`;
      
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
      console.error('Erreur lors de la génération du rapport:', error);
      return null;
    }
  }
}

export default SendService; 
import { ApiClient, ApiResponse, API_BASE_URL } from './api';

export interface GlobalStats {
  total_documents: number;
  total_destinataires: number;
  total_envoyes: number;
  total_vues: number;
  taux_lecture: number; // pourcentage
  documents_ce_mois: number;
  vues_ce_mois: number;
  nouveaux_destinataires_ce_mois: number;
}

export interface DocumentStats {
  id: number;
  nom_fichier: string;
  titre: string;
  vues: number;
  destinataires: number;
  date_upload: string;
  dernier_acces?: string;
  taux_lecture: number;
  temps_moyen_lecture?: number; // en minutes
}

export interface RecipientStats {
  total: number;
  actifs: number;
  inactifs: number;
  expires: number;
  nouveaux_ce_mois: number;
  top_destinataires: Array<{
    email: string;
    nom: string;
    prenom: string;
    documents_recus: number;
    derniere_activite: string;
  }>;
}

export interface TimeSeriesData {
  date: string;
  documents: number;
  vues: number;
  envois: number;
}

export interface ActivityStats {
  aujourd_hui: {
    documents_uploades: number;
    documents_envoyes: number;
    vues: number;
    nouveaux_destinataires: number;
  };
  cette_semaine: {
    documents_uploades: number;
    documents_envoyes: number;
    vues: number;
    nouveaux_destinataires: number;
  };
  ce_mois: {
    documents_uploades: number;
    documents_envoyes: number;
    vues: number;
    nouveaux_destinataires: number;
  };
}

class StatsService {
  // Récupérer les statistiques globales
  async getGlobalStats(): Promise<ApiResponse<GlobalStats>> {
    return ApiClient.get<GlobalStats>('stats.php');
  }

  // Récupérer les statistiques des documents
  async getDocumentStats(period?: 'day' | 'week' | 'month' | 'year'): Promise<ApiResponse<DocumentStats[]>> {
    const endpoint = period 
      ? `stats.php?type=documents&period=${period}`
      : 'stats.php?type=documents';
    return ApiClient.get<DocumentStats[]>(endpoint);
  }

  // Récupérer les statistiques d'un document spécifique
  async getDocumentStatsById(id: number): Promise<ApiResponse<DocumentStats>> {
    return ApiClient.get<DocumentStats>(`stats.php?type=document&id=${id}`);
  }

  // Récupérer les statistiques des destinataires
  async getRecipientStats(): Promise<ApiResponse<RecipientStats>> {
    return ApiClient.get<RecipientStats>('stats.php?type=recipients');
  }

  // Récupérer les données de série temporelle
  async getTimeSeriesData(period: 'week' | 'month' | 'year'): Promise<ApiResponse<TimeSeriesData[]>> {
    return ApiClient.get<TimeSeriesData[]>(`stats.php?type=timeseries&period=${period}`);
  }

  // Récupérer les statistiques d'activité
  async getActivityStats(): Promise<ApiResponse<ActivityStats>> {
    return ApiClient.get<ActivityStats>('stats.php?type=activity');
  }

  // Récupérer les statistiques d'envoi
  async getSendStats(period?: 'day' | 'week' | 'month' | 'year'): Promise<ApiResponse<{
    total_envoyes: number;
    total_lus: number;
    total_expires: number;
    taux_lecture: number;
    moyenne_temps_lecture: number;
  }>> {
    const endpoint = period 
      ? `stats.php?type=send&period=${period}`
      : 'stats.php?type=send';
    return ApiClient.get<{
      total_envoyes: number;
      total_lus: number;
      total_expires: number;
      taux_lecture: number;
      moyenne_temps_lecture: number;
    }>(endpoint);
  }

  // Récupérer les statistiques de performance
  async getPerformanceStats(): Promise<ApiResponse<{
    temps_reponse_moyen: number;
    taux_erreur: number;
    documents_populaires: Array<{
      id: number;
      nom: string;
      vues: number;
    }>;
    heures_pointe: Array<{
      heure: number;
      activite: number;
    }>;
  }>> {
    return ApiClient.get<{
      temps_reponse_moyen: number;
      taux_erreur: number;
      documents_populaires: Array<{
        id: number;
        nom: string;
        vues: number;
      }>;
      heures_pointe: Array<{
        heure: number;
        activite: number;
      }>;
    }>('stats.php?type=performance');
  }

  // Récupérer les statistiques de sécurité
  async getSecurityStats(): Promise<ApiResponse<{
    tentatives_acces_echouees: number;
    documents_expires: number;
    acces_non_autorises: number;
    derniers_incidents: Array<{
      date: string;
      type: string;
      description: string;
      severite: 'faible' | 'moyenne' | 'elevee';
    }>;
  }>> {
    return ApiClient.get<{
      tentatives_acces_echouees: number;
      documents_expires: number;
      acces_non_autorises: number;
      derniers_incidents: Array<{
        date: string;
        type: string;
        description: string;
        severite: 'faible' | 'moyenne' | 'elevee';
      }>;
    }>('stats.php?type=security');
  }

  // Générer un rapport de statistiques (PDF)
  async generateStatsReport(period: 'week' | 'month' | 'year'): Promise<Blob | null> {
    try {
      const token = localStorage.getItem('authToken');
      const url = `${API_BASE_URL}/stats.php?action=report&period=${period}${token ? `&token=${encodeURIComponent(token)}` : ''}`;
      
      const response = await fetch(url);

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}`);
      }

      return await response.blob();
    } catch (error) {
      console.error('Erreur lors de la génération du rapport:', error);
      return null;
    }
  }

  // Exporter les statistiques en CSV
  async exportStats(type: 'documents' | 'recipients' | 'sends', period?: string): Promise<Blob | null> {
    try {
      const token = localStorage.getItem('authToken');
      const url = `${API_BASE_URL}/stats.php?action=export&type=${type}${period ? `&period=${period}` : ''}`;
      
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
      console.error('Erreur lors de l\'export des statistiques:', error);
      return null;
    }
  }

  // Récupérer les alertes et notifications
  async getAlerts(): Promise<ApiResponse<Array<{
    id: number;
    type: 'warning' | 'error' | 'info' | 'success';
    titre: string;
    message: string;
    date: string;
    lu: boolean;
  }>>> {
    return ApiClient.get<Array<{
      id: number;
      type: 'warning' | 'error' | 'info' | 'success';
      titre: string;
      message: string;
      date: string;
      lu: boolean;
    }>>('stats.php?action=alerts');
  }

  // Marquer une alerte comme lue
  async markAlertAsRead(alertId: number): Promise<ApiResponse<{ message: string }>> {
    return ApiClient.put<{ message: string }>('stats.php', {
      action: 'mark_alert_read',
      alert_id: alertId
    } as unknown as Record<string, unknown>);
  }
}

export default StatsService; 
import { ApiClient, ApiResponse, API_BASE_URL } from './api';

export interface Subscriber {
  id: number;
  nom: string;
  prenom: string;
  email: string;
  telephone?: string;
  status: 'actif' | 'expire' | 'inactif';
  date_ajout: string;
  documents_recus?: number;
  dernier_envoi?: string;
}

export interface SubscriberStats {
  total: number;
  actifs: number;
  expires: number;
}

export interface SubscribersResponse {
  subscribers: Subscriber[];
  stats: SubscriberStats;
}

export interface CreateSubscriberData {
  nom: string;
  prenom: string;
  email: string;
  telephone?: string;
}

export interface UpdateSubscriberData {
  id: number;
  nom?: string;
  prenom?: string;
  email?: string;
  telephone?: string;
  status?: 'actif' | 'expire' | 'inactif';
}

class SubscriberService {
  // Récupérer tous les abonnés
  async getSubscribers(): Promise<ApiResponse<SubscribersResponse>> {
    return ApiClient.get<SubscribersResponse>('subscribers.php');
  }

  // Créer un nouvel abonné
  async createSubscriber(data: CreateSubscriberData): Promise<ApiResponse<Subscriber>> {
    return ApiClient.post<Subscriber>('subscribers.php', data as unknown as Record<string, unknown>);
  }

  // Mettre à jour un abonné
  async updateSubscriber(data: UpdateSubscriberData): Promise<ApiResponse<Subscriber>> {
    return ApiClient.put<Subscriber>('subscribers.php', data as unknown as Record<string, unknown>);
  }

  // Supprimer un abonné
  async deleteSubscriber(id: number): Promise<ApiResponse<{ message: string }>> {
    return ApiClient.delete<{ message: string }>('subscribers.php', { id } as unknown as Record<string, unknown>);
  }

  // Basculer le statut d'un abonné
  async toggleStatus(id: number, currentStatus: string): Promise<ApiResponse<Subscriber>> {
    let newStatus: 'actif' | 'expire' | 'inactif';
    if (currentStatus === 'actif') newStatus = 'expire';
    else if (currentStatus === 'expire') newStatus = 'actif';
    else newStatus = 'actif';
    return this.updateSubscriber({ id, status: newStatus });
  }

  // Rechercher des abonnés
  async searchSubscribers(query: string): Promise<ApiResponse<SubscribersResponse>> {
    // Pour l'instant, on utilise le filtrage côté client
    // On pourrait ajouter un paramètre de recherche à l'API plus tard
    const response = await this.getSubscribers();
    if (response.success && response.data) {
      const filteredSubscribers = response.data.subscribers.filter(sub =>
        sub.email.toLowerCase().includes(query.toLowerCase()) ||
        sub.nom.toLowerCase().includes(query.toLowerCase()) ||
        sub.prenom.toLowerCase().includes(query.toLowerCase())
      );
      
      const total = filteredSubscribers.length;
      const actifs = filteredSubscribers.filter(s => s.status === 'actif').length;
      const expires = total - actifs;
      
      return {
        success: true,
        data: {
          subscribers: filteredSubscribers,
          stats: { total, actifs, expires }
        }
      };
    }
    return response;
  }

  // Valider un email
  validateEmail(email: string): boolean {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
  }

  // Valider les données d'un abonné
  validateSubscriberData(data: CreateSubscriberData): { isValid: boolean; errors: string[] } {
    const errors: string[] = [];
    
    if (!data.nom?.trim()) {
      errors.push('Le nom est requis');
    }
    
    if (!data.prenom?.trim()) {
      errors.push('Le prénom est requis');
    }
    
    if (!data.email?.trim()) {
      errors.push('L\'email est requis');
    } else if (!this.validateEmail(data.email)) {
      errors.push('L\'email n\'est pas valide');
    }
    
    return {
      isValid: errors.length === 0,
      errors
    };
  }
}

export default SubscriberService; 
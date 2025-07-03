// Configuration de l'API
export const API_BASE_URL = 'http://localhost:8888/isend-document-flow/backend-php/api';

// Types de base
export interface ApiResponse<T = unknown> {
  success: boolean;
  message?: string;
  data?: T;
  error?: string;
}

export interface User {
  id: number;
  email: string;
  nom: string;
  prenom: string;
  role: 'user' | 'admin';
  created_at: string;
}

export interface AuthResponse {
  token: string;
  user: User;
}

// Classe utilitaire pour les appels API
export class ApiClient {
  private static getAuthHeaders(): HeadersInit {
    return {
      'Content-Type': 'application/json'
    };
  }

  private static getToken(): string | null {
    return localStorage.getItem('authToken');
  }

  private static addTokenToUrl(url: string): string {
    const token = this.getToken();
    if (token) {
      const separator = url.includes('?') ? '&' : '?';
      return `${url}${separator}token=${encodeURIComponent(token)}`;
    }
    return url;
  }

  static async request<T>(
    endpoint: string,
    options: RequestInit = {}
  ): Promise<ApiResponse<T>> {
    try {
      let url = `${API_BASE_URL}/${endpoint}`;
      
      // Ajouter le token à l'URL pour MAMP
      url = this.addTokenToUrl(url);
      
      const config: RequestInit = {
        headers: this.getAuthHeaders(),
        ...options
      };

      const response = await fetch(url, config);
      const data = await response.json();

      if (!response.ok) {
        // Gestion spéciale des erreurs 401 (non autorisé)
        if (response.status === 401) {
          console.log('Token expiré ou invalide, redirection vers la connexion...');
          
          // Nettoyer le localStorage
          localStorage.removeItem('authToken');
          localStorage.removeItem('user');
          
          // Rediriger vers la page de connexion
          if (window.location.pathname !== '/login') {
            window.location.href = '/login';
          }
          
          return {
            success: false,
            error: 'Session expirée, veuillez vous reconnecter'
          };
        }
        
        throw new Error(data.error || `HTTP ${response.status}`);
      }

      return data;
    } catch (error) {
      console.error('API Error:', error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Erreur réseau'
      };
    }
  }

  // Méthodes utilitaires
  static async get<T>(endpoint: string): Promise<ApiResponse<T>> {
    return this.request<T>(endpoint, { method: 'GET' });
  }

  static async post<T>(endpoint: string, data: Record<string, unknown>): Promise<ApiResponse<T>> {
    return this.request<T>(endpoint, {
      method: 'POST',
      body: JSON.stringify(data)
    });
  }

  static async put<T>(endpoint: string, data: Record<string, unknown>): Promise<ApiResponse<T>> {
    return this.request<T>(endpoint, {
      method: 'PUT',
      body: JSON.stringify(data)
    });
  }

  static async delete<T>(endpoint: string, data?: Record<string, unknown>): Promise<ApiResponse<T>> {
    return this.request<T>(endpoint, {
      method: 'DELETE',
      ...(data ? { body: JSON.stringify(data) } : {})
    });
  }

  // Upload de fichiers
  static async uploadFile<T>(endpoint: string, file: File, additionalData?: Record<string, string>): Promise<ApiResponse<T>> {
    try {
      const formData = new FormData();
      formData.append('document', file);
      
      if (additionalData) {
        Object.entries(additionalData).forEach(([key, value]) => {
          formData.append(key, value);
        });
      }

      const token = this.getToken();
      let url = `${API_BASE_URL}/${endpoint}`;
      
      // Ajouter le token à l'URL pour MAMP
      if (token) {
        const separator = url.includes('?') ? '&' : '?';
        url = `${url}${separator}token=${encodeURIComponent(token)}`;
      }
      
      const response = await fetch(url, {
        method: 'POST',
        body: formData
      });

      const data = await response.json();

      if (!response.ok) {
        throw new Error(data.error || `HTTP ${response.status}`);
      }

      return data;
    } catch (error) {
      console.error('Upload Error:', error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Erreur lors de l\'upload'
      };
    }
  }
} 
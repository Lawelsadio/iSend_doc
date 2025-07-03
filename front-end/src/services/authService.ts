import { ApiClient, ApiResponse, AuthResponse, User } from './api';

export interface LoginCredentials {
  email: string;
  password: string;
}

export interface RegisterData {
  email: string;
  password: string;
  nom: string;
  prenom: string;
}

export interface AuthState {
  user: User | null;
  token: string | null;
  isAuthenticated: boolean;
}

class AuthService {
  private static instance: AuthService;
  private authState: AuthState = {
    user: null,
    token: null,
    isAuthenticated: false
  };

  private constructor() {
    this.loadAuthFromStorage();
  }

  static getInstance(): AuthService {
    if (!AuthService.instance) {
      AuthService.instance = new AuthService();
    }
    return AuthService.instance;
  }

  // Charger l'état d'authentification depuis le localStorage
  private loadAuthFromStorage(): void {
    const token = localStorage.getItem('authToken');
    const userStr = localStorage.getItem('user');
    
    if (token && userStr) {
      try {
        const user = JSON.parse(userStr);
        
        // Vérifier si le token n'est pas expiré
        if (this.isTokenExpired(token)) {
          console.log('Token expiré, déconnexion automatique');
          this.clearAuth();
          return;
        }
        
        this.authState = {
          user,
          token,
          isAuthenticated: true
        };
      } catch (error) {
        console.error('Erreur lors du chargement de l\'utilisateur:', error);
        this.clearAuth();
      }
    }
  }

  // Vérifier si le token JWT est expiré
  private isTokenExpired(token: string): boolean {
    try {
      const payload = JSON.parse(atob(token.split('.')[1]));
      const currentTime = Math.floor(Date.now() / 1000);
      return payload.exp < currentTime;
    } catch (error) {
      console.error('Erreur lors de la vérification du token:', error);
      return true; // Considérer comme expiré en cas d'erreur
    }
  }

  // Vérifier si le token va expirer bientôt (dans les 5 minutes)
  private isTokenExpiringSoon(token: string): boolean {
    try {
      const payload = JSON.parse(atob(token.split('.')[1]));
      const currentTime = Math.floor(Date.now() / 1000);
      const fiveMinutes = 5 * 60; // 5 minutes en secondes
      return payload.exp < (currentTime + fiveMinutes);
    } catch (error) {
      return true;
    }
  }

  // Sauvegarder l'état d'authentification
  private saveAuthToStorage(token: string, user: User): void {
    localStorage.setItem('authToken', token);
    localStorage.setItem('user', JSON.stringify(user));
  }

  // Effacer l'état d'authentification
  private clearAuth(): void {
    localStorage.removeItem('authToken');
    localStorage.removeItem('user');
    this.authState = {
      user: null,
      token: null,
      isAuthenticated: false
    };
  }

  // Connexion
  async login(credentials: LoginCredentials): Promise<ApiResponse<AuthResponse>> {
    try {
      const response = await ApiClient.post<AuthResponse>('auth.php', {
        action: 'login',
        ...credentials
      } as unknown as Record<string, unknown>);
      
      if (response.success && response.data) {
        this.authState = {
          user: response.data.user,
          token: response.data.token,
          isAuthenticated: true
        };
        this.saveAuthToStorage(response.data.token, response.data.user);
      }
      
      return response;
    } catch (error) {
      console.error('Erreur de connexion:', error);
      return {
        success: false,
        error: 'Erreur lors de la connexion'
      };
    }
  }

  // Inscription
  async register(data: RegisterData): Promise<ApiResponse<AuthResponse>> {
    try {
      const response = await ApiClient.post<AuthResponse>('auth.php', {
        action: 'register',
        ...data
      } as unknown as Record<string, unknown>);
      
      if (response.success && response.data) {
        this.authState = {
          user: response.data.user,
          token: response.data.token,
          isAuthenticated: true
        };
        this.saveAuthToStorage(response.data.token, response.data.user);
      }
      
      return response;
    } catch (error) {
      console.error('Erreur d\'inscription:', error);
      return {
        success: false,
        error: 'Erreur lors de l\'inscription'
      };
    }
  }

  // Déconnexion
  logout(): void {
    this.clearAuth();
  }

  // Vérifier si l'utilisateur est connecté
  isAuthenticated(): boolean {
    return this.authState.isAuthenticated;
  }

  // Obtenir l'utilisateur actuel
  getCurrentUser(): User | null {
    return this.authState.user;
  }

  // Obtenir le token actuel avec vérification d'expiration
  getToken(): string | null {
    if (!this.authState.token) {
      return null;
    }

    // Si le token est expiré, déconnecter l'utilisateur
    if (this.isTokenExpired(this.authState.token)) {
      console.log('Token expiré détecté, déconnexion automatique');
      this.clearAuth();
      return null;
    }

    // Si le token va expirer bientôt, essayer de le rafraîchir
    if (this.isTokenExpiringSoon(this.authState.token)) {
      console.log('Token va expirer bientôt, rafraîchissement automatique');
      this.refreshToken().catch(error => {
        console.error('Erreur lors du rafraîchissement automatique:', error);
      });
    }

    return this.authState.token;
  }

  // Obtenir l'état complet d'authentification
  getAuthState(): AuthState {
    return { ...this.authState };
  }

  // Vérifier la validité du token (optionnel)
  async validateToken(): Promise<boolean> {
    if (!this.authState.token) {
      return false;
    }

    try {
      const response = await ApiClient.get<{ valid: boolean }>('auth.php');
      return response.success && response.data?.valid === true;
    } catch (error) {
      console.error('Erreur de validation du token:', error);
      this.clearAuth();
      return false;
    }
  }

  // Rafraîchir le token
  async refreshToken(): Promise<boolean> {
    if (!this.authState.token) {
      return false;
    }

    try {
      const response = await ApiClient.post<AuthResponse>('auth.php', {
        action: 'refresh',
        token: this.authState.token
      } as unknown as Record<string, unknown>);
      
      if (response.success && response.data) {
        this.authState = {
          user: response.data.user,
          token: response.data.token,
          isAuthenticated: true
        };
        this.saveAuthToStorage(response.data.token, response.data.user);
        return true;
      }
      
      return false;
    } catch (error) {
      console.error('Erreur lors du rafraîchissement du token:', error);
      this.clearAuth();
      return false;
    }
  }
}

export default AuthService; 
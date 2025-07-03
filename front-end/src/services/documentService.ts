import { ApiClient, ApiResponse, API_BASE_URL } from './api';

export interface Document {
  id: number;
  nom_fichier: string;
  titre: string;
  description?: string;
  tags?: string;
  taille: number;
  date_upload: string;
  date_expiration?: string;
  statut: 'actif' | 'expiré' | 'supprimé';
  utilisateur_id: number;
  chemin_fichier: string;
}

export interface DocumentMetadata {
  titre: string;
  description?: string;
  tags?: string[];
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

export interface UploadResponse {
  document_id: number;
  document: Document;
  message: string;
}

class DocumentService {
  // Récupérer tous les documents de l'utilisateur
  async getDocuments(): Promise<ApiResponse<Document[]>> {
    return ApiClient.get<Document[]>('documents.php');
  }

  // Récupérer un document spécifique
  async getDocument(id: number): Promise<ApiResponse<Document>> {
    return ApiClient.get<Document>(`documents.php?id=${id}`);
  }

  // Upload d'un nouveau document
  async uploadDocument(
    file: File, 
    metadata: DocumentMetadata
  ): Promise<ApiResponse<UploadResponse>> {
    const additionalData: Record<string, string> = {
      titre: metadata.titre,
      description: metadata.description || '',
      tags: metadata.tags ? metadata.tags.join(',') : ''
    };

    return ApiClient.uploadFile<UploadResponse>('documents.php', file, additionalData);
  }

  // Mettre à jour les métadonnées d'un document
  async updateDocument(
    id: number, 
    metadata: DocumentMetadata
  ): Promise<ApiResponse<Document>> {
    return ApiClient.put<Document>('documents.php', {
      id,
      titre: metadata.titre,
      description: metadata.description || '',
      tags: metadata.tags ? metadata.tags.join(',') : ''
    });
  }

  // Mettre à jour les métadonnées après l'upload initial
  async updateDocumentMetadata(
    id: number, 
    metadata: DocumentMetadata
  ): Promise<ApiResponse<Document>> {
    return this.updateDocument(id, metadata);
  }

  // Supprimer un document
  async deleteDocument(id: number): Promise<ApiResponse<{ message: string }>> {
    return ApiClient.delete<{ message: string }>(`documents.php?id=${id}`);
  }

  // Récupérer les statistiques des documents
  async getDocumentStats(): Promise<ApiResponse<DocumentStats[]>> {
    return ApiClient.get<DocumentStats[]>('stats.php?type=documents');
  }

  // Récupérer les statistiques d'un document spécifique
  async getDocumentStatsById(id: number): Promise<ApiResponse<DocumentStats>> {
    return ApiClient.get<DocumentStats>(`stats.php?type=document&id=${id}`);
  }

  // Télécharger un document (pour l'aperçu)
  async downloadDocument(id: number): Promise<Blob | null> {
    try {
      const token = localStorage.getItem('authToken');
      const url = `${API_BASE_URL}/documents.php?id=${id}&download=1`;
      
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
      console.error('Erreur lors du téléchargement:', error);
      return null;
    }
  }

  // Obtenir l'URL de prévisualisation d'un document
  getPreviewUrl(id: number): string {
    const token = localStorage.getItem('authToken');
    return `${API_BASE_URL}/documents.php?id=${id}&preview=1&token=${token}`;
  }
}

export default DocumentService; 
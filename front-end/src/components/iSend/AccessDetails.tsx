import { useEffect, useState } from 'react';
import { Button } from '@/components/ui/button';
import { Card, CardHeader, CardContent, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { ArrowLeft, CheckCircle, XCircle, Eye, Calendar, RefreshCw, AlertCircle, FileText } from 'lucide-react';
import { documentService, sendService } from '@/services';
import type { Document } from '@/services/documentService';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog';

interface AccessDetailsProps {
  onBack: () => void;
  documentId?: number; // ID du document à afficher
}

interface AccessLink {
  email: string;
  access_token: string;
  access_url: string;
  statut: 'actif' | 'expiré' | 'lu';
  created_at?: string;
  date_derniere_utilisation?: string;
  nombre_acces?: number;
}

interface AccessStats {
  total_liens: number;
  liens_actifs: number;
  liens_expires: number;
  liens_lus: number;
  total_acces: number;
  taux_lecture: number;
}

const AccessDetails = ({ onBack, documentId }: AccessDetailsProps) => {
  const [document, setDocument] = useState<Document | null>(null);
  const [accessLinks, setAccessLinks] = useState<AccessLink[]>([]);
  const [stats, setStats] = useState<AccessStats | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [error, setError] = useState('');
  const [openPreview, setOpenPreview] = useState(false);

  // Protection contre documentId undefined
  if (!documentId) {
    return (
      <div className="space-y-6">
        <div className="flex items-center space-x-4">
          <Button variant="outline" onClick={onBack}>
            <ArrowLeft className="h-4 w-4 mr-2" />
            Retour
          </Button>
          <div>
            <h1 className="text-3xl font-bold text-gray-900">Détails d'accès</h1>
            <p className="text-gray-600 mt-1">Aucun document sélectionné</p>
          </div>
        </div>
        <div className="flex items-center space-x-2 p-3 bg-yellow-50 border border-yellow-200 rounded-lg">
          <AlertCircle className="h-4 w-4 text-yellow-600" />
          <span className="text-sm text-yellow-600">
            Veuillez sélectionner un document depuis le tableau de bord ou les statistiques.
          </span>
        </div>
      </div>
    );
  }

  useEffect(() => {
    if (documentId) {
      loadAccessDetails();
      
      // Rafraîchissement automatique toutes les 30 secondes
      const interval = setInterval(() => {
        loadAccessDetails(true); // true = rafraîchissement silencieux
      }, 30000);
      
      return () => clearInterval(interval);
    }
  }, [documentId]);

  const loadAccessDetails = async (silent = false) => {
    if (!documentId) return;
    
    if (!silent) {
      setIsLoading(true);
    }
    setIsRefreshing(true);
    setError('');
    
    try {
      const [docRes, linksRes] = await Promise.all([
        documentService.getDocument(documentId),
        sendService.getAccessLinks(documentId)
      ]);
      
      if (docRes.success && docRes.data) {
        setDocument(docRes.data);
      }
      
      if (linksRes.success && linksRes.data) {
        setAccessLinks(linksRes.data);
        
        // Calculer les statistiques
        const totalLiens = linksRes.data.length;
        const liensActifs = linksRes.data.filter(l => l.statut === 'actif').length;
        const liensExpires = linksRes.data.filter(l => l.statut === 'expiré').length;
        const liensLus = linksRes.data.filter(l => l.statut === 'lu').length;
        const totalAcces = linksRes.data.reduce((sum, l) => sum + ((l as any).nombre_acces || 0), 0);
        const tauxLecture = totalLiens > 0 ? Math.round((liensLus / totalLiens) * 100) : 0;
        
        setStats({
          total_liens: totalLiens,
          liens_actifs: liensActifs,
          liens_expires: liensExpires,
          liens_lus: liensLus,
          total_acces: totalAcces,
          taux_lecture: tauxLecture
        });
      }
      
      if (!docRes.success || !linksRes.success) {
        setError('Erreur lors du chargement des données');
      }
    } catch (err) {
      setError('Erreur de connexion au backend');
      console.error('Erreur access details:', err);
    } finally {
      setIsLoading(false);
      setIsRefreshing(false);
    }
  };

  const handleManualRefresh = () => {
    loadAccessDetails();
  };

  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'actif':
        return (
          <Badge variant="secondary" className="bg-green-100 text-green-800">
            <CheckCircle className="h-3 w-3 mr-1" />
            Actif
          </Badge>
        );
      case 'lu':
        return (
          <Badge variant="secondary" className="bg-blue-100 text-blue-800">
            <Eye className="h-3 w-3 mr-1" />
            Lu
          </Badge>
        );
      case 'expiré':
        return (
          <Badge variant="secondary" className="bg-red-100 text-red-800">
            <XCircle className="h-3 w-3 mr-1" />
            Expiré
          </Badge>
        );
      default:
        return (
          <Badge variant="secondary" className="bg-gray-100 text-gray-800">
            Inconnu
          </Badge>
        );
    }
  };

  if (isLoading) {
    return (
      <div className="space-y-6">
        <div className="flex items-center space-x-4">
          <Button variant="outline" disabled>
            <ArrowLeft className="h-4 w-4 mr-2" />
            Retour
          </Button>
          <div>
            <h1 className="text-3xl font-bold text-gray-900">Détails d'accès</h1>
            <p className="text-gray-600 mt-1">Chargement...</p>
          </div>
        </div>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          {[...Array(3)].map((_, i) => (
            <Card key={i}><CardContent className="p-6 animate-pulse"><div className="h-16 bg-gray-200 rounded"></div></CardContent></Card>
          ))}
        </div>
        <Card><CardHeader><CardTitle>Détail par destinataire</CardTitle></CardHeader><CardContent><div className="space-y-4"><div className="h-16 bg-gray-200 rounded animate-pulse"></div></div></CardContent></Card>
      </div>
    );
  }

  if (!document) {
    return (
      <div className="space-y-6">
        <div className="flex items-center space-x-4">
          <Button variant="outline" onClick={onBack}>
            <ArrowLeft className="h-4 w-4 mr-2" />
            Retour
          </Button>
          <div>
            <h1 className="text-3xl font-bold text-gray-900">Détails d'accès</h1>
            <p className="text-gray-600 mt-1">Document non trouvé</p>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div className="flex items-center space-x-4">
          <Button variant="outline" onClick={onBack}>
            <ArrowLeft className="h-4 w-4 mr-2" />
            Retour
          </Button>
          <div>
            <h1 className="text-3xl font-bold text-gray-900">Détails d'accès</h1>
            <p className="text-gray-600 mt-1">Suivi des accès au document</p>
          </div>
        </div>
        <Button 
          onClick={handleManualRefresh} 
          variant="outline" 
          size="sm"
          disabled={isRefreshing}
          className="flex items-center space-x-1"
        >
          <RefreshCw className={`h-4 w-4 ${isRefreshing ? 'animate-spin' : ''}`} />
          <span>Actualiser</span>
        </Button>
      </div>

      {error && (
        <div className="flex items-center space-x-2 p-3 bg-red-50 border border-red-200 rounded-lg">
          <AlertCircle className="h-4 w-4 text-red-600" />
          <span className="text-sm text-red-600">{error}</span>
          <Button variant="outline" size="sm" onClick={handleManualRefresh}>Réessayer</Button>
        </div>
      )}

      <Card>
        <CardHeader>
          <CardTitle className="flex items-center justify-between">
            <span>{document.titre || document.nom_fichier}</span>
            <div className="flex items-center text-sm text-gray-500">
              <Eye className="h-4 w-4 mr-1" />
              {stats?.total_acces || 0} vues totales
            </div>
          </CardTitle>
          <p className="text-gray-600">
            Envoyé le {new Date(document.date_upload).toLocaleDateString('fr-FR')} à {new Date(document.date_upload).toLocaleTimeString('fr-FR')}
          </p>
          <div className="mt-2 flex gap-2">
            <Dialog open={openPreview} onOpenChange={setOpenPreview}>
              <DialogTrigger asChild>
                <Button variant="outline" onClick={() => setOpenPreview(true)}>
                  Aperçu
                </Button>
              </DialogTrigger>
              <DialogContent className="max-w-4xl w-full p-0">
                <DialogHeader>
                  <DialogTitle>Aperçu du document PDF</DialogTitle>
                </DialogHeader>
                <div className="p-4">
                  <iframe
                    src={documentService.getPreviewUrl(document.id)}
                    width="100%"
                    height="700px"
                    style={{ border: '1px solid #e5e7eb', borderRadius: 8 }}
                    title="Aperçu du document"
                    className="w-full"
                  />
                </div>
              </DialogContent>
            </Dialog>
            <Button
              variant="outline"
              onClick={() => window.open(documentService.getPreviewUrl(document.id), '_blank')}
            >
              Aperçu (nouvel onglet)
            </Button>
            <Button
              variant="outline"
              onClick={() => window.open(documentService.getPreviewUrl(document.id).replace('preview=1', 'download=1'), '_blank')}
            >
              Télécharger
            </Button>
          </div>
        </CardHeader>
      </Card>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <Card>
          <CardContent className="p-6">
            <div className="flex items-center space-x-4">
              <div className="w-12 h-12 bg-green-100 rounded-lg flex items-center justify-center">
                <CheckCircle className="h-6 w-6 text-green-600" />
              </div>
              <div>
                <p className="text-2xl font-bold text-gray-900">{stats?.liens_actifs || 0}</p>
                <p className="text-gray-600">Liens actifs</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="flex items-center space-x-4">
              <div className="w-12 h-12 bg-blue-100 rounded-lg flex items-center justify-center">
                <Eye className="h-6 w-6 text-blue-600" />
              </div>
              <div>
                <p className="text-2xl font-bold text-gray-900">{stats?.liens_lus || 0}</p>
                <p className="text-gray-600">Documents lus</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="flex items-center space-x-4">
              <div className="w-12 h-12 bg-red-100 rounded-lg flex items-center justify-center">
                <XCircle className="h-6 w-6 text-red-600" />
              </div>
              <div>
                <p className="text-2xl font-bold text-gray-900">{stats?.liens_expires || 0}</p>
                <p className="text-gray-600">Liens expirés</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Détail par destinataire ({accessLinks.length} lien{accessLinks.length > 1 ? 's' : ''})</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-4">
            {accessLinks.length === 0 ? (
              <p className="text-gray-500 text-center py-8">Aucun lien d'accès trouvé</p>
            ) : (
              <div className="max-h-96 overflow-y-auto space-y-4">
                {accessLinks.map((link, index) => (
                  <div key={index} className="flex items-center justify-between p-4 border border-gray-200 rounded-lg hover:bg-gray-50 transition-colors">
                    <div className="flex-1">
                      <h3 className="font-medium text-gray-900">{link.email}</h3>
                      <div className="flex items-center space-x-4 mt-2">
                        {getStatusBadge(link.statut)}
                        {link.date_derniere_utilisation && (
                          <div className="flex items-center text-sm text-gray-500">
                            <Calendar className="h-4 w-4 mr-1" />
                            Dernier accès : {new Date(link.date_derniere_utilisation).toLocaleDateString('fr-FR')} à {new Date(link.date_derniere_utilisation).toLocaleTimeString('fr-FR')}
                          </div>
                        )}
                        <div className="flex items-center text-sm text-gray-500">
                          <Calendar className="h-4 w-4 mr-1" />
                          Créé le : {new Date(link.created_at).toLocaleDateString('fr-FR')}
                        </div>
                      </div>
                    </div>
                    <div className="text-right">
                      <p className="text-lg font-bold text-gray-900">0</p>
                      <p className="text-sm text-gray-500">accès</p>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        </CardContent>
      </Card>
    </div>
  );
};

export default AccessDetails;

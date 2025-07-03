import { useEffect, useState } from 'react';
import { Button } from '@/components/ui/button';
import { Card, CardHeader, CardContent, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Plus, FileText, Eye, Calendar, CheckCircle, XCircle, AlertCircle, RefreshCw, ChevronDown, ChevronUp, Search } from 'lucide-react';
import { statsService, documentService } from '@/services';
import type { Document } from '@/services/documentService';
import type { GlobalStats } from '@/services/statsService';
import { Input } from '@/components/ui/input';

interface DashboardProps {
  onNewDocument: () => void;
  onNavigate: (screen: string, id?: number) => void;
}

const Dashboard = ({ onNewDocument, onNavigate }: DashboardProps) => {
  const [documents, setDocuments] = useState<Document[]>([]);
  const [stats, setStats] = useState<GlobalStats | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [error, setError] = useState('');
  const [lastUpdate, setLastUpdate] = useState<Date>(new Date());
  const [showAllDocuments, setShowAllDocuments] = useState(false);
  const [documentsSearch, setDocumentsSearch] = useState('');

  useEffect(() => {
    loadDashboardData();
    
    // Rafraîchissement automatique toutes les 30 secondes
    const interval = setInterval(() => {
      loadDashboardData(true); // true = rafraîchissement silencieux
    }, 30000);
    
    return () => clearInterval(interval);
  }, []);

  const loadDashboardData = async (silent = false) => {
    if (!silent) {
      setIsLoading(true);
    }
    setIsRefreshing(true);
    setError('');
    
    try {
      const [statsRes, docsRes] = await Promise.all([
        statsService.getGlobalStats(),
        documentService.getDocuments()
      ]);
      
      if (statsRes.success && statsRes.data) setStats(statsRes.data);
      if (docsRes.success && docsRes.data) {
        // Trier les documents par date d'upload (plus récent en premier)
        const sortedDocs = docsRes.data.sort((a, b) => 
          new Date(b.date_upload).getTime() - new Date(a.date_upload).getTime()
        );
        setDocuments(sortedDocs);
      }
      
      if (!statsRes.success || !docsRes.success) {
        setError('Erreur lors du chargement des données');
      } else {
        setLastUpdate(new Date());
      }
    } catch (err) {
      setError('Erreur de connexion au backend');
      console.error('Erreur dashboard:', err);
    } finally {
      setIsLoading(false);
      setIsRefreshing(false);
    }
  };

  const handleManualRefresh = () => {
    loadDashboardData();
  };

  const getStatusBadge = (status: string) => {
    return status === 'actif' ? (
      <Badge variant="secondary" className="bg-green-100 text-green-800">
        <CheckCircle className="h-3 w-3 mr-1" />
        Actif
      </Badge>
    ) : (
      <Badge variant="secondary" className="bg-red-100 text-red-800">
        <XCircle className="h-3 w-3 mr-1" />
        Expiré
      </Badge>
    );
  };

  // Filtrage des documents par recherche
  const filteredDocuments = documents.filter(doc => {
    if (!documentsSearch) return true;
    const searchLower = documentsSearch.toLowerCase();
    const title = (doc.titre || doc.nom_fichier || '').toLowerCase();
    const matches = title.includes(searchLower);
    console.log('Recherche:', { searchTerm: documentsSearch, title, matches, totalDocs: documents.length });
    return matches;
  });

  console.log('Dashboard State:', { 
    documentsCount: documents.length, 
    documentsSearch, 
    filteredCount: filteredDocuments.length,
    showAllDocuments 
  });

  const displayedDocuments = showAllDocuments ? filteredDocuments : filteredDocuments.slice(0, 5);
  const hasMoreDocuments = filteredDocuments.length > 5;

  if (isLoading) {
    return (
      <div className="space-y-6">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-3xl font-bold text-gray-900">Tableau de bord</h1>
            <p className="text-gray-600 mt-1">Chargement...</p>
          </div>
          <Button disabled className="bg-blue-600">
            <Plus className="h-4 w-4 mr-2" />
            Nouveau document
          </Button>
        </div>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          {[...Array(3)].map((_, i) => (
            <Card key={i}><CardContent className="p-6 animate-pulse"><div className="h-16 bg-gray-200 rounded"></div></CardContent></Card>
          ))}
        </div>
        <Card><CardHeader><CardTitle>Documents récents</CardTitle></CardHeader><CardContent><div className="space-y-4"><div className="h-16 bg-gray-200 rounded animate-pulse"></div></div></CardContent></Card>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Tableau de bord</h1>
          <div className="flex items-center space-x-4 mt-1">
            <p className="text-gray-600">Bienvenue sur votre plateforme iSend</p>
            <div className="flex items-center space-x-2 text-xs text-gray-500">
              <span>Dernière mise à jour : {lastUpdate.toLocaleTimeString('fr-FR')}</span>
              {isRefreshing && (
                <RefreshCw className="h-3 w-3 animate-spin" />
              )}
            </div>
          </div>
        </div>
        <div className="flex items-center space-x-2">
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
          <Button onClick={onNewDocument} className="bg-blue-600 hover:bg-blue-700">
            <Plus className="h-4 w-4 mr-2" />
            Nouveau document
          </Button>
        </div>
      </div>

      {error && (
        <div className="flex items-center space-x-2 p-3 bg-red-50 border border-red-200 rounded-lg">
          <AlertCircle className="h-4 w-4 text-red-600" />
          <span className="text-sm text-red-600">{error}</span>
          <Button variant="outline" size="sm" onClick={handleManualRefresh}>Réessayer</Button>
        </div>
      )}

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <Card>
          <CardContent className="p-6">
            <div className="flex items-center space-x-4">
              <div className="w-12 h-12 bg-blue-100 rounded-lg flex items-center justify-center">
                <FileText className="h-6 w-6 text-blue-600" />
              </div>
              <div>
                <p className="text-2xl font-bold text-gray-900">{stats?.total_documents ?? 0}</p>
                <p className="text-gray-600">Documents envoyés</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-6">
            <div className="flex items-center space-x-4">
              <div className="w-12 h-12 bg-green-100 rounded-lg flex items-center justify-center">
                <Eye className="h-6 w-6 text-green-600" />
              </div>
              <div>
                <p className="text-2xl font-bold text-gray-900">{stats?.total_vues ?? 0}</p>
                <p className="text-gray-600">Vues totales</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-6">
            <div className="flex items-center space-x-4">
              <div className="w-12 h-12 bg-purple-100 rounded-lg flex items-center justify-center">
                <Calendar className="h-6 w-6 text-purple-600" />
              </div>
              <div>
                <p className="text-2xl font-bold text-gray-900">{stats?.documents_ce_mois ?? 0}</p>
                <p className="text-gray-600">Ce mois-ci</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle>Documents récents</CardTitle>
            <div className="flex items-center space-x-2">
              <div className="relative max-w-sm">
                <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-gray-400" />
                <Input
                  placeholder="Rechercher un document..."
                  value={documentsSearch}
                  onChange={(e) => {
                    console.log('Dashboard Search onChange:', e.target.value);
                    setDocumentsSearch(e.target.value);
                  }}
                  className="pl-10"
                />
              </div>
              <span className="text-sm text-gray-500">
                {filteredDocuments.length} document{filteredDocuments.length > 1 ? 's' : ''} au total
              </span>
              {isRefreshing && (
                <RefreshCw className="h-4 w-4 animate-spin text-blue-600" />
              )}
            </div>
          </div>
        </CardHeader>
        <CardContent>
          <div className="space-y-4">
            {filteredDocuments.length === 0 ? (
              <p className="text-gray-500 text-center py-8">
                {documentsSearch ? 'Aucun document trouvé pour cette recherche' : 'Aucun document trouvé'}
              </p>
            ) : (
              <>
                <div className="max-h-96 overflow-y-auto space-y-4">
                  {displayedDocuments.map((doc) => (
                    <div key={doc.id} className="flex items-center justify-between p-4 border border-gray-200 rounded-lg hover:bg-gray-50 transition-colors">
                      <div className="flex items-center space-x-4">
                        <FileText className="h-8 w-8 text-gray-400" />
                        <div>
                          <h3 className="font-medium text-gray-900">{doc.titre || doc.nom_fichier}</h3>
                          <p className="text-sm text-gray-500">
                            Envoyé le {new Date(doc.date_upload).toLocaleDateString('fr-FR')} à {new Date(doc.date_upload).toLocaleTimeString('fr-FR')}
                          </p>
                        </div>
                      </div>
                      <div className="flex items-center space-x-4">
                        {getStatusBadge(doc.statut)}
                        <Button 
                          variant="outline" 
                          size="sm"
                          onClick={() => onNavigate('access-details', doc.id)}
                        >
                          Voir détails
                        </Button>
                      </div>
                    </div>
                  ))}
                </div>
                
                {hasMoreDocuments && (
                  <div className="flex justify-center pt-4 border-t border-gray-200">
                    <Button 
                      variant="outline" 
                      onClick={() => setShowAllDocuments(!showAllDocuments)}
                      className="flex items-center space-x-2"
                    >
                      {showAllDocuments ? (
                        <>
                          <ChevronUp className="h-4 w-4" />
                          <span>Voir moins</span>
                        </>
                      ) : (
                        <>
                          <ChevronDown className="h-4 w-4" />
                          <span>Voir tous les documents ({documents.length - 5} de plus)</span>
                        </>
                      )}
                    </Button>
                  </div>
                )}
              </>
            )}
          </div>
        </CardContent>
      </Card>
    </div>
  );
};

export default Dashboard;

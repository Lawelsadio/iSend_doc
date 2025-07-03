import { useState, useEffect } from 'react';
import { Button } from '@/components/ui/button';
import { Card, CardHeader, CardContent, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { FileText, Eye, Calendar, Users, AlertCircle, Download, Search } from 'lucide-react';
import { statsService } from '@/services';
import type { DocumentStats, GlobalStats } from '@/services/statsService';
import { Input } from '@/components/ui/input';

interface StatisticsProps {
  onNavigate: (screen: string, id?: number) => void;
}

const Statistics = ({ onNavigate }: StatisticsProps) => {
  const [globalStats, setGlobalStats] = useState<GlobalStats | null>(null);
  const [documentStats, setDocumentStats] = useState<DocumentStats[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState('');
  const [documentsSearch, setDocumentsSearch] = useState('');

  console.log('Statistics component rendered');

  useEffect(() => {
    console.log('Statistics useEffect triggered');
    loadStatistics();
  }, []);

  const loadStatistics = async () => {
    console.log('loadStatistics called');
    setIsLoading(true);
    setError('');

    // Vérifier si l'utilisateur est connecté
    const token = localStorage.getItem('authToken');
    if (!token) {
      console.error('Aucun token d\'authentification trouvé');
      setError('Vous devez être connecté pour voir les statistiques');
      setIsLoading(false);
      return;
    }

    console.log('Token trouvé:', token.substring(0, 20) + '...');

    try {
      // Charger les statistiques globales
      console.log('Loading global stats...');
      const globalResponse = await statsService.getGlobalStats();
      console.log('Global stats response:', globalResponse);
      if (globalResponse.success && globalResponse.data) {
        setGlobalStats(globalResponse.data);
      }

      // Charger les statistiques des documents
      console.log('Loading document stats...');
      const documentsResponse = await statsService.getDocumentStats();
      console.log('Document stats response:', documentsResponse);
      if (documentsResponse.success && documentsResponse.data) {
        setDocumentStats(documentsResponse.data);
      }

      if (!globalResponse.success && !documentsResponse.success) {
        setError('Erreur lors du chargement des statistiques');
      }
    } catch (err) {
      console.error('Error in loadStatistics:', err);
      setError('Erreur de connexion');
    } finally {
      setIsLoading(false);
    }
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('fr-FR');
  };

  const formatTime = (timeString: string) => {
    return new Date(timeString).toLocaleTimeString('fr-FR', {
      hour: '2-digit',
      minute: '2-digit'
    });
  };

  const handleExportReport = async () => {
    try {
      const blob = await statsService.generateStatsReport('month');
      if (blob) {
        // Créer un lien de téléchargement
        const url = window.URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `rapport_statistiques_${new Date().toISOString().split('T')[0]}.html`;
        document.body.appendChild(a);
        a.click();
        window.URL.revokeObjectURL(url);
        document.body.removeChild(a);
      } else {
        setError('Erreur lors de la génération du rapport');
      }
    } catch (err) {
      console.error('Erreur export rapport:', err);
      setError('Erreur lors de l\'export du rapport');
    }
  };

  // Filtrage des documents par recherche
  const filteredDocumentStats = documentStats.filter(doc => {
    if (!documentsSearch) return true;
    const searchLower = documentsSearch.toLowerCase();
    const title = (doc.titre || '').toLowerCase();
    const matches = title.includes(searchLower);
    console.log('Recherche Statistics:', { searchTerm: documentsSearch, title, matches });
    return matches;
  });

  if (isLoading) {
    return (
      <div className="space-y-6">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Statistiques</h1>
          <p className="text-gray-600 mt-1">Suivez les performances de vos documents</p>
        </div>
        
        <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
          {[...Array(4)].map((_, i) => (
            <Card key={i}>
              <CardContent className="p-6">
                <div className="animate-pulse">
                  <div className="w-12 h-12 bg-gray-200 rounded-lg mb-4"></div>
                  <div className="h-8 bg-gray-200 rounded mb-2"></div>
                  <div className="h-4 bg-gray-200 rounded"></div>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>

        <Card>
          <CardHeader>
            <CardTitle>Historique des documents</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              {[...Array(3)].map((_, i) => (
                <div key={i} className="animate-pulse">
                  <div className="h-16 bg-gray-200 rounded"></div>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold text-gray-900">Statistiques</h1>
        <p className="text-gray-600 mt-1">Suivez les performances de vos documents</p>
      </div>

      {error && (
        <div className="flex items-center space-x-2 p-3 bg-red-50 border border-red-200 rounded-lg">
          <AlertCircle className="h-4 w-4 text-red-600" />
          <span className="text-sm text-red-600">{error}</span>
          <Button variant="outline" size="sm" onClick={loadStatistics}>
            Réessayer
          </Button>
        </div>
      )}

      <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
        <Card>
          <CardContent className="p-6">
            <div className="flex items-center space-x-4">
              <div className="w-12 h-12 bg-blue-100 rounded-lg flex items-center justify-center">
                <FileText className="h-6 w-6 text-blue-600" />
              </div>
              <div>
                <p className="text-2xl font-bold text-gray-900">
                  {globalStats?.total_documents || 0}
                </p>
                <p className="text-gray-600">Documents</p>
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
                <p className="text-2xl font-bold text-gray-900">
                  {globalStats?.total_vues || 0}
                </p>
                <p className="text-gray-600">Vues totales</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="flex items-center space-x-4">
              <div className="w-12 h-12 bg-purple-100 rounded-lg flex items-center justify-center">
                <Users className="h-6 w-6 text-purple-600" />
              </div>
              <div>
                <p className="text-2xl font-bold text-gray-900">
                  {globalStats?.total_destinataires || 0}
                </p>
                <p className="text-gray-600">Destinataires</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="flex items-center space-x-4">
              <div className="w-12 h-12 bg-orange-100 rounded-lg flex items-center justify-center">
                <Calendar className="h-6 w-6 text-orange-600" />
              </div>
              <div>
                <p className="text-2xl font-bold text-gray-900">
                  {globalStats?.taux_lecture ? `${globalStats.taux_lecture}%` : '0%'}
                </p>
                <p className="text-gray-600">Taux de lecture</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle>Historique des documents</CardTitle>
            <div className="relative max-w-sm">
              <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-gray-400" />
              <Input
                placeholder="Rechercher un document..."
                value={documentsSearch}
                onChange={(e) => {
                  console.log('Statistics Search onChange:', e.target.value);
                  setDocumentsSearch(e.target.value);
                }}
                className="pl-10"
              />
            </div>
          </div>
        </CardHeader>
        <CardContent>
          {filteredDocumentStats.length === 0 ? (
            <p className="text-gray-500 text-center py-8">
              {documentsSearch ? 'Aucun document trouvé pour cette recherche' : 'Aucun document trouvé'}
            </p>
          ) : (
            <div className="max-h-96 overflow-y-auto space-y-4">
              {filteredDocumentStats.map((doc) => (
                <div key={doc.id} className="flex items-center justify-between p-4 border border-gray-200 rounded-lg hover:bg-gray-50 transition-colors">
                  <div className="flex items-center space-x-4">
                    <FileText className="h-8 w-8 text-gray-400" />
                    <div>
                      <h3 className="font-medium text-gray-900">{doc.titre}</h3>
                      <p className="text-sm text-gray-500">
                        Envoyé le {formatDate(doc.date_upload)} • {doc.destinataires} destinataires
                      </p>
                    </div>
                  </div>
                  <div className="flex items-center space-x-6">
                    <div className="text-center">
                      <p className="text-lg font-bold text-gray-900">{doc.vues}</p>
                      <p className="text-xs text-gray-500">Vues</p>
                    </div>
                    <div className="text-center">
                      <p className="text-sm text-gray-900">
                        {doc.dernier_acces ? formatTime(doc.dernier_acces) : 'Aucun'}
                      </p>
                      <p className="text-xs text-gray-500">Dernier accès</p>
                    </div>
                    <div className="text-center">
                      <p className="text-sm font-bold text-gray-900">
                        {doc.taux_lecture}%
                      </p>
                      <p className="text-xs text-gray-500">Taux de lecture</p>
                    </div>
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
          )}
        </CardContent>
      </Card>

      <div className="flex justify-end space-x-4">
        <Button 
          variant="outline" 
          onClick={handleExportReport}
        >
          <Download className="h-4 w-4 mr-2" />
          Exporter le rapport
        </Button>
        <Button onClick={loadStatistics}>
          Actualiser
        </Button>
      </div>
    </div>
  );
};

export default Statistics;

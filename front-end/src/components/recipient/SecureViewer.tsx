import { useState, useEffect } from 'react';
import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { X, Shield, FileText, Eye, Clock, Download } from 'lucide-react';
import { useParams, useNavigate, useSearchParams } from 'react-router-dom';

interface DocumentData {
  id: number;
  titre: string;
  nom_fichier: string;
  description: string;
  chemin_fichier: string;
  taille: number;
  expediteur: string;
}

interface AccessInfo {
  date_creation: string;
  date_expiration: string;
  nombre_acces: number;
}

const SecureViewer = () => {
  const [accessTime] = useState(new Date());
  const [documentData, setDocumentData] = useState<DocumentData | null>(null);
  const [accessInfo, setAccessInfo] = useState<AccessInfo | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState('');
  const { token } = useParams();
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const email = searchParams.get('email') || '';

  useEffect(() => {
    const fetchDocumentData = async () => {
      try {
        // Récupérer les données du document via l'API
        const response = await fetch('http://localhost:8888/isend-document-flow/backend-php/api/access.php', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json'
          },
          body: JSON.stringify({
            token: token,
            email: email
          })
        });

        const data = await response.json();
        
        if (data.success) {
          setDocumentData(data.data.document);
          setAccessInfo(data.data.access_info);
    console.log(`Accès enregistré pour ${email} à ${accessTime.toLocaleString()}`);
        } else {
          setError(data.message || 'Erreur lors de la récupération du document');
        }
      } catch (err) {
        console.error('Erreur lors de la récupération:', err);
        setError('Erreur de connexion lors de la récupération du document');
      } finally {
        setIsLoading(false);
      }
    };

    if (token && email) {
      fetchDocumentData();
    }
  }, [token, email, accessTime]);

  const handleClose = () => {
    navigate(`/d/${token}/confirmation?email=${encodeURIComponent(email)}`);
  };

  const handleDownload = () => {
    if (documentData) {
      // Télécharger le document via l'API
      window.open(`http://localhost:8888/isend-document-flow/backend-php/api/access.php?token=${token}&action=download`, '_blank');
    }
  };

  const formatFileSize = (bytes: number) => {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
  };

  // Log de l'URL de l'iframe
  const iframeUrl = `http://localhost:8888/isend-document-flow/backend-php/api/view-document.php?token=${token}&email=${encodeURIComponent(email)}`;
  console.log('Iframe URL:', iframeUrl);

  if (isLoading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto mb-4"></div>
          <p className="text-gray-600">Chargement du document...</p>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <Card className="w-full max-w-md">
          <CardContent className="p-8 text-center">
            <div className="w-16 h-16 bg-red-100 rounded-full flex items-center justify-center mx-auto mb-4">
              <X className="h-8 w-8 text-red-600" />
            </div>
            <h2 className="text-xl font-bold text-gray-900 mb-2">Erreur</h2>
            <p className="text-gray-600 mb-4">{error}</p>
            <Button onClick={() => navigate(`/d/${token}`)}>
              Retour
            </Button>
          </CardContent>
        </Card>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-900 flex flex-col">
      {/* En-tête sécurisé */}
      <div className="bg-white border-b shadow-sm">
        <div className="max-w-7xl mx-auto px-4 py-3">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-4">
              <div className="flex items-center space-x-2">
                <FileText className="h-6 w-6 text-blue-600" />
                <h1 className="text-lg font-semibold text-gray-900">
                  {documentData?.titre || 'Document sécurisé'}
                </h1>
              </div>
            </div>
            <div className="flex items-center space-x-2">
              <Button variant="outline" onClick={handleDownload}>
                <Download className="h-4 w-4 mr-2" />
                Télécharger
              </Button>
            <Button variant="outline" onClick={handleClose}>
              <X className="h-4 w-4 mr-2" />
                Fermer
            </Button>
            </div>
          </div>
        </div>
      </div>

      {/* Bandeau de sécurité */}
      <div className="bg-blue-50 border-b border-blue-200">
        <div className="max-w-7xl mx-auto px-4 py-3">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-3">
              <Shield className="h-5 w-5 text-blue-600" />
              <span className="text-sm text-blue-800">
                Ce document est réservé à : 
                <Badge variant="secondary" className="ml-2 bg-blue-100 text-blue-800">
                  {email}
                </Badge>
              </span>
            </div>
            <div className="flex items-center space-x-4 text-xs text-blue-700">
              <span>Expéditeur : {documentData?.expediteur}</span>
              <span>•</span>
              <span>Taille : {documentData ? formatFileSize(documentData.taille) : ''}</span>
              <span>•</span>
              <Clock className="h-4 w-4" />
              <span>Ouvert le {accessTime.toLocaleDateString()} à {accessTime.toLocaleTimeString()}</span>
            </div>
          </div>
        </div>
      </div>

      {/* Zone de lecture PDF */}
      <div className="flex-1 p-6">
        <Card className="h-full">
          <CardContent className="h-full p-0">
            <div className="h-full bg-gray-50 rounded-lg">
              {/* Viewer PDF intégré */}
              <iframe
                src={iframeUrl}
                className="w-full h-full rounded-lg"
                title="Document PDF"
                frameBorder="0"
              />
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Pied de page */}
      <div className="bg-white border-t">
        <div className="max-w-7xl mx-auto px-4 py-3">
          <div className="flex items-center justify-center space-x-2 text-sm text-gray-500">
            <Shield className="h-4 w-4" />
            <span>Document protégé par iSend - Distribution sécurisée</span>
          </div>
        </div>
      </div>
    </div>
  );
};

export default SecureViewer;


import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { X, Shield, FileText, Eye } from 'lucide-react';

interface SecurePDFViewerProps {
  documentTitle?: string;
  userEmail?: string;
  onClose: () => void;
}

const SecurePDFViewer = ({ 
  documentTitle = 'Rapport_Mensuel_Janvier_2024.pdf', 
  userEmail = 'marie.martin@entreprise.com',
  onClose 
}: SecurePDFViewerProps) => {
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
                  {documentTitle}
                </h1>
              </div>
            </div>
            <Button variant="outline" onClick={onClose}>
              <X className="h-4 w-4 mr-2" />
              Fermer
            </Button>
          </div>
        </div>
      </div>

      {/* Bandeau de sécurité */}
      <div className="bg-blue-50 border-b border-blue-200">
        <div className="max-w-7xl mx-auto px-4 py-3">
          <div className="flex items-center space-x-3">
            <Shield className="h-5 w-5 text-blue-600" />
            <span className="text-sm text-blue-800">
              Ce document est sécurisé pour l'adresse : 
              <Badge variant="secondary" className="ml-2 bg-blue-100 text-blue-800">
                {userEmail}
              </Badge>
            </span>
          </div>
        </div>
      </div>

      {/* Zone de lecture PDF */}
      <div className="flex-1 p-6">
        <Card className="h-full">
          <CardContent className="h-full p-0">
            <div className="h-full bg-gray-50 rounded-lg flex items-center justify-center">
              {/* Simulation d'un viewer PDF */}
              <div className="text-center space-y-4 p-8">
                <div className="w-24 h-32 bg-white border-2 border-dashed border-gray-300 rounded-lg mx-auto flex items-center justify-center">
                  <div className="text-center">
                    <FileText className="h-8 w-8 text-gray-400 mx-auto mb-2" />
                    <div className="text-xs text-gray-500">PDF</div>
                  </div>
                </div>
                <div className="space-y-2">
                  <p className="text-lg font-medium text-gray-700">
                    Document PDF sécurisé
                  </p>
                  <p className="text-sm text-gray-500">
                    Le contenu du document s'afficherait ici dans un viewer PDF intégré
                  </p>
                  <div className="flex items-center justify-center space-x-2 text-xs text-gray-400">
                    <Eye className="h-4 w-4" />
                    <span>Lecture sécurisée activée</span>
                  </div>
                </div>
              </div>
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

export default SecurePDFViewer;

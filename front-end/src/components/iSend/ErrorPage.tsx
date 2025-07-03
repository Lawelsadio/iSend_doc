
import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';
import { AlertTriangle, Home, Mail } from 'lucide-react';

interface ErrorPageProps {
  onBackHome: () => void;
  errorType?: 'expired' | 'unauthorized';
}

const ErrorPage = ({ onBackHome, errorType = 'expired' }: ErrorPageProps) => {
  const getErrorContent = () => {
    if (errorType === 'unauthorized') {
      return {
        title: 'Accès refusé',
        message: 'L\'accès à ce document vous est refusé.',
        description: 'Vous n\'êtes pas autorisé à consulter ce document ou votre autorisation a été révoquée.'
      };
    }
    
    return {
      title: 'Lien expiré',
      message: 'Ce lien est expiré ou non valide.',
      description: 'Le lien d\'accès à ce document n\'est plus valide ou a été désactivé.'
    };
  };

  const errorContent = getErrorContent();

  const handleContactEditor = () => {
    alert('Redirection vers le formulaire de contact...');
  };

  return (
    <div className="min-h-screen bg-gray-50 flex items-center justify-center p-4">
      <Card className="w-full max-w-md text-center">
        <CardContent className="p-8 space-y-6">
          <div className="flex justify-center">
            <div className="w-16 h-16 bg-red-100 rounded-full flex items-center justify-center">
              <AlertTriangle className="h-8 w-8 text-red-600" />
            </div>
          </div>
          
          <div className="space-y-2">
            <h1 className="text-2xl font-bold text-gray-900">
              {errorContent.title}
            </h1>
            <p className="text-lg text-gray-700">
              {errorContent.message}
            </p>
            <p className="text-sm text-gray-500">
              {errorContent.description}
            </p>
          </div>

          <div className="space-y-3 pt-4">
            <Button onClick={onBackHome} className="w-full">
              <Home className="h-4 w-4 mr-2" />
              Retour à l'accueil
            </Button>
            <Button variant="outline" onClick={handleContactEditor} className="w-full">
              <Mail className="h-4 w-4 mr-2" />
              Contacter l'éditeur
            </Button>
          </div>

          <div className="pt-4 border-t">
            <div className="flex items-center justify-center space-x-2">
              <div className="w-6 h-6 bg-blue-600 rounded-lg flex items-center justify-center">
                <Mail className="h-4 w-4 text-white" />
              </div>
              <span className="text-sm text-gray-500">iSend</span>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
};

export default ErrorPage;

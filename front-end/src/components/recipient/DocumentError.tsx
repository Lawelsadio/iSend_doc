
import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';
import { AlertTriangle, XCircle, Mail, Home } from 'lucide-react';
import { useSearchParams, useNavigate } from 'react-router-dom';

const DocumentError = () => {
  const [searchParams] = useSearchParams();
  const navigate = useNavigate();
  const errorType = searchParams.get('type') || 'general';

  const getErrorContent = () => {
    switch (errorType) {
      case 'invalid-email':
        return {
          icon: XCircle,
          iconColor: 'text-red-600',
          bgColor: 'bg-red-100',
          title: 'Adresse email invalide',
          message: 'Ce lien ne correspond pas à votre adresse email.',
          description: 'Veuillez vérifier que vous utilisez la bonne adresse email ou contactez l\'expéditeur.'
        };
      case 'expired':
        return {
          icon: AlertTriangle,
          iconColor: 'text-orange-600',
          bgColor: 'bg-orange-100',
          title: 'Abonnement expiré',
          message: 'Votre abonnement a expiré.',
          description: 'Vous ne pouvez pas consulter ce document. Veuillez contacter l\'éditeur pour renouveler votre accès.'
        };
      case 'unauthorized':
        return {
          icon: XCircle,
          iconColor: 'text-red-600',
          bgColor: 'bg-red-100',
          title: 'Accès refusé',
          message: 'L\'accès à ce document vous est refusé.',
          description: 'Vous n\'êtes pas autorisé à consulter ce document ou votre autorisation a été révoquée.'
        };
      default:
        return {
          icon: AlertTriangle,
          iconColor: 'text-red-600',
          bgColor: 'bg-red-100',
          title: 'Lien invalide',
          message: 'Ce lien est invalide ou a expiré.',
          description: 'Le lien d\'accès à ce document n\'est plus valide ou a été désactivé.'
        };
    }
  };

  const errorContent = getErrorContent();
  const IconComponent = errorContent.icon;

  const handleContactEditor = () => {
    // Simulation - en réalité cela ouvrirait un formulaire de contact
    alert('Redirection vers le formulaire de contact...');
  };

  const handleBackHome = () => {
    navigate('/');
  };

  return (
    <div className="min-h-screen bg-gray-50 flex items-center justify-center p-4">
      <Card className="w-full max-w-md text-center">
        <CardContent className="p-8 space-y-6">
          <div className="flex justify-center">
            <div className={`w-16 h-16 ${errorContent.bgColor} rounded-full flex items-center justify-center`}>
              <IconComponent className={`h-8 w-8 ${errorContent.iconColor}`} />
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
            <Button onClick={handleContactEditor} className="w-full">
              <Mail className="h-4 w-4 mr-2" />
              Contacter l'éditeur
            </Button>
            <Button variant="outline" onClick={handleBackHome} className="w-full">
              <Home className="h-4 w-4 mr-2" />
              Retour à l'accueil
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

export default DocumentError;

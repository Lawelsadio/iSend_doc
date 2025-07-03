import { useState } from 'react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Mail, FileText, Shield } from 'lucide-react';
import { useParams, useNavigate } from 'react-router-dom';

const DocumentAccess = () => {
  const [email, setEmail] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState('');
  const { token } = useParams();
  const navigate = useNavigate();

  const handleAccessDocument = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!email.trim()) return;

    setIsLoading(true);
    setError('');

    try {
      // Appel à l'API backend pour vérifier l'accès
      const response = await fetch('http://localhost:8888/isend-document-flow/backend-php/api/access.php', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          token: token,
          email: email.trim()
        })
      });

      const data = await response.json();
      
      // Log de débogage
      console.log('API Response:', data);
      console.log('Token:', token);
      console.log('Email:', email);
      
      if (data.success) {
        // Accès autorisé - rediriger vers la visionneuse
        navigate(`/d/${token}/view?email=${encodeURIComponent(email)}`);
      } else {
        // Accès refusé - déterminer le type d'erreur
        let errorType = 'general';
        
        if (data.message.includes('expiré')) {
          errorType = 'expired';
        } else if (data.message.includes('Accès temporairement indisponible')) {
          errorType = 'unauthorized';
        } else if (data.message.includes('Lien invalide')) {
          errorType = 'invalid-email';
        }
        
        console.log('Error type:', errorType);
        navigate(`/d/${token}/error?type=${errorType}`);
      }
    } catch (err) {
      console.error('Erreur lors de la vérification:', err);
      setError('Erreur de connexion. Veuillez réessayer.');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-gray-50 flex items-center justify-center p-4">
      <div className="w-full max-w-md">
        <Card>
          <CardHeader className="text-center pb-4">
            <div className="flex justify-center mb-4">
              <div className="w-16 h-16 bg-blue-100 rounded-full flex items-center justify-center">
                <FileText className="h-8 w-8 text-blue-600" />
              </div>
            </div>
            <CardTitle className="text-2xl font-bold text-gray-900">
              Consultation de votre document
            </CardTitle>
            <p className="text-gray-600 mt-2">
              Ce document vous a été envoyé par l'éditeur iSend.
            </p>
          </CardHeader>
          
          <CardContent>
            <form onSubmit={handleAccessDocument} className="space-y-6">
              <div className="space-y-2">
                <Label htmlFor="email" className="text-sm font-medium">
                  Adresse email
                </Label>
                <div className="relative">
                  <Mail className="absolute left-3 top-3 h-4 w-4 text-gray-400" />
                  <Input
                    id="email"
                    type="email"
                    placeholder="Veuillez saisir l'adresse email à laquelle le document a été envoyé"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    className="pl-10"
                    required
                  />
                </div>
                <p className="text-xs text-gray-500">
                  Cette adresse doit correspondre à celle utilisée pour l'envoi du document.
                </p>
              </div>

              {error && (
                <div className="text-sm text-red-600 bg-red-50 p-3 rounded-md">
                  {error}
                </div>
              )}

              <Button 
                type="submit" 
                className="w-full" 
                disabled={isLoading || !email.trim()}
              >
                {isLoading ? (
                  <>
                    <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2"></div>
                    Vérification en cours...
                  </>
                ) : (
                  <>
                    <Shield className="h-4 w-4 mr-2" />
                    Accéder au document
                  </>
                )}
              </Button>
            </form>

            <div className="mt-6 pt-6 border-t text-center">
              <div className="flex items-center justify-center space-x-2 text-sm text-gray-500">
                <div className="w-6 h-6 bg-blue-600 rounded-lg flex items-center justify-center">
                  <Mail className="h-4 w-4 text-white" />
                </div>
                <span>Document protégé par iSend</span>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
};

export default DocumentAccess;


import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';
import { CheckCircle, Clock, Mail, X } from 'lucide-react';
import { useSearchParams } from 'react-router-dom';
import { useState } from 'react';

const AccessConfirmation = () => {
  const [searchParams] = useSearchParams();
  const email = searchParams.get('email') || '';
  const [accessTime] = useState(new Date());

  const handleClose = () => {
    window.close();
  };

  return (
    <div className="min-h-screen bg-gray-50 flex items-center justify-center p-4">
      <Card className="w-full max-w-md text-center">
        <CardContent className="p-8 space-y-6">
          <div className="flex justify-center">
            <div className="w-16 h-16 bg-green-100 rounded-full flex items-center justify-center">
              <CheckCircle className="h-8 w-8 text-green-600" />
            </div>
          </div>
          
          <div className="space-y-2">
            <h1 className="text-2xl font-bold text-gray-900">
              Lecture enregistrée
            </h1>
            <p className="text-lg text-gray-700">
              Merci d'avoir consulté ce document.
            </p>
          </div>

          <div className="bg-gray-50 rounded-lg p-4 space-y-2">
            <div className="flex items-center justify-center space-x-2 text-sm text-gray-600">
              <Clock className="h-4 w-4" />
              <span>Lecture enregistrée le {accessTime.toLocaleDateString()}</span>
            </div>
            <div className="flex items-center justify-center space-x-2 text-sm text-gray-600">
              <span>à {accessTime.toLocaleTimeString()}</span>
            </div>
            {email && (
              <div className="flex items-center justify-center space-x-2 text-sm text-gray-500">
                <Mail className="h-4 w-4" />
                <span>{email}</span>
              </div>
            )}
          </div>

          <div className="space-y-3 pt-4">
            <Button onClick={handleClose} className="w-full">
              <X className="h-4 w-4 mr-2" />
              Fermer
            </Button>
          </div>

          <div className="pt-4 border-t">
            <div className="flex items-center justify-center space-x-2">
              <div className="w-6 h-6 bg-blue-600 rounded-lg flex items-center justify-center">
                <Mail className="h-4 w-4 text-white" />
              </div>
              <span className="text-sm text-gray-500">Document protégé par iSend</span>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
};

export default AccessConfirmation;

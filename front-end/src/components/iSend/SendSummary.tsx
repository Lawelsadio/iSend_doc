import { useState } from 'react';
import { Button } from '@/components/ui/button';
import { Card, CardHeader, CardContent, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { ArrowLeft, FileText, Users, Send, AlertCircle, CheckCircle, Lock, FileDown } from 'lucide-react';
import { sendService, documentService } from '@/services';
import type { SendData } from '@/services/sendService';
import { API_BASE_URL } from '@/services/api';

interface SendSummaryProps {
  data: {
    file: File | null;
    title: string;
    description: string;
    tags: string[];
    recipients: string[];
    documentId?: number;
  };
  onSend: () => void;
  onBack: () => void;
  onDocumentIdUpdate?: (id: number) => void;
}

const SendSummary = ({ data, onSend, onBack, onDocumentIdUpdate }: SendSummaryProps) => {
  const [isSending, setIsSending] = useState(false);
  const [isSendingPDF, setIsSendingPDF] = useState(false);
  const [isSendingNormalPDF, setIsSendingNormalPDF] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState(false);
  const [successMessage, setSuccessMessage] = useState('');

  const handleSendLink = async () => {
    if (!data.documentId) {
      setError('ID du document manquant');
      return;
    }

    setIsSending(true);
    setError('');

    try {
      const sendData: SendData = {
        document_id: data.documentId,
        destinataires: data.recipients,
        message: `Document: ${data.title}\n\n${data.description || ''}`,
        expiration: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString().split('T')[0], // 30 jours
        notification_email: true
      };

      const response = await sendService.sendDocument(sendData);

      if (response.success) {
        setSuccess(true);
        setSuccessMessage('Lien sécurisé envoyé avec succès !');
        setTimeout(() => {
          onSend();
        }, 2000);
      } else {
        setError(response.error || 'Erreur lors de l\'envoi du lien');
      }
    } catch (err) {
      setError('Erreur de connexion lors de l\'envoi du lien');
      console.error('Erreur envoi lien:', err);
    } finally {
      setIsSending(false);
    }
  };

  const handleSendPDF = async () => {
    if (!data.documentId) {
      setError('ID du document manquant');
      return;
    }

    setIsSendingPDF(true);
    setError('');

    try {
      const sendData: SendData = {
        document_id: data.documentId,
        destinataires: data.recipients,
        message: `Document: ${data.title}\n\n${data.description || ''}\n\nMot de passe du PDF: votre adresse email`,
        expiration: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString().split('T')[0], // 30 jours
        notification_email: true,
        send_pdf: true // Nouveau paramètre pour indiquer l'envoi de PDF sécurisé
      };

      const response = await sendService.sendSecurePDF(sendData);

      if (response.success) {
        setSuccess(true);
        setSuccessMessage('PDF sécurisé envoyé avec succès !');
        setTimeout(() => {
          onSend();
        }, 2000);
      } else {
        setError(response.error || 'Erreur lors de l\'envoi du PDF sécurisé');
      }
    } catch (err) {
      setError('Erreur de connexion lors de l\'envoi du PDF sécurisé');
      console.error('Erreur envoi PDF:', err);
    } finally {
      setIsSendingPDF(false);
    }
  };

  const handleSendNormalPDF = async () => {
    if (!data.documentId) {
      setError('ID du document manquant');
      return;
    }

    setIsSendingNormalPDF(true);
    setError('');

    try {
      // Récupérer les informations du document depuis l'API
      const documentResponse = await documentService.getDocument(data.documentId);
      
      if (!documentResponse.success || !documentResponse.data) {
        throw new Error('Impossible de récupérer les informations du document');
      }
      
      const document = documentResponse.data;
      const cheminFichier = `uploads/${document.chemin_fichier}`;

      // Préparer les données dans le format attendu par l'API
      const sendData = {
        destinataires: data.recipients.map(email => ({
          email: email,
          nom: email.split('@')[0] // Utiliser la partie avant @ comme nom
        })),
        nom_document: data.title,
        chemin_fichier: cheminFichier,
        metadata: {
          description: data.description,
          tags: data.tags.join(', '),
          date_creation: new Date().toISOString()
        },
        message_personnalise: `Document: ${data.title}\n\n${data.description || ''}`
      };

      const response = await sendService.sendNormalPDF(sendData);

      if (response.success) {
        // Mettre à jour l'ID du document dans l'état parent si un nouvel ID est retourné
        if (response.data && typeof response.data === 'object' && 'document_id' in response.data && onDocumentIdUpdate) {
          onDocumentIdUpdate(Number(response.data.document_id));
        }
        setSuccess(true);
        setSuccessMessage('PDF normal envoyé avec succès !');
        setTimeout(() => {
          onSend();
        }, 2000);
      } else {
        setError(response.error || 'Erreur lors de l\'envoi du PDF normal');
      }
    } catch (err) {
      setError('Erreur de connexion lors de l\'envoi du PDF normal');
      console.error('Erreur envoi PDF normal:', err);
    } finally {
      setIsSendingNormalPDF(false);
    }
  };

  if (success) {
    return (
      <div className="space-y-6">
        <div className="flex items-center space-x-4">
          <Button variant="outline" onClick={onSend}>
            <ArrowLeft className="h-4 w-4 mr-2" />
            Retour au tableau de bord
          </Button>
        </div>
        
        <Card className="border-green-200 bg-green-50">
          <CardContent className="p-8 text-center">
            <CheckCircle className="h-16 w-16 text-green-600 mx-auto mb-4" />
            <h2 className="text-2xl font-bold text-green-900 mb-2">
              {successMessage}
            </h2>
            <p className="text-green-700">
              Le document a été distribué à {data.recipients.length} destinataire(s).
            </p>
            <p className="text-sm text-green-600 mt-2">
              {successMessage.includes('PDF sécurisé') 
                ? 'Les destinataires recevront un email avec le PDF sécurisé protégé par mot de passe.'
                : successMessage.includes('PDF normal')
                ? 'Les destinataires recevront un email avec le PDF normal en pièce jointe.'
                : 'Les destinataires recevront un email avec un lien sécurisé pour accéder au document.'
              }
            </p>
          </CardContent>
        </Card>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center space-x-4">
        <Button variant="outline" onClick={onBack} disabled={isSending || isSendingPDF || isSendingNormalPDF}>
          <ArrowLeft className="h-4 w-4 mr-2" />
          Retour
        </Button>
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Résumé avant envoi</h1>
          <p className="text-gray-600 mt-1">Vérifiez les informations avant l'envoi</p>
        </div>
      </div>

      {error && (
        <div className="flex items-center space-x-2 p-3 bg-red-50 border border-red-200 rounded-lg">
          <AlertCircle className="h-4 w-4 text-red-600" />
          <span className="text-sm text-red-600">{error}</span>
        </div>
      )}

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center space-x-2">
              <FileText className="h-5 w-5" />
              <span>Document</span>
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div>
              <p className="text-sm text-gray-500">Fichier</p>
              <p className="font-medium">{data.file?.name}</p>
              <p className="text-sm text-gray-500">
                {data.file ? (data.file.size / 1024 / 1024).toFixed(2) + ' MB' : ''}
              </p>
            </div>
            <div>
              <p className="text-sm text-gray-500">Titre</p>
              <p className="font-medium">{data.title}</p>
            </div>
            {data.description && (
              <div>
                <p className="text-sm text-gray-500">Description</p>
                <p className="text-sm">{data.description}</p>
              </div>
            )}
            {data.tags.length > 0 && (
              <div>
                <p className="text-sm text-gray-500 mb-2">Tags</p>
                <div className="flex flex-wrap gap-1">
                  {data.tags.map((tag, index) => (
                    <Badge key={index} variant="secondary">
                      {tag}
                    </Badge>
                  ))}
                </div>
              </div>
            )}
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="flex items-center space-x-2">
              <Users className="h-5 w-5" />
              <span>Destinataires ({data.recipients.length})</span>
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-2 max-h-96 overflow-y-auto">
              {data.recipients.map((email, index) => (
                <div key={index} className="p-2 bg-gray-50 rounded text-sm">
                  {email}
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      </div>

      <Card className="border-blue-200 bg-blue-50">
        <CardContent className="p-6">
          <div className="flex items-center justify-between">
            <div>
              <h3 className="text-lg font-semibold text-blue-900">
                Prêt à envoyer
              </h3>
              <p className="text-blue-700">
                Le document sera distribué de manière sécurisée à {data.recipients.length} destinataire(s)
              </p>
              <p className="text-sm text-blue-600 mt-1">
                • Les destinataires recevront un email avec le document<br/>
                • Le document sera accessible pendant 30 jours<br/>
                • Vous pourrez suivre les statistiques de lecture
              </p>
            </div>
            <div className="flex space-x-2">
              <Button 
                onClick={handleSendLink} 
                className="bg-blue-600 hover:bg-blue-700"
                disabled={isSending || isSendingPDF || isSendingNormalPDF}
              >
                {isSending ? (
                  <>
                    <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2"></div>
                    Envoi en cours...
                  </>
                ) : (
                  <>
                    <Send className="h-4 w-4 mr-2" />
                    Envoyer lien sécurisé
                  </>
                )}
              </Button>
              
              <Button 
                onClick={handleSendPDF} 
                className="bg-green-600 hover:bg-green-700"
                disabled={isSending || isSendingPDF || isSendingNormalPDF}
              >
                {isSendingPDF ? (
                  <>
                    <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2"></div>
                    Envoi en cours...
                  </>
                ) : (
                  <>
                    <Lock className="h-4 w-4 mr-2" />
                    Envoyer le PDF sécurisé
                  </>
                )}
              </Button>

              <Button 
                onClick={handleSendNormalPDF} 
                className="bg-purple-600 hover:bg-purple-700"
                disabled={isSending || isSendingPDF || isSendingNormalPDF}
              >
                {isSendingNormalPDF ? (
                  <>
                    <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2"></div>
                    Envoi en cours...
                  </>
                ) : (
                  <>
                    <FileDown className="h-4 w-4 mr-2" />
                    Envoyer le PDF
                  </>
                )}
              </Button>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
};

export default SendSummary;

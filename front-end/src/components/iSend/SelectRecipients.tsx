import { useState, useEffect } from 'react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Card, CardHeader, CardContent, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Checkbox } from '@/components/ui/checkbox';
import { ArrowLeft, Plus, X, CheckCircle, XCircle, AlertCircle } from 'lucide-react';
import { subscriberService } from '@/services';
import type { Subscriber } from '@/services/subscriberService';

interface SelectRecipientsProps {
  onNext: (data: { recipients: string[] }) => void;
  onBack: () => void;
  initialData: {
    recipients?: string[];
    [key: string]: unknown;
  };
}

const SelectRecipients = ({ onNext, onBack, initialData }: SelectRecipientsProps) => {
  const [recipients, setRecipients] = useState<string[]>(initialData.recipients || []);
  const [newEmail, setNewEmail] = useState('');
  const [existingSubscribers, setExistingSubscribers] = useState<Subscriber[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState('');
  const [selectAllActive, setSelectAllActive] = useState(true);

  // Charger les abonnés existants au montage du composant
  useEffect(() => {
    loadExistingSubscribers();
  }, []);

  // Effet pour sélectionner automatiquement tous les abonnés actifs quand ils sont chargés
  useEffect(() => {
    if (selectAllActive && existingSubscribers.length > 0) {
      const activeSubscribers = existingSubscribers
        .filter(subscriber => subscriber.status === 'actif')
        .map(subscriber => subscriber.email);
      
      // Ajouter seulement les abonnés actifs qui ne sont pas déjà sélectionnés
      const newRecipients = [...new Set([...recipients, ...activeSubscribers])];
      if (newRecipients.length !== recipients.length) {
        setRecipients(newRecipients);
      }
    }
  }, [existingSubscribers, selectAllActive]);

  const loadExistingSubscribers = async () => {
    setIsLoading(true);
    try {
      const response = await subscriberService.getSubscribers();
      if (response.success && response.data) {
        setExistingSubscribers(response.data.subscribers);
      } else {
        setError('Erreur lors du chargement des abonnés');
      }
    } catch (err) {
      setError('Erreur de connexion');
      console.error('Erreur chargement abonnés:', err);
    } finally {
      setIsLoading(false);
    }
  };

  const isValidEmail = (email: string) => {
    return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
  };

  const addRecipient = () => {
    if (isValidEmail(newEmail) && !recipients.includes(newEmail)) {
      setRecipients([...recipients, newEmail]);
      setNewEmail('');
      setError('');
    } else if (!isValidEmail(newEmail)) {
      setError('Adresse email invalide');
    } else {
      setError('Cet email est déjà dans la liste');
    }
  };

  const removeRecipient = (emailToRemove: string) => {
    setRecipients(recipients.filter(email => email !== emailToRemove));
  };

  const addExistingSubscriber = (email: string) => {
    if (!recipients.includes(email)) {
      setRecipients([...recipients, email]);
      setError('');
    } else {
      setError('Cet abonné est déjà sélectionné');
    }
  };

  const getSubscriberInfo = (email: string) => {
    return existingSubscribers.find(s => s.email === email);
  };

  const getSubscriberStatus = (email: string) => {
    const subscriber = existingSubscribers.find(s => s.email === email);
    return subscriber?.status || 'nouveau';
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
      case 'inactif':
      case 'expire':
        return (
          <Badge variant="secondary" className="bg-red-100 text-red-800">
            <XCircle className="h-3 w-3 mr-1" />
            {status === 'inactif' ? 'Inactif' : 'Expiré'}
          </Badge>
        );
      default:
        return (
          <Badge variant="secondary" className="bg-blue-100 text-blue-800">
            Nouveau
          </Badge>
        );
    }
  };

  const selectAllActiveSubscribers = () => {
    const activeSubscribers = existingSubscribers
      .filter(subscriber => subscriber.status === 'actif')
      .map(subscriber => subscriber.email);
    
    // Ajouter tous les abonnés actifs
    const newRecipients = [...new Set([...recipients, ...activeSubscribers])];
    setRecipients(newRecipients);
  };

  const deselectAllActiveSubscribers = () => {
    const activeSubscribers = existingSubscribers
      .filter(subscriber => subscriber.status === 'actif')
      .map(subscriber => subscriber.email);
    
    // Retirer tous les abonnés actifs
    const newRecipients = recipients.filter(email => !activeSubscribers.includes(email));
    setRecipients(newRecipients);
  };

  const handleSelectAllActiveChange = (checked: boolean) => {
    setSelectAllActive(checked);
    if (checked) {
      selectAllActiveSubscribers();
    } else {
      deselectAllActiveSubscribers();
    }
  };

  const handleNext = () => {
    if (recipients.length > 0) {
      onNext({ recipients });
    } else {
      setError('Veuillez sélectionner au moins un destinataire');
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center space-x-4">
        <Button variant="outline" onClick={onBack}>
          <ArrowLeft className="h-4 w-4 mr-2" />
          Retour
        </Button>
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Sélection des destinataires</h1>
          <p className="text-gray-600 mt-1">Choisissez qui recevra le document</p>
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
            <CardTitle>Ajouter des destinataires</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="space-y-2">
              <Label>Adresse email</Label>
              <div className="flex space-x-2">
                <Input
                  type="email"
                  placeholder="destinataire@email.com"
                  value={newEmail}
                  onChange={(e) => setNewEmail(e.target.value)}
                  onKeyPress={(e) => e.key === 'Enter' && addRecipient()}
                />
                <Button onClick={addRecipient} variant="outline">
                  <Plus className="h-4 w-4" />
                </Button>
              </div>
            </div>

            <div className="space-y-3">
              <Label>Abonnés existants</Label>
              
              {/* Checkbox pour sélectionner tous les abonnés actifs */}
              <div className="flex items-center space-x-2 p-3 bg-blue-50 border border-blue-200 rounded-lg">
                <Checkbox
                  id="select-all-active"
                  checked={selectAllActive}
                  onCheckedChange={handleSelectAllActiveChange}
                />
                <Label htmlFor="select-all-active" className="text-sm font-medium cursor-pointer">
                  Sélectionner tous les abonnés actifs
                </Label>
                <Badge variant="secondary" className="bg-green-100 text-green-800">
                  {existingSubscribers.filter(s => s.status === 'actif').length} actifs
                </Badge>
              </div>
              
              {isLoading ? (
                <div className="text-center py-4">
                  <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-blue-600 mx-auto"></div>
                  <p className="text-sm text-gray-500 mt-2">Chargement...</p>
                </div>
              ) : (
                <div className="max-h-96 overflow-y-auto space-y-3">
                  {existingSubscribers.map((subscriber) => (
                    <div key={subscriber.id} className="flex items-center justify-between p-3 border rounded-lg">
                      <div className="flex-1">
                        <p className="text-sm font-medium">
                          {subscriber.prenom} {subscriber.nom}
                        </p>
                        <p className="text-xs text-gray-600">{subscriber.email}</p>
                        <div className="mt-1">
                          {getStatusBadge(subscriber.status)}
                        </div>
                      </div>
                      <Button
                        size="sm"
                        variant="outline"
                        onClick={() => addExistingSubscriber(subscriber.email)}
                        disabled={recipients.includes(subscriber.email)}
                      >
                        {recipients.includes(subscriber.email) ? 'Ajouté' : 'Ajouter'}
                      </Button>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Destinataires sélectionnés ({recipients.length})</CardTitle>
          </CardHeader>
          <CardContent>
            {recipients.length === 0 ? (
              <p className="text-gray-500 text-center py-8">
                Aucun destinataire sélectionné
              </p>
            ) : (
              <div className="max-h-96 overflow-y-auto space-y-3">
                {recipients.map((email) => {
                  const subscriberInfo = getSubscriberInfo(email);
                  return (
                    <div key={email} className="flex items-center justify-between p-3 border rounded-lg">
                      <div className="flex-1">
                        {subscriberInfo ? (
                          <>
                            <p className="text-sm font-medium">
                              {subscriberInfo.prenom} {subscriberInfo.nom}
                            </p>
                            <p className="text-xs text-gray-600">{email}</p>
                          </>
                        ) : (
                          <p className="text-sm font-medium">{email}</p>
                        )}
                        <div className="mt-1">
                          {getStatusBadge(getSubscriberStatus(email))}
                        </div>
                      </div>
                      <Button
                        size="sm"
                        variant="outline"
                        onClick={() => removeRecipient(email)}
                      >
                        <X className="h-4 w-4" />
                      </Button>
                    </div>
                  );
                })}
              </div>
            )}
          </CardContent>
        </Card>
      </div>

      <div className="flex justify-end">
        <Button 
          onClick={handleNext} 
          className="bg-blue-600 hover:bg-blue-700"
          disabled={recipients.length === 0}
        >
          Suivant ({recipients.length} destinataire{recipients.length > 1 ? 's' : ''})
        </Button>
      </div>
    </div>
  );
};

export default SelectRecipients;

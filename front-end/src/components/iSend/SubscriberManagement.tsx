import { useState, useEffect } from 'react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Card, CardHeader, CardContent, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog';
import { Plus, CheckCircle, XCircle, Search, AlertCircle, RefreshCw, Trash2 } from 'lucide-react';
import { subscriberService } from '@/services';
import type { Subscriber, SubscriberStats, CreateSubscriberData } from '@/services/subscriberService';

const SubscriberManagement = () => {
  const [subscribers, setSubscribers] = useState<Subscriber[]>([]);
  const [stats, setStats] = useState<SubscriberStats>({ total: 0, actifs: 0, expires: 0 });
  const [isLoading, setIsLoading] = useState(true);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [error, setError] = useState('');
  const [searchTerm, setSearchTerm] = useState('');

  const [newSubscriber, setNewSubscriber] = useState<CreateSubscriberData>({
    nom: '',
    prenom: '',
    email: '',
    telephone: ''
  });

  const [isDialogOpen, setIsDialogOpen] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);

  useEffect(() => {
    loadSubscribers();
  }, []);

  const loadSubscribers = async () => {
    setIsLoading(true);
    setError('');

    try {
      const response = await subscriberService.getSubscribers();
      if (response.success && response.data) {
        setSubscribers(response.data.subscribers);
        setStats(response.data.stats);
      } else {
        setError(response.error || 'Erreur lors du chargement des abonnés');
      }
    } catch (err) {
      console.error('Erreur chargement abonnés:', err);
      setError('Erreur de connexion');
    } finally {
      setIsLoading(false);
    }
  };

  const handleRefresh = async () => {
    setIsRefreshing(true);
    await loadSubscribers();
    setIsRefreshing(false);
  };

  const addSubscriber = async () => {
    // Validation côté client
    const validation = subscriberService.validateSubscriberData(newSubscriber);
    if (!validation.isValid) {
      setError(validation.errors.join(', '));
      return;
    }

    setIsSubmitting(true);
    setError('');

    try {
      const response = await subscriberService.createSubscriber(newSubscriber);
      if (response.success && response.data) {
        // Ajouter le nouvel abonné à la liste
        setSubscribers(prev => [response.data!, ...prev]);
        // Mettre à jour les statistiques
        setStats(prev => ({
          total: prev.total + 1,
          actifs: prev.actifs + 1,
          expires: prev.expires
        }));
        
        // Réinitialiser le formulaire et fermer la modal
        setNewSubscriber({ nom: '', prenom: '', email: '', telephone: '' });
        setIsDialogOpen(false);
      } else {
        setError(response.error || 'Erreur lors de l\'ajout de l\'abonné');
      }
    } catch (err) {
      console.error('Erreur ajout abonné:', err);
      setError('Erreur de connexion');
    } finally {
      setIsSubmitting(false);
    }
  };

  const toggleStatus = async (id: number, currentStatus: string) => {
    try {
      const response = await subscriberService.toggleStatus(id, currentStatus);
      if (response.success && response.data) {
        // Mettre à jour l'abonné dans la liste
        setSubscribers(prev => prev.map(sub => 
          sub.id === id ? response.data! : sub
        ));
        
        // Mettre à jour les statistiques
        const newStatus = currentStatus === 'actif' ? 'expiré' : 'actif';
        setStats(prev => ({
          total: prev.total,
          actifs: newStatus === 'actif' ? prev.actifs + 1 : prev.actifs - 1,
          expires: newStatus === 'expiré' ? prev.expires + 1 : prev.expires - 1
        }));
      } else {
        setError(response.error || 'Erreur lors de la modification du statut');
      }
    } catch (err) {
      console.error('Erreur modification statut:', err);
      setError('Erreur de connexion');
    }
  };

  const deleteSubscriber = async (id: number) => {
    if (!confirm('Êtes-vous sûr de vouloir supprimer cet abonné ?')) {
      return;
    }

    try {
      const response = await subscriberService.deleteSubscriber(id);
      if (response.success) {
        // Retirer l'abonné de la liste
        const deletedSubscriber = subscribers.find(sub => sub.id === id);
        setSubscribers(prev => prev.filter(sub => sub.id !== id));
        
        // Mettre à jour les statistiques
        if (deletedSubscriber) {
          setStats(prev => ({
            total: prev.total - 1,
            actifs: deletedSubscriber.status === 'actif' ? prev.actifs - 1 : prev.actifs,
            expires: deletedSubscriber.status === 'expiré' ? prev.expires - 1 : prev.expires
          }));
        }
      } else {
        setError(response.error || 'Erreur lors de la suppression');
      }
    } catch (err) {
      console.error('Erreur suppression abonné:', err);
      setError('Erreur de connexion');
    }
  };

  const getStatusBadge = (status: string) => {
    if (status === 'actif') {
      return (
        <Badge variant="secondary" className="bg-green-100 text-green-800">
          <CheckCircle className="h-3 w-3 mr-1" />
          Actif
        </Badge>
      );
    } else if (status === 'expire') {
      return (
        <Badge variant="secondary" className="bg-yellow-100 text-yellow-800">
          <XCircle className="h-3 w-3 mr-1" />
          Expiré
        </Badge>
      );
    } else {
      return (
        <Badge variant="secondary" className="bg-gray-200 text-gray-700">
          <XCircle className="h-3 w-3 mr-1" />
          Inactif
        </Badge>
      );
    }
  };

  const filteredSubscribers = subscribers.filter(sub =>
    sub.email.toLowerCase().includes(searchTerm.toLowerCase()) ||
    sub.nom.toLowerCase().includes(searchTerm.toLowerCase()) ||
    sub.prenom.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('fr-FR');
  };

  if (isLoading) {
    return (
      <div className="space-y-6">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Gestion des abonnés</h1>
          <p className="text-gray-600 mt-1">Chargement...</p>
        </div>
        
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          {[...Array(3)].map((_, i) => (
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
            <CardTitle>Liste des abonnés</CardTitle>
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
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Gestion des abonnés</h1>
          <p className="text-gray-600 mt-1">Gérez votre liste de destinataires</p>
        </div>
        <div className="flex items-center space-x-2">
          <Button 
            onClick={handleRefresh} 
            variant="outline" 
            size="sm"
            disabled={isRefreshing}
          >
            <RefreshCw className={`h-4 w-4 ${isRefreshing ? 'animate-spin' : ''}`} />
            Actualiser
          </Button>
          <Dialog open={isDialogOpen} onOpenChange={setIsDialogOpen}>
            <DialogTrigger asChild>
              <Button className="bg-blue-600 hover:bg-blue-700">
                <Plus className="h-4 w-4 mr-2" />
                Ajouter un abonné
              </Button>
            </DialogTrigger>
            <DialogContent>
              <DialogHeader>
                <DialogTitle>Ajouter un nouvel abonné</DialogTitle>
              </DialogHeader>
              <div className="space-y-4">
                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <Label htmlFor="nom">Nom *</Label>
                    <Input
                      id="nom"
                      placeholder="Nom"
                      value={newSubscriber.nom}
                      onChange={(e) => setNewSubscriber({ ...newSubscriber, nom: e.target.value })}
                    />
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="prenom">Prénom *</Label>
                    <Input
                      id="prenom"
                      placeholder="Prénom"
                      value={newSubscriber.prenom}
                      onChange={(e) => setNewSubscriber({ ...newSubscriber, prenom: e.target.value })}
                    />
                  </div>
                </div>
                <div className="space-y-2">
                  <Label htmlFor="email">Adresse email *</Label>
                  <Input
                    id="email"
                    type="email"
                    placeholder="email@exemple.com"
                    value={newSubscriber.email}
                    onChange={(e) => setNewSubscriber({ ...newSubscriber, email: e.target.value })}
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="telephone">Numéro de téléphone</Label>
                  <Input
                    id="telephone"
                    type="tel"
                    placeholder="+33 1 23 45 67 89"
                    value={newSubscriber.telephone}
                    onChange={(e) => setNewSubscriber({ ...newSubscriber, telephone: e.target.value })}
                  />
                </div>
                <Button 
                  onClick={addSubscriber} 
                  className="w-full"
                  disabled={!newSubscriber.nom || !newSubscriber.prenom || !newSubscriber.email || isSubmitting}
                >
                  {isSubmitting ? (
                    <>
                      <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2"></div>
                      Ajout en cours...
                    </>
                  ) : (
                    'Ajouter l\'abonné'
                  )}
                </Button>
              </div>
            </DialogContent>
          </Dialog>
        </div>
      </div>

      {error && (
        <div className="flex items-center space-x-2 p-3 bg-red-50 border border-red-200 rounded-lg">
          <AlertCircle className="h-4 w-4 text-red-600" />
          <span className="text-sm text-red-600">{error}</span>
          <Button variant="outline" size="sm" onClick={() => setError('')}>
            Fermer
          </Button>
        </div>
      )}

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <Card>
          <CardContent className="p-6">
            <div className="flex items-center space-x-4">
              <div className="w-12 h-12 bg-blue-100 rounded-lg flex items-center justify-center">
                <CheckCircle className="h-6 w-6 text-blue-600" />
              </div>
              <div>
                <p className="text-2xl font-bold text-gray-900">{stats.total}</p>
                <p className="text-gray-600">Total abonnés</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="flex items-center space-x-4">
              <div className="w-12 h-12 bg-green-100 rounded-lg flex items-center justify-center">
                <CheckCircle className="h-6 w-6 text-green-600" />
              </div>
              <div>
                <p className="text-2xl font-bold text-gray-900">{stats.actifs}</p>
                <p className="text-gray-600">Actifs</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="flex items-center space-x-4">
              <div className="w-12 h-12 bg-red-100 rounded-lg flex items-center justify-center">
                <XCircle className="h-6 w-6 text-red-600" />
              </div>
              <div>
                <p className="text-2xl font-bold text-gray-900">{stats.expires}</p>
                <p className="text-gray-600">Expirés</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle>Liste des abonnés</CardTitle>
            <div className="relative max-w-sm">
              <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-gray-400" />
              <Input
                placeholder="Rechercher un abonné..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="pl-10"
              />
            </div>
          </div>
        </CardHeader>
        <CardContent>
          {filteredSubscribers.length === 0 ? (
            <p className="text-gray-500 text-center py-8">
              {searchTerm ? 'Aucun abonné trouvé pour cette recherche' : 'Aucun abonné trouvé'}
            </p>
          ) : (
            <div className="max-h-96 overflow-y-auto space-y-4">
              {filteredSubscribers.map((subscriber) => (
                <div key={subscriber.id} className="flex items-center justify-between p-4 border border-gray-200 rounded-lg hover:bg-gray-50 transition-colors">
                  <div className="flex-1">
                    <h3 className="font-medium text-gray-900">
                      {subscriber.prenom} {subscriber.nom}
                    </h3>
                    <p className="text-sm text-gray-600">{subscriber.email}</p>
                    {subscriber.telephone && (
                      <p className="text-sm text-gray-500">{subscriber.telephone}</p>
                    )}
                    <p className="text-sm text-gray-500">
                      Ajouté le {formatDate(subscriber.date_ajout)} • {subscriber.documents_recus || 0} documents reçus
                    </p>
                  </div>
                  <div className="flex items-center space-x-4">
                    {getStatusBadge(subscriber.status)}
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={() => toggleStatus(subscriber.id, subscriber.status)}
                    >
                      {subscriber.status === 'actif' ? 'Désactiver' : 'Activer'}
                    </Button>
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={() => deleteSubscriber(subscriber.id)}
                      className="text-red-600 hover:text-red-700"
                    >
                      <Trash2 className="h-4 w-4" />
                    </Button>
                  </div>
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
};

export default SubscriberManagement;

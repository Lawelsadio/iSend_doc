import { useState, useEffect } from 'react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Card, CardHeader, CardContent, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { 
  Plus, 
  Users, 
  CreditCard, 
  BarChart3, 
  Settings, 
  Search, 
  RefreshCw, 
  Trash2, 
  Edit, 
  Eye,
  CheckCircle,
  XCircle,
  AlertCircle,
  Calendar,
  FileText,
  Mail,
  Shield,
  Crown
} from 'lucide-react';
import { adminService } from '@/services';
import type { 
  AdminUser, 
  AdminSubscription, 
  AdminStats, 
  CreateUserData,
  CreateSubscriptionData 
} from '@/services/adminService';
import SubscriberService from '@/services/subscriberService';

const AdminDashboard = () => {
  const [activeTab, setActiveTab] = useState('overview');
  const [users, setUsers] = useState<AdminUser[]>([]);
  const [subscriptions, setSubscriptions] = useState<AdminSubscription[]>([]);
  const [stats, setStats] = useState<AdminStats | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [error, setError] = useState('');
  const [searchTerm, setSearchTerm] = useState('');
  const [showInactiveUsers, setShowInactiveUsers] = useState(false);

  // États pour les modales
  const [isUserDialogOpen, setIsUserDialogOpen] = useState(false);
  const [isSubscriptionDialogOpen, setIsSubscriptionDialogOpen] = useState(false);
  const [isEditUserDialogOpen, setIsEditUserDialogOpen] = useState(false);
  const [isEditSubscriptionDialogOpen, setIsEditSubscriptionDialogOpen] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);

  // États pour les formulaires
  const [newUser, setNewUser] = useState<CreateUserData>({
    nom: '',
    prenom: '',
    email: '',
    password: '',
    role: 'user'
  });

  const [editingUser, setEditingUser] = useState<AdminUser | null>(null);
  const [editUserForm, setEditUserForm] = useState<Partial<CreateUserData>>({
    nom: '',
    prenom: '',
    email: '',
    password: '',
    role: 'user'
  });

  const [editingSubscription, setEditingSubscription] = useState<AdminSubscription | null>(null);
  const [editSubscriptionForm, setEditSubscriptionForm] = useState<Partial<CreateSubscriptionData>>({
    type: 'premium',
    status: 'actif',
    limite_documents: 1000,
    limite_destinataires: 500,
    date_debut: new Date().toISOString().split('T')[0],
    date_fin: ''
  });

  const [newSubscription, setNewSubscription] = useState<CreateSubscriptionData>({
    abonne_id: 0,
    type: 'premium',
    status: 'actif',
    limite_documents: 1000,
    limite_destinataires: 500,
    date_debut: new Date().toISOString().split('T')[0],
    date_fin: ''
  });

  // États pour la recherche dans le tableau de bord
  const [recentUsersSearch, setRecentUsersSearch] = useState('');
  const [activeSubscriptionsSearch, setActiveSubscriptionsSearch] = useState('');

  // Ajout d'un état pour la liste des abonnes
  const [abonnes, setAbonnes] = useState([]);

  // Remplacer l'ancienne instance (s'il y en a une)
  // const subscriberService = ...
  const subscriberService = new SubscriberService();

  useEffect(() => {
    loadAdminData();
  }, []);

  // Effet pour gérer les limites illimitées
  useEffect(() => {
    if (newSubscription.type === 'illimite') {
      setNewSubscription(prev => ({
        ...prev,
        limite_documents: -1,
        limite_destinataires: -1
      }));
    }
  }, [newSubscription.type]);

  // Chargement des abonnes au montage
  useEffect(() => {
    const fetchAbonnes = async () => {
      const response = await subscriberService.getSubscribers();
      if (response.success && response.data) {
        setAbonnes(response.data.subscribers);
      }
    };
    fetchAbonnes();
  }, []);

  const loadAdminData = async () => {
    setIsLoading(true);
    setError('');

    try {
      const [usersRes, subscriptionsRes, statsRes] = await Promise.all([
        adminService.getUsers(),
        adminService.getSubscriptions(),
        adminService.getGlobalStats()
      ]);

      if (usersRes.success && usersRes.data) setUsers(usersRes.data);
      if (subscriptionsRes.success && subscriptionsRes.data) setSubscriptions(subscriptionsRes.data);
      if (statsRes.success && statsRes.data) setStats(statsRes.data);

      if (!usersRes.success || !subscriptionsRes.success || !statsRes.success) {
        setError('Erreur lors du chargement des données');
      }
    } catch (err) {
      console.error('Erreur chargement admin:', err);
      setError('Erreur de connexion');
    } finally {
      setIsLoading(false);
    }
  };

  const handleRefresh = async () => {
    setIsRefreshing(true);
    await loadAdminData();
    setIsRefreshing(false);
  };

  const createUser = async () => {
    setIsSubmitting(true);
    setError('');

    try {
      const response = await adminService.createUser(newUser);
      if (response.success && response.data) {
        setUsers(prev => [response.data!, ...prev]);
        setNewUser({ nom: '', prenom: '', email: '', password: '', role: 'user' });
        setIsUserDialogOpen(false);
      } else {
        setError(response.error || 'Erreur lors de la création de l\'utilisateur');
      }
    } catch (err) {
      console.error('Erreur création utilisateur:', err);
      setError('Erreur de connexion');
    } finally {
      setIsSubmitting(false);
    }
  };

  const createSubscription = async () => {
    setIsSubmitting(true);
    setError('');

    console.log('Données d\'abonnement à envoyer:', newSubscription);

    try {
      const response = await adminService.createSubscription(newSubscription);
      console.log('Réponse de l\'API:', response);
      
      if (response.success && response.data) {
        setSubscriptions(prev => [response.data!, ...prev]);
        setNewSubscription({
          abonne_id: 0,
          type: 'premium',
          status: 'actif',
          limite_documents: 1000,
          limite_destinataires: 500,
          date_debut: new Date().toISOString().split('T')[0],
          date_fin: ''
        });
        setIsSubscriptionDialogOpen(false);
      } else {
        setError(response.error || 'Erreur lors de la création de l\'abonnement');
      }
    } catch (err) {
      console.error('Erreur création abonnement:', err);
      setError('Erreur de connexion');
    } finally {
      setIsSubmitting(false);
    }
  };

  const toggleUserStatus = async (userId: number, currentStatus: string) => {
    try {
      const response = await adminService.toggleUserStatus(userId, currentStatus);
      if (response.success && response.data) {
        setUsers(prev => prev.map(user => 
          user.id === userId ? response.data! : user
        ));
      } else {
        setError(response.error || 'Erreur lors de la modification du statut');
      }
    } catch (err) {
      console.error('Erreur modification statut:', err);
      setError('Erreur de connexion');
    }
  };

  const toggleSubscriptionStatus = async (subscriptionId: number, currentStatus: string) => {
    try {
      const response = await adminService.toggleSubscriptionStatus(subscriptionId, currentStatus);
      if (response.success && response.data) {
        setSubscriptions(prev => prev.map(sub => 
          sub.id === subscriptionId ? response.data! : sub
        ));
      } else {
        setError(response.error || 'Erreur lors de la modification du statut');
      }
    } catch (err) {
      console.error('Erreur modification statut abonnement:', err);
      setError('Erreur de connexion');
    }
  };

  const openEditUserDialog = (user: AdminUser) => {
    setEditingUser(user);
    setEditUserForm({
      nom: user.nom,
      prenom: user.prenom,
      email: user.email,
      password: '', // On ne pré-remplit pas le mot de passe
      role: user.role
    });
    setIsEditUserDialogOpen(true);
  };

  const openEditSubscriptionDialog = (subscription: AdminSubscription) => {
    setEditingSubscription(subscription);
    
    // Formater les dates pour les champs input[type="date"]
    const formatDateForInput = (dateString: string | null | undefined) => {
      if (!dateString) return '';
      return dateString.split(' ')[0]; // Prendre seulement la partie date (YYYY-MM-DD)
    };
    
    setEditSubscriptionForm({
      type: subscription.type,
      status: subscription.status,
      limite_documents: subscription.limite_documents,
      limite_destinataires: subscription.limite_destinataires,
      date_debut: formatDateForInput(subscription.date_debut),
      date_fin: formatDateForInput(subscription.date_fin)
    });
    setIsEditSubscriptionDialogOpen(true);
  };

  const updateUser = async () => {
    if (!editingUser) return;

    setIsSubmitting(true);
    setError('');

    try {
      // Ne pas envoyer le mot de passe s'il est vide
      const updateData = { ...editUserForm };
      if (!updateData.password) {
        delete updateData.password;
      }

      const response = await adminService.updateUser(editingUser.id, updateData);
      if (response.success && response.data) {
        setUsers(prev => prev.map(user => 
          user.id === editingUser.id ? response.data! : user
        ));
        setIsEditUserDialogOpen(false);
        setEditingUser(null);
        setEditUserForm({ nom: '', prenom: '', email: '', password: '', role: 'user' });
      } else {
        setError(response.error || 'Erreur lors de la modification de l\'utilisateur');
      }
    } catch (err) {
      console.error('Erreur modification utilisateur:', err);
      setError('Erreur de connexion');
    } finally {
      setIsSubmitting(false);
    }
  };

  const updateSubscription = async () => {
    if (!editingSubscription) return;

    setIsSubmitting(true);
    setError('');

    try {
      const response = await adminService.updateSubscription(editingSubscription.id, editSubscriptionForm);
      if (response.success && response.data) {
        setSubscriptions(prev => prev.map(sub => 
          sub.id === editingSubscription.id ? response.data! : sub
        ));
        setIsEditSubscriptionDialogOpen(false);
        setEditingSubscription(null);
        setEditSubscriptionForm({
          type: 'premium',
          status: 'actif',
          limite_documents: 1000,
          limite_destinataires: 500,
          date_debut: new Date().toISOString().split('T')[0],
          date_fin: ''
        });
      } else {
        setError(response.error || 'Erreur lors de la modification de l\'abonnement');
      }
    } catch (err) {
      console.error('Erreur modification abonnement:', err);
      setError('Erreur de connexion');
    } finally {
      setIsSubmitting(false);
    }
  };

  const deleteUser = async (userId: number) => {
    if (!confirm('Êtes-vous sûr de vouloir supprimer cet utilisateur ?')) {
      return;
    }

    try {
      const response = await adminService.deleteUser(userId);
      if (response.success) {
        setUsers(prev => prev.filter(user => user.id !== userId));
      } else {
        setError(response.error || 'Erreur lors de la suppression');
      }
    } catch (err) {
      console.error('Erreur suppression utilisateur:', err);
      setError('Erreur de connexion');
    }
  };

  const deleteSubscription = async (subscriptionId: number) => {
    if (!confirm('Êtes-vous sûr de vouloir supprimer cet abonnement ?')) {
      return;
    }

    try {
      const response = await adminService.deleteSubscription(subscriptionId);
      if (response.success) {
        setSubscriptions(prev => prev.filter(sub => sub.id !== subscriptionId));
      } else {
        setError(response.error || 'Erreur lors de la suppression');
      }
    } catch (err) {
      console.error('Erreur suppression abonnement:', err);
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
    } else if (status === 'annule') {
      return (
        <Badge variant="secondary" className="bg-gray-200 text-gray-700">
          <XCircle className="h-3 w-3 mr-1" />
          Annulé
        </Badge>
      );
    } else if (status === 'inactif') {
      return (
        <Badge variant="secondary" className="bg-red-100 text-red-800">
          <XCircle className="h-3 w-3 mr-1" />
          Inactif
        </Badge>
      );
    } else {
      return (
        <Badge variant="secondary" className="bg-gray-100 text-gray-800">
          <XCircle className="h-3 w-3 mr-1" />
          Inconnu
        </Badge>
      );
    }
  };

  const getRoleBadge = (role: string) => {
    if (role === 'admin') {
      return (
        <Badge variant="secondary" className="bg-purple-100 text-purple-800">
          <Crown className="h-3 w-3 mr-1" />
          Admin
        </Badge>
      );
    } else {
      return (
        <Badge variant="secondary" className="bg-blue-100 text-blue-800">
          <Shield className="h-3 w-3 mr-1" />
          Utilisateur
        </Badge>
      );
    }
  };

  const getSubscriptionTypeBadge = (type: string) => {
    const colors = {
      'gratuit': 'bg-gray-100 text-gray-800',
      'premium': 'bg-blue-100 text-blue-800',
      'entreprise': 'bg-purple-100 text-purple-800',
      'illimite': 'bg-yellow-100 text-yellow-800'
    };
    
    return (
      <Badge variant="secondary" className={colors[type as keyof typeof colors] || colors.gratuit}>
        {type.charAt(0).toUpperCase() + type.slice(1)}
      </Badge>
    );
  };

  const filteredUsers = users.filter(user => {
    // Filtre par statut
    if (!showInactiveUsers && user.status === 'inactif') {
      return false;
    }
    
    // Filtre par recherche
    return user.email.toLowerCase().includes(searchTerm.toLowerCase()) ||
           user.nom.toLowerCase().includes(searchTerm.toLowerCase()) ||
           user.prenom.toLowerCase().includes(searchTerm.toLowerCase());
  });

  // Filtrage pour les utilisateurs récents
  const filteredRecentUsers = users.slice(0, 5).filter(user => {
    if (!recentUsersSearch) return true;
    const searchLower = recentUsersSearch.toLowerCase();
    const matches = user.email.toLowerCase().includes(searchLower) ||
                   user.nom.toLowerCase().includes(searchLower) ||
                   user.prenom.toLowerCase().includes(searchLower);
    console.log('Recherche Utilisateurs récents:', { searchTerm: recentUsersSearch, user: `${user.prenom} ${user.nom}`, matches });
    return matches;
  });

  // Filtrage pour les abonnements actifs
  const filteredActiveSubscriptions = subscriptions.filter(sub => sub.status === 'actif').slice(0, 5).filter(subscription => {
    if (!activeSubscriptionsSearch) return true;
    const abonne = abonnes.find(a => a.id === subscription.abonne_id);
    if (!abonne) return false;
    const searchLower = activeSubscriptionsSearch.toLowerCase();
    const matches = abonne.email.toLowerCase().includes(searchLower) ||
                   abonne.nom.toLowerCase().includes(searchLower) ||
                   abonne.prenom.toLowerCase().includes(searchLower) ||
                   subscription.type.toLowerCase().includes(searchLower);
    console.log('Recherche Abonnements actifs:', { searchTerm: activeSubscriptionsSearch, user: `${abonne.prenom} ${abonne.nom}`, type: subscription.type, matches });
    return matches;
  });

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('fr-FR');
  };

  if (isLoading) {
    return (
      <div className="space-y-6">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Administration</h1>
          <p className="text-gray-600 mt-1">Chargement...</p>
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
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Administration</h1>
          <p className="text-gray-600 mt-1">Gestion complète de la plateforme iSend</p>
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

      <Tabs value={activeTab} onValueChange={setActiveTab} className="space-y-6">
        <TabsList className="grid w-full grid-cols-4">
          <TabsTrigger value="overview" className="flex items-center space-x-2">
            <BarChart3 className="h-4 w-4" />
            <span>Vue d'ensemble</span>
          </TabsTrigger>
          <TabsTrigger value="users" className="flex items-center space-x-2">
            <Users className="h-4 w-4" />
            <span>Utilisateurs</span>
          </TabsTrigger>
          <TabsTrigger value="subscriptions" className="flex items-center space-x-2">
            <CreditCard className="h-4 w-4" />
            <span>Abonnements</span>
          </TabsTrigger>
          <TabsTrigger value="settings" className="flex items-center space-x-2">
            <Settings className="h-4 w-4" />
            <span>Paramètres</span>
          </TabsTrigger>
        </TabsList>

        <TabsContent value="overview" className="space-y-6">
          <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
            <Card>
              <CardContent className="p-6">
                <div className="flex items-center space-x-4">
                  <div className="w-12 h-12 bg-blue-100 rounded-lg flex items-center justify-center">
                    <Users className="h-6 w-6 text-blue-600" />
                  </div>
                  <div>
                    <p className="text-2xl font-bold text-gray-900">{stats?.total_users ?? 0}</p>
                    <p className="text-gray-600">Utilisateurs</p>
                  </div>
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardContent className="p-6">
                <div className="flex items-center space-x-4">
                  <div className="w-12 h-12 bg-green-100 rounded-lg flex items-center justify-center">
                    <CreditCard className="h-6 w-6 text-green-600" />
                  </div>
                  <div>
                    <p className="text-2xl font-bold text-gray-900">{stats?.active_subscriptions ?? 0}</p>
                    <p className="text-gray-600">Abonnements actifs</p>
                  </div>
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardContent className="p-6">
                <div className="flex items-center space-x-4">
                  <div className="w-12 h-12 bg-purple-100 rounded-lg flex items-center justify-center">
                    <FileText className="h-6 w-6 text-purple-600" />
                  </div>
                  <div>
                    <p className="text-2xl font-bold text-gray-900">{stats?.total_documents ?? 0}</p>
                    <p className="text-gray-600">Documents envoyés</p>
                  </div>
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardContent className="p-6">
                <div className="flex items-center space-x-4">
                  <div className="w-12 h-12 bg-orange-100 rounded-lg flex items-center justify-center">
                    <Eye className="h-6 w-6 text-orange-600" />
                  </div>
                  <div>
                    <p className="text-2xl font-bold text-gray-900">{stats?.total_views ?? 0}</p>
                    <p className="text-gray-600">Vues totales</p>
                  </div>
                </div>
              </CardContent>
            </Card>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <Card>
              <CardHeader>
                <div className="flex items-center justify-between">
                  <CardTitle>Utilisateurs récents</CardTitle>
                  <div className="relative max-w-sm">
                    <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-gray-400" />
                    <Input
                      placeholder="Rechercher un utilisateur..."
                      value={recentUsersSearch}
                      onChange={(e) => {
                        console.log('AdminDashboard RecentUsers Search onChange:', e.target.value);
                        setRecentUsersSearch(e.target.value);
                      }}
                      className="pl-10"
                    />
                  </div>
                </div>
              </CardHeader>
              <CardContent>
                <div className="max-h-96 overflow-y-auto space-y-4">
                  {filteredRecentUsers.map((user) => (
                    <div key={user.id} className="flex items-center justify-between p-3 border border-gray-200 rounded-lg">
                      <div className="flex items-center space-x-3">
                        <div className="w-10 h-10 bg-gray-100 rounded-full flex items-center justify-center">
                          <span className="text-sm font-medium text-gray-600">
                            {user.prenom.charAt(0)}{user.nom.charAt(0)}
                          </span>
                        </div>
                        <div>
                          <p className="font-medium text-gray-900">{user.prenom} {user.nom}</p>
                          <p className="text-sm text-gray-600">{user.email}</p>
                        </div>
                      </div>
                      <div className="flex items-center space-x-2">
                        {getRoleBadge(user.role)}
                        {getStatusBadge(user.status)}
                      </div>
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <div className="flex items-center justify-between">
                  <CardTitle>Abonnements actifs</CardTitle>
                  <div className="relative max-w-sm">
                    <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-gray-400" />
                    <Input
                      placeholder="Rechercher un abonnement..."
                      value={activeSubscriptionsSearch}
                      onChange={(e) => {
                        console.log('AdminDashboard ActiveSubscriptions Search onChange:', e.target.value);
                        setActiveSubscriptionsSearch(e.target.value);
                      }}
                      className="pl-10"
                    />
                  </div>
                </div>
              </CardHeader>
              <CardContent>
                <div className="max-h-96 overflow-y-auto space-y-4">
                  {filteredActiveSubscriptions.map((subscription) => {
                    const abonne = abonnes.find(a => a.id === subscription.abonne_id);
                    return (
                      <div key={subscription.id} className="flex items-center justify-between p-3 border border-gray-200 rounded-lg">
                        <div>
                          <p className="font-medium text-gray-900">
                            {abonne ? `${abonne.prenom} ${abonne.nom}` : `Abonné ${subscription.abonne_id}`}
                          </p>
                          <p className="text-sm text-gray-600">{getSubscriptionTypeBadge(subscription.type).props.children}</p>
                        </div>
                        <div className="text-right">
                          <p className="text-sm text-gray-600">
                            Expire: {subscription.date_fin ? formatDate(subscription.date_fin) : 'Illimité'}
                          </p>
                        </div>
                      </div>
                    );
                  })}
                </div>
              </CardContent>
            </Card>
          </div>
        </TabsContent>

        <TabsContent value="users" className="space-y-6">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-4">
              <div className="relative">
                <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-gray-400" />
                <Input
                  placeholder="Rechercher un utilisateur..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  className="pl-10 w-80"
                />
              </div>
              <Button
                variant="outline"
                onClick={() => setShowInactiveUsers(!showInactiveUsers)}
                className={showInactiveUsers ? "bg-gray-100" : ""}
              >
                {showInactiveUsers ? "Masquer inactifs" : "Afficher inactifs"}
              </Button>
            </div>
            <Dialog open={isUserDialogOpen} onOpenChange={setIsUserDialogOpen}>
              <DialogTrigger asChild>
                <Button className="bg-blue-600 hover:bg-blue-700">
                  <Plus className="h-4 w-4 mr-2" />
                  Nouvel utilisateur
                </Button>
              </DialogTrigger>
              <DialogContent>
                <DialogHeader>
                  <DialogTitle>Créer un nouvel utilisateur</DialogTitle>
                </DialogHeader>
                <div className="space-y-4">
                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <Label htmlFor="prenom">Prénom</Label>
                      <Input
                        id="prenom"
                        value={newUser.prenom}
                        onChange={(e) => setNewUser(prev => ({ ...prev, prenom: e.target.value }))}
                      />
                    </div>
                    <div>
                      <Label htmlFor="nom">Nom</Label>
                      <Input
                        id="nom"
                        value={newUser.nom}
                        onChange={(e) => setNewUser(prev => ({ ...prev, nom: e.target.value }))}
                      />
                    </div>
                  </div>
                  <div>
                    <Label htmlFor="email">Email</Label>
                    <Input
                      id="email"
                      type="email"
                      value={newUser.email}
                      onChange={(e) => setNewUser(prev => ({ ...prev, email: e.target.value }))}
                    />
                  </div>
                  <div>
                    <Label htmlFor="password">Mot de passe</Label>
                    <Input
                      id="password"
                      type="password"
                      value={newUser.password}
                      onChange={(e) => setNewUser(prev => ({ ...prev, password: e.target.value }))}
                    />
                  </div>
                  <div>
                    <Label htmlFor="role">Rôle</Label>
                    <Select value={newUser.role} onValueChange={(value) => setNewUser(prev => ({ ...prev, role: value as 'user' | 'admin' }))}>
                      <SelectTrigger>
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="user">Utilisateur</SelectItem>
                        <SelectItem value="admin">Administrateur</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>
                  <Button 
                    onClick={createUser} 
                    className="w-full"
                    disabled={!newUser.nom || !newUser.prenom || !newUser.email || !newUser.password || isSubmitting}
                  >
                    {isSubmitting ? (
                      <>
                        <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2"></div>
                        Création en cours...
                      </>
                    ) : (
                      'Créer l\'utilisateur'
                    )}
                  </Button>
                </div>
              </DialogContent>
            </Dialog>
          </div>

          <Card>
            <CardContent>
              <div className="max-h-96 overflow-y-auto">
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>Utilisateur</TableHead>
                      <TableHead>Email</TableHead>
                      <TableHead>Rôle</TableHead>
                      <TableHead>Statut</TableHead>
                      <TableHead>Date d'inscription</TableHead>
                      <TableHead>Actions</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {filteredUsers.map((user) => (
                      <TableRow key={user.id}>
                        <TableCell>
                          <div className="flex items-center space-x-3">
                            <div className="w-8 h-8 bg-gray-100 rounded-full flex items-center justify-center">
                              <span className="text-xs font-medium text-gray-600">
                                {user.prenom.charAt(0)}{user.nom.charAt(0)}
                              </span>
                            </div>
                            <span className="font-medium">{user.prenom} {user.nom}</span>
                          </div>
                        </TableCell>
                        <TableCell>{user.email}</TableCell>
                        <TableCell>{getRoleBadge(user.role)}</TableCell>
                        <TableCell>{getStatusBadge(user.status)}</TableCell>
                        <TableCell>{formatDate(user.date_inscription)}</TableCell>
                        <TableCell>
                          <div className="flex items-center space-x-2">
                            <Button
                              variant="outline"
                              size="sm"
                              onClick={() => openEditUserDialog(user)}
                            >
                              <Edit className="h-4 w-4" />
                            </Button>
                            <Button
                              variant="outline"
                              size="sm"
                              onClick={() => toggleUserStatus(user.id, user.status)}
                            >
                              {user.status === 'actif' ? 'Désactiver' : 'Activer'}
                            </Button>
                            <Button
                              variant="outline"
                              size="sm"
                              onClick={() => deleteUser(user.id)}
                              className="text-red-600 hover:text-red-700"
                            >
                              <Trash2 className="h-4 w-4" />
                            </Button>
                          </div>
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="subscriptions" className="space-y-6">
          <div className="flex items-center justify-between">
            <h2 className="text-xl font-semibold">Gestion des abonnements</h2>
            <Dialog open={isSubscriptionDialogOpen} onOpenChange={setIsSubscriptionDialogOpen}>
              <DialogTrigger asChild>
                <Button className="bg-blue-600 hover:bg-blue-700">
                  <Plus className="h-4 w-4 mr-2" />
                  Nouvel abonnement
                </Button>
              </DialogTrigger>
              <DialogContent>
                <DialogHeader>
                  <DialogTitle>Créer un nouvel abonnement</DialogTitle>
                </DialogHeader>
                <div className="space-y-4">
                  <div>
                    <Label htmlFor="abonne_id">Abonné</Label>
                    <Select value={newSubscription.abonne_id?.toString() || ''} onValueChange={(value) => setNewSubscription(prev => ({ ...prev, abonne_id: parseInt(value) }))}>
                      <SelectTrigger>
                        <SelectValue placeholder="Sélectionner un abonné" />
                      </SelectTrigger>
                      <SelectContent>
                        {abonnes
                          .filter(abonne => !subscriptions.some(sub => sub.abonne_id === abonne.id))
                          .map((abonne) => (
                            <SelectItem key={abonne.id} value={abonne.id.toString()}>
                              {abonne.prenom} {abonne.nom} ({abonne.email})
                            </SelectItem>
                          ))}
                      </SelectContent>
                    </Select>
                  </div>
                  <div>
                    <Label htmlFor="type">Type d'abonnement</Label>
                    <Select value={newSubscription.type} onValueChange={(value) => setNewSubscription(prev => ({ ...prev, type: value as 'gratuit' | 'premium' | 'entreprise' | 'illimite' }))}>
                      <SelectTrigger>
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="gratuit">Gratuit</SelectItem>
                        <SelectItem value="premium">Premium</SelectItem>
                        <SelectItem value="entreprise">Entreprise</SelectItem>
                        <SelectItem value="illimite">Illimité</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>
                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <Label htmlFor="limite_documents">Limite documents</Label>
                      <Input
                        id="limite_documents"
                        type="number"
                        value={newSubscription.limite_documents}
                        onChange={(e) => setNewSubscription(prev => ({ ...prev, limite_documents: parseInt(e.target.value) }))}
                        disabled={newSubscription.type === 'illimite'}
                        placeholder={newSubscription.type === 'illimite' ? 'Illimité' : '100'}
                      />
                    </div>
                    <div>
                      <Label htmlFor="limite_destinataires">Limite destinataires</Label>
                      <Input
                        id="limite_destinataires"
                        type="number"
                        value={newSubscription.limite_destinataires}
                        onChange={(e) => setNewSubscription(prev => ({ ...prev, limite_destinataires: parseInt(e.target.value) }))}
                        disabled={newSubscription.type === 'illimite'}
                        placeholder={newSubscription.type === 'illimite' ? 'Illimité' : '50'}
                      />
                    </div>
                  </div>
                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <Label htmlFor="date_debut">Date de début</Label>
                      <Input
                        id="date_debut"
                        type="date"
                        value={newSubscription.date_debut}
                        onChange={(e) => setNewSubscription(prev => ({ ...prev, date_debut: e.target.value }))}
                      />
                    </div>
                    <div>
                      <Label htmlFor="date_fin">Date de fin (optionnel)</Label>
                      <Input
                        id="date_fin"
                        type="date"
                        value={newSubscription.date_fin}
                        onChange={(e) => setNewSubscription(prev => ({ ...prev, date_fin: e.target.value }))}
                      />
                    </div>
                  </div>
                  <Button 
                    onClick={createSubscription} 
                    className="w-full"
                    disabled={!newSubscription.abonne_id || isSubmitting}
                  >
                    {isSubmitting ? (
                      <>
                        <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2"></div>
                        Création en cours...
                      </>
                    ) : (
                      'Créer l\'abonnement'
                    )}
                  </Button>
                </div>
              </DialogContent>
            </Dialog>
          </div>

          <Card>
            <CardContent>
              <div className="max-h-96 overflow-y-auto">
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>Utilisateur</TableHead>
                      <TableHead>Type</TableHead>
                      <TableHead>Statut</TableHead>
                      <TableHead>Limites</TableHead>
                      <TableHead>Période</TableHead>
                      <TableHead>Actions</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {subscriptions.map((subscription) => {
                      const abonne = abonnes.find(a => a.id === subscription.abonne_id);
                      return (
                        <TableRow key={subscription.id}>
                          <TableCell>
                            {abonne ? `${abonne.prenom} ${abonne.nom}` : `Abonné ${subscription.abonne_id}`}
                          </TableCell>
                          <TableCell>{getSubscriptionTypeBadge(subscription.type)}</TableCell>
                          <TableCell>{getStatusBadge(subscription.status)}</TableCell>
                          <TableCell>
                            <div className="text-sm">
                              <p>Docs: {subscription.limite_documents === -1 ? 'Illimité' : subscription.limite_documents}</p>
                              <p>Dest: {subscription.limite_destinataires === -1 ? 'Illimité' : subscription.limite_destinataires}</p>
                            </div>
                          </TableCell>
                          <TableCell>
                            <div className="text-sm">
                              <p>Début: {formatDate(subscription.date_debut)}</p>
                              <p>Fin: {subscription.date_fin ? formatDate(subscription.date_fin) : 'Illimité'}</p>
                            </div>
                          </TableCell>
                          <TableCell>
                            <div className="flex items-center space-x-2">
                              <Button
                                variant="outline"
                                size="sm"
                                onClick={() => openEditSubscriptionDialog(subscription)}
                              >
                                <Edit className="h-4 w-4" />
                              </Button>
                              <Button
                                variant="outline"
                                size="sm"
                                onClick={() => toggleSubscriptionStatus(subscription.id, subscription.status)}
                              >
                                {subscription.status === 'actif' ? 'Désactiver' : 'Activer'}
                              </Button>
                              <Button
                                variant="outline"
                                size="sm"
                                onClick={() => deleteSubscription(subscription.id)}
                                className="text-red-600 hover:text-red-700"
                              >
                                <Trash2 className="h-4 w-4" />
                              </Button>
                            </div>
                          </TableCell>
                        </TableRow>
                      );
                    })}
                  </TableBody>
                </Table>
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="settings" className="space-y-6">
          <Card>
            <CardHeader>
              <CardTitle>Paramètres de la plateforme</CardTitle>
            </CardHeader>
            <CardContent>
              <p className="text-gray-600">
                Les paramètres de configuration de la plateforme seront disponibles ici.
              </p>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>

      {/* Modal de modification d'utilisateur */}
      <Dialog open={isEditUserDialogOpen} onOpenChange={setIsEditUserDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Modifier l'utilisateur</DialogTitle>
          </DialogHeader>
          <div className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div>
                <Label htmlFor="edit-prenom">Prénom</Label>
                <Input
                  id="edit-prenom"
                  value={editUserForm.prenom}
                  onChange={(e) => setEditUserForm(prev => ({ ...prev, prenom: e.target.value }))}
                />
              </div>
              <div>
                <Label htmlFor="edit-nom">Nom</Label>
                <Input
                  id="edit-nom"
                  value={editUserForm.nom}
                  onChange={(e) => setEditUserForm(prev => ({ ...prev, nom: e.target.value }))}
                />
              </div>
            </div>
            <div>
              <Label htmlFor="edit-email">Email</Label>
              <Input
                id="edit-email"
                type="email"
                value={editUserForm.email}
                onChange={(e) => setEditUserForm(prev => ({ ...prev, email: e.target.value }))}
              />
            </div>
            <div>
              <Label htmlFor="edit-password">Nouveau mot de passe (optionnel)</Label>
              <Input
                id="edit-password"
                type="password"
                placeholder="Laisser vide pour ne pas changer"
                value={editUserForm.password}
                onChange={(e) => setEditUserForm(prev => ({ ...prev, password: e.target.value }))}
              />
            </div>
            <div>
              <Label htmlFor="edit-role">Rôle</Label>
              <Select value={editUserForm.role} onValueChange={(value) => setEditUserForm(prev => ({ ...prev, role: value as 'user' | 'admin' }))}>
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="user">Utilisateur</SelectItem>
                  <SelectItem value="admin">Administrateur</SelectItem>
                </SelectContent>
              </Select>
            </div>
            <div className="flex space-x-2">
              <Button 
                onClick={updateUser} 
                className="flex-1"
                disabled={!editUserForm.nom || !editUserForm.prenom || !editUserForm.email || isSubmitting}
              >
                {isSubmitting ? (
                  <>
                    <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2"></div>
                    Modification en cours...
                  </>
                ) : (
                  'Modifier l\'utilisateur'
                )}
              </Button>
              <Button 
                variant="outline" 
                onClick={() => setIsEditUserDialogOpen(false)}
                disabled={isSubmitting}
              >
                Annuler
              </Button>
            </div>
          </div>
        </DialogContent>
      </Dialog>

      {/* Modal de modification d'abonnement */}
      <Dialog open={isEditSubscriptionDialogOpen} onOpenChange={setIsEditSubscriptionDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Modifier l'abonnement</DialogTitle>
          </DialogHeader>
          <div className="space-y-4">
            <div>
              <Label htmlFor="edit-type">Type d'abonnement</Label>
              <Select value={editSubscriptionForm.type} onValueChange={(value) => setEditSubscriptionForm(prev => ({ ...prev, type: value as 'gratuit' | 'premium' | 'entreprise' | 'illimite' }))}>
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="gratuit">Gratuit</SelectItem>
                  <SelectItem value="premium">Premium</SelectItem>
                  <SelectItem value="entreprise">Entreprise</SelectItem>
                  <SelectItem value="illimite">Illimité</SelectItem>
                </SelectContent>
              </Select>
            </div>
            <div>
              <Label htmlFor="edit-status">Statut</Label>
              <Select value={editSubscriptionForm.status} onValueChange={(value) => setEditSubscriptionForm(prev => ({ ...prev, status: value as 'actif' | 'expire' | 'annule' }))}>
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="actif">Actif</SelectItem>
                  <SelectItem value="expire">Expiré</SelectItem>
                  <SelectItem value="annule">Annulé</SelectItem>
                </SelectContent>
              </Select>
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <Label htmlFor="edit-limite-documents">Limite documents</Label>
                <Input
                  id="edit-limite-documents"
                  type="number"
                  value={editSubscriptionForm.limite_documents}
                  onChange={(e) => setEditSubscriptionForm(prev => ({ ...prev, limite_documents: parseInt(e.target.value) }))}
                />
              </div>
              <div>
                <Label htmlFor="edit-limite-destinataires">Limite destinataires</Label>
                <Input
                  id="edit-limite-destinataires"
                  type="number"
                  value={editSubscriptionForm.limite_destinataires}
                  onChange={(e) => setEditSubscriptionForm(prev => ({ ...prev, limite_destinataires: parseInt(e.target.value) }))}
                />
              </div>
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <Label htmlFor="edit-date-debut">Date de début</Label>
                <Input
                  id="edit-date-debut"
                  type="date"
                  value={editSubscriptionForm.date_debut}
                  onChange={(e) => setEditSubscriptionForm(prev => ({ ...prev, date_debut: e.target.value }))}
                />
              </div>
              <div>
                <Label htmlFor="edit-date-fin">Date de fin (optionnel)</Label>
                <Input
                  id="edit-date-fin"
                  type="date"
                  value={editSubscriptionForm.date_fin}
                  onChange={(e) => setEditSubscriptionForm(prev => ({ ...prev, date_fin: e.target.value }))}
                />
              </div>
            </div>
            <div className="flex space-x-2">
              <Button 
                onClick={updateSubscription} 
                className="flex-1"
                disabled={!editSubscriptionForm.type || !editSubscriptionForm.status || isSubmitting}
              >
                {isSubmitting ? (
                  <>
                    <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2"></div>
                    Modification en cours...
                  </>
                ) : (
                  'Modifier l\'abonnement'
                )}
              </Button>
              <Button 
                variant="outline" 
                onClick={() => setIsEditSubscriptionDialogOpen(false)}
                disabled={isSubmitting}
              >
                Annuler
              </Button>
            </div>
          </div>
        </DialogContent>
      </Dialog>
    </div>
  );
};

export default AdminDashboard; 
import { useState, useEffect } from 'react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Card, CardHeader, CardContent, CardTitle } from '@/components/ui/card';
import { Separator } from '@/components/ui/separator';
import { User, Mail, Settings, BarChart3, FileText, Eye, Users, RefreshCw, Save, AlertCircle } from 'lucide-react';
import { userProfileService } from '@/services';
import type { UserProfile, UpdateProfileData, ChangePasswordData } from '@/services/userProfileService';

const UserSettings = () => {
  const [userProfile, setUserProfile] = useState<UserProfile | null>(null);
  const [isLoadingProfile, setIsLoadingProfile] = useState(true);
  const [profileError, setProfileError] = useState('');

  const [userInfo, setUserInfo] = useState({
    nom: '',
    prenom: '',
    email: ''
  });

  const [password, setPassword] = useState({
    current: '',
    new: '',
    confirm: ''
  });

  const [isUpdatingProfile, setIsUpdatingProfile] = useState(false);
  const [isChangingPassword, setIsChangingPassword] = useState(false);
  const [updateMessage, setUpdateMessage] = useState('');

  const [stats, setStats] = useState({
    total_documents: 0,
    total_destinataires: 0,
    total_envoyes: 0,
    total_vues: 0,
    taux_lecture: 0,
    documents_ce_mois: 0,
    vues_ce_mois: 0,
    nouveaux_destinataires_ce_mois: 0
  });
  const [isLoadingStats, setIsLoadingStats] = useState(false);
  const [error, setError] = useState('');

  // Charger le profil utilisateur
  const loadProfile = async () => {
    setIsLoadingProfile(true);
    setProfileError('');

    try {
      const token = localStorage.getItem('authToken');
      if (!token) {
        setProfileError('Utilisateur non authentifié');
        return;
      }

      const response = await fetch(`http://localhost:8888/isend-document-flow/backend-php/api/user-profile.php?action=get&token=${encodeURIComponent(token)}`, {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json'
        }
      });

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}`);
      }

      const data = await response.json();
      
      if (data.success && data.data) {
        setUserProfile(data.data);
        setUserInfo({
          nom: data.data.nom,
          prenom: data.data.prenom,
          email: data.data.email
        });
      } else {
        setProfileError(data.error || 'Erreur lors du chargement du profil');
      }
    } catch (err) {
      console.error('Erreur chargement profil:', err);
      setProfileError('Erreur de connexion - Profil non disponible');
    } finally {
      setIsLoadingProfile(false);
    }
  };

  // Fonction pour charger les statistiques de manière sécurisée
  const loadStats = async () => {
    setIsLoadingStats(true);
    setError('');

    try {
      // Vérifier l'authentification
      const token = localStorage.getItem('authToken');
      if (!token) {
        setError('Utilisateur non authentifié');
        return;
      }

      // Appel API avec token dans l'URL (format attendu par le backend)
      const response = await fetch(`http://localhost:8888/isend-document-flow/backend-php/api/stats.php?token=${encodeURIComponent(token)}`, {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json'
        }
      });

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}`);
      }

      const data = await response.json();
      
      if (data.success && data.data) {
        setStats(data.data);
      } else {
        setError(data.error || 'Erreur lors du chargement des statistiques');
      }
    } catch (err) {
      console.error('Erreur chargement stats:', err);
      setError('Erreur de connexion - Statistiques non disponibles');
    } finally {
      setIsLoadingStats(false);
    }
  };

  // Charger les données au montage du composant
  useEffect(() => {
    loadProfile();
    loadStats();
  }, []);

  const handleSaveProfile = async () => {
    setIsUpdatingProfile(true);
    setUpdateMessage('');

    try {
      const token = localStorage.getItem('authToken');
      if (!token) {
        setUpdateMessage('Utilisateur non authentifié');
        return;
      }

      const updateData: UpdateProfileData = {
        nom: userInfo.nom,
        prenom: userInfo.prenom,
        email: userInfo.email
      };

      const response = await fetch(`http://localhost:8888/isend-document-flow/backend-php/api/user-profile.php?action=profile&token=${encodeURIComponent(token)}`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(updateData)
      });

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}`);
      }

      const data = await response.json();
      
      if (data.success) {
        setUpdateMessage('Profil mis à jour avec succès !');
        // Recharger le profil
        await loadProfile();
      } else {
        setUpdateMessage(data.message || 'Erreur lors de la mise à jour');
      }
    } catch (err) {
      console.error('Erreur mise à jour profil:', err);
      setUpdateMessage('Erreur de connexion');
    } finally {
      setIsUpdatingProfile(false);
    }
  };

  const handleChangePassword = async () => {
    if (password.new !== password.confirm) {
      setUpdateMessage('Les mots de passe ne correspondent pas.');
      return;
    }

    setIsChangingPassword(true);
    setUpdateMessage('');

    try {
      const token = localStorage.getItem('authToken');
      if (!token) {
        setUpdateMessage('Utilisateur non authentifié');
        return;
      }

      const passwordData: ChangePasswordData = {
        current_password: password.current,
        new_password: password.new,
        confirm_password: password.confirm
      };

      const response = await fetch(`http://localhost:8888/isend-document-flow/backend-php/api/user-profile.php?action=password&token=${encodeURIComponent(token)}`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(passwordData)
      });

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}`);
      }

      const data = await response.json();
      
      if (data.success) {
        setUpdateMessage('Mot de passe modifié avec succès !');
        setPassword({ current: '', new: '', confirm: '' });
      } else {
        setUpdateMessage(data.message || 'Erreur lors du changement de mot de passe');
      }
    } catch (err) {
      console.error('Erreur changement mot de passe:', err);
      setUpdateMessage('Erreur de connexion');
    } finally {
      setIsChangingPassword(false);
    }
  };

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold text-gray-900">Paramètres utilisateur</h1>
        <p className="text-gray-600 mt-1">Gérez vos informations de compte</p>
      </div>

      {/* Message de mise à jour */}
      {updateMessage && (
        <div className={`p-4 rounded-lg border ${
          updateMessage.includes('succès') 
            ? 'bg-green-50 border-green-200 text-green-700' 
            : 'bg-red-50 border-red-200 text-red-700'
        }`}>
          <div className="flex items-center">
            {updateMessage.includes('succès') ? (
              <Save className="h-5 w-5 mr-2" />
            ) : (
              <AlertCircle className="h-5 w-5 mr-2" />
            )}
            <span>{updateMessage}</span>
          </div>
        </div>
      )}

      {/* Statistiques du compte - EN PREMIER */}
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle className="flex items-center space-x-2">
              <BarChart3 className="h-5 w-5" />
              <span>Statistiques du compte</span>
            </CardTitle>
            <Button 
              onClick={loadStats} 
              variant="outline" 
              size="sm"
              disabled={isLoadingStats}
            >
              <RefreshCw className={`h-4 w-4 ${isLoadingStats ? 'animate-spin' : ''}`} />
              Actualiser
            </Button>
          </div>
        </CardHeader>
        <CardContent>
          {error && (
            <div className="mb-4 p-3 bg-red-50 border border-red-200 rounded-lg">
              <span className="text-sm text-red-600">{error}</span>
            </div>
          )}
          
          <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
            <div className="text-center">
              <div className="flex items-center justify-center mb-2">
                <FileText className="h-6 w-6 text-blue-600" />
              </div>
              <p className="text-2xl font-bold text-gray-900">{stats.total_documents}</p>
              <p className="text-gray-600">Documents envoyés</p>
            </div>
            <div className="text-center">
              <div className="flex items-center justify-center mb-2">
                <Eye className="h-6 w-6 text-green-600" />
              </div>
              <p className="text-2xl font-bold text-gray-900">{stats.total_vues}</p>
              <p className="text-gray-600">Vues totales</p>
            </div>
            <div className="text-center">
              <div className="flex items-center justify-center mb-2">
                <Users className="h-6 w-6 text-purple-600" />
              </div>
              <p className="text-2xl font-bold text-gray-900">{stats.total_destinataires}</p>
              <p className="text-gray-600">Destinataires</p>
            </div>
            <div className="text-center">
              <div className="flex items-center justify-center mb-2">
                <BarChart3 className="h-6 w-6 text-orange-600" />
              </div>
              <p className="text-2xl font-bold text-gray-900">{stats.documents_ce_mois}</p>
              <p className="text-gray-600">Ce mois</p>
            </div>
          </div>
        </CardContent>
      </Card>

      <Separator />

      {/* Informations personnelles et Sécurité - EN DEUXIÈME */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center space-x-2">
              <User className="h-5 w-5" />
              <span>Informations personnelles</span>
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            {profileError && (
              <div className="p-3 bg-red-50 border border-red-200 rounded-lg">
                <span className="text-sm text-red-600">{profileError}</span>
              </div>
            )}
            
            {isLoadingProfile ? (
              <div className="space-y-4">
                {[...Array(3)].map((_, i) => (
                  <div key={i} className="space-y-2">
                    <div className="h-4 bg-gray-200 rounded animate-pulse"></div>
                    <div className="h-10 bg-gray-200 rounded animate-pulse"></div>
                  </div>
                ))}
              </div>
            ) : (
              <>
                <div className="space-y-2">
                  <Label htmlFor="prenom">Prénom</Label>
                  <Input
                    id="prenom"
                    value={userInfo.prenom}
                    onChange={(e) => setUserInfo({ ...userInfo, prenom: e.target.value })}
                    placeholder="Votre prénom"
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="nom">Nom</Label>
                  <Input
                    id="nom"
                    value={userInfo.nom}
                    onChange={(e) => setUserInfo({ ...userInfo, nom: e.target.value })}
                    placeholder="Votre nom"
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="email">Email</Label>
                  <Input
                    id="email"
                    type="email"
                    value={userInfo.email}
                    onChange={(e) => setUserInfo({ ...userInfo, email: e.target.value })}
                    placeholder="votre.email@exemple.com"
                  />
                </div>
                {userProfile && (
                  <div className="text-sm text-gray-500 space-y-1">
                    <p>Membre depuis : {new Date(userProfile.created_at).toLocaleDateString('fr-FR')}</p>
                    <p>Dernière connexion : {userProfile.derniere_connexion ? new Date(userProfile.derniere_connexion).toLocaleString('fr-FR') : 'Jamais'}</p>
                  </div>
                )}
                <Button 
                  onClick={handleSaveProfile} 
                  className="w-full"
                  disabled={isUpdatingProfile}
                >
                  {isUpdatingProfile ? (
                    <>
                      <RefreshCw className="h-4 w-4 mr-2 animate-spin" />
                      Mise à jour...
                    </>
                  ) : (
                    <>
                      <Save className="h-4 w-4 mr-2" />
                      Sauvegarder les modifications
                    </>
                  )}
                </Button>
              </>
            )}
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="flex items-center space-x-2">
              <Settings className="h-5 w-5" />
              <span>Sécurité</span>
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="current-password">Mot de passe actuel</Label>
              <Input
                id="current-password"
                type="password"
                value={password.current}
                onChange={(e) => setPassword({ ...password, current: e.target.value })}
                placeholder="Votre mot de passe actuel"
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="new-password">Nouveau mot de passe</Label>
              <Input
                id="new-password"
                type="password"
                value={password.new}
                onChange={(e) => setPassword({ ...password, new: e.target.value })}
                placeholder="Nouveau mot de passe (min. 6 caractères)"
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="confirm-password">Confirmer le mot de passe</Label>
              <Input
                id="confirm-password"
                type="password"
                value={password.confirm}
                onChange={(e) => setPassword({ ...password, confirm: e.target.value })}
                placeholder="Confirmez le nouveau mot de passe"
              />
            </div>
            <div className="text-sm text-gray-500">
              <p>• Le mot de passe doit contenir au moins 6 caractères</p>
              <p>• Utilisez des caractères variés pour plus de sécurité</p>
            </div>
            <Button 
              onClick={handleChangePassword} 
              className="w-full"
              disabled={isChangingPassword}
            >
              {isChangingPassword ? (
                <>
                  <RefreshCw className="h-4 w-4 mr-2 animate-spin" />
                  Modification...
                </>
              ) : (
                'Changer le mot de passe'
              )}
            </Button>
          </CardContent>
        </Card>
      </div>
    </div>
  );
};

export default UserSettings;

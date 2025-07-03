# Guide d'Administration - iSend Document Flow

## 🚀 Vue d'ensemble

L'interface d'administration d'iSend Document Flow permet aux administrateurs de gérer l'ensemble de la plateforme, incluant les utilisateurs, les abonnements et les statistiques globales.

## 📋 Prérequis

### 1. Créer un utilisateur administrateur

Avant d'utiliser l'interface d'administration, vous devez créer un utilisateur avec les droits administrateur :

```bash
cd backend-php
php create-admin-user.php
```

Cela créera un utilisateur admin avec les identifiants :
- **Email** : `admin@isend.com`
- **Mot de passe** : `admin123`
- **Rôle** : `admin`

### 2. Vérifier la structure de la base de données

Le script vérifiera automatiquement et ajoutera les colonnes nécessaires :
- `role` dans la table `users`
- `type` dans la table `abonnements`

## 🔐 Connexion à l'administration

1. Connectez-vous avec les identifiants administrateur
2. Une icône couronne (👑) apparaîtra dans la sidebar pour indiquer votre statut admin
3. Cliquez sur "Administration" dans le menu

## 📊 Interface d'Administration

### Vue d'ensemble

La page d'accueil affiche :
- **Statistiques globales** : utilisateurs, abonnements, documents, vues
- **Utilisateurs récents** : les 5 derniers utilisateurs inscrits
- **Abonnements actifs** : les 5 abonnements actifs les plus récents

### Gestion des Utilisateurs

#### Liste des utilisateurs
- Affichage de tous les utilisateurs avec leurs informations
- Recherche par nom, prénom ou email
- Filtrage par statut et rôle

#### Actions disponibles
- **Créer un utilisateur** : Ajouter un nouvel utilisateur
- **Modifier le statut** : Activer/désactiver un utilisateur
- **Supprimer** : Désactiver un utilisateur (soft delete)

#### Création d'utilisateur
1. Cliquez sur "Nouvel utilisateur"
2. Remplissez le formulaire :
   - Prénom et nom
   - Email (unique)
   - Mot de passe (minimum 6 caractères)
   - Rôle (utilisateur ou administrateur)
3. Cliquez sur "Créer l'utilisateur"

### Gestion des Abonnements

#### Liste des abonnements
- Affichage de tous les abonnements avec les informations utilisateur
- Filtrage par type et statut
- Informations sur les limites et dates

#### Actions disponibles
- **Créer un abonnement** : Attribuer un abonnement à un utilisateur
- **Modifier le statut** : Activer/désactiver un abonnement
- **Supprimer** : Désactiver un abonnement

#### Types d'abonnements
- **Gratuit** : Limites de base
- **Premium** : Limites étendues
- **Entreprise** : Limites maximales

#### Création d'abonnement
1. Cliquez sur "Nouvel abonnement"
2. Sélectionnez l'utilisateur
3. Choisissez le type d'abonnement
4. Définissez les limites :
   - Nombre de documents
   - Nombre de destinataires
5. Définissez la période (début et fin optionnelle)
6. Cliquez sur "Créer l'abonnement"

### Statistiques Détaillées

#### Périodes disponibles
- **Jour** : Statistiques par heure
- **Semaine** : Statistiques par jour
- **Mois** : Statistiques par jour
- **Année** : Statistiques par mois

#### Métriques affichées
- Nombre de documents envoyés
- Nombre de vues
- Nombre d'utilisateurs actifs

## 🔧 Configuration

### Paramètres de la plateforme
- Configuration des limites par défaut
- Paramètres de sécurité
- Configuration des notifications

## 🛡️ Sécurité

### Vérification des droits
- Seuls les utilisateurs avec le rôle `admin` peuvent accéder à l'interface
- Vérification côté serveur et côté client
- Logs des actions administratives

### Bonnes pratiques
- Changez le mot de passe admin par défaut
- Créez des comptes admin séparés pour chaque administrateur
- Surveillez régulièrement les logs d'activité

## 🧪 Tests

### Vérifier le fonctionnement
```bash
cd backend-php
php test-admin-api.php
```

Ce script teste :
- Création de token admin
- Endpoints utilisateurs
- Endpoints abonnements
- Endpoints statistiques
- Création d'utilisateur

## 📝 API Endpoints

### Utilisateurs
- `GET /admin/users` - Liste des utilisateurs
- `POST /admin/users` - Créer un utilisateur
- `PUT /admin/users/{id}` - Modifier un utilisateur
- `PUT /admin/users/{id}/status` - Basculer le statut
- `DELETE /admin/users/{id}` - Supprimer un utilisateur

### Abonnements
- `GET /admin/subscriptions` - Liste des abonnements
- `POST /admin/subscriptions` - Créer un abonnement
- `PUT /admin/subscriptions/{id}` - Modifier un abonnement
- `PUT /admin/subscriptions/{id}/status` - Basculer le statut
- `DELETE /admin/subscriptions/{id}` - Supprimer un abonnement

### Statistiques
- `GET /admin/stats` - Statistiques globales
- `GET /admin/stats/detailed?period={period}` - Statistiques détaillées

## 🚨 Dépannage

### Problèmes courants

#### Erreur 403 - Accès refusé
- Vérifiez que l'utilisateur a le rôle `admin`
- Vérifiez que le token JWT est valide
- Vérifiez les logs d'erreur

#### Erreur 404 - Endpoint non trouvé
- Vérifiez que les fichiers PHP sont bien placés
- Vérifiez la configuration du serveur web
- Vérifiez les permissions des fichiers

#### Erreur de base de données
- Vérifiez la connexion à la base de données
- Vérifiez que les tables existent
- Vérifiez que les colonnes nécessaires sont présentes

### Logs
Les erreurs sont loggées dans :
- Logs du serveur web (Apache/Nginx)
- Logs PHP (error_log)
- Logs de l'application (si configurés)

## 📞 Support

Pour toute question ou problème :
1. Consultez ce guide
2. Vérifiez les logs d'erreur
3. Testez avec le script de test
4. Contactez l'équipe de développement

---

**Version** : 1.0  
**Dernière mise à jour** : Décembre 2024  
**Auteur** : Équipe iSend Document Flow 
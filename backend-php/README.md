# Backend PHP - iSend Document Flow

Backend API RESTful pour l'application de partage sécurisé de documents PDF.

## 🏗️ Architecture

- **PHP 8.4** procédural avec PDO
- **MySQL** avec MAMP (port 8889)
- **JWT** pour l'authentification
- **PHPMailer** pour l'envoi d'emails
- **Structure modulaire** avec séparation des responsabilités

## 📁 Structure des fichiers

```
backend-php/
├── api/                    # Endpoints API
│   ├── auth.php           # Authentification JWT
│   ├── documents.php      # Gestion des documents PDF
│   ├── destinataires.php  # CRUD destinataires
│   ├── send.php           # Envoi de documents
│   ├── access.php         # Accès aux documents
│   ├── stats.php          # Statistiques
│   └── test.php           # Test de base
├── includes/              # Classes et utilitaires
│   ├── db.php            # Classe Database PDO
│   └── jwt.php           # Gestion JWT
├── uploads/               # Stockage des PDF
├── vendor/                # Dépendances Composer
├── composer.json          # Configuration
├── database.sql           # Structure BDD
└── test-endpoints.php     # Script de test complet
```

## 🚀 Installation

### 1. Prérequis

- **MAMP** avec PHP 8.4
- **Composer** installé
- **MySQL** accessible sur le port 8889

### 2. Configuration

```bash
# Installer les dépendances
composer install

# Créer le dossier uploads
mkdir uploads
chmod 755 uploads

# Importer la base de données
mysql -u root -p < database.sql
```

### 3. Configuration de la base de données

Modifier `includes/db.php` si nécessaire :

```php
// Configuration MAMP par défaut
$host = 'localhost';
$port = '8889';
$dbname = 'isend_document_flow';
$username = 'root';
$password = 'root';
```

## 🧪 Tests

### Test rapide

```bash
# Test de base
curl http://localhost:8888/isend-document-flow/backend-php/api/test.php

# Test de connexion BDD
php api/db-test.php

# Test JWT
php api/jwt-test.php
```

### Test complet des APIs

```bash
# Lancer le script de test complet
php test-endpoints.php
```

### Tests manuels par API

#### 1. Authentification

```bash
# Inscription
curl -X POST http://localhost:8888/isend-document-flow/backend-php/api/auth.php \
  -H "Content-Type: application/json" \
  -d '{
    "action": "register",
    "email": "test@example.com",
    "password": "123456",
    "nom": "Test",
    "prenom": "User"
  }'

# Connexion
curl -X POST http://localhost:8888/isend-document-flow/backend-php/api/auth.php \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "123456"
  }'
```

#### 2. Récupération du token

```bash
# Récupérer le token JWT
TOKEN=$(curl -s -X POST http://localhost:8888/isend-document-flow/backend-php/api/auth.php \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"123456"}' \
  | grep -o '"token":"[^"]*"' | cut -d'"' -f4)

echo "Token: $TOKEN"
```

#### 3. APIs protégées

```bash
# Destinataires
curl "http://localhost:8888/isend-document-flow/backend-php/api/destinataires-crud.php?token=$TOKEN"

# Statistiques
curl "http://localhost:8888/isend-document-flow/backend-php/api/stats-test.php?token=$TOKEN"

# Documents
curl "http://localhost:8888/isend-document-flow/backend-php/api/documents.php?token=$TOKEN"
```

## 📚 Documentation des APIs

### 🔐 Authentification (`/api/auth.php`)

**POST** - Inscription et connexion

```json
// Inscription
{
  "action": "register",
  "email": "user@example.com",
  "password": "password123",
  "nom": "Nom",
  "prenom": "Prénom"
}

// Connexion
{
  "email": "user@example.com",
  "password": "password123"
}
```

**Réponse :**
```json
{
  "success": true,
  "token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
  "user": {
    "id": 1,
    "email": "user@example.com",
    "nom": "Nom",
    "prenom": "Prénom"
  }
}
```

### 📄 Documents (`/api/documents.php`)

**GET** - Liste des documents
**POST** - Upload de document
**PUT** - Modification
**DELETE** - Suppression

### 👥 Destinataires (`/api/destinataires.php`)

**GET** - Liste des destinataires
**POST** - Création
**PUT** - Modification
**DELETE** - Suppression

### 📧 Envoi (`/api/send.php`)

**POST** - Envoi de document par email

```json
{
  "document_id": 1,
  "destinataires": [1, 2, 3],
  "message": "Voici votre document",
  "expiration": "2024-12-31"
}
```

### 🔓 Accès (`/api/access.php`)

**GET** - Accès au document via token d'accès

### 📊 Statistiques (`/api/stats.php`)

**GET** - Statistiques d'utilisation

## 🔒 Sécurité

### JWT (JSON Web Tokens)

- **Secret** : Configuré dans `includes/jwt.php`
- **Expiration** : 24 heures par défaut
- **Algorithme** : HS256

### Validation des données

- **Sanitisation** des entrées utilisateur
- **Validation** des types et formats
- **Protection** contre les injections SQL

### Gestion des erreurs

- **Codes HTTP** appropriés
- **Messages d'erreur** informatifs
- **Logs** pour audit

## 🐛 Dépannage

### Erreur 500

1. Vérifier les logs Apache dans MAMP
2. Désactiver le fichier `.htaccess` si nécessaire
3. Vérifier les permissions des dossiers

### Erreur de connexion BDD

1. Vérifier que MySQL est démarré dans MAMP
2. Vérifier le port (8889 pour MAMP)
3. Tester avec `php api/db-test.php`

### Problème d'authentification

1. Vérifier que la table `utilisateurs` existe
2. Tester avec `php api/auth-test.php`
3. Vérifier la configuration JWT

### Header Authorization non reçu

**Problème connu avec MAMP :** Le header `Authorization` n'est pas toujours reçu par PHP via cURL.

**Solution temporaire :** Utiliser le paramètre `?token=` dans l'URL pour les tests.

```bash
# Au lieu de :
curl -H "Authorization: Bearer $TOKEN" http://localhost/api/endpoint

# Utiliser :
curl "http://localhost/api/endpoint?token=$TOKEN"
```

## 📝 Logs et monitoring

### Logs d'erreur

- **Apache** : `/Applications/MAMP/logs/apache_error.log`
- **PHP** : `/Applications/MAMP/logs/php_error.log`
- **MySQL** : `/Applications/MAMP/logs/mysql_error.log`

### Monitoring

- Vérifier les performances avec `php api/stats-test.php`
- Surveiller l'espace disque dans `uploads/`
- Contrôler les accès via les logs

## 🚀 Déploiement

### Production

1. **Configurer HTTPS**
2. **Sécuriser la base de données**
3. **Configurer les variables d'environnement**
4. **Optimiser PHP** (OPcache, etc.)
5. **Configurer l'envoi d'emails**

### Variables de production

```env
DB_HOST=production_host
DB_PORT=3306
DB_NAME=isend_production
DB_USER=isend_user
DB_PASS=secure_password
JWT_SECRET=very_long_random_secret_key
SMTP_HOST=smtp.provider.com
SMTP_PORT=587
SMTP_USER=your_email@domain.com
SMTP_PASS=your_password
```

## 🤝 Contribution

1. Suivre les conventions de code PHP
2. Tester les nouvelles fonctionnalités
3. Documenter les APIs
4. Mettre à jour ce README

---

**Backend développé avec PHP 8.4 et MAMP** 
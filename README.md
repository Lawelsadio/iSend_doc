# iSend Document Flow

Application complète de partage sécurisé de documents PDF avec authentification JWT et interface moderne.

## 🏗️ Architecture

- **Backend** : PHP procédural avec PDO MySQL
- **Frontend** : React + TypeScript + Tailwind CSS
- **Base de données** : MySQL avec MAMP
- **Authentification** : JWT (Firebase/php-jwt)
- **Envoi d'emails** : PHPMailer

## 📁 Structure du projet

```
isend-document-flow/
├── backend-php/           # Backend PHP
│   ├── api/              # Endpoints API
│   ├── includes/         # Classes et fonctions utilitaires
│   ├── uploads/          # Stockage des documents PDF
│   ├── vendor/           # Dépendances Composer
│   └── composer.json     # Configuration Composer
├── front-end/            # Frontend React
│   ├── src/              # Code source React
│   ├── components/       # Composants UI
│   └── package.json      # Dépendances npm
└── README.md            # Ce fichier
```

## 🚀 Installation et configuration

### Prérequis

- **MAMP** (Apache + MySQL + PHP 8.4)
- **Node.js** (pour le frontend)
- **Composer** (pour le backend PHP)

### 1. Configuration de la base de données

```bash
# Importer la base de données
mysql -u root -p < backend-php/database.sql
```

**Configuration MAMP :**
- Host : `localhost`
- Port : `8889`
- Utilisateur : `root`
- Mot de passe : `root`
- Base : `isend_document_flow`

### 2. Installation du backend PHP

```bash
cd backend-php

# Installer les dépendances Composer
composer install

# Créer le dossier uploads
mkdir uploads
chmod 755 uploads
```

### 3. Installation du frontend React

```bash
cd front-end

# Installer les dépendances
npm install

# Démarrer le serveur de développement
npm run dev
```

## 🔧 Configuration

### Backend PHP

Les fichiers de configuration se trouvent dans `backend-php/includes/` :

- **`db.php`** : Connexion à la base de données MySQL
- **`jwt.php`** : Gestion des tokens JWT

### Variables d'environnement

Créer un fichier `.env` dans `backend-php/` :

```env
DB_HOST=localhost
DB_PORT=8889
DB_NAME=isend_document_flow
DB_USER=root
DB_PASS=root
JWT_SECRET=isend_secret_key_2024_very_secure
```

## 🧪 Tests des APIs

### 1. Test rapide avec curl

```bash
# Test de base
curl http://localhost:8888/isend-document-flow/backend-php/api/test.php

# Authentification
curl -X POST http://localhost:8888/isend-document-flow/backend-php/api/auth.php \
  -H "Content-Type: application/json" \
  -d '{"email":"nouveau@test.com","password":"123456"}'

# Récupérer un token
TOKEN=$(curl -s -X POST http://localhost:8888/isend-document-flow/backend-php/api/auth.php \
  -H "Content-Type: application/json" \
  -d '{"email":"nouveau@test.com","password":"123456"}' \
  | grep -o '"token":"[^"]*"' | cut -d'"' -f4)

# Tester les APIs protégées
curl "http://localhost:8888/isend-document-flow/backend-php/api/destinataires-crud.php?token=$TOKEN"
curl "http://localhost:8888/isend-document-flow/backend-php/api/stats-test.php?token=$TOKEN"
```

### 2. Script de test complet

```bash
cd backend-php
php test-endpoints.php
```

### 3. Tests manuels des APIs

#### Authentification
```bash
# Inscription
curl -X POST http://localhost:8888/isend-document-flow/backend-php/api/auth.php \
  -H "Content-Type: application/json" \
  -d '{"action":"register","email":"test@example.com","password":"123456","nom":"Test","prenom":"User"}'

# Connexion
curl -X POST http://localhost:8888/isend-document-flow/backend-php/api/auth.php \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"123456"}'
```

#### Gestion des destinataires
```bash
# Récupérer la liste
curl "http://localhost:8888/isend-document-flow/backend-php/api/destinataires-crud.php?token=$TOKEN"

# Créer un destinataire
curl -X POST "http://localhost:8888/isend-document-flow/backend-php/api/destinataires-crud.php?token=$TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"nom":"Dupont","prenom":"Jean","email":"jean.dupont@example.com","numero":"+33123456789"}'
```

#### Statistiques
```bash
curl "http://localhost:8888/isend-document-flow/backend-php/api/stats-test.php?token=$TOKEN"
```

## 📚 APIs disponibles

### 🔐 Authentification (`/api/auth.php`)
- `POST` - Inscription et connexion utilisateur
- Génération de tokens JWT

### 📄 Documents (`/api/documents.php`)
- `GET` - Récupération des documents
- `POST` - Upload de document PDF
- `PUT` - Modification de document
- `DELETE` - Suppression de document

### 👥 Destinataires (`/api/destinataires.php`)
- `GET` - Liste des destinataires
- `POST` - Création de destinataire
- `PUT` - Modification de destinataire
- `DELETE` - Suppression de destinataire

### 📧 Envoi (`/api/send.php`)
- `POST` - Envoi de document par email
- Génération de liens sécurisés

### 🔓 Accès (`/api/access.php`)
- `GET` - Accès au document via token
- `POST` - Vérification d'accès

### 📊 Statistiques (`/api/stats.php`)
- `GET` - Statistiques d'utilisation
- Par document, destinataire ou générales

## 🔒 Sécurité

- **Authentification JWT** avec expiration
- **Validation des données** côté serveur
- **Protection CSRF** via tokens
- **Gestion des permissions** par utilisateur
- **Logs d'accès** pour audit

## 🚀 Déploiement

### Production

1. **Configurer le serveur web** (Apache/Nginx)
2. **Sécuriser la base de données**
3. **Configurer les variables d'environnement**
4. **Activer HTTPS**
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

1. Fork le projet
2. Créer une branche feature (`git checkout -b feature/AmazingFeature`)
3. Commit les changements (`git commit -m 'Add some AmazingFeature'`)
4. Push vers la branche (`git push origin feature/AmazingFeature`)
5. Ouvrir une Pull Request

## 📝 Licence

Ce projet est sous licence MIT. Voir le fichier `LICENSE` pour plus de détails.

## 👨‍💻 Développé avec

- **Backend** : PHP 8.4, PDO, Firebase JWT, PHPMailer
- **Frontend** : React 18, TypeScript, Tailwind CSS, Vite
- **Base de données** : MySQL 8.0
- **Serveur** : MAMP (développement)

## 📞 Support

Pour toute question ou problème :
- Ouvrir une issue sur GitHub
- Consulter la documentation des APIs
- Vérifier les logs d'erreur dans MAMP

---

**Développé avec ❤️ pour iSend Document Flow** 
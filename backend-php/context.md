# Contexte – Backend PHP de l'application iSend

L'application iSend permet à un éditeur d’envoyer des documents PDF à des destinataires via email, de manière sécurisée.

## Objectif :
Créer un backend PHP RESTful (PHP procédural, PDO, MySQL) qui communique avec un front-end React.js existant (ShadCN UI), et une app mobile.

## Fonctionnalités à développer :

### Authentification (éditeur)
- Connexion via email + mot de passe
- Génération de token JWT
- Middleware pour protéger les routes API

### Documents
- Upload de fichiers PDF (dans /uploads)
- Stockage des infos : titre, description, date
- Attribution du document à un éditeur

### Destinataires
- Ajout / suppression d’emails
- Statut d’abonnement : actif / expiré
- Vérification d’abonnement au moment de l’accès

### Envoi
- Génération d’un lien sécurisé unique par email (UUID)
- Lien réutilisable uniquement par le bon email

### Accès au document (destinataire)
- Route publique /access.php
- Vérifie :
  - le token
  - l’email fourni
  - l’abonnement
- Retourne le PDF si tout est valide

### Statistiques
- Journalisation de chaque accès :
  - IP
  - Timestamp
  - Email
  - Résultat (autorisé / refusé)

## Base de données
MySQL avec les tables suivantes :
- users (éditeurs)
- documents
- destinataires
- liens (UUID, email, id_document)
- logs_acces

## Contraintes :
- PHP procédural (pas de framework lourd)
- Utilisation de PDO
- JWT pour auth
- Respect des CORS (API consommée par React)
# 📧 Guide d'Envoi d'Emails en Local - iSend Document Flow

## 🎯 **Objectif**
Ce guide vous explique comment configurer l'envoi d'emails réels depuis votre environnement de développement local en utilisant Gmail SMTP.

## ✅ **Configuration actuelle**

Votre application est maintenant configurée pour envoyer de vrais emails via Gmail :

### **Informations SMTP configurées :**
- **Serveur SMTP :** `smtp.gmail.com`
- **Port :** `587`
- **Chiffrement :** `TLS`
- **Email :** `mellowrime@gmail.com`
- **Mot de passe d'application :** `95580058aA$`

## 🧪 **Test de la configuration**

### **Étape 1 : Tester l'envoi d'emails**

1. **Ouvrez votre navigateur**
2. **Accédez à :** `http://localhost:8888/isend-document-flow/backend-php/test-email-gmail.php`
3. **Vérifiez que la configuration s'affiche correctement**
4. **Cliquez sur "Tentative d'envoi d'email"**
5. **Vérifiez votre boîte Gmail** (et les spams)

### **Étape 2 : Vérifier les résultats**

**✅ Si le test réussit :**
- Vous verrez un message vert "Email envoyé avec succès !"
- Vous recevrez un email de test dans votre boîte Gmail
- Votre application peut maintenant envoyer de vrais emails

**❌ Si le test échoue :**
- Vérifiez que l'authentification à 2 facteurs est activée sur Gmail
- Vérifiez que le mot de passe d'application est correct
- Vérifiez votre connexion internet

## 🚀 **Utilisation dans l'application**

### **Envoi de PDF normaux :**
- Utilisez l'interface web pour uploader un PDF
- Ajoutez des destinataires
- Les emails seront envoyés avec des liens d'accès

### **Envoi de PDF sécurisés :**
- Sélectionnez "PDF sécurisé" lors de l'envoi
- Les emails contiendront le PDF en pièce jointe avec mot de passe

## 🔧 **Dépannage**

### **Erreur d'authentification :**
```
SMTP Error: Could not authenticate
```
**Solution :**
1. Vérifiez que l'authentification à 2 facteurs est activée
2. Générez un nouveau mot de passe d'application
3. Mettez à jour la configuration dans `backend-php/includes/settings.php`

### **Erreur de connexion :**
```
SMTP Error: Could not connect to SMTP host
```
**Solution :**
1. Vérifiez votre connexion internet
2. Vérifiez que le port 587 n'est pas bloqué par votre pare-feu
3. Essayez avec le port 465 (SSL) si nécessaire

### **Email non reçu :**
**Solutions :**
1. Vérifiez votre dossier spam
2. Vérifiez que l'adresse email est correcte
3. Attendez quelques minutes (Gmail peut avoir des délais)

## 📋 **Fichiers modifiés**

### **Fichiers corrigés :**
- ✅ `backend-php/api/send-normal-pdf.php` - Logique de simulation corrigée
- ✅ `backend-php/api/send-secure-pdf.php` - Logique de simulation corrigée
- ✅ `backend-php/includes/settings.php` - Configuration Gmail ajoutée

### **Fichiers créés :**
- ✅ `backend-php/test-email-gmail.php` - Script de test

## 🔒 **Sécurité**

### **Mot de passe d'application :**
- Le mot de passe `95580058aA$` est un mot de passe d'application Gmail
- Il est différent de votre mot de passe Gmail principal
- Il est sécurisé pour l'utilisation par des applications

### **Authentification à 2 facteurs :**
- Obligatoire pour utiliser les mots de passe d'application
- Améliore la sécurité de votre compte Gmail
- Permet l'utilisation de mots de passe d'application

## 📞 **Support**

Si vous rencontrez des problèmes :

1. **Vérifiez les logs PHP** dans `/Applications/MAMP/logs/php_error.log`
2. **Testez avec le script** `test-email-gmail.php`
3. **Vérifiez la configuration Gmail** dans les paramètres de sécurité

## 🎉 **Félicitations !**

Votre application iSend Document Flow peut maintenant envoyer de vrais emails depuis votre environnement de développement local !

---

*Guide généré le 2024-01-XX*

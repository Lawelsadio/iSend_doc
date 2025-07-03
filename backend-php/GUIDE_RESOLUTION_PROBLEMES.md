# 🔧 Guide de Résolution des Problèmes - iSend Document Flow

## 📋 Problèmes de Métadonnées et d'Accès aux Documents

### 🚨 Problème Principal : Incohérence des Métadonnées

**Symptômes :**
- Les métadonnées ajoutées lors de l'import ne correspondent pas à celles affichées
- L'expéditeur perd l'accès à ses documents après envoi
- Erreurs de mapping des champs entre frontend et backend

**Causes identifiées :**

#### 1. **Incohérence des noms de champs**
```php
// ❌ AVANT (Backend)
SELECT id, nom, description, fichier_path, fichier_original...

// ✅ APRÈS (Backend corrigé)
SELECT id, nom as titre, description, fichier_path as chemin_fichier, 
       fichier_original as nom_fichier...
```

#### 2. **Mapping incorrect frontend ↔ backend**
```typescript
// ❌ AVANT (Frontend)
interface Document {
  nom_fichier: string;  // Incohérent avec backend
  titre: string;        // Incohérent avec backend
}

// ✅ APRÈS (Frontend corrigé)
interface Document {
  nom_fichier: string;  // Mappé depuis fichier_original
  titre: string;        // Mappé depuis nom
  chemin_fichier: string; // Mappé depuis fichier_path
}
```

#### 3. **Gestion des métadonnées après upload**
```typescript
// ✅ Solution implémentée
// 1. Upload avec métadonnées temporaires
const metadata: DocumentMetadata = {
  titre: selectedFile.name.replace('.pdf', ''),
  description: '',
  tags: []
};

// 2. Mise à jour des métadonnées dans AddMetadata
const response = await documentService.updateDocument(documentId, metadata);
```

### 🛠️ Solutions Appliquées

#### 1. **Correction de l'API documents.php**
- ✅ Mapping cohérent des champs dans les requêtes SELECT
- ✅ Gestion des noms de champs alternatifs (titre/nom, statut/status)
- ✅ Retour des données avec les noms de champs frontend

#### 2. **Correction de l'API access.php**
- ✅ Ajout des endpoints metadata et security
- ✅ Mapping cohérent des métadonnées pour les destinataires
- ✅ Vérification des permissions d'accès

#### 3. **Correction du service frontend**
- ✅ Interface Document cohérente
- ✅ Méthodes de mise à jour des métadonnées
- ✅ Gestion des erreurs de mapping

### 🔍 Vérification des Corrections

#### Test de cohérence des métadonnées :
```bash
cd backend-php
/Applications/MAMP/bin/php/php8.2.26/bin/php test-metadata.php
```

**Résultats attendus :**
```
✅ Structure de la table correcte
📄 Nombre de documents actifs: X
🔗 Nombre de liens actifs: Y
✅ Mapping des champs correct
```

### 🚀 Prévention des Problèmes

#### 1. **Standards de nommage**
- **Backend (base de données)** : `nom`, `fichier_path`, `fichier_original`
- **Frontend (interface)** : `titre`, `chemin_fichier`, `nom_fichier`
- **Mapping** : Utiliser des alias dans les requêtes SQL

#### 2. **Gestion des métadonnées**
```typescript
// ✅ Bonne pratique
const metadata: DocumentMetadata = {
  titre: title.trim(),
  description: description.trim(),
  tags: tags.filter(tag => tag.trim())
};

// ✅ Mise à jour après upload
await documentService.updateDocument(documentId, metadata);
```

#### 3. **Vérification des permissions**
```php
// ✅ Vérification que le document appartient à l'utilisateur
$stmt = $db->prepare("
    SELECT id FROM documents 
    WHERE id = ? AND user_id = ? AND status != 'supprime'
");
```

### 🔧 Outils de Diagnostic

#### 1. **Test de connectivité**
```bash
curl -X GET "http://localhost:8888/isend-document-flow/backend-php/api/ping.php"
```

#### 2. **Test d'authentification**
```bash
curl -X POST "http://localhost:8888/isend-document-flow/backend-php/api/auth.php" \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"password123"}'
```

#### 3. **Test des métadonnées**
```bash
curl -X GET "http://localhost:8888/isend-document-flow/backend-php/api/documents.php" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 📞 Support

En cas de problème persistant :

1. **Vérifier les logs PHP** : `/Applications/MAMP/logs/php_error.log`
2. **Vérifier les logs MySQL** : `/Applications/MAMP/logs/mysql_error.log`
3. **Tester la connectivité** : `test-metadata.php`
4. **Vérifier les permissions** : Chmod 755 sur les dossiers uploads/

### 🔄 Workflow de Correction

1. **Identifier le problème** : Métadonnées ou accès ?
2. **Vérifier la cohérence** : Frontend ↔ Backend
3. **Tester les corrections** : Scripts de test
4. **Valider le fonctionnement** : Tests complets
5. **Documenter** : Mise à jour de ce guide

---

**Dernière mise à jour** : $(date)
**Version** : 1.0
**Statut** : ✅ Résolu 
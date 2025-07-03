<?php
/**
 * Script pour créer un utilisateur administrateur
 * Usage: php create-admin-user.php
 */

require_once 'includes/db.php';

try {
    $db = getDB();
    
    // Données de l'administrateur
    $adminData = [
        'nom' => 'Administrateur',
        'prenom' => 'iSend',
        'email' => 'admin@isend.com',
        'password' => 'admin123',
        'role' => 'admin'
    ];
    
    // Vérifier si l'utilisateur existe déjà
    $stmt = $db->prepare("SELECT id FROM users WHERE email = ?");
    $stmt->execute([$adminData['email']]);
    $existingUser = $stmt->fetch();
    
    if ($existingUser) {
        echo "✅ L'utilisateur admin existe déjà (ID: {$existingUser['id']})\n";
        
        // Mettre à jour le rôle si nécessaire
        $stmt = $db->prepare("UPDATE users SET role = ? WHERE id = ?");
        $stmt->execute([$adminData['role'], $existingUser['id']]);
        echo "✅ Rôle administrateur mis à jour\n";
    } else {
        // Créer le nouvel utilisateur admin
        $hashedPassword = password_hash($adminData['password'], PASSWORD_DEFAULT);
        
        $stmt = $db->prepare("
            INSERT INTO users (nom, prenom, email, password, role, status, date_creation)
            VALUES (?, ?, ?, ?, ?, 'actif', NOW())
        ");
        $stmt->execute([
            $adminData['nom'],
            $adminData['prenom'],
            $adminData['email'],
            $hashedPassword,
            $adminData['role']
        ]);
        
        $adminId = $db->lastInsertId();
        echo "✅ Utilisateur administrateur créé avec succès (ID: $adminId)\n";
        
        // Créer un abonnement premium pour l'admin
        $stmt = $db->prepare("
            INSERT INTO abonnements (user_id, type, status, limite_documents, limite_destinataires, date_debut, date_creation)
            VALUES (?, 'entreprise', 'actif', 10000, 5000, NOW(), NOW())
        ");
        $stmt->execute([$adminId]);
        
        echo "✅ Abonnement entreprise créé pour l'administrateur\n";
    }
    
    // Afficher les informations de connexion
    echo "\n📋 Informations de connexion:\n";
    echo "Email: {$adminData['email']}\n";
    echo "Mot de passe: {$adminData['password']}\n";
    echo "Rôle: {$adminData['role']}\n";
    
    // Vérifier la structure de la base de données
    echo "\n🔍 Vérification de la structure:\n";
    
    // Vérifier la table users
    $stmt = $db->prepare("DESCRIBE users");
    $stmt->execute();
    $columns = $stmt->fetchAll();
    $hasRole = false;
    foreach ($columns as $column) {
        if ($column['Field'] === 'role') {
            $hasRole = true;
            break;
        }
    }
    
    if (!$hasRole) {
        echo "❌ La colonne 'role' n'existe pas dans la table users\n";
        echo "Ajout de la colonne 'role'...\n";
        
        $stmt = $db->prepare("ALTER TABLE users ADD COLUMN role ENUM('user', 'admin') DEFAULT 'user'");
        $stmt->execute();
        
        echo "✅ Colonne 'role' ajoutée à la table users\n";
    } else {
        echo "✅ La colonne 'role' existe dans la table users\n";
    }
    
    // Vérifier la table abonnements
    $stmt = $db->prepare("DESCRIBE abonnements");
    $stmt->execute();
    $columns = $stmt->fetchAll();
    $hasType = false;
    foreach ($columns as $column) {
        if ($column['Field'] === 'type') {
            $hasType = true;
            break;
        }
    }
    
    if (!$hasType) {
        echo "❌ La colonne 'type' n'existe pas dans la table abonnements\n";
        echo "Ajout de la colonne 'type'...\n";
        
        $stmt = $db->prepare("ALTER TABLE abonnements ADD COLUMN type ENUM('gratuit', 'premium', 'entreprise') DEFAULT 'gratuit'");
        $stmt->execute();
        
        echo "✅ Colonne 'type' ajoutée à la table abonnements\n";
    } else {
        echo "✅ La colonne 'type' existe dans la table abonnements\n";
    }
    
    echo "\n🎉 Configuration terminée avec succès!\n";
    echo "Vous pouvez maintenant vous connecter avec les identifiants admin.\n";
    
} catch (Exception $e) {
    echo "❌ Erreur: " . $e->getMessage() . "\n";
    echo "Trace: " . $e->getTraceAsString() . "\n";
}
?> 
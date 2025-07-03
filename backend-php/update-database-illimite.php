<?php
/**
 * Script pour ajouter le type d'abonnement 'illimite' à la base de données
 */

require_once 'includes/db.php';

try {
    $db = getDB();
    
    echo "Modification de la table abonnements...\n";
    
    // Modifier l'enum pour inclure 'illimite'
    $sql = "ALTER TABLE abonnements MODIFY COLUMN type enum('gratuit','basique','premium','entreprise','illimite') DEFAULT 'gratuit'";
    $db->exec($sql);
    
    echo "✅ Type 'illimite' ajouté à l'enum\n";
    
    // Créer un abonnement illimité de test pour l'admin
    $sql = "INSERT INTO abonnements (user_id, type, status, limite_documents, limite_destinataires, date_debut) 
            VALUES (1, 'illimite', 'actif', -1, -1, NOW())
            ON DUPLICATE KEY UPDATE 
            type = 'illimite',
            limite_documents = -1,
            limite_destinataires = -1,
            status = 'actif'";
    $db->exec($sql);
    
    echo "✅ Abonnement illimité créé pour l'admin\n";
    
    // Afficher les types d'abonnement disponibles
    $stmt = $db->query("SELECT DISTINCT type FROM abonnements");
    $types = $stmt->fetchAll(PDO::FETCH_COLUMN);
    
    echo "Types d'abonnement disponibles : " . implode(', ', $types) . "\n";
    
    echo "✅ Modification terminée avec succès !\n";
    
} catch (Exception $e) {
    echo "❌ Erreur : " . $e->getMessage() . "\n";
}
?> 
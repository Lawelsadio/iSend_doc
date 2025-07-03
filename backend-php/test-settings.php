<?php
/**
 * Test de la classe SystemSettings
 */

echo "=== TEST SYSTEMSETTINGS ===\n\n";

// Inclure les fichiers nécessaires
require_once 'includes/db.php';
require_once 'includes/settings.php';

echo "1. Vérification de l'inclusion des fichiers:\n";
echo "   - db.php: " . (file_exists('includes/db.php') ? 'OK' : 'ERREUR') . "\n";
echo "   - settings.php: " . (file_exists('includes/settings.php') ? 'OK' : 'ERREUR') . "\n\n";

echo "2. Vérification de la classe SystemSettings:\n";
echo "   - Classe existe: " . (class_exists('SystemSettings') ? 'OUI' : 'NON') . "\n\n";

if (class_exists('SystemSettings')) {
    try {
        $settings = SystemSettings::getInstance();
        echo "3. Instance créée avec succès\n";
        
        $smtpConfig = $settings->getSMTPConfig();
        echo "4. Configuration SMTP récupérée:\n";
        echo "   - Host: " . $smtpConfig['host'] . "\n";
        echo "   - Username: " . $smtpConfig['username'] . "\n";
        echo "   - Password: " . substr($smtpConfig['password'], 0, 4) . "...\n";
        
    } catch (Exception $e) {
        echo "ERREUR: " . $e->getMessage() . "\n";
    }
} else {
    echo "ERREUR: Classe SystemSettings non trouvée\n";
}

echo "\n=== FIN DU TEST ===\n";
?> 
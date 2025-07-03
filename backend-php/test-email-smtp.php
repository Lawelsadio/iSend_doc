<?php
/**
 * Test de la configuration SMTP
 */

require_once 'includes/settings.php';
require_once 'vendor/autoload.php';

use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\SMTP;
use PHPMailer\PHPMailer\Exception as PHPMailerException;

echo "=== TEST CONFIGURATION SMTP ===\n\n";

// Récupérer la configuration SMTP
$settings = SystemSettings::getInstance();
$smtpConfig = $settings->getSMTPConfig();

echo "1. Configuration SMTP:\n";
echo "   - Host: " . $smtpConfig['host'] . "\n";
echo "   - Port: " . $smtpConfig['port'] . "\n";
echo "   - Username: " . $smtpConfig['username'] . "\n";
echo "   - Password: " . substr($smtpConfig['password'], 0, 4) . "..." . "\n";
echo "   - From Email: " . $smtpConfig['from_email'] . "\n";
echo "   - From Name: " . $smtpConfig['from_name'] . "\n\n";

// Test de connexion SMTP
echo "2. Test de connexion SMTP:\n";

try {
    $mail = new PHPMailer(true);
    
    // Configuration SMTP
    $mail->isSMTP();
    $mail->Host = $smtpConfig['host'];
    $mail->SMTPAuth = true;
    $mail->Username = $smtpConfig['username'];
    $mail->Password = $smtpConfig['password'];
    $mail->SMTPSecure = PHPMailer::ENCRYPTION_STARTTLS;
    $mail->Port = $smtpConfig['port'];
    
    // Configuration de l'expéditeur
    $mail->setFrom($smtpConfig['from_email'], $smtpConfig['from_name']);
    $mail->addAddress('test@example.com'); // Email de test
    
    // Configuration du contenu
    $mail->isHTML(true);
    $mail->Subject = 'Test SMTP - iSend Document Flow';
    $mail->Body = '<h2>Test de configuration SMTP</h2><p>Si vous recevez cet email, la configuration SMTP fonctionne correctement.</p>';
    $mail->AltBody = 'Test de configuration SMTP - Si vous recevez cet email, la configuration SMTP fonctionne correctement.';
    
    echo "   - Tentative d'envoi...\n";
    $mail->send();
    echo "   - SUCCÈS: Email envoyé avec succès!\n";
    
} catch (PHPMailerException $e) {
    echo "   - ERREUR: " . $e->getMessage() . "\n";
    echo "   - Code: " . $e->getCode() . "\n";
}

echo "\n=== FIN DU TEST ===\n";
?> 
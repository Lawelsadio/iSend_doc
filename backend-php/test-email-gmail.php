<?php
/**
 * Script de test pour l'envoi d'emails Gmail
 * Teste la configuration SMTP et l'envoi d'un email de test
 */

require_once 'includes/db.php';
require_once 'includes/settings.php';
require_once 'vendor/autoload.php';

use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\SMTP;
use PHPMailer\PHPMailer\Exception as PHPMailerException;

echo "<h1>🧪 Test d'envoi d'emails Gmail - iSend Document Flow</h1>";

try {
    // Récupérer la configuration SMTP
    $settings = SystemSettings::getInstance();
    $smtpConfig = $settings->getSMTPConfig();
    
    echo "<h2>📧 Configuration SMTP actuelle :</h2>";
    echo "<pre>";
    print_r($smtpConfig);
    echo "</pre>";
    
    // Vérifier si la configuration est complète
    if (empty($smtpConfig['host']) || empty($smtpConfig['username']) || empty($smtpConfig['password'])) {
        echo "<div style='color: red; background: #ffe6e6; padding: 10px; border-radius: 5px;'>";
        echo "<strong>❌ Configuration SMTP incomplète !</strong><br>";
        echo "Host: " . ($smtpConfig['host'] ?: 'MANQUANT') . "<br>";
        echo "Username: " . ($smtpConfig['username'] ?: 'MANQUANT') . "<br>";
        echo "Password: " . ($smtpConfig['password'] ? 'CONFIGURÉ' : 'MANQUANT') . "<br>";
        echo "</div>";
        exit;
    }
    
    echo "<div style='color: green; background: #e6ffe6; padding: 10px; border-radius: 5px;'>";
    echo "<strong>✅ Configuration SMTP complète !</strong>";
    echo "</div>";
    
    // Créer l'instance PHPMailer
    $mail = new PHPMailer(true);
    
    // Configuration SMTP
    $mail->isSMTP();
    $mail->Host = $smtpConfig['host'];
    $mail->SMTPAuth = true;
    $mail->Username = $smtpConfig['username'];
    $mail->Password = $smtpConfig['password'];
    $mail->SMTPSecure = PHPMailer::ENCRYPTION_STARTTLS;
    $mail->Port = $smtpConfig['port'];
    
    // Configuration de l'email
    $mail->setFrom($smtpConfig['from_email'], $smtpConfig['from_name']);
    $mail->addAddress('mellowrime@gmail.com', 'Test User');
    
    $mail->isHTML(true);
    $mail->Subject = '🧪 Test Email Gmail - iSend Document Flow';
    
    $mail->Body = "
    <html>
    <head>
        <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background: #007bff; color: white; padding: 20px; text-align: center; }
            .content { padding: 20px; background: #f8f9fa; }
            .success { background: #d4edda; border: 1px solid #c3e6cb; padding: 15px; border-radius: 5px; margin: 20px 0; }
            .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; }
        </style>
    </head>
    <body>
        <div class='container'>
            <div class='header'>
                <h1>🧪 Test Email Gmail</h1>
            </div>
            <div class='content'>
                <h2>Bonjour !</h2>
                <p>Ceci est un email de test pour vérifier que la configuration Gmail SMTP fonctionne correctement.</p>
                
                <div class='success'>
                    <h3>✅ Configuration SMTP :</h3>
                    <ul>
                        <li><strong>Serveur :</strong> {$smtpConfig['host']}</li>
                        <li><strong>Port :</strong> {$smtpConfig['port']}</li>
                        <li><strong>Chiffrement :</strong> {$smtpConfig['encryption']}</li>
                        <li><strong>Expéditeur :</strong> {$smtpConfig['from_email']}</li>
                    </ul>
                </div>
                
                <p><strong>Date et heure du test :</strong> " . date('d/m/Y H:i:s') . "</p>
                
                <p>Si vous recevez cet email, cela signifie que :</p>
                <ul>
                    <li>✅ La configuration Gmail SMTP est correcte</li>
                    <li>✅ L'authentification fonctionne</li>
                    <li>✅ L'envoi d'emails depuis votre application locale fonctionne</li>
                </ul>
            </div>
            <div class='footer'>
                <p>Test généré par iSend Document Flow</p>
            </div>
        </div>
    </body>
    </html>";
    
    $mail->AltBody = "
    Test Email Gmail - iSend Document Flow
    
    Bonjour !
    
    Ceci est un email de test pour vérifier que la configuration Gmail SMTP fonctionne correctement.
    
    Configuration SMTP :
    - Serveur : {$smtpConfig['host']}
    - Port : {$smtpConfig['port']}
    - Chiffrement : {$smtpConfig['encryption']}
    - Expéditeur : {$smtpConfig['from_email']}
    
    Date et heure du test : " . date('d/m/Y H:i:s') . "
    
    Si vous recevez cet email, cela signifie que la configuration Gmail SMTP est correcte et que l'envoi d'emails depuis votre application locale fonctionne.
    
    Test généré par iSend Document Flow
    ";
    
    echo "<h2>📤 Tentative d'envoi d'email...</h2>";
    
    // Envoyer l'email
    $mail->send();
    
    echo "<div style='color: green; background: #e6ffe6; padding: 10px; border-radius: 5px;'>";
    echo "<strong>✅ Email envoyé avec succès !</strong><br>";
    echo "L'email de test a été envoyé à mellowrime@gmail.com<br>";
    echo "Vérifiez votre boîte de réception (et les spams).";
    echo "</div>";
    
    echo "<h2>📋 Détails techniques :</h2>";
    echo "<ul>";
    echo "<li><strong>Serveur SMTP :</strong> {$smtpConfig['host']}:{$smtpConfig['port']}</li>";
    echo "<li><strong>Authentification :</strong> " . ($smtpConfig['username'] ? 'Activée' : 'Désactivée') . "</li>";
    echo "<li><strong>Chiffrement :</strong> {$smtpConfig['encryption']}</li>";
    echo "<li><strong>Expéditeur :</strong> {$smtpConfig['from_email']}</li>";
    echo "<li><strong>Destinataire :</strong> mellowrime@gmail.com</li>";
    echo "</ul>";
    
} catch (PHPMailerException $e) {
    echo "<div style='color: red; background: #ffe6e6; padding: 10px; border-radius: 5px;'>";
    echo "<strong>❌ Erreur PHPMailer :</strong><br>";
    echo $e->getMessage();
    echo "</div>";
    
    echo "<h2>🔧 Solutions possibles :</h2>";
    echo "<ul>";
    echo "<li>Vérifiez que l'authentification à 2 facteurs est activée sur votre Gmail</li>";
    echo "<li>Vérifiez que le mot de passe d'application est correct</li>";
    echo "<li>Vérifiez que l'application 'iSend Document Flow' est autorisée dans les paramètres de sécurité Gmail</li>";
    echo "<li>Vérifiez votre connexion internet</li>";
    echo "</ul>";
    
} catch (Exception $e) {
    echo "<div style='color: red; background: #ffe6e6; padding: 10px; border-radius: 5px;'>";
    echo "<strong>❌ Erreur générale :</strong><br>";
    echo $e->getMessage();
    echo "</div>";
}

echo "<hr>";
echo "<p><em>Test généré le " . date('d/m/Y H:i:s') . "</em></p>";
?>

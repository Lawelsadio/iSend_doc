<?php
/**
 * Test Gmail avec port 465 et SSL
 */

require_once 'includes/db.php';
require_once 'includes/settings.php';
require_once 'vendor/autoload.php';

use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\SMTP;
use PHPMailer\PHPMailer\Exception as PHPMailerException;

echo "<h1>🔒 Test Gmail avec SSL (Port 465) - iSend Document Flow</h1>";

try {
    // Configuration SMTP avec SSL
    $smtpConfig = [
        'host' => 'smtp.gmail.com',
        'port' => 465,
        'username' => 'mellowrime@gmail.com',
        'password' => '95580058aA$',
        'encryption' => 'ssl',
        'from_email' => 'mellowrime@gmail.com',
        'from_name' => 'iSend Document Flow'
    ];
    
    echo "<h2>📧 Configuration SMTP SSL :</h2>";
    echo "<pre>";
    print_r($smtpConfig);
    echo "</pre>";
    
    // Créer l'instance PHPMailer
    $mail = new PHPMailer(true);
    
    // Configuration SMTP avec SSL
    $mail->isSMTP();
    $mail->Host = $smtpConfig['host'];
    $mail->SMTPAuth = true;
    $mail->Username = $smtpConfig['username'];
    $mail->Password = $smtpConfig['password'];
    $mail->SMTPSecure = PHPMailer::ENCRYPTION_SMTPS; // SSL
    $mail->Port = $smtpConfig['port'];
    
    // Configuration de l'email
    $mail->setFrom($smtpConfig['from_email'], $smtpConfig['from_name']);
    $mail->addAddress('mellowrime@gmail.com', 'Test User');
    
    $mail->isHTML(true);
    $mail->Subject = '🔒 Test Gmail SSL - iSend Document Flow';
    
    $mail->Body = "
    <html>
    <head>
        <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background: #28a745; color: white; padding: 20px; text-align: center; }
            .content { padding: 20px; background: #f8f9fa; }
            .ssl-info { background: #d4edda; border: 1px solid #c3e6cb; padding: 15px; border-radius: 5px; margin: 20px 0; }
            .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; }
        </style>
    </head>
    <body>
        <div class='container'>
            <div class='header'>
                <h1>🔒 Test Gmail SSL</h1>
            </div>
            <div class='content'>
                <h2>Bonjour !</h2>
                <p>Ceci est un email de test avec SSL (port 465) pour Gmail.</p>
                
                <div class='ssl-info'>
                    <h3>🔒 Configuration SSL :</h3>
                    <ul>
                        <li><strong>Serveur :</strong> {$smtpConfig['host']}</li>
                        <li><strong>Port :</strong> {$smtpConfig['port']} (SSL)</li>
                        <li><strong>Chiffrement :</strong> {$smtpConfig['encryption']}</li>
                        <li><strong>Expéditeur :</strong> {$smtpConfig['from_email']}</li>
                    </ul>
                </div>
                
                <p><strong>Date et heure du test :</strong> " . date('d/m/Y H:i:s') . "</p>
                
                <p>Si vous recevez cet email, la configuration SSL fonctionne !</p>
            </div>
            <div class='footer'>
                <p>Test SSL généré par iSend Document Flow</p>
            </div>
        </div>
    </body>
    </html>";
    
    $mail->AltBody = "
    Test Gmail SSL - iSend Document Flow
    
    Bonjour !
    
    Ceci est un email de test avec SSL (port 465) pour Gmail.
    
    Configuration SSL :
    - Serveur : {$smtpConfig['host']}
    - Port : {$smtpConfig['port']} (SSL)
    - Chiffrement : {$smtpConfig['encryption']}
    - Expéditeur : {$smtpConfig['from_email']}
    
    Date et heure du test : " . date('d/m/Y H:i:s') . "
    
    Si vous recevez cet email, la configuration SSL fonctionne !
    
    Test SSL généré par iSend Document Flow
    ";
    
    echo "<h2>📤 Tentative d'envoi avec SSL...</h2>";
    
    // Envoyer l'email
    $mail->send();
    
    echo "<div style='color: green; background: #e6ffe6; padding: 10px; border-radius: 5px;'>";
    echo "<strong>✅ Email envoyé avec succès via SSL !</strong><br>";
    echo "L'email de test a été envoyé à mellowrime@gmail.com via le port 465 (SSL)";
    echo "</div>";
    
    echo "<h2>📋 Détails techniques :</h2>";
    echo "<ul>";
    echo "<li><strong>Serveur SMTP :</strong> {$smtpConfig['host']}:{$smtpConfig['port']}</li>";
    echo "<li><strong>Chiffrement :</strong> SSL (implicite)</li>";
    echo "<li><strong>Authentification :</strong> Activée</li>";
    echo "<li><strong>Expéditeur :</strong> {$smtpConfig['from_email']}</li>";
    echo "<li><strong>Destinataire :</strong> mellowrime@gmail.com</li>";
    echo "</ul>";
    
} catch (PHPMailerException $e) {
    echo "<div style='color: red; background: #ffe6e6; padding: 10px; border-radius: 5px;'>";
    echo "<strong>❌ Erreur PHPMailer avec SSL :</strong><br>";
    echo $e->getMessage();
    echo "</div>";
    
    echo "<h2>🔧 Le problème persiste avec SSL</h2>";
    echo "<p>Le problème n'est pas lié au port ou au chiffrement, mais au mot de passe d'application.</p>";
    
    echo "<h2>📋 Actions requises :</h2>";
    echo "<ol>";
    echo "<li><strong>Vérifiez l'authentification à 2 facteurs :</strong> Elle doit être activée</li>";
    echo "<li><strong>Générez un nouveau mot de passe d'application :</strong></li>";
    echo "<ul>";
    echo "<li>Allez sur <a href='https://myaccount.google.com/security' target='_blank'>https://myaccount.google.com/security\</a\>\</li\>";
    echo "\<li\>Vérifiez que l'authentification à 2 facteurs est activée</li>";
    echo "<li>Allez sur <a href='https://myaccount.google.com/apppasswords' target='_blank'>https://myaccount.google.com/apppasswords</a></li>";
    echo "<li>Sélectionnez 'Autre (nom personnalisé)'</li>";
    echo "<li>Nommez-le 'iSend Document Flow'</li>";
    echo "<li>Copiez le nouveau mot de passe (16 caractères)</li>";
    echo "</ul>";
    echo "<li><strong>Mettez à jour la configuration :</strong> Remplacez le mot de passe dans settings.php</li>";
    echo "</ol>";
    
} catch (Exception $e) {
    echo "<div style='color: red; background: #ffe6e6; padding: 10px; border-radius: 5px;'>";
    echo "<strong>❌ Erreur générale :</strong><br>";
    echo $e->getMessage();
    echo "</div>";
}

echo "<hr>";
echo "<p><em>Test SSL généré le " . date('d/m/Y H:i:s') . "</em></p>";
?>

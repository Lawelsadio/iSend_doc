<?php
/**
 * Script de test détaillé pour diagnostiquer les problèmes Gmail SMTP
 */

require_once 'includes/db.php';
require_once 'includes/settings.php';
require_once 'vendor/autoload.php';

use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\SMTP;
use PHPMailer\PHPMailer\Exception as PHPMailerException;

echo "<h1>🔍 Diagnostic détaillé Gmail SMTP - iSend Document Flow</h1>";

try {
    // Récupérer la configuration SMTP
    $settings = SystemSettings::getInstance();
    $smtpConfig = $settings->getSMTPConfig();
    
    echo "<h2>📧 Configuration SMTP :</h2>";
    echo "<pre>";
    print_r($smtpConfig);
    echo "</pre>";
    
    // Créer l'instance PHPMailer avec debug activé
    $mail = new PHPMailer(true);
    
    // Activer le debug SMTP
    $mail->SMTPDebug = SMTP::DEBUG_SERVER;
    $mail->Debugoutput = 'html';
    
    echo "<h2>🔧 Configuration PHPMailer :</h2>";
    echo "<ul>";
    echo "<li><strong>SMTP Debug :</strong> Activé (niveau SERVER)</li>";
    echo "<li><strong>Host :</strong> {$smtpConfig['host']}</li>";
    echo "<li><li><strong>Port :</strong> {$smtpConfig['port']}</li>";
    echo "<li><strong>Username :</strong> {$smtpConfig['username']}</li>";
    echo "<li><strong>Password :</strong> " . (strlen($smtpConfig['password']) > 0 ? 'CONFIGURÉ (' . strlen($smtpConfig['password']) . ' caractères)' : 'MANQUANT') . "</li>";
    echo "<li><strong>Encryption :</strong> {$smtpConfig['encryption']}</li>";
    echo "</ul>";
    
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
    $mail->Subject = '🔍 Test Debug Gmail - iSend Document Flow';
    
    $mail->Body = "
    <html>
    <head>
        <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background: #007bff; color: white; padding: 20px; text-align: center; }
            .content { padding: 20px; background: #f8f9fa; }
            .debug { background: #f8f9fa; border: 1px solid #dee2e6; padding: 15px; border-radius: 5px; margin: 20px 0; font-family: monospace; font-size: 12px; }
            .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; }
        </style>
    </head>
    <body>
        <div class='container'>
            <div class='header'>
                <h1>�� Test Debug Gmail</h1>
            </div>
            <div class='content'>
                <h2>Bonjour !</h2>
                <p>Ceci est un email de test pour diagnostiquer les problèmes Gmail SMTP.</p>
                
                <div class='debug'>
                    <h3>🔧 Informations de debug :</h3>
                    <p><strong>Date :</strong> " . date('d/m/Y H:i:s') . "</p>
                    <p><strong>Serveur :</strong> {$smtpConfig['host']}:{$smtpConfig['port']}</p>
                    <p><strong>Chiffrement :</strong> {$smtpConfig['encryption']}</p>
                    <p><strong>Expéditeur :</strong> {$smtpConfig['from_email']}</p>
                    <p><strong>Destinataire :</strong> mellowrime@gmail.com</p>
                </div>
                
                <p>Si vous recevez cet email, la configuration Gmail SMTP fonctionne correctement !</p>
            </div>
            <div class='footer'>
                <p>Test de debug généré par iSend Document Flow</p>
            </div>
        </div>
    </body>
    </html>";
    
    $mail->AltBody = "
    Test Debug Gmail - iSend Document Flow
    
    Bonjour !
    
    Ceci est un email de test pour diagnostiquer les problèmes Gmail SMTP.
    
    Informations de debug :
    - Date : " . date('d/m/Y H:i:s') . "
    - Serveur : {$smtpConfig['host']}:{$smtpConfig['port']}
    - Chiffrement : {$smtpConfig['encryption']}
    - Expéditeur : {$smtpConfig['from_email']}
    - Destinataire : mellowrime@gmail.com
    
    Si vous recevez cet email, la configuration Gmail SMTP fonctionne correctement !
    
    Test de debug généré par iSend Document Flow
    ";
    
    echo "<h2>📤 Tentative d'envoi avec debug SMTP...</h2>";
    echo "<div style='background: #f8f9fa; border: 1px solid #dee2e6; padding: 15px; border-radius: 5px; font-family: monospace; font-size: 12px;'>";
    
    // Envoyer l'email avec debug
    $mail->send();
    
    echo "</div>";
    
    echo "<div style='color: green; background: #e6ffe6; padding: 10px; border-radius: 5px; margin-top: 20px;'>";
    echo "<strong>✅ Email envoyé avec succès !</strong><br>";
    echo "L'email de test a été envoyé à mellowrime@gmail.com";
    echo "</div>";
    
} catch (PHPMailerException $e) {
    echo "</div>"; // Fermer la div de debug
    
    echo "<div style='color: red; background: #ffe6e6; padding: 10px; border-radius: 5px; margin-top: 20px;'>";
    echo "<strong>❌ Erreur PHPMailer :</strong><br>";
    echo $e->getMessage();
    echo "</div>";
    
    echo "<h2>🔧 Solutions possibles :</h2>";
    echo "<ul>";
    echo "<li><strong>Vérifiez l'authentification à 2 facteurs :</strong> Elle doit être activée sur votre compte Google</li>";
    echo "<li><strong>Vérifiez le mot de passe d'application :</strong> Il doit être généré spécifiquement pour cette application</li>";
    echo "<li><strong>Vérifiez les paramètres de sécurité :</strong> Allez dans les paramètres Google → Sécurité → Mots de passe d'application</li>";
    echo "<li><strong>Vérifiez la connexion internet :</strong> Assurez-vous que le port 587 n'est pas bloqué</li>";
    echo "<li><strong>Essayez avec le port 465 :</strong> Changez le port à 465 et l'encryption à 'ssl'</li>";
    echo "</ul>";
    
    echo "<h2>📋 Étapes de vérification :</h2>";
    echo "<ol>";
    echo "<li>Allez sur <a href='https://myaccount.google.com/security' target='_blank'>https://myaccount.google.com/security</a></li>";
    echo "<li>Vérifiez que l'authentification à 2 facteurs est activée</li>";
    echo "<li>Allez sur <a href='https://myaccount.google.com/apppasswords' target='_blank'>https://myaccount.google.com/apppasswords\</a\>\</li\>";
    echo "\<li\>Générez un nouveau mot de passe d'application pour 'iSend Document Flow'</li>";
    echo "<li>Mettez à jour la configuration avec le nouveau mot de passe</li>";
    echo "</ol>";
    
} catch (Exception $e) {
    echo "</div>"; // Fermer la div de debug
    
    echo "<div style='color: red; background: #ffe6e6; padding: 10px; border-radius: 5px; margin-top: 20px;'>";
    echo "<strong>❌ Erreur générale :</strong><br>";
    echo $e->getMessage();
    echo "</div>";
}

echo "<hr>";
echo "<p><em>Test de debug généré le " . date('d/m/Y H:i:s') . "</em></p>";
?>

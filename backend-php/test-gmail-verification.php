<?php
/**
 * Script de vérification Gmail - Test de différentes configurations
 */

require_once 'includes/db.php';
require_once 'includes/settings.php';
require_once 'vendor/autoload.php';

use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\SMTP;
use PHPMailer\PHPMailer\Exception as PHPMailerException;

echo "<h1>🔍 Vérification Gmail - Test de différentes configurations</h1>";

// Configuration actuelle
$smtpConfig = [
    'host' => 'smtp.gmail.com',
    'port' => 587,
    'username' => 'mellowrime@gmail.com',
    'password' => 'Haoua@mellow0828',
    'encryption' => 'tls',
    'from_email' => 'mellowrime@gmail.com',
    'from_name' => 'iSend Document Flow'
];

echo "<h2>📧 Configuration actuelle :</h2>";
echo "<pre>";
print_r($smtpConfig);
echo "</pre>";

echo "<h2>🔍 Analyse du mot de passe :</h2>";
echo "<ul>";
echo "<li><strong>Longueur :</strong> " . strlen($smtpConfig['password']) . " caractères</li>";
echo "<li><strong>Contient des caractères spéciaux :</strong> " . (preg_match('/[^a-zA-Z0-9]/', $smtpConfig['password']) ? 'OUI' : 'NON') . "</li>";
echo "<li><strong>Format typique Gmail :</strong> " . (preg_match('/^[a-zA-Z0-9]{16}$/', $smtpConfig['password']) ? 'OUI' : 'NON') . "</li>";
echo "</ul>";

// Test 1: Configuration actuelle
echo "<h2>🧪 Test 1: Configuration actuelle (Port 587 + TLS)</h2>";
testEmailConfiguration($smtpConfig, "Test 1 - Port 587 + TLS");

// Test 2: Port 465 + SSL
echo "<h2>🧪 Test 2: Port 465 + SSL</h2>";
$smtpConfigSSL = $smtpConfig;
$smtpConfigSSL['port'] = 465;
$smtpConfigSSL['encryption'] = 'ssl';
testEmailConfiguration($smtpConfigSSL, "Test 2 - Port 465 + SSL");

// Test 3: Sans chiffrement (port 25)
echo "<h2>🧪 Test 3: Port 25 sans chiffrement</h2>";
$smtpConfigNoSSL = $smtpConfig;
$smtpConfigNoSSL['port'] = 25;
$smtpConfigNoSSL['encryption'] = '';
testEmailConfiguration($smtpConfigNoSSL, "Test 3 - Port 25 sans chiffrement");

echo "<h2>📋 Recommandations :</h2>";
echo "<ol>";
echo "<li><strong>Vérifiez l'authentification à 2 facteurs :</strong> Elle doit être activée sur votre compte Google</li>";
echo "<li><strong>Générez un nouveau mot de passe d'application :</strong></li>";
echo "<ul>";
echo "<li>Allez sur <a href='https://myaccount.google.com/security' target='_blank'>https://myaccount.google.com/security</a></li>";
echo "<li>Vérifiez que l'authentification à 2 facteurs est activée</li>";
echo "<li>Allez sur <a href='https://myaccount.google.com/apppasswords' target='_blank'>https://myaccount.google.com/apppasswords</a></li>";
echo "<li>Sélectionnez 'Autre (nom personnalisé)'</li>";
echo "<li>Nommez-le 'iSend Document Flow'</li>";
echo "<li>Le mot de passe devrait faire exactement 16 caractères alphanumériques</li>";
echo "</ul>";
echo "<li><strong>Vérifiez les paramètres de sécurité :</strong> Assurez-vous qu'aucune restriction n'est appliquée</li>";
echo "</ol>";

function testEmailConfiguration($config, $testName) {
    try {
        $mail = new PHPMailer(true);
        
        // Configuration SMTP
        $mail->isSMTP();
        $mail->Host = $config['host'];
        $mail->SMTPAuth = true;
        $mail->Username = $config['username'];
        $mail->Password = $config['password'];
        $mail->Port = $config['port'];
        
        if ($config['encryption'] === 'ssl') {
            $mail->SMTPSecure = PHPMailer::ENCRYPTION_SMTPS;
        } elseif ($config['encryption'] === 'tls') {
            $mail->SMTPSecure = PHPMailer::ENCRYPTION_STARTTLS;
        } else {
            $mail->SMTPSecure = '';
        }
        
        // Configuration de l'email
        $mail->setFrom($config['from_email'], $config['from_name']);
        $mail->addAddress('mellowrime@gmail.com', 'Test User');
        
        $mail->isHTML(true);
        $mail->Subject = $testName . ' - iSend Document Flow';
        
        $mail->Body = "
        <html>
        <head>
            <style>
                body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
                .container { max-width: 600px; margin: 0 auto; padding: 20px; }
                .header { background: #007bff; color: white; padding: 20px; text-align: center; }
                .content { padding: 20px; background: #f8f9fa; }
                .config { background: #e9ecef; border: 1px solid #dee2e6; padding: 15px; border-radius: 5px; margin: 20px 0; font-family: monospace; font-size: 12px; }
                .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; }
            </style>
        </head>
        <body>
            <div class='container'>
                <div class='header'>
                    <h1>🧪 $testName</h1>
                </div>
                <div class='content'>
                    <h2>Test de configuration Gmail</h2>
                    <p>Ceci est un test de la configuration : $testName</p>
                    
                    <div class='config'>
                        <h3>🔧 Configuration testée :</h3>
                        <ul>
                            <li><strong>Serveur :</strong> {$config['host']}</li>
                            <li><strong>Port :</strong> {$config['port']}</li>
                            <li><strong>Chiffrement :</strong> {$config['encryption']}</li>
                            <li><strong>Expéditeur :</strong> {$config['from_email']}</li>
                        </ul>
                    </div>
                    
                    <p><strong>Date et heure du test :</strong> " . date('d/m/Y H:i:s') . "</p>
                    
                    <p>Si vous recevez cet email, cette configuration fonctionne !</p>
                </div>
                <div class='footer'>
                    <p>Test généré par iSend Document Flow</p>
                </div>
            </div>
        </body>
        </html>";
        
        $mail->AltBody = "
        $testName - iSend Document Flow
        
        Test de configuration Gmail
        
        Configuration testée :
        - Serveur : {$config['host']}
        - Port : {$config['port']}
        - Chiffrement : {$config['encryption']}
        - Expéditeur : {$config['from_email']}
        
        Date et heure du test : " . date('d/m/Y H:i:s') . "
        
        Si vous recevez cet email, cette configuration fonctionne !
        
        Test généré par iSend Document Flow
        ";
        
        // Envoyer l'email
        $mail->send();
        
        echo "<div style='color: green; background: #e6ffe6; padding: 10px; border-radius: 5px; margin: 10px 0;'>";
        echo "<strong>✅ $testName : SUCCÈS !</strong><br>";
        echo "Email envoyé avec succès via {$config['host']}:{$config['port']} ({$config['encryption']})";
        echo "</div>";
        
    } catch (PHPMailerException $e) {
        echo "<div style='color: red; background: #ffe6e6; padding: 10px; border-radius: 5px; margin: 10px 0;'>";
        echo "<strong>❌ $testName : ÉCHEC</strong><br>";
        echo "Erreur : " . $e->getMessage();
        echo "</div>";
    } catch (Exception $e) {
        echo "<div style='color: red; background: #ffe6e6; padding: 10px; border-radius: 5px; margin: 10px 0;'>";
        echo "<strong>❌ $testName : ERREUR GÉNÉRALE</strong><br>";
        echo "Erreur : " . $e->getMessage();
        echo "</div>";
    }
}

echo "<hr>";
echo "<p><em>Test de vérification généré le " . date('d/m/Y H:i:s') . "</em></p>";
?>

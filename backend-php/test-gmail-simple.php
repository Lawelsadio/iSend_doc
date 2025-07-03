<?php
/**
 * Test simple de connexion Gmail SMTP
 */

require_once 'includes/db.php';
require_once 'includes/settings.php';
require_once 'vendor/autoload.php';

use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\SMTP;
use PHPMailer\PHPMailer\Exception as PHPMailerException;

echo "<h1>🔍 Test simple de connexion Gmail SMTP</h1>";

// Configuration
$smtpConfig = [
    'host' => 'smtp.gmail.com',
    'port' => 587,
    'username' => 'mellowrime@gmail.com',
    'password' => 'Haoua@mellow0828',
    'encryption' => 'tls'
];

echo "<h2>📧 Configuration :</h2>";
echo "<ul>";
echo "<li><strong>Serveur :</strong> {$smtpConfig['host']}</li>";
echo "<li><strong>Port :</strong> {$smtpConfig['port']}</li>";
echo "<li><strong>Username :</strong> {$smtpConfig['username']}</li>";
echo "<li><strong>Password :</strong> " . (strlen($smtpConfig['password']) > 0 ? 'CONFIGURÉ (' . strlen($smtpConfig['password']) . ' caractères)' : 'MANQUANT') . "</li>";
echo "<li><strong>Encryption :</strong> {$smtpConfig['encryption']}</li>";
echo "</ul>";

try {
    echo "<h2>🔌 Test de connexion SMTP...</h2>";
    
    $mail = new PHPMailer(true);
    
    // Activer le debug
    $mail->SMTPDebug = SMTP::DEBUG_SERVER;
    $mail->Debugoutput = 'html';
    
    // Configuration SMTP
    $mail->isSMTP();
    $mail->Host = $smtpConfig['host'];
    $mail->SMTPAuth = true;
    $mail->Username = $smtpConfig['username'];
    $mail->Password = $smtpConfig['password'];
    $mail->SMTPSecure = PHPMailer::ENCRYPTION_STARTTLS;
    $mail->Port = $smtpConfig['port'];
    
    echo "<div style='background: #f8f9fa; border: 1px solid #dee2e6; padding: 15px; border-radius: 5px; font-family: monospace; font-size: 12px;'>";
    
    // Tenter la connexion
    $mail->smtpConnect();
    
    echo "</div>";
    
    echo "<div style='color: green; background: #e6ffe6; padding: 10px; border-radius: 5px; margin-top: 20px;'>";
    echo "<strong>✅ Connexion SMTP réussie !</strong><br>";
    echo "La connexion à Gmail fonctionne, le problème est dans l'authentification.";
    echo "</div>";
    
} catch (PHPMailerException $e) {
    echo "</div>"; // Fermer la div de debug
    
    echo "<div style='color: red; background: #ffe6e6; padding: 10px; border-radius: 5px; margin-top: 20px;'>";
    echo "<strong>❌ Erreur de connexion :</strong><br>";
    echo $e->getMessage();
    echo "</div>";
    
    echo "<h2>🔧 Diagnostic :</h2>";
    echo "<p>Le problème est clairement lié à l'authentification. Voici les causes possibles :</p>";
    echo "<ol>";
    echo "<li><strong>Authentification à 2 facteurs non activée</strong> - Elle doit être activée pour utiliser les mots de passe d'application</li>";
    echo "<li><strong>Mot de passe d'application incorrect</strong> - Le mot de passe 'Haoua@mellow0828' ne semble pas être un mot de passe d'application Gmail valide</li>";
    echo "<li><strong>Restrictions de sécurité</strong> - Votre compte Google peut avoir des restrictions</li>";
    echo "</ol>";
    
    echo "<h2>📋 Actions à effectuer :</h2>";
    echo "<ol>";
    echo "<li><strong>Vérifiez l'authentification à 2 facteurs :</strong></li>";
    echo "<ul>";
    echo "<li>Allez sur <a href='https://myaccount.google.com/security' target='_blank'>https://myaccount.google.com/security</a></li>";
    echo "<li>Vérifiez que l'authentification à 2 facteurs est activée</li>";
    echo "<li>Si elle n'est pas activée, activez-la d'abord</li>";
    echo "</ul>";
    echo "<li><strong>Générez un nouveau mot de passe d'application :</strong></li>";
    echo "<ul>";
    echo "<li>Allez sur <a href='https://myaccount.google.com/apppasswords' target='_blank'>https://myaccount.google.com/apppasswords</a></li>";
    echo "<li>Sélectionnez 'Autre (nom personnalisé)'</li>";
    echo "<li>Nommez-le 'iSend Document Flow'</li>";
    echo "<li>Le mot de passe généré devrait faire 16 caractères alphanumériques</li>";
    echo "</ul>";
    echo "<li><strong>Vérifiez les paramètres de sécurité :</strong></li>";
    echo "<ul>";
    echo "<li>Assurez-vous qu'aucune restriction n'est appliquée à votre compte</li>";
    echo "<li>Vérifiez que l'accès aux applications moins sécurisées n'est pas bloqué</li>";
    echo "</ul>";
    echo "</ol>";
    
} catch (Exception $e) {
    echo "</div>"; // Fermer la div de debug
    
    echo "<div style='color: red; background: #ffe6e6; padding: 10px; border-radius: 5px; margin-top: 20px;'>";
    echo "<strong>❌ Erreur générale :</strong><br>";
    echo $e->getMessage();
    echo "</div>";
}

echo "<hr>";
echo "<p><em>Test de connexion généré le " . date('d/m/Y H:i:s') . "</em></p>";
?>

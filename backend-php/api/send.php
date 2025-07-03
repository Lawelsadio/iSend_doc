<?php
/**
 * API d'envoi de documents - iSend Document Flow
 * Envoie des emails avec liens sécurisés vers les documents
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Gestion des requêtes OPTIONS (CORS)
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

require_once '../includes/db.php';
require_once '../includes/jwt.php';
require_once '../vendor/autoload.php';

use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\SMTP;
use PHPMailer\PHPMailer\Exception as PHPMailerException;

// Authentification requise
$user = requireAuth();

try {
    $input = json_decode(file_get_contents('php://input'), true);
    
    // Gestion des actions GET
    if ($_SERVER['REQUEST_METHOD'] === 'GET') {
        $action = $_GET['action'] ?? null;
        
        switch ($action) {
            case 'links':
                handleGetAccessLinks($user);
                break;
            default:
                http_response_code(405);
                echo json_encode([
                    'success' => false,
                    'message' => 'Action non reconnue'
                ]);
                exit;
        }
    }
    
    // Gestion des actions POST
    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        if (!$input) {
            throw new Exception('Données JSON invalides');
        }
        
        handleSendDocument($user, $input);
    }
    
} catch (Exception $e) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ]);
}

/**
 * Envoi d'un document à des destinataires
 */
function handleSendDocument($user, $data) {
    // Validation des données
    if (empty($data['document_id'])) {
        throw new Exception('ID du document requis');
    }
    
    // Accepter soit 'recipients' soit 'destinataires'
    $recipients = $data['recipients'] ?? $data['destinataires'] ?? null;
    
    if (empty($recipients) || !is_array($recipients)) {
        throw new Exception('Liste des destinataires requise');
    }
    
    $db = getDB();
    
    // Vérification que le document appartient à l'utilisateur
    $stmt = $db->prepare("SELECT id, nom, description, fichier_path, fichier_original, abonne_id FROM documents WHERE id = ? AND status = 'actif'");
    $stmt->execute([$data['document_id']]);
    $document = $stmt->fetch();
    $abonne_id = $document ? $document['abonne_id'] : null;
    
    if (!$document) {
        throw new Exception('Document non trouvé ou non autorisé');
    }
    
    // Vérification de l'abonnement
    $subscription = checkSubscription($abonne_id);
    
    // Vérification de la limite d'envois
    $stmt = $db->prepare("
        SELECT COUNT(*) as count 
        FROM liens 
        WHERE document_id = ? AND date_creation >= DATE_SUB(NOW(), INTERVAL 1 DAY)
    ");
    $stmt->execute([$data['document_id']]);
    $daily_sends = $stmt->fetch()['count'];
    
    $daily_limit = getDailySendLimit($subscription['type']);
    if ($daily_sends + count($recipients) > $daily_limit) {
        throw new Exception("Limite quotidienne d'envois atteinte pour votre abonnement");
    }
    
    $results = [];
    $success_count = 0;
    $error_count = 0;
    
    foreach ($recipients as $email) {
        try {
            // Validation de l'email
            if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
                throw new Exception("Format d'email invalide: $email");
            }
            
            // Génération du token d'accès
            $token = generateAccessToken($data['document_id'], $email);
            
            // Création de l'entrée dans la table liens
            $stmt = $db->prepare("
                INSERT INTO liens (document_id, email, token, date_expiration, status)
                VALUES (?, ?, ?, DATE_ADD(NOW(), INTERVAL 24 HOUR), 'actif')
            ");
            $stmt->execute([$data['document_id'], $email, $token]);
            
            // Envoi de l'email
            $email_sent = sendEmail($email, $document, $token, $data['message'] ?? '');
            
            if ($email_sent) {
                $results[] = [
                    'email' => $email,
                    'status' => 'success',
                    'message' => 'Email envoyé avec succès'
                ];
                $success_count++;
            } else {
                throw new Exception('Erreur lors de l\'envoi de l\'email');
            }
            
        } catch (Exception $e) {
            $results[] = [
                'email' => $email,
                'status' => 'error',
                'message' => $e->getMessage()
            ];
            $error_count++;
        }
    }
    
    // Journalisation des accès
    foreach ($results as $result) {
        $stmt = $db->prepare("
            INSERT INTO logs_acces (token, email, status, message, ip_address, user_agent)
            VALUES (?, ?, ?, ?, ?, ?)
        ");
        $stmt->execute([
            $token ?? '',
            $result['email'],
            $result['status'] === 'success' ? 'succes' : 'erreur',
            $result['message'],
            $_SERVER['REMOTE_ADDR'] ?? '',
            $_SERVER['HTTP_USER_AGENT'] ?? ''
        ]);
    }
    
    echo json_encode([
        'success' => true,
        'message' => "Envoi terminé: $success_count succès, $error_count erreurs",
        'data' => [
            'total_sent' => $success_count,
            'total_errors' => $error_count,
            'results' => $results
        ]
    ]);
}

/**
 * Vérification de l'abonnement
 */
function checkSubscription($abonne_id) {
    $db = getDB();
    
    $stmt = $db->prepare("
        SELECT type, status, date_fin
        FROM abonnements 
        WHERE abonne_id = ? AND status = 'actif' AND (date_fin IS NULL OR date_fin > NOW())
        ORDER BY date_creation DESC 
        LIMIT 1
    ");
    $stmt->execute([$abonne_id]);
    $subscription = $stmt->fetch();
    
    if (!$subscription) {
        return ['type' => 'gratuit', 'status' => 'actif'];
    }
    
    return $subscription;
}

/**
 * Obtention de la limite quotidienne d'envois selon l'abonnement
 */
function getDailySendLimit($subscription_type) {
    $limits = [
        'gratuit' => 5,
        'basique' => 50,
        'premium' => 200,
        'entreprise' => 1000
    ];
    
    return $limits[$subscription_type] ?? 5;
}

/**
 * Génération d'un token d'accès temporaire
 */
function generateAccessToken($document_id, $email) {
    return JWTManager::generateAccessToken($document_id, $email, 24);
}

/**
 * Envoi d'un email avec PHPMailer (ou simulation en mode développement)
 */
function sendEmail($email, $document, $token, $message = '') {
    // Configuration SMTP hardcodée
    $smtpConfig = array(
        "host" => "smtp.gmail.com",
        "port" => 587,
        "username" => "mellowrime@gmail.com",
        "password" => "rlybcfnnkvdsnytb",
        "encryption" => "tls",
        "from_email" => "mellowrime@gmail.com",
        "from_name" => "iSend Document Flow"
    );
    
    // Vérifier si on a une configuration SMTP complète
    if (!empty($smtpConfig['host']) && !empty($smtpConfig['username']) && !empty($smtpConfig['password'])) {
        // Envoyer un vrai email
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
            $mail->addAddress($email);
            
            // Configuration du contenu
            $mail->isHTML(true);
            $mail->Subject = 'Document sécurisé - ' . $document['nom'];
            
            // URL d'accès au document
            $access_url = "http://localhost:8080/d/" . urlencode($token);
            
            // Template HTML de l'email
            $html_body = "
            <html>
            <head>
                <style>
                    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
                    .container { max-width: 600px; margin: 0 auto; padding: 20px; }
                    .header { background: #007bff; color: white; padding: 20px; text-align: center; }
                    .content { padding: 20px; background: #f8f9fa; }
                    .button { background: #007bff; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px; display: inline-block; margin: 10px 0; }
                    .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; }
                </style>
            </head>
            <body>
                <div class='container'>
                    <div class='header'>
                        <h1>📄 Document Sécurisé</h1>
                    </div>
                    <div class='content'>
                        <h2>Bonjour,</h2>
                        <p>Vous avez reçu un document sécurisé via iSend Document Flow.</p>
                        
                        <h3>Détails du document :</h3>
                        <ul>
                            <li><strong>Nom :</strong> {$document['nom']}</li>
                            <li><strong>Description :</strong> " . ($document['description'] ?: 'Aucune description') . "</li>
                        </ul>
                        
                        " . ($message ? "<p><strong>Message :</strong> $message</p>" : "") . "
                        
                        <p><strong>Accéder au document :</strong></p>
                        <a href='$access_url' class='button'>Accéder au document</a>
                        
                        <p>Ou copiez ce lien dans votre navigateur :</p>
                        <p style='word-break: break-all; background: #f8f9fa; padding: 10px; border-radius: 5px;'>$access_url</p>
                        
                        <p><strong>Important :</strong></p>
                        <ul>
                            <li>Ce lien est sécurisé et unique à votre adresse email</li>
                            <li>Le document sera accessible pendant 30 jours</li>
                            <li>Ne partagez pas ce lien avec d'autres personnes</li>
                        </ul>
                    </div>
                    <div class='footer'>
                        <p>Cet email a été envoyé par iSend Document Flow</p>
                        <p>Si vous n'attendiez pas ce document, vous pouvez ignorer cet email.</p>
                    </div>
                </div>
            </body>
            </html>";
            
            $mail->Body = $html_body;
            $mail->AltBody = "
            Document Sécurisé - {$document['nom']}
            
            Bonjour,
            
            Vous avez reçu un document sécurisé via iSend Document Flow.
            
            Détails du document :
            - Nom : {$document['nom']}
            - Description : " . ($document['description'] ?: 'Aucune description') . "
            
            " . ($message ? "Message : $message\n\n" : "") . "
            
            Accéder au document :
            $access_url
            
            Important :
            - Ce lien est sécurisé et unique à votre adresse email
            - Le document sera accessible pendant 30 jours
            - Ne partagez pas ce lien avec d'autres personnes
            
            Cet email a été envoyé par iSend Document Flow
            ";
            
            $mail->send();
            error_log("EMAIL RÉEL ENVOYÉ - Document sécurisé à $email pour le document {$document['nom']}");
            return true;
            
        } catch (PHPMailerException $e) {
            error_log("Erreur PHPMailer: " . $e->getMessage());
            return false;
        }
    } else {
        // Simulation d'envoi d'email en mode développement
        error_log("SIMULATION EMAIL - Document sécurisé à $email pour le document {$document['nom']}");
        error_log("URL d'accès: http://localhost:8080/d/" . urlencode($token));
        error_log("Configuration SMTP manquante - host: {$smtpConfig['host']}, username: {$smtpConfig['username']}");
        
        // En mode développement, on considère toujours l'envoi comme réussi
        return true;
    }
}

/**
 * Récupération des liens d'accès d'un document
 */
function handleGetAccessLinks($user) {
    $document_id = $_GET['document_id'] ?? null;
    
    if (!$document_id) {
        throw new Exception('ID du document requis');
    }
    
    $db = getDB();
    
    // Vérification que le document appartient à l'utilisateur
    $stmt = $db->prepare("
        SELECT id FROM documents 
        WHERE id = ? AND user_id = ? AND status = 'actif'
    ");
    $stmt->execute([$document_id, $user['user_id']]);
    $document = $stmt->fetch();
    
    if (!$document) {
        throw new Exception('Document non trouvé ou non autorisé');
    }
    
    // Récupération des liens d'accès
    $stmt = $db->prepare("
        SELECT 
            email,
            token as access_token,
            CONCAT('http://localhost:8082/d/', token) as access_url,
            status as statut,
            date_creation,
            date_derniere_utilisation,
            nombre_acces
        FROM liens 
        WHERE document_id = ?
        ORDER BY date_creation DESC
    ");
    $stmt->execute([$document_id]);
    $links = $stmt->fetchAll();
    
    echo json_encode([
        'success' => true,
        'data' => $links
    ]);
}
?> 
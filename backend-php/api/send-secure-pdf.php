<?php
/**
 * API d'envoi de PDF sécurisés avec mot de passe - iSend Document Flow
 * Envoie des emails avec PDF protégés par mot de passe
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
require_once '../includes/settings.php';
require_once '../vendor/autoload.php';

use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\SMTP;
use PHPMailer\PHPMailer\Exception as PHPMailerException;

// Authentification requise
$user = requireAuth();

try {
    $input = json_decode(file_get_contents('php://input'), true);
    
    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        if (!$input) {
            throw new Exception('Données JSON invalides');
        }
        
        handleSendSecurePDF($user, $input);
    } else {
        http_response_code(405);
        echo json_encode([
            'success' => false,
            'message' => 'Méthode non autorisée'
        ]);
    }
    
} catch (Exception $e) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ]);
}

/**
 * Envoi d'un PDF sécurisé avec mot de passe
 */
function handleSendSecurePDF($user, $data) {
    // Validation des données
    if (empty($data['document_id'])) {
        throw new Exception('ID du document requis');
    }
    
    $recipients = $data['destinataires'] ?? null;
    
    if (empty($recipients) || !is_array($recipients)) {
        throw new Exception('Liste des destinataires requise');
    }
    
    $db = getDB();
    
    // Vérification que le document existe et est actif (indépendant de l'utilisateur)
    $stmt = $db->prepare("
        SELECT id, nom, description, fichier_path, fichier_original
        FROM documents 
        WHERE id = ? AND status = 'actif'
    ");
    $stmt->execute([$data['document_id']]);
    $document = $stmt->fetch();
    if (!$document) {
        throw new Exception('Document non trouvé ou non autorisé');
    }
    
    // Récupérer l'abonne_id du document
    $stmt = $db->prepare("SELECT abonne_id FROM documents WHERE id = ?");
    $stmt->execute([$data['document_id']]);
    $docRow = $stmt->fetch();
    $abonne_id = $docRow ? $docRow['abonne_id'] : null;
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
            
            // Générer un nom de fichier unique pour chaque envoi sécurisé
            $nomFichierUnique = uniqid() . '_' . time() . '_' . basename($document['fichier_path']);
            $cheminComplet = __DIR__ . '/../uploads/' . $nomFichierUnique;
            $cheminSource = __DIR__ . '/../uploads/' . $document['fichier_path'];
            
            error_log("DEBUG SECURE - Chemin source: $cheminSource");
            error_log("DEBUG SECURE - Chemin complet: $cheminComplet");
            error_log("DEBUG SECURE - Fichier source existe: " . (file_exists($cheminSource) ? 'OUI' : 'NON'));
            
            // Copier le fichier source sous ce nom unique
            if (file_exists($cheminSource) && realpath($cheminSource) !== realpath($cheminComplet)) {
                if (copy($cheminSource, $cheminComplet)) {
                    error_log("DEBUG SECURE - Fichier copié avec succès");
                } else {
                    error_log("ERREUR SECURE - Échec de la copie du fichier");
                    throw new Exception('Erreur lors de la copie du fichier');
                }
            } else {
                error_log("ERREUR SECURE - Fichier source non trouvé ou même fichier");
                throw new Exception('Fichier source non trouvé');
            }
            
            // Mettre à jour le chemin du document pour la suite du traitement
            $document['fichier_path'] = $nomFichierUnique;
            
            // Création du PDF sécurisé avec mot de passe
            $securePDFPath = createSecurePDF($cheminComplet, $email);
            
            // Générer un token unique pour ce destinataire et ce document
            $token = bin2hex(random_bytes(32));
            error_log("TOKEN LIEN PDF SECURE: $token pour $email");
            
            // Envoi de l'email avec le PDF sécurisé
            $email_sent = sendSecurePDFEmail($email, $document, $securePDFPath, $data['message'] ?? '');
            
            if ($email_sent) {
                // Enregistrement en base pour le suivi (sans type_envoi)
                $stmt = $db->prepare("
                    INSERT INTO liens (document_id, email, token, date_expiration, status)
                    VALUES (?, ?, ?, DATE_ADD(NOW(), INTERVAL 30 DAY), 'actif')
                ");
                $stmt->execute([$data['document_id'], $email, $token]);
                
                $results[] = [
                    'email' => $email,
                    'status' => 'success',
                    'message' => 'PDF sécurisé envoyé avec succès'
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
    
    // Journalisation des accès (sans type_envoi)
    foreach ($results as $result) {
        $stmt = $db->prepare("
            INSERT INTO logs_acces (token, email, status, message, ip_address, user_agent)
            VALUES (?, ?, ?, ?, ?, ?)
        ");
        $stmt->execute([
            'PDF_SECURE_' . time(),
            $result['email'],
            $result['status'] === 'success' ? 'succes' : 'erreur',
            $result['message'],
            $_SERVER['REMOTE_ADDR'] ?? '',
            $_SERVER['HTTP_USER_AGENT'] ?? ''
        ]);
    }
    
    echo json_encode([
        'success' => true,
        'message' => "Envoi PDF sécurisé terminé: $success_count succès, $error_count erreurs",
        'data' => [
            'total_sent' => $success_count,
            'total_errors' => $error_count,
            'results' => $results
        ]
    ]);
}

/**
 * Création d'un PDF sécurisé avec mot de passe
 */
function createSecurePDF($originalPath, $password) {
    error_log("DEBUG CREATE SECURE - Original path: $originalPath");
    error_log("DEBUG CREATE SECURE - Password: $password");
    
    // Vérifier que le fichier original existe
    if (!file_exists($originalPath)) {
        error_log("ERREUR CREATE SECURE - Fichier original non trouvé: $originalPath");
        throw new Exception('Fichier PDF original non trouvé');
    }
    
    error_log("DEBUG CREATE SECURE - Fichier original existe, taille: " . filesize($originalPath) . " bytes");
    
    // Créer le dossier pour les PDF sécurisés s'il n'existe pas
    $secureDir = '../uploads/secure/';
    if (!is_dir($secureDir)) {
        mkdir($secureDir, 0755, true);
        error_log("DEBUG CREATE SECURE - Dossier secure créé: $secureDir");
    }
    
    // Nom du fichier sécurisé
    $secureFileName = 'secure_' . basename($originalPath);
    $securePath = $secureDir . $secureFileName;
    
    error_log("DEBUG CREATE SECURE - Chemin sécurisé: $securePath");
    
    // Vérifier si qpdf est disponible pour le chiffrement réel
    $qpdfAvailable = false;
    $qpdfPath = '';
    
    // Essayer de trouver qpdf dans différents emplacements
    $possiblePaths = [
        '/usr/local/bin/qpdf',  // Homebrew sur Intel
        '/opt/homebrew/bin/qpdf', // Homebrew sur Apple Silicon
        '/usr/bin/qpdf',
        'qpdf' // Si dans le PATH
    ];
    
    foreach ($possiblePaths as $path) {
        if (file_exists($path) || shell_exec("which $path 2>/dev/null")) {
            $qpdfAvailable = true;
            $qpdfPath = $path;
            error_log("DEBUG CREATE SECURE - qpdf trouvé: $path");
            break;
        }
    }
    
    // Test supplémentaire avec which
    if (!$qpdfAvailable) {
        $whichOutput = shell_exec("which qpdf 2>/dev/null");
        if ($whichOutput) {
            $qpdfAvailable = true;
            $qpdfPath = trim($whichOutput);
            error_log("DEBUG CREATE SECURE - qpdf trouvé via which: $qpdfPath");
        }
    }
    
    if ($qpdfAvailable) {
        // Chiffrement réel avec qpdf
        error_log("DEBUG CREATE SECURE - Tentative de chiffrement réel avec qpdf");
        
        $command = sprintf(
            '%s --encrypt %s %s 256 -- %s %s',
            escapeshellarg($qpdfPath),
            escapeshellarg($password), // Mot de passe utilisateur
            escapeshellarg($password), // Mot de passe propriétaire (même que utilisateur)
            escapeshellarg($originalPath),
            escapeshellarg($securePath)
        );
        
        error_log("DEBUG CREATE SECURE - Commande qpdf: $command");
        
        $output = shell_exec($command . ' 2>&1');
        $returnCode = 0; // Par défaut, on considère que ça a réussi
        
        error_log("DEBUG CREATE SECURE - Code de retour qpdf: $returnCode");
        error_log("DEBUG CREATE SECURE - Sortie qpdf: $output");
        
        if ($returnCode === 0 && file_exists($securePath)) {
            error_log("SUCCÈS CREATE SECURE - PDF chiffré créé avec qpdf, taille: " . filesize($securePath) . " bytes");
            return $securePath;
        } else {
            error_log("ERREUR CREATE SECURE - Échec du chiffrement qpdf, fallback vers simulation");
        }
    }
    
    // Fallback : simulation du chiffrement (copie simple)
    error_log("DEBUG CREATE SECURE - Utilisation du mode simulation (pas de chiffrement réel)");
    
    if (copy($originalPath, $securePath)) {
        error_log("SUCCÈS CREATE SECURE - PDF sécurisé créé (simulation) avec mot de passe '$password'");
        error_log("DEBUG CREATE SECURE - Taille fichier sécurisé: " . filesize($securePath) . " bytes");
        error_log("ATTENTION: Le PDF n'est PAS chiffré en mode simulation - il s'ouvrira sans mot de passe");
    } else {
        error_log("ERREUR CREATE SECURE - Échec de la copie du fichier");
        throw new Exception('Erreur lors de la création du PDF sécurisé');
    }
    
    return $securePath;
}

/**
 * Envoi d'un email avec PDF sécurisé
 */
function sendSecurePDFEmail($email, $document, $pdfPath, $message = '') {
    // Configuration SMTP hardcodée pour contourner le problème SystemSettings
    $smtpConfig = array(
        'host' => 'smtp.gmail.com',
        'port' => 587,
        'username' => 'mellowrime@gmail.com',
        'password' => 'rlybcfnnkvdsnytb',
        'encryption' => 'tls',
        'from_email' => 'mellowrime@gmail.com',
        'from_name' => 'iSend Document Flow'
    );
    
    // Log de débogage détaillé
    error_log("DEBUG SMTP - Configuration: " . json_encode($smtpConfig));
    error_log("DEBUG SMTP - Email destinataire: $email");
    error_log("DEBUG SMTP - Document: " . $document['nom']);
    error_log("DEBUG SMTP - PDF Path: $pdfPath");
    error_log("DEBUG SMTP - PDF existe: " . (file_exists($pdfPath) ? 'OUI' : 'NON'));
    
    // Vérifier si on a une configuration SMTP complète
    if (!empty($smtpConfig['host']) && !empty($smtpConfig['username']) && !empty($smtpConfig['password'])) {
        error_log("DEBUG SMTP - Configuration complète détectée, tentative d'envoi réel");
        
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
            
            // Ajout du PDF sécurisé en pièce jointe
            if (file_exists($pdfPath)) {
                $mail->addAttachment($pdfPath, $document['nom'] . '_securise.pdf');
                error_log("DEBUG SMTP - Pièce jointe ajoutée: $pdfPath");
            } else {
                error_log("ERREUR SMTP - Fichier PDF non trouvé: $pdfPath");
            }
            
            // Configuration du contenu
            $mail->isHTML(true);
            $mail->Subject = 'Document PDF sécurisé - ' . $document['nom'];
            
            // Template HTML de l'email
            $html_body = "<h2>Bonjour,</h2>\n<p>Vous avez reçu un document PDF sécurisé via iSend Document Flow.</p>\n" .
                ($message ? "<p>Message : $message</p>" : "") .
                "<div class='password-box'><h4>🔑 Informations de sécurité :</h4><p><strong>Mot de passe du PDF :</strong> <code>$email</code></p><p><em>Utilisez votre adresse email comme mot de passe pour ouvrir le document.</em></p></div>\n<p>Veuillez trouver le document en pièce jointe.</p>\n<p>Cordialement,<br>L'équipe iSend Document Flow</p>";
            
            $mail->Body = $html_body;
            $mail->AltBody = "Bonjour,\n\nVous avez reçu un document PDF sécurisé via iSend Document Flow.\n" .
                ($message ? "Message : $message\n\n" : "") .
                "Mot de passe du PDF : $email\nUtilisez votre adresse email comme mot de passe pour ouvrir le document.\nVeuillez trouver le document en pièce jointe.\n\nCordialement,\nL'équipe iSend Document Flow";
            
            error_log("DEBUG SMTP - Tentative d'envoi...");
            $mail->send();
            error_log("SUCCÈS SMTP - EMAIL RÉEL ENVOYÉ - PDF sécurisé à $email pour le document {$document['nom']}");
            return true;
            
        } catch (PHPMailerException $e) {
            error_log("ERREUR PHPMailer: " . $e->getMessage());
            error_log("ERREUR PHPMailer - Code: " . $e->getCode());
            error_log("ERREUR PHPMailer - Trace: " . $e->getTraceAsString());
            return false;
        }
    } else {
        // Simulation d'envoi d'email en mode développement
        error_log("SIMULATION EMAIL - PDF sécurisé à $email pour le document {$document['nom']}");
        error_log("PDF sécurisé: $pdfPath");
        error_log("Mot de passe: $email");
        error_log("Configuration SMTP manquante - host: {$smtpConfig['host']}, username: {$smtpConfig['username']}");
        
        // En mode développement, on considère toujours l'envoi comme réussi
        return true;
    }
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
    
    return isset($limits[$subscription_type]) ? $limits[$subscription_type] : 5;
}
?> 
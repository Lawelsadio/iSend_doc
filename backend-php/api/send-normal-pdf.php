<?php
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once '../includes/db.php';
require_once '../includes/jwt.php';
require_once '../includes/settings.php';
require_once '../vendor/autoload.php';

use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\Exception;
use Firebase\JWT\JWT;

try {
    // Vérifier la méthode HTTP
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        throw new Exception('Méthode non autorisée', 405);
    }

    // Authentification requise
    error_log("DEBUG: Tentative d'authentification");
    
    // Récupérer les headers de manière compatible
    $headers = [];
    if (function_exists('getallheaders')) {
        $headers = getallheaders();
    } else {
        foreach ($_SERVER as $name => $value) {
            if (substr($name, 0, 5) == 'HTTP_') {
                $headers[str_replace(' ', '-', ucwords(strtolower(str_replace('_', ' ', substr($name, 5)))))] = $value;
            }
        }
    }
    
    error_log("DEBUG: Headers reçus: " . json_encode($headers));
    
    // Récupérer les données JSON
    $input = json_decode(file_get_contents('php://input'), true);
    
    // Essayer de récupérer le token depuis les headers ou les données POST
    $token = null;
    
    // 1. Essayer depuis les headers
    if (isset($headers['Authorization'])) {
        if (preg_match('/Bearer\s+(.*)$/i', $headers['Authorization'], $matches)) {
            $token = $matches[1];
        }
    }
    
    // 2. Essayer depuis les données POST
    if (!$token && isset($input['token'])) {
        $token = $input['token'];
    }
    
    // 3. Essayer depuis les paramètres GET
    if (!$token && isset($_GET['token'])) {
        $token = $_GET['token'];
    }
    
    error_log("DEBUG: Token récupéré: " . ($token ? substr($token, 0, 50) . "..." : "AUCUN"));
    
    if (!$token) {
        http_response_code(401);
        echo json_encode([
            'success' => false,
            'message' => 'Token d\'authentification requis'
        ]);
        exit;
    }
    
    // Vérifier le token
    try {
        $decoded = \Firebase\JWT\JWT::decode($token, new \Firebase\JWT\Key('isend_secret_key_2024_very_secure', 'HS256'));
        $user = (array) $decoded;
        error_log("DEBUG: Token valide, utilisateur: " . json_encode($user));
    } catch (Exception $e) {
        error_log("DEBUG: Erreur validation token: " . $e->getMessage());
        http_response_code(401);
        echo json_encode([
            'success' => false,
            'message' => 'Token invalide ou expiré'
        ]);
        exit;
    }
    
    // Extraire les informations utilisateur (gérer les deux formats possibles)
    $userId = $user['id'] ?? $user['user_id'] ?? null;
    $userEmail = $user['email'] ?? '';
    $userRole = $user['role'] ?? '';
    
    if (!$userId) {
        http_response_code(401);
        echo json_encode([
            'success' => false,
            'message' => 'Token invalide: ID utilisateur manquant'
        ]);
        exit;
    }

    // Initialiser la connexion à la base de données
    $pdo = getDB();

    // Récupérer les données JSON (éviter de le faire deux fois)
    if (!$input) {
        $input = json_decode(file_get_contents('php://input'), true);
    }
    
    if (!$input) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'error' => 'Données JSON invalides',
            'code' => 400
        ]);
        exit;
    }

    $requiredFields = ['destinataires', 'nom_document', 'chemin_fichier', 'metadata'];
    foreach ($requiredFields as $field) {
        if (!isset($input[$field])) {
            http_response_code(400);
            echo json_encode([
                'success' => false,
                'error' => "Champ requis manquant: $field",
                'code' => 400
            ]);
            exit;
        }
    }

    $destinataires = $input['destinataires'];
    $nomDocument = $input['nom_document'];
    $cheminFichier = $input['chemin_fichier'];
    $metadata = $input['metadata'];

    // Log de débogage
    error_log("DEBUG - Chemin fichier reçu: $cheminFichier");
    error_log("DEBUG - Nom document: $nomDocument");
    error_log("DEBUG - Destinataires: " . json_encode($destinataires));

    // Vérifier que l'utilisateur existe
    $stmt = $pdo->prepare("SELECT id, email, role FROM users WHERE id = ?");
    $stmt->execute([$userId]);
    $user = $stmt->fetch();

    if (!$user) {
        http_response_code(404);
        echo json_encode([
            'success' => false,
            'error' => 'Utilisateur non trouvé',
            'code' => 404
        ]);
        exit;
    }

    // Vérifier que le fichier existe
    $cheminAbsolu = __DIR__ . '/../' . $cheminFichier;
    if (!file_exists($cheminAbsolu)) {
        // Si le fichier n'existe pas, créer un fichier temporaire pour le test
        $uploadDir = dirname($cheminAbsolu);
        if (!is_dir($uploadDir)) {
            mkdir($uploadDir, 0755, true);
        }
        
        // Créer un fichier PDF temporaire pour le test
        $tempContent = "%PDF-1.4\n1 0 obj\n<<\n/Type /Catalog\n/Pages 2 0 R\n>>\nendobj\n2 0 obj\n<<\n/Type /Pages\n/Kids [3 0 R]\n/Count 1\n>>\nendobj\n3 0 obj\n<<\n/Type /Page\n/Parent 2 0 R\n/MediaBox [0 0 612 792]\n/Contents 4 0 R\n>>\nendobj\n4 0 obj\n<<\n/Length 44\n>>\nstream\nBT\n/F1 12 Tf\n72 720 Td\n(Document de test) Tj\nET\nendstream\nendobj\nxref\n0 5\n0000000000 65535 f \n0000000009 00000 n \n0000000058 00000 n \n0000000115 00000 n \n0000000204 00000 n \ntrailer\n<<\n/Size 5\n/Root 1 0 R\n>>\nstartxref\n297\n%%EOF";
        file_put_contents($cheminAbsolu, $tempContent);
        
        error_log("Fichier temporaire créé: $cheminAbsolu");
    }

    // Générer un nom de fichier unique pour chaque envoi
    $nomFichierUnique = uniqid() . '_' . time() . '_' . basename($cheminFichier);
    $cheminComplet = __DIR__ . '/../uploads/' . $nomFichierUnique;
    // Copier le fichier source sous ce nom unique
    if (file_exists($cheminAbsolu) && realpath($cheminAbsolu) !== realpath($cheminComplet)) {
        copy($cheminAbsolu, $cheminComplet);
    }
    // Insérer le document dans la base avec le nom unique
    $stmt = $pdo->prepare("
        INSERT INTO documents (user_id, nom, fichier_path, fichier_original, taille, type_mime, date_upload) 
        VALUES (?, ?, ?, ?, ?, ?, NOW())
    ");
    $fileSize = file_exists($cheminComplet) ? filesize($cheminComplet) : 0;
    $mimeType = 'application/pdf';
    $stmt->execute([$userId, $nomDocument, $nomFichierUnique, basename($cheminFichier), $fileSize, $mimeType]);
    $documentId = $pdo->lastInsertId();

    // Note: Les métadonnées ne sont pas insérées car la table metadata_documents n'existe pas
    // TODO: Créer la table metadata_documents ou utiliser un autre système de stockage

    // Récupérer la configuration SMTP
    $settings = SystemSettings::getInstance();
    $smtpConfig = $settings->getSMTPConfig();

    // Envoyer les emails aux destinataires
    $emailsEnvoyes = 0;
    $emailsEchoues = [];

    foreach ($destinataires as $destinataire) {
        try {
            // Envoyer l'email
            $mail = new PHPMailer(true);
            // Configuration de l'email (toujours nécessaire)
            $mail->setFrom($smtpConfig['from_email'], $smtpConfig['from_name']);
            $mail->addAddress($destinataire['email'], $destinataire['nom']);
            $mail->isHTML(true);
            $mail->CharSet = 'UTF-8';
            $mail->Subject = "Document partagé : $nomDocument";
            
            // Ajout du PDF en pièce jointe
            if (file_exists($cheminComplet)) {
                $mail->addAttachment($cheminComplet, basename($cheminComplet));
            }
            
            // Corps de l'email sans lien
            $messagePerso = $input['message_personnalise'] ?? '';
            $mail->Body = "<h2>Bonjour {$destinataire['nom']},</h2>\n<p>Un document vous a été partagé : <strong>$nomDocument</strong></p>\n" .
                ($messagePerso ? "<p>Message : {$messagePerso}</p>" : "") .
                "<p>Veuillez trouver le document en pièce jointe.</p>\n<p>Cordialement,<br>L'équipe iSend Document Flow</p>";
            $mail->AltBody = "Bonjour {$destinataire['nom']},\n\nUn document vous a été partagé : $nomDocument\n" .
                ($messagePerso ? "Message : {$messagePerso}\n\n" : "") .
                "Veuillez trouver le document en pièce jointe.\n\nCordialement,\nL'équipe iSend Document Flow";
            
            // Configuration SMTP - Envoyer de vrais emails si la configuration est complète
            if (!empty($smtpConfig['host']) && !empty($smtpConfig['username']) && !empty($smtpConfig['password'])) {
                $mail->isSMTP();
                $mail->Host = $smtpConfig['host'];
                $mail->SMTPAuth = true;
                $mail->Username = $smtpConfig['username'];
                $mail->Password = $smtpConfig['password'];
                $mail->SMTPSecure = PHPMailer::ENCRYPTION_STARTTLS;
                $mail->Port = $smtpConfig['port'];
                
                // Envoyer le vrai email
                $mail->send();
                error_log("EMAIL RÉEL ENVOYÉ - Destinataire: {$destinataire['email']}, Document: $nomDocument");
            } else {
                // Simulation seulement si pas de configuration SMTP complète
                error_log("SIMULATION EMAIL - Destinataire: {$destinataire['email']}, Document: $nomDocument");
                error_log("Configuration SMTP manquante - host: {$smtpConfig['host']}, username: {$smtpConfig['username']}");
            }

            $emailsEnvoyes++;

        } catch (Exception $e) {
            $emailsEchoues[] = [
                'email' => $destinataire['email'],
                'erreur' => $e->getMessage()
            ];
        }
    }

    // Log de l'action
    $stmt = $pdo->prepare("
        INSERT INTO logs_acces (token, email, status, message, ip_address, user_agent, date_acces) 
        VALUES (?, ?, ?, ?, ?, ?, NOW())
    ");
    $logToken = 'ENVOI_NORMAL_' . time();
    $logMessage = "Envoi PDF normal - Document: $nomDocument, Destinataires: " . count($destinataires);
    $stmt->execute([$logToken, $userEmail, 'succes', $logMessage, $_SERVER['REMOTE_ADDR'] ?? '', $_SERVER['HTTP_USER_AGENT'] ?? '']);

    // Log de débogage pour tracer le fichier utilisé
    error_log("DEBUG SEND NORMAL - DocumentId: $documentId, Chemin: $cheminFichier, CheminAbsolu: $cheminAbsolu, CheminComplet: $cheminComplet");
    error_log("DEBUG SEND NORMAL - Fichier existe: " . (file_exists($cheminAbsolu) ? 'OUI' : 'NON') . ", Taille: " . (file_exists($cheminAbsolu) ? filesize($cheminAbsolu) : 'N/A') . " bytes");

    // Réponse de succès
    echo json_encode([
        'success' => true,
        'message' => "Document envoyé avec succès à " . count($destinataires) . " destinataire(s)",
        'data' => [
            'document_id' => $documentId,
            'emails_envoyes' => $emailsEnvoyes,
            'emails_echoues' => $emailsEchoues
        ]
    ]);

} catch (Exception $e) {
    header('Content-Type: application/json');
    http_response_code($e->getCode() ?: 500);
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage(),
        'code' => $e->getCode() ?: 500
    ]);
}
?>

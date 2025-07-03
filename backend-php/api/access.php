<?php
// ini_set('display_errors', 1);
// error_reporting(E_ALL);
/**
 * API d'accès aux documents - iSend Document Flow
 * Vérifie les permissions et retourne le document PDF
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Gestion des requêtes OPTIONS (CORS)
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

require_once '../includes/db.php';
require_once '../includes/jwt.php';

try {
    switch ($_SERVER['REQUEST_METHOD']) {
        case 'GET':
            $action = $_GET['action'] ?? 'download';
            
            switch ($action) {
                case 'metadata':
                    handleGetMetadata();
                    break;
                case 'security':
                    handleGetSecurityInfo();
                    break;
                case 'view':
                    handleViewDocument();
                    break;
                default:
                    handleGetDocument();
                    break;
            }
            break;
        case 'POST':
            handleVerifyAccess();
            break;
        default:
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
 * Récupération d'un document via token et email
 */
function handleGetDocument() {
    $token = $_GET['token'] ?? null;
    $email = $_GET['email'] ?? null;
    
    if (!$token || !$email) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Token et email requis'
        ]);
        return;
    }
    
    $access_result = verifyDocumentAccess($token, $email);
    
    if (!$access_result['success']) {
        http_response_code(403);
        echo json_encode($access_result);
        return;
    }
    
    $document = $access_result['document'];
    $filepath = '../uploads/' . $document['fichier_path'];
    
    // Vérification que le fichier existe
    if (!file_exists($filepath)) {
        http_response_code(404);
        echo json_encode([
            'success' => false,
            'message' => 'Fichier non trouvé'
        ]);
        return;
    }
    
    // Mise à jour du nombre d'accès
    updateAccessCount($token);
    
    // Retour du fichier PDF
    header('Content-Type: application/pdf');
    header('Content-Disposition: inline; filename="' . $document['fichier_original'] . '"');
    header('Content-Length: ' . filesize($filepath));
    header('Cache-Control: no-cache, must-revalidate');
    header('Pragma: no-cache');
    
    readfile($filepath);
    exit;
}

/**
 * Affichage d'un document dans un iframe (pour la visionneuse)
 */
function handleViewDocument() {
    $token = $_GET['token'] ?? null;
    $email = $_GET['email'] ?? null;
    
    if (!$token || !$email) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Token et email requis'
        ]);
        return;
    }
    
    $access_result = verifyDocumentAccess($token, $email);
    
    if (!$access_result['success']) {
        http_response_code(403);
        echo json_encode($access_result);
        return;
    }
    
    $document = $access_result['data']['document'];
    $filepath = '../uploads/' . $document['chemin_fichier'];
    
    // Vérification que le fichier existe
    if (!file_exists($filepath)) {
        http_response_code(404);
        echo json_encode([
            'success' => false,
            'message' => 'Fichier non trouvé'
        ]);
        return;
    }
    
    // Mise à jour du nombre d'accès
    updateAccessCount($token);
    
    // Retour du fichier PDF pour affichage dans iframe
    header('Content-Type: application/pdf');
    header('Content-Disposition: inline; filename="' . $document['nom_fichier'] . '"');
    header('Content-Length: ' . filesize($filepath));
    header('Cache-Control: no-cache, must-revalidate');
    header('Pragma: no-cache');
    header('X-Frame-Options: SAMEORIGIN'); // Permettre l'affichage dans iframe
    
    readfile($filepath);
    exit;
}

/**
 * Vérification de l'accès à un document
 */
function handleVerifyAccess() {
    $input = json_decode(file_get_contents('php://input'), true);
    
    if (!$input) {
        throw new Exception('Données JSON invalides');
    }
    
    $token = $input['token'] ?? null;
    $email = $input['email'] ?? null;
    
    if (!$token || !$email) {
        throw new Exception('Token et email requis');
    }
    
    $result = verifyDocumentAccess($token, $email);
    
    if ($result['success']) {
        // Mise à jour du nombre d'accès
        updateAccessCount($token);
    }
    
    echo json_encode($result);
}

/**
 * Vérification de l'accès à un document
 */
function verifyDocumentAccess($token, $email) {
    $db = getDB();
    
    // Vérification du lien d'accès
    $stmt = $db->prepare("
        SELECT l.*, d.nom, d.description, d.fichier_path, d.fichier_original, d.taille,
               u.nom as user_nom, u.prenom as user_prenom
        FROM liens l
        JOIN documents d ON l.document_id = d.id
        JOIN users u ON d.user_id = u.id
        WHERE l.token = ? AND l.email = ? AND l.status = 'actif'
    ");
    $stmt->execute([$token, $email]);
    $link = $stmt->fetch();
    
    if (!$link) {
        logAccess($token, $email, 'refuse', 'Lien invalide ou expiré');
        return [
            'success' => false,
            'message' => 'Lien invalide ou expiré'
        ];
    }
    
    // Vérification de l'expiration
    if ($link['date_expiration'] && strtotime($link['date_expiration']) < time()) {
        // Marquer le lien comme expiré
        $stmt = $db->prepare("UPDATE liens SET status = 'expire' WHERE token = ?");
        $stmt->execute([$token]);
        
        logAccess($token, $email, 'refuse', 'Lien expiré');
        return [
            'success' => false,
            'message' => 'Lien expiré'
        ];
    }
    
    // Vérification que le document est actif
    if ($link['status'] !== 'actif') {
        logAccess($token, $email, 'refuse', 'Document non disponible');
        return [
            'success' => false,
            'message' => 'Document non disponible'
        ];
    }
    
    // On récupère l'abonne_id du document
    $stmt = $db->prepare("SELECT abonne_id FROM documents WHERE id = ?");
    $stmt->execute([$link['document_id']]);
    $docRow = $stmt->fetch();
    $abonne_id = $docRow ? $docRow['abonne_id'] : null;
    error_log("DEBUG ACCESS: abonne_id utilisé pour vérification abonnement: " . $abonne_id);
    $stmt = $db->prepare("
        SELECT status, date_fin
        FROM abonnements 
        WHERE abonne_id = ? AND status = 'actif' AND (date_fin IS NULL OR date_fin > NOW())
        ORDER BY date_debut DESC
        LIMIT 1
    ");
    $stmt->execute([$abonne_id]);
    $subscription = $stmt->fetch();
    error_log("DEBUG ACCESS: résultat abonnement: " . json_encode($subscription));
    
    if (!$subscription) {
        logAccess($token, $email, 'refuse', 'Abonnement expiré');
        return [
            'success' => false,
            'message' => 'Accès temporairement indisponible'
        ];
    }
    
    // Journalisation de l'accès réussi
    logAccess($token, $email, 'succes', 'Accès autorisé');
    
    return [
        'success' => true,
        'message' => 'Accès autorisé',
        'data' => [
            'document' => [
                'id' => $link['document_id'],
                'titre' => $link['nom'],
                'nom_fichier' => $link['fichier_original'],
                'description' => $link['description'],
                'chemin_fichier' => $link['fichier_path'],
                'taille' => $link['taille'],
                'expediteur' => $link['user_nom'] . ' ' . $link['user_prenom']
            ],
            'access_info' => [
                'date_creation' => $link['date_creation'],
                'date_expiration' => $link['date_expiration'],
                'nombre_acces' => $link['nombre_acces'] + 1
            ]
        ]
    ];
}

/**
 * Mise à jour du compteur d'accès
 */
function updateAccessCount($token) {
    $db = getDB();
    
    $stmt = $db->prepare("
        UPDATE liens 
        SET nombre_acces = nombre_acces + 1, date_derniere_utilisation = NOW()
        WHERE token = ?
    ");
    $stmt->execute([$token]);
}

/**
 * Journalisation des accès
 */
function logAccess($token, $email, $status, $message) {
    $db = getDB();
    
    $stmt = $db->prepare("
        INSERT INTO logs_acces (token, email, status, message, ip_address, user_agent)
        VALUES (?, ?, ?, ?, ?, ?)
    ");
    $stmt->execute([
        $token,
        $email,
        $status,
        $message,
        $_SERVER['REMOTE_ADDR'] ?? '',
        $_SERVER['HTTP_USER_AGENT'] ?? ''
    ]);
}

/**
 * Vérification JWT du token (alternative)
 */
function verifyJWTAccess($token) {
    try {
        $payload = JWTManager::verifyToken($token);
        
        if (!$payload) {
            return false;
        }
        
        // Vérification que c'est un token d'accès document
        if (!isset($payload['type']) || $payload['type'] !== 'document_access') {
            return false;
        }
        
        // Vérification de l'expiration
        if (isset($payload['exp']) && $payload['exp'] < time()) {
            return false;
        }
        
        return $payload;
    } catch (Exception $e) {
        return false;
    }
}

/**
 * Récupération des métadonnées d'un document
 */
function handleGetMetadata() {
    $token = $_GET['token'] ?? null;
    $email = $_GET['email'] ?? null;
    
    if (!$token || !$email) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Token et email requis'
        ]);
        return;
    }
    
    $access_result = verifyDocumentAccess($token, $email);
    
    if (!$access_result['success']) {
        http_response_code(403);
        echo json_encode($access_result);
        return;
    }
    
    $document = $access_result['data']['document'];
    
    // Extraction de l'extension du fichier
    $extension = pathinfo($document['nom_fichier'], PATHINFO_EXTENSION);
    
    echo json_encode([
        'success' => true,
        'data' => [
            'titre' => $document['titre'],
            'description' => $document['description'],
            'date_upload' => $access_result['data']['access_info']['date_creation'],
            'taille' => $document['taille'],
            'format' => strtoupper($extension),
            'tags' => $document['tags'] ? explode(',', $document['tags']) : []
        ]
    ]);
}

/**
 * Récupération des informations de sécurité d'un document
 */
function handleGetSecurityInfo() {
    $token = $_GET['token'] ?? null;
    $email = $_GET['email'] ?? null;
    
    if (!$token || !$email) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Token et email requis'
        ]);
        return;
    }
    
    $access_result = verifyDocumentAccess($token, $email);
    
    if (!$access_result['success']) {
        http_response_code(403);
        echo json_encode($access_result);
        return;
    }
    
    $access_info = $access_result['data']['access_info'];
    
    echo json_encode([
        'success' => true,
        'data' => [
            'watermark_enabled' => true,
            'download_allowed' => true,
            'print_allowed' => false,
            'copy_allowed' => false,
            'expiration_date' => $access_info['date_expiration'],
            'access_count' => $access_info['nombre_acces'],
            'max_access_count' => null
        ]
    ]);
}
?> 
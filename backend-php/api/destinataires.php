<?php
/**
 * API de gestion des destinataires - iSend Document Flow
 * CRUD complet des destinataires avec vérification d'abonnement
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Gestion des requêtes OPTIONS (CORS)
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

require_once '../includes/db.php';
require_once '../includes/jwt.php';

// Authentification requise
$user = requireAuth();

try {
    switch ($_SERVER['REQUEST_METHOD']) {
        case 'GET':
            handleGetDestinataires($user);
            break;
        case 'POST':
            handleCreateDestinataire($user);
            break;
        case 'PUT':
            handleUpdateDestinataire($user);
            break;
        case 'DELETE':
            handleDeleteDestinataire($user);
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
 * Vérification de l'abonnement de l'utilisateur
 */
function checkSubscription($user_id) {
    $db = getDB();
    
    $stmt = $db->prepare("
        SELECT type, status, limite_destinataires, date_fin
        FROM abonnements 
        WHERE user_id = ? AND status = 'actif' AND (date_fin IS NULL OR date_fin > NOW())
        ORDER BY date_creation DESC 
        LIMIT 1
    ");
    $stmt->execute([$user_id]);
    $subscription = $stmt->fetch();
    
    if (!$subscription) {
        // Créer un abonnement gratuit par défaut
        $stmt = $db->prepare("
            INSERT INTO abonnements (user_id, type, status, limite_destinataires)
            VALUES (?, 'gratuit', 'actif', 10)
        ");
        $stmt->execute([$user_id]);
        
        return [
            'type' => 'gratuit',
            'status' => 'actif',
            'limite_destinataires' => 10,
            'date_fin' => null
        ];
    }
    
    return $subscription;
}

/**
 * Récupération des destinataires de l'utilisateur
 */
function handleGetDestinataires($user) {
    $db = getDB();
    
    $destinataire_id = $_GET['id'] ?? null;
    
    if ($destinataire_id) {
        // Récupération d'un destinataire spécifique
        $stmt = $db->prepare("
            SELECT id, nom, prenom, email, numero, entreprise, status, 
                   date_expiration, date_ajout, date_modification
            FROM abonnes 
            WHERE id = ? AND user_id = ? AND status != 'expire'
        ");
        $stmt->execute([$destinataire_id, $user['user_id']]);
        $destinataire = $stmt->fetch();
        
        if (!$destinataire) {
            http_response_code(404);
            echo json_encode([
                'success' => false,
                'message' => 'Destinataire non trouvé'
            ]);
            return;
        }
        
        echo json_encode([
            'success' => true,
            'data' => $destinataire
        ]);
    } else {
        // Récupération de tous les destinataires
        $stmt = $db->prepare("
            SELECT id, nom, prenom, email, numero, entreprise, status, 
                   date_expiration, date_ajout, date_modification
            FROM abonnes 
            WHERE user_id = ? AND status != 'expire'
            ORDER BY date_ajout DESC
        ");
        $stmt->execute([$user['user_id']]);
        $destinataires = $stmt->fetchAll();
        
        echo json_encode([
            'success' => true,
            'data' => $destinataires
        ]);
    }
}

/**
 * Création d'un nouveau destinataire
 */
function handleCreateDestinataire($user) {
    $input = json_decode(file_get_contents('php://input'), true);
    
    if (!$input) {
        throw new Exception('Données JSON invalides');
    }
    
    // Validation des données
    $required_fields = ['nom', 'prenom', 'email'];
    foreach ($required_fields as $field) {
        if (empty($input[$field])) {
            throw new Exception("Le champ '$field' est requis");
        }
    }
    
    // Validation de l'email
    if (!filter_var($input['email'], FILTER_VALIDATE_EMAIL)) {
        throw new Exception('Format d\'email invalide');
    }
    
    $db = getDB();
    
    // Vérification de l'abonnement
    $subscription = checkSubscription($user['user_id']);
    
    // Vérification de la limite de destinataires
    $stmt = $db->prepare("
        SELECT COUNT(*) as count 
        FROM abonnes 
        WHERE user_id = ? AND status = 'actif'
    ");
    $stmt->execute([$user['user_id']]);
    $count = $stmt->fetch()['count'];
    
    if ($count >= $subscription['limite_destinataires']) {
        throw new Exception('Limite de destinataires atteinte pour votre abonnement');
    }
    
    // Vérification si l'email existe déjà pour cet utilisateur
    $stmt = $db->prepare("
        SELECT id FROM abonnes 
        WHERE user_id = ? AND email = ? AND status != 'expire'
    ");
    $stmt->execute([$user['user_id'], $input['email']]);
    
    if ($stmt->fetch()) {
        throw new Exception('Cet email existe déjà dans vos destinataires');
    }
    
    // Insertion du destinataire
    $stmt = $db->prepare("
        INSERT INTO abonnes (user_id, nom, prenom, email, numero, entreprise, status)
        VALUES (?, ?, ?, ?, ?, ?, 'actif')
    ");
    
    $stmt->execute([
        $user['user_id'],
        $input['nom'],
        $input['prenom'],
        $input['email'],
        $input['numero'] ?? null,
        $input['entreprise'] ?? null
    ]);
    
    $destinataire_id = $db->lastInsertId();
    
    // Récupération du destinataire créé
    $stmt = $db->prepare("
        SELECT id, nom, prenom, email, numero, entreprise, status, date_ajout
        FROM abonnes 
        WHERE id = ?
    ");
    $stmt->execute([$destinataire_id]);
    $destinataire = $stmt->fetch();
    
    echo json_encode([
        'success' => true,
        'message' => 'Destinataire créé avec succès',
        'data' => $destinataire
    ]);
}

/**
 * Mise à jour d'un destinataire
 */
function handleUpdateDestinataire($user) {
    $input = json_decode(file_get_contents('php://input'), true);
    
    if (!$input || empty($input['id'])) {
        throw new Exception('ID du destinataire requis');
    }
    
    $db = getDB();
    
    // Vérification que le destinataire appartient à l'utilisateur
    $stmt = $db->prepare("
        SELECT id FROM abonnes 
        WHERE id = ? AND user_id = ? AND status != 'expire'
    ");
    $stmt->execute([$input['id'], $user['user_id']]);
    
    if (!$stmt->fetch()) {
        http_response_code(404);
        echo json_encode([
            'success' => false,
            'message' => 'Destinataire non trouvé'
        ]);
        return;
    }
    
    // Construction de la requête de mise à jour
    $update_fields = [];
    $params = [];
    
    if (isset($input['nom'])) {
        $update_fields[] = 'nom = ?';
        $params[] = $input['nom'];
    }
    
    if (isset($input['prenom'])) {
        $update_fields[] = 'prenom = ?';
        $params[] = $input['prenom'];
    }
    
    if (isset($input['email'])) {
        if (!filter_var($input['email'], FILTER_VALIDATE_EMAIL)) {
            throw new Exception('Format d\'email invalide');
        }
        $update_fields[] = 'email = ?';
        $params[] = $input['email'];
    }
    
    if (isset($input['numero'])) {
        $update_fields[] = 'numero = ?';
        $params[] = $input['numero'];
    }
    
    if (isset($input['entreprise'])) {
        $update_fields[] = 'entreprise = ?';
        $params[] = $input['entreprise'];
    }
    
    if (isset($input['status'])) {
        $update_fields[] = 'status = ?';
        $params[] = $input['status'];
    }
    
    if (isset($input['date_expiration'])) {
        $update_fields[] = 'date_expiration = ?';
        $params[] = $input['date_expiration'];
    }
    
    if (empty($update_fields)) {
        throw new Exception('Aucun champ à mettre à jour');
    }
    
    $params[] = $input['id'];
    $params[] = $user['user_id'];
    
    $sql = "UPDATE abonnes SET " . implode(', ', $update_fields) . 
           ", date_modification = NOW() WHERE id = ? AND user_id = ?";
    
    $stmt = $db->prepare($sql);
    $stmt->execute($params);
    
    echo json_encode([
        'success' => true,
        'message' => 'Destinataire mis à jour avec succès'
    ]);
}

/**
 * Suppression d'un destinataire (soft delete)
 */
function handleDeleteDestinataire($user) {
    $destinataire_id = $_GET['id'] ?? null;
    
    if (!$destinataire_id) {
        throw new Exception('ID du destinataire requis');
    }
    
    $db = getDB();
    
    // Vérification que le destinataire appartient à l'utilisateur
    $stmt = $db->prepare("
        SELECT id FROM abonnes 
        WHERE id = ? AND user_id = ? AND status != 'expire'
    ");
    $stmt->execute([$destinataire_id, $user['user_id']]);
    
    if (!$stmt->fetch()) {
        http_response_code(404);
        echo json_encode([
            'success' => false,
            'message' => 'Destinataire non trouvé'
        ]);
        return;
    }
    
    // Soft delete
    $stmt = $db->prepare("
        UPDATE abonnes 
        SET status = 'expire', date_modification = NOW() 
        WHERE id = ? AND user_id = ?
    ");
    $stmt->execute([$destinataire_id, $user['user_id']]);
    
    echo json_encode([
        'success' => true,
        'message' => 'Destinataire supprimé avec succès'
    ]);
}
?> 
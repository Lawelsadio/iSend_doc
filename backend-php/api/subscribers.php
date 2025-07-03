<?php
/**
 * API de gestion des abonnés - iSend Document Flow
 * CRUD complet avec sécurité multi-tenant
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

// Vérification de la méthode HTTP
if (!in_array($_SERVER['REQUEST_METHOD'], ['GET', 'POST', 'PUT', 'DELETE'])) {
    http_response_code(405);
    echo json_encode([
        'success' => false,
        'message' => 'Méthode non autorisée'
    ]);
    exit;
}

try {
    switch ($_SERVER['REQUEST_METHOD']) {
        case 'GET':
            handleGetSubscribers($user);
            break;
        case 'POST':
            handleCreateSubscriber($user);
            break;
        case 'PUT':
            handleUpdateSubscriber($user);
            break;
        case 'DELETE':
            handleDeleteSubscriber($user);
            break;
    }
    
} catch (Exception $e) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ]);
}

/**
 * Récupérer tous les abonnés de l'utilisateur
 */
function handleGetSubscribers($user) {
    $db = getDB();
    
    // Récupérer les abonnés avec statistiques
    $stmt = $db->prepare("
        SELECT 
            d.id,
            d.nom,
            d.prenom,
            d.email,
            d.numero as telephone,
            d.status,
            d.date_ajout,
            COUNT(DISTINCT l.document_id) as documents_recus,
            MAX(l.date_creation) as dernier_envoi
        FROM abonnes d
        LEFT JOIN liens l ON d.email = l.email AND l.document_id IN (
            SELECT id FROM documents WHERE user_id = ?
        )
        WHERE d.user_id = ?
        GROUP BY d.id
        ORDER BY d.date_ajout DESC
    ");
    $stmt->execute([$user['user_id'], $user['user_id']]);
    $subscribers = $stmt->fetchAll();
    
    // Statistiques
    $total = count($subscribers);
    $actifs = count(array_filter($subscribers, fn($s) => $s['status'] === 'actif'));
    $expires = $total - $actifs;
    
    echo json_encode([
        'success' => true,
        'data' => [
            'subscribers' => $subscribers,
            'stats' => [
                'total' => $total,
                'actifs' => $actifs,
                'expires' => $expires
            ]
        ]
    ]);
}

/**
 * Créer un nouvel abonné
 */
function handleCreateSubscriber($user) {
    $raw_input = file_get_contents('php://input');
    $input = json_decode($raw_input, true);
    
    // Si JSON a échoué, essayer avec $_POST (fallback)
    if (!$input && !empty($_POST)) {
        $input = $_POST;
    }
    
    // Validation des données
    if (!$input || !isset($input['nom']) || !isset($input['prenom']) || !isset($input['email'])) {
        $error_msg = 'Données invalides reçues';
        if (!$input) {
            $error_msg .= ' - JSON decode failed';
        } else {
            $error_msg .= ' - Champs manquants: ' . implode(', ', array_keys($input));
        }
        throw new Exception($error_msg);
    }
    
    $nom = trim($input['nom']);
    $prenom = trim($input['prenom']);
    $email = trim($input['email']);
    $numero = trim($input['telephone'] ?? '');
    
    // Validation de l'email
    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        throw new Exception('Adresse email invalide');
    }
    
    $db = getDB();
    
    // Vérifier si l'email existe déjà pour cet utilisateur
    $stmt = $db->prepare("SELECT id FROM abonnes WHERE email = ? AND user_id = ?");
    $stmt->execute([$email, $user['user_id']]);
    if ($stmt->fetch()) {
        throw new Exception('Cette adresse email est déjà utilisée');
    }
    
    // Insérer le nouvel abonné
    $stmt = $db->prepare("
        INSERT INTO abonnes (user_id, nom, prenom, email, numero, status, date_ajout)
        VALUES (?, ?, ?, ?, ?, 'actif', NOW())
    ");
    $stmt->execute([$user['user_id'], $nom, $prenom, $email, $numero]);
    
    $subscriber_id = $db->lastInsertId();
    
    // Récupérer l'abonné créé
    $stmt = $db->prepare("
        SELECT 
            id, nom, prenom, email, numero as telephone, status, date_ajout
        FROM abonnes 
        WHERE id = ?
    ");
    $stmt->execute([$subscriber_id]);
    $subscriber = $stmt->fetch();
    
    echo json_encode([
        'success' => true,
        'message' => 'Abonné créé avec succès',
        'data' => $subscriber
    ]);
}

/**
 * Mettre à jour un abonné
 */
function handleUpdateSubscriber($user) {
    $input = json_decode(file_get_contents('php://input'), true);
    
    if (!isset($input['id'])) {
        throw new Exception('ID de l\'abonné requis');
    }
    
    $subscriber_id = $input['id'];
    $nom = trim($input['nom'] ?? '');
    $prenom = trim($input['prenom'] ?? '');
    $email = trim($input['email'] ?? '');
    $numero = trim($input['telephone'] ?? '');
    $status = $input['status'] ?? null;
    
    $db = getDB();
    
    // Vérifier que l'abonné appartient à l'utilisateur
    $stmt = $db->prepare("SELECT id FROM abonnes WHERE id = ? AND user_id = ?");
    $stmt->execute([$subscriber_id, $user['user_id']]);
    if (!$stmt->fetch()) {
        throw new Exception('Abonné non trouvé');
    }
    
    // Vérifier si l'email existe déjà (sauf pour cet abonné)
    if ($email) {
        $stmt = $db->prepare("SELECT id FROM abonnes WHERE email = ? AND user_id = ? AND id != ?");
        $stmt->execute([$email, $user['user_id'], $subscriber_id]);
        if ($stmt->fetch()) {
            throw new Exception('Cette adresse email est déjà utilisée');
        }
    }
    
    // Construire la requête de mise à jour
    $updates = [];
    $params = [];
    
    if ($nom) {
        $updates[] = "nom = ?";
        $params[] = $nom;
    }
    if ($prenom) {
        $updates[] = "prenom = ?";
        $params[] = $prenom;
    }
    if ($email) {
        $updates[] = "email = ?";
        $params[] = $email;
    }
    if ($numero !== '') {
        $updates[] = "numero = ?";
        $params[] = $numero;
    }
    if ($status) {
        $updates[] = "status = ?";
        $params[] = $status;
    }
    
    if (empty($updates)) {
        throw new Exception('Aucune donnée à mettre à jour');
    }
    
    $params[] = $subscriber_id;
    $params[] = $user['user_id'];
    
    $sql = "UPDATE abonnes SET " . implode(', ', $updates) . " WHERE id = ? AND user_id = ?";
    $stmt = $db->prepare($sql);
    $stmt->execute($params);
    
    // Récupérer l'abonné mis à jour
    $stmt = $db->prepare("
        SELECT 
            id, nom, prenom, email, numero as telephone, status, date_ajout
        FROM abonnes 
        WHERE id = ?
    ");
    $stmt->execute([$subscriber_id]);
    $subscriber = $stmt->fetch();
    
    echo json_encode([
        'success' => true,
        'message' => 'Abonné mis à jour avec succès',
        'data' => $subscriber
    ]);
}

/**
 * Supprimer un abonné
 */
function handleDeleteSubscriber($user) {
    $input = json_decode(file_get_contents('php://input'), true);
    
    if (!isset($input['id'])) {
        throw new Exception('ID de l\'abonné requis');
    }
    
    $subscriber_id = $input['id'];
    
    $db = getDB();
    
    // Vérifier que l'abonné appartient à l'utilisateur
    $stmt = $db->prepare("SELECT id FROM abonnes WHERE id = ? AND user_id = ?");
    $stmt->execute([$subscriber_id, $user['user_id']]);
    if (!$stmt->fetch()) {
        throw new Exception('Abonné non trouvé');
    }
    
    // Supprimer définitivement l'abonné (hard delete)
    $stmt = $db->prepare("DELETE FROM abonnes WHERE id = ? AND user_id = ?");
    $stmt->execute([$subscriber_id, $user['user_id']]);
    
    echo json_encode([
        'success' => true,
        'message' => 'Abonné supprimé avec succès'
    ]);
}
?> 
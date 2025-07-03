<?php
/**
 * API d'administration des abonnements - iSend Document Flow
 * Gestion complète des abonnements avec vérification des droits admin
 */

// Headers CORS - DOIT être en premier
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
header('Content-Type: application/json');

// Gestion des requêtes OPTIONS (CORS)
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

require_once '../includes/db.php';
require_once '../includes/jwt.php';

// Authentification requise
$user = requireAuth();

// Vérification des droits admin
if ($user['role'] !== 'admin') {
    http_response_code(403);
    echo json_encode([
        'success' => false,
        'message' => 'Accès refusé - Droits administrateur requis'
    ]);
    exit;
}

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
            handleGetSubscriptions();
            break;
        case 'POST':
            handleCreateSubscription();
            break;
        case 'PUT':
            handleUpdateSubscription();
            break;
        case 'DELETE':
            handleDeleteSubscription();
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
 * Récupérer tous les abonnements
 */
function handleGetSubscriptions() {
    $db = getDB();
    
    $stmt = $db->prepare("
        SELECT 
            a.id,
            a.abonne_id,
            a.type,
            a.status,
            a.limite_documents,
            a.limite_destinataires,
            a.date_debut,
            a.date_fin,
            a.date_creation,
            u.nom,
            u.prenom,
            u.email
        FROM abonnements a
        LEFT JOIN users u ON a.abonne_id = u.id
        ORDER BY a.date_creation DESC
    ");
    $stmt->execute();
    $subscriptions = $stmt->fetchAll();
    
    echo json_encode([
        'success' => true,
        'data' => $subscriptions
    ]);
}

/**
 * Créer un nouvel abonnement
 */
function handleCreateSubscription() {
    $input = json_decode(file_get_contents('php://input'), true);
    
    // Validation des données
    if (!isset($input['abonne_id']) || !isset($input['type'])) {
        throw new Exception('ID abonné et type d\'abonnement sont requis');
    }
    
    $abonne_id = $input['abonne_id'];
    $type = $input['type'];
    $status = $input['status'] ?? 'actif';
    $limite_documents = $input['limite_documents'] ?? 100;
    $limite_destinataires = $input['limite_destinataires'] ?? 50;
    $date_debut = $input['date_debut'] ?? date('Y-m-d');
    $date_fin = $input['date_fin'] ?? null;
    
    // Convertir les chaînes vides en null pour date_fin
    if ($date_fin === '') {
        $date_fin = null;
    }
    
    // Validation du type d'abonnement
    if (!in_array($type, ['gratuit', 'premium', 'entreprise', 'illimite'])) {
        throw new Exception('Type d\'abonnement invalide');
    }
    
    // Validation du statut
    if (!in_array($status, ['actif', 'expire', 'annule'])) {
        throw new Exception('Statut invalide');
    }
    
    // Validation des limites (permettre -1 pour illimité)
    if ($type === 'illimite') {
        $limite_documents = -1;
        $limite_destinataires = -1;
    } else {
        if ($limite_documents < 0 || $limite_destinataires < 0) {
            throw new Exception('Les limites doivent être positives');
        }
    }
    
    // Validation des dates
    if ($date_fin && strtotime($date_fin) <= strtotime($date_debut)) {
        throw new Exception('La date de fin doit être postérieure à la date de début');
    }
    
    $db = getDB();
    
    // Vérifier que l'abonné existe
    $stmt = $db->prepare("SELECT id FROM users WHERE id = ?");
    $stmt->execute([$abonne_id]);
    if (!$stmt->fetch()) {
        throw new Exception('Abonné non trouvé');
    }
    
    // Désactiver les autres abonnements actifs de l'abonné
    $stmt = $db->prepare("UPDATE abonnements SET status = 'annule' WHERE abonne_id = ? AND status = 'actif'");
    $stmt->execute([$abonne_id]);
    
    // Insérer le nouvel abonnement
    $stmt = $db->prepare("
        INSERT INTO abonnements (abonne_id, type, status, limite_documents, limite_destinataires, date_debut, date_fin, date_creation)
        VALUES (?, ?, ?, ?, ?, ?, ?, NOW())
    ");
    $stmt->execute([$abonne_id, $type, $status, $limite_documents, $limite_destinataires, $date_debut, $date_fin]);
    
    $subscription_id = $db->lastInsertId();
    
    // Récupérer l'abonnement créé
    $stmt = $db->prepare("
        SELECT 
            id, abonne_id, type, status, limite_documents, limite_destinataires, date_debut, date_fin, date_creation
        FROM abonnements 
        WHERE id = ?
    ");
    $stmt->execute([$subscription_id]);
    $subscription = $stmt->fetch();
    
    echo json_encode([
        'success' => true,
        'message' => 'Abonnement créé avec succès',
        'data' => $subscription
    ]);
}

/**
 * Mettre à jour un abonnement
 */
function handleUpdateSubscription() {
    $input = json_decode(file_get_contents('php://input'), true);
    
    if (!isset($input['id'])) {
        throw new Exception('ID de l\'abonnement requis');
    }
    
    $subscription_id = $input['id'];
    $type = $input['type'] ?? '';
    $status = $input['status'] ?? '';
    $limite_documents = $input['limite_documents'] ?? null;
    $limite_destinataires = $input['limite_destinataires'] ?? null;
    $date_debut = $input['date_debut'] ?? '';
    $date_fin = $input['date_fin'] ?? '';
    
    // Convertir les chaînes vides en null pour date_fin
    if ($date_fin === '') {
        $date_fin = null;
    }
    
    $db = getDB();
    
    // Vérifier que l'abonnement existe
    $stmt = $db->prepare("SELECT id FROM abonnements WHERE id = ?");
    $stmt->execute([$subscription_id]);
    if (!$stmt->fetch()) {
        throw new Exception('Abonnement non trouvé');
    }
    
    // Construire la requête de mise à jour
    $updates = [];
    $params = [];
    
    if ($type && in_array($type, ['gratuit', 'premium', 'entreprise', 'illimite'])) {
        $updates[] = "type = ?";
        $params[] = $type;
    }
    
    if ($status && in_array($status, ['actif', 'expire', 'annule'])) {
        $updates[] = "status = ?";
        $params[] = $status;
    }
    
    if ($limite_documents !== null && $limite_documents >= 0) {
        $updates[] = "limite_documents = ?";
        $params[] = $limite_documents;
    }
    
    if ($limite_destinataires !== null && $limite_destinataires >= 0) {
        $updates[] = "limite_destinataires = ?";
        $params[] = $limite_destinataires;
    }
    
    if ($date_debut) {
        $updates[] = "date_debut = ?";
        $params[] = $date_debut;
    }
    
    if ($date_fin !== '') {
        $updates[] = "date_fin = ?";
        $params[] = $date_fin ?: null;
    }
    
    if (empty($updates)) {
        throw new Exception('Aucune donnée à mettre à jour');
    }
    
    $params[] = $subscription_id;
    $sql = "UPDATE abonnements SET " . implode(', ', $updates) . " WHERE id = ?";
    $stmt = $db->prepare($sql);
    $stmt->execute($params);
    
    // Récupérer l'abonnement mis à jour
    $stmt = $db->prepare("
        SELECT 
            id, abonne_id, type, status, limite_documents, limite_destinataires, date_debut, date_fin, date_creation
        FROM abonnements 
        WHERE id = ?
    ");
    $stmt->execute([$subscription_id]);
    $subscription = $stmt->fetch();
    
    echo json_encode([
        'success' => true,
        'message' => 'Abonnement mis à jour avec succès',
        'data' => $subscription
    ]);
}

/**
 * Basculer le statut d'un abonnement
 */
function handleToggleSubscriptionStatus() {
    $input = json_decode(file_get_contents('php://input'), true);
    
    if (!isset($input['id']) || !isset($input['status'])) {
        throw new Exception('ID et statut requis');
    }
    
    $subscription_id = $input['id'];
    $newStatus = $input['status'];
    
    if (!in_array($newStatus, ['actif', 'expire', 'annule'])) {
        throw new Exception('Statut invalide');
    }
    
    $db = getDB();
    
    // Vérifier que l'abonnement existe
    $stmt = $db->prepare("SELECT id FROM abonnements WHERE id = ?");
    $stmt->execute([$subscription_id]);
    if (!$stmt->fetch()) {
        throw new Exception('Abonnement non trouvé');
    }
    
    // Mettre à jour le statut
    $stmt = $db->prepare("UPDATE abonnements SET status = ? WHERE id = ?");
    $stmt->execute([$newStatus, $subscription_id]);
    
    // Récupérer l'abonnement mis à jour
    $stmt = $db->prepare("
        SELECT 
            id, abonne_id, type, status, limite_documents, limite_destinataires, date_debut, date_fin, date_creation
        FROM abonnements 
        WHERE id = ?
    ");
    $stmt->execute([$subscription_id]);
    $subscription = $stmt->fetch();
    
    echo json_encode([
        'success' => true,
        'message' => 'Statut mis à jour avec succès',
        'data' => $subscription
    ]);
}

/**
 * Supprimer un abonnement
 */
function handleDeleteSubscription() {
    // Récupérer l'ID depuis les paramètres GET
    $subscription_id = $_GET['id'] ?? null;
    
    if (!$subscription_id) {
        throw new Exception('ID de l\'abonnement requis');
    }
    
    $db = getDB();
    
    // Vérifier que l'abonnement existe
    $stmt = $db->prepare("SELECT id FROM abonnements WHERE id = ?");
    $stmt->execute([$subscription_id]);
    if (!$stmt->fetch()) {
        throw new Exception('Abonnement non trouvé');
    }
    
    // Hard delete - Suppression définitive de l'abonnement
    $stmt = $db->prepare("DELETE FROM abonnements WHERE id = ?");
    $stmt->execute([$subscription_id]);
    
    echo json_encode([
        'success' => true,
        'message' => 'Abonnement supprimé définitivement avec succès'
    ]);
}
?> 
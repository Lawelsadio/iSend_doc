<?php
/**
 * API d'administration des utilisateurs - iSend Document Flow
 * Gestion complète des utilisateurs avec vérification des droits admin
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
            handleGetUsers();
            break;
        case 'POST':
            handleCreateUser();
            break;
        case 'PUT':
            handleUpdateUser();
            break;
        case 'DELETE':
            handleDeleteUser();
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
 * Récupérer tous les utilisateurs
 */
function handleGetUsers() {
    $db = getDB();
    
    $stmt = $db->prepare("
        SELECT 
            id,
            nom,
            prenom,
            email,
            role,
            status,
            date_creation as date_inscription,
            derniere_connexion
        FROM users 
        ORDER BY date_creation DESC
    ");
    $stmt->execute();
    $users = $stmt->fetchAll();
    
    echo json_encode([
        'success' => true,
        'data' => $users
    ]);
}

/**
 * Créer un nouvel utilisateur
 */
function handleCreateUser() {
    $input = json_decode(file_get_contents('php://input'), true);
    
    // Validation des données
    if (!isset($input['nom']) || !isset($input['prenom']) || !isset($input['email']) || !isset($input['password'])) {
        throw new Exception('Nom, prénom, email et mot de passe sont requis');
    }
    
    $nom = trim($input['nom']);
    $prenom = trim($input['prenom']);
    $email = trim($input['email']);
    $password = $input['password'];
    $role = $input['role'] ?? 'user';
    
    // Validation de l'email
    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        throw new Exception('Adresse email invalide');
    }
    
    // Validation du mot de passe
    if (strlen($password) < 6) {
        throw new Exception('Le mot de passe doit contenir au moins 6 caractères');
    }
    
    // Validation du rôle
    if (!in_array($role, ['user', 'admin'])) {
        throw new Exception('Rôle invalide');
    }
    
    $db = getDB();
    
    // Vérifier si l'email existe déjà
    $stmt = $db->prepare("SELECT id FROM users WHERE email = ?");
    $stmt->execute([$email]);
    if ($stmt->fetch()) {
        throw new Exception('Cette adresse email est déjà utilisée');
    }
    
    // Hasher le mot de passe
    $hashedPassword = password_hash($password, PASSWORD_DEFAULT);
    
    // Insérer le nouvel utilisateur
    $stmt = $db->prepare("
        INSERT INTO users (nom, prenom, email, password, role, status, date_creation)
        VALUES (?, ?, ?, ?, ?, 'actif', NOW())
    ");
    $stmt->execute([$nom, $prenom, $email, $hashedPassword, $role]);
    
    $user_id = $db->lastInsertId();
    
    // Récupérer l'utilisateur créé
    $stmt = $db->prepare("
        SELECT 
            id, nom, prenom, email, role, status, date_creation as date_inscription
        FROM users 
        WHERE id = ?
    ");
    $stmt->execute([$user_id]);
    $user = $stmt->fetch();
    
    echo json_encode([
        'success' => true,
        'message' => 'Utilisateur créé avec succès',
        'data' => $user
    ]);
}

/**
 * Mettre à jour un utilisateur
 */
function handleUpdateUser() {
    $input = json_decode(file_get_contents('php://input'), true);
    
    if (!isset($input['id'])) {
        throw new Exception('ID de l\'utilisateur requis');
    }
    
    $user_id = $input['id'];
    $nom = trim($input['nom'] ?? '');
    $prenom = trim($input['prenom'] ?? '');
    $email = trim($input['email'] ?? '');
    $password = $input['password'] ?? '';
    $role = $input['role'] ?? '';
    $status = $input['status'] ?? '';
    
    $db = getDB();
    
    // Vérifier que l'utilisateur existe
    $stmt = $db->prepare("SELECT id FROM users WHERE id = ?");
    $stmt->execute([$user_id]);
    if (!$stmt->fetch()) {
        throw new Exception('Utilisateur non trouvé');
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
        if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
            throw new Exception('Adresse email invalide');
        }
        $updates[] = "email = ?";
        $params[] = $email;
    }
    
    if ($password) {
        if (strlen($password) < 6) {
            throw new Exception('Le mot de passe doit contenir au moins 6 caractères');
        }
        $updates[] = "password = ?";
        $params[] = password_hash($password, PASSWORD_DEFAULT);
    }
    
    if ($role && in_array($role, ['user', 'admin'])) {
        $updates[] = "role = ?";
        $params[] = $role;
    }
    
    if ($status && in_array($status, ['actif', 'inactif'])) {
        $updates[] = "status = ?";
        $params[] = $status;
    }
    
    if (empty($updates)) {
        throw new Exception('Aucune donnée à mettre à jour');
    }
    
    $params[] = $user_id;
    $sql = "UPDATE users SET " . implode(', ', $updates) . " WHERE id = ?";
    $stmt = $db->prepare($sql);
    $stmt->execute($params);
    
    // Récupérer l'utilisateur mis à jour
    $stmt = $db->prepare("
        SELECT 
            id, nom, prenom, email, role, status, date_creation as date_inscription, derniere_connexion
        FROM users 
        WHERE id = ?
    ");
    $stmt->execute([$user_id]);
    $user = $stmt->fetch();
    
    echo json_encode([
        'success' => true,
        'message' => 'Utilisateur mis à jour avec succès',
        'data' => $user
    ]);
}

/**
 * Basculer le statut d'un utilisateur
 */
function handleToggleUserStatus() {
    $input = json_decode(file_get_contents('php://input'), true);
    
    if (!isset($input['id']) || !isset($input['status'])) {
        throw new Exception('ID et statut requis');
    }
    
    $user_id = $input['id'];
    $newStatus = $input['status'];
    
    if (!in_array($newStatus, ['actif', 'inactif'])) {
        throw new Exception('Statut invalide');
    }
    
    $db = getDB();
    
    // Vérifier que l'utilisateur existe
    $stmt = $db->prepare("SELECT id FROM users WHERE id = ?");
    $stmt->execute([$user_id]);
    if (!$stmt->fetch()) {
        throw new Exception('Utilisateur non trouvé');
    }
    
    // Mettre à jour le statut
    $stmt = $db->prepare("UPDATE users SET status = ? WHERE id = ?");
    $stmt->execute([$newStatus, $user_id]);
    
    // Récupérer l'utilisateur mis à jour
    $stmt = $db->prepare("
        SELECT 
            id, nom, prenom, email, role, status, date_creation as date_inscription
        FROM users 
        WHERE id = ?
    ");
    $stmt->execute([$user_id]);
    $user = $stmt->fetch();
    
    echo json_encode([
        'success' => true,
        'message' => 'Statut mis à jour avec succès',
        'data' => $user
    ]);
}

/**
 * Supprimer un utilisateur
 */
function handleDeleteUser() {
    // Récupérer l'ID depuis les paramètres GET
    $user_id = $_GET['id'] ?? null;
    
    if (!$user_id) {
        throw new Exception('ID de l\'utilisateur requis');
    }
    
    $db = getDB();
    
    // Vérifier que l'utilisateur existe
    $stmt = $db->prepare("SELECT id FROM users WHERE id = ?");
    $stmt->execute([$user_id]);
    if (!$stmt->fetch()) {
        throw new Exception('Utilisateur non trouvé');
    }
    
    // Hard delete - Suppression définitive de l'utilisateur
    $stmt = $db->prepare("DELETE FROM users WHERE id = ?");
    $stmt->execute([$user_id]);
    
    echo json_encode([
        'success' => true,
        'message' => 'Utilisateur supprimé définitivement avec succès'
    ]);
}
?> 
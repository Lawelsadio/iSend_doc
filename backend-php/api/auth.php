<?php
/**
 * API d'authentification - iSend Document Flow
 * Gestion de la connexion et inscription des utilisateurs
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');

// Gestion des requêtes OPTIONS (CORS)
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

require_once '../includes/db.php';
require_once '../includes/jwt.php';
require_once '../includes/settings.php';

// Vérification de la méthode HTTP
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode([
        'success' => false,
        'message' => 'Méthode non autorisée'
    ]);
    exit;
}

try {
    $input = json_decode(file_get_contents('php://input'), true);
    
    if (!isset($input['action'])) {
        throw new Exception('Action requise');
    }
    
    switch ($input['action']) {
        case 'login':
            handleLogin($input);
            break;
        case 'register':
            handleRegister($input);
            break;
        case 'refresh':
            handleRefresh($input);
            break;
        default:
            throw new Exception('Action invalide');
    }
    
} catch (Exception $e) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ]);
}

/**
 * Gestion de la connexion d'un utilisateur
 */
function handleLogin($input) {
    if (!isset($input['email']) || !isset($input['password'])) {
        throw new Exception('Email et mot de passe requis');
    }
    
    $email = $input['email'];
    $password = $input['password'];
    
    // Récupérer les paramètres de sécurité
    $settings = SystemSettings::getInstance();
    $securityConfig = $settings->getSecurityConfig();
    
    // Vérifier les tentatives de connexion
    $attempts = checkLoginAttempts($email);
    if ($attempts >= $securityConfig['max_login_attempts']) {
        throw new Exception('Trop de tentatives de connexion. Réessayez plus tard.');
    }
    
    $db = getDB();
    $stmt = $db->prepare("SELECT id, email, password, nom, prenom, role, status FROM users WHERE email = ?");
    $stmt->execute([$email]);
    $user = $stmt->fetch();
    
    if (!$user || !password_verify($password, $user['password'])) {
        // Enregistrer l'échec de connexion
        recordLoginAttempt($email, false);
        throw new Exception('Email ou mot de passe incorrect');
    }
    
    if ($user['status'] !== 'actif') {
        throw new Exception('Compte désactivé');
    }
    
    // Réinitialiser les tentatives de connexion
    recordLoginAttempt($email, true);
    
    // Générer le token avec la durée configurée
    $token = generateJWT([
        'id' => $user['id'],
        'email' => $user['email'],
        'role' => $user['role']
    ]);
    
    echo json_encode([
        'success' => true,
        'message' => 'Connexion réussie',
        'data' => [
            'token' => $token,
            'user' => [
                'id' => $user['id'],
                'email' => $user['email'],
                'nom' => $user['nom'],
                'prenom' => $user['prenom'],
                'role' => $user['role']
            ]
        ]
    ]);
}

/**
 * Gestion de l'inscription d'un utilisateur
 */
function handleRegister($input) {
    if (!isset($input['email']) || !isset($input['password']) || !isset($input['nom']) || !isset($input['prenom'])) {
        throw new Exception('Tous les champs sont requis');
    }
    
    $email = $input['email'];
    $password = $input['password'];
    $nom = $input['nom'];
    $prenom = $input['prenom'];
    
    // Récupérer les paramètres de sécurité
    $settings = SystemSettings::getInstance();
    $securityConfig = $settings->getSecurityConfig();
    
    // Validation du mot de passe
    if (strlen($password) < $securityConfig['min_password_length']) {
        throw new Exception('Le mot de passe doit contenir au moins ' . $securityConfig['min_password_length'] . ' caractères');
    }
    
    if ($securityConfig['password_complexity']) {
        if (!preg_match('/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/', $password)) {
            throw new Exception('Le mot de passe doit contenir au moins une minuscule, une majuscule et un chiffre');
        }
    }
    
    $db = getDB();
    
    // Vérifier si l'email existe déjà
    $stmt = $db->prepare("SELECT id FROM users WHERE email = ?");
    $stmt->execute([$email]);
    if ($stmt->fetch()) {
        throw new Exception('Cet email est déjà utilisé');
    }
    
    // Créer l'utilisateur
    $hashedPassword = password_hash($password, PASSWORD_DEFAULT);
    $stmt = $db->prepare("
        INSERT INTO users (email, password, nom, prenom, role, status, date_creation) 
        VALUES (?, ?, ?, ?, 'user', 'actif', NOW())
    ");
    $stmt->execute([$email, $hashedPassword, $nom, $prenom]);
    
    $userId = $db->lastInsertId();
    
    // Créer un abonnement gratuit par défaut
    $limits = $settings->getSubscriptionLimits('gratuit');
    $stmt = $db->prepare("
        INSERT INTO abonnements (user_id, type, status, limite_documents, limite_destinataires, date_debut) 
        VALUES (?, 'gratuit', 'actif', ?, ?, NOW())
    ");
    $stmt->execute([$userId, $limits['documents'], $limits['destinataires']]);
    
    // Générer le token
    $token = generateJWT([
        'user_id' => $userId,
        'email' => $email,
        'role' => 'user'
    ]);
    
    echo json_encode([
        'success' => true,
        'message' => 'Inscription réussie',
        'data' => [
            'token' => $token,
            'user' => [
                'id' => $userId,
                'email' => $email,
                'nom' => $nom,
                'prenom' => $prenom,
                'role' => 'user'
            ]
        ]
    ]);
}

/**
 * Gestion du rafraîchissement de token
 */
function handleRefresh($input) {
    if (!isset($input['token'])) {
        throw new Exception('Token requis');
    }
    
    $payload = verifyJWT($input['token']);
    if (!$payload) {
        throw new Exception('Token invalide');
    }
    
    // Générer un nouveau token
    $settings = SystemSettings::getInstance();
    $refresh_duration = $settings->get('securite', 'duree_refresh_token', 604800);
    
    $newToken = generateJWT([
        'user_id' => $payload['user_id'],
        'email' => $payload['email'],
        'role' => $payload['role']
    ]);
    
    echo json_encode([
        'success' => true,
        'message' => 'Token renouvelé',
        'data' => [
            'token' => $newToken
        ]
    ]);
}

/**
 * Vérifier les tentatives de connexion
 */
function checkLoginAttempts($email) {
    $db = getDB();
    $settings = SystemSettings::getInstance();
    $lockout_duration = $settings->get('securite', 'duree_blocage', 900);
    
    $stmt = $db->prepare("
        SELECT COUNT(*) as attempts 
        FROM login_attempts 
        WHERE email = ? AND success = 0 AND created_at > DATE_SUB(NOW(), INTERVAL ? SECOND)
    ");
    $stmt->execute([$email, $lockout_duration]);
    $result = $stmt->fetch();
    
    return $result['attempts'];
}

/**
 * Enregistrer une tentative de connexion
 */
function recordLoginAttempt($email, $success) {
    $db = getDB();
    $stmt = $db->prepare("
        INSERT INTO login_attempts (email, success, ip_address, created_at) 
        VALUES (?, ?, ?, NOW())
    ");
    $stmt->execute([$email, $success ? 1 : 0, $_SERVER['REMOTE_ADDR'] ?? '']);
}
?> 
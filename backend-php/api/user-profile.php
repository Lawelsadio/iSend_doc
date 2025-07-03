<?php
/**
 * API de gestion du profil utilisateur et sécurité
 * iSend Document Flow
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, OPTIONS');
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
if (!in_array($_SERVER['REQUEST_METHOD'], ['GET', 'POST', 'PUT'])) {
    http_response_code(405);
    echo json_encode([
        'success' => false,
        'message' => 'Méthode non autorisée'
    ]);
    exit;
}

try {
    $action = $_GET['action'] ?? 'profile';
    
    switch ($action) {
        case 'profile':
            handleProfileAction($user);
            break;
        case 'password':
            handlePasswordAction($user);
            break;
        case 'get':
            handleGetProfile($user);
            break;
        default:
            http_response_code(400);
            echo json_encode([
                'success' => false,
                'message' => 'Action non reconnue'
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
 * Gestion des actions de profil
 */
function handleProfileAction($user) {
    $db = getDB();
    
    if ($_SERVER['REQUEST_METHOD'] === 'GET') {
        // Récupérer les informations du profil
        $stmt = $db->prepare("
            SELECT id, email, nom, prenom, role, status, date_creation, derniere_connexion
            FROM users 
            WHERE id = ?
        ");
        $stmt->execute([$user['user_id']]);
        $profile = $stmt->fetch();
        
        if (!$profile) {
            throw new Exception('Profil utilisateur non trouvé');
        }
        
        echo json_encode([
            'success' => true,
            'data' => [
                'id' => $profile['id'],
                'email' => $profile['email'],
                'nom' => $profile['nom'],
                'prenom' => $profile['prenom'],
                'nom_complet' => $profile['prenom'] . ' ' . $profile['nom'],
                'role' => $profile['role'],
                'status' => $profile['status'],
                'date_creation' => $profile['date_creation'],
                'derniere_connexion' => $profile['derniere_connexion']
            ]
        ]);
        
    } elseif ($_SERVER['REQUEST_METHOD'] === 'PUT') {
        // Mettre à jour le profil
        $input = json_decode(file_get_contents('php://input'), true);
        
        if (!$input) {
            throw new Exception('Données invalides');
        }
        
        $nom = trim($input['nom'] ?? '');
        $prenom = trim($input['prenom'] ?? '');
        $email = trim($input['email'] ?? '');
        
        // Validation
        if (empty($nom) || empty($prenom)) {
            throw new Exception('Le nom et prénom sont requis');
        }
        
        if (empty($email) || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
            throw new Exception('Email invalide');
        }
        
        // Vérifier si l'email existe déjà (sauf pour l'utilisateur actuel)
        $stmt = $db->prepare("SELECT id FROM users WHERE email = ? AND id != ?");
        $stmt->execute([$email, $user['user_id']]);
        if ($stmt->fetch()) {
            throw new Exception('Cet email est déjà utilisé');
        }
        
        // Mettre à jour le profil
        $stmt = $db->prepare("
            UPDATE users 
            SET nom = ?, prenom = ?, email = ?
            WHERE id = ?
        ");
        $stmt->execute([$nom, $prenom, $email, $user['user_id']]);
        
        echo json_encode([
            'success' => true,
            'message' => 'Profil mis à jour avec succès'
        ]);
    }
}

/**
 * Gestion des actions de mot de passe
 */
function handlePasswordAction($user) {
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        http_response_code(405);
        echo json_encode([
            'success' => false,
            'message' => 'Méthode non autorisée'
        ]);
        exit;
    }
    
    $db = getDB();
    $input = json_decode(file_get_contents('php://input'), true);
    
    if (!$input) {
        throw new Exception('Données invalides');
    }
    
    $current_password = $input['current_password'] ?? '';
    $new_password = $input['new_password'] ?? '';
    $confirm_password = $input['confirm_password'] ?? '';
    
    // Validation
    if (empty($current_password) || empty($new_password) || empty($confirm_password)) {
        throw new Exception('Tous les champs sont requis');
    }
    
    if ($new_password !== $confirm_password) {
        throw new Exception('Les mots de passe ne correspondent pas');
    }
    
    if (strlen($new_password) < 6) {
        throw new Exception('Le mot de passe doit contenir au moins 6 caractères');
    }
    
    // Vérifier le mot de passe actuel
    $stmt = $db->prepare("SELECT password FROM users WHERE id = ?");
    $stmt->execute([$user['user_id']]);
    $user_data = $stmt->fetch();
    
    if (!$user_data || !password_verify($current_password, $user_data['password'])) {
        throw new Exception('Mot de passe actuel incorrect');
    }
    
    // Mettre à jour le mot de passe
    $new_password_hash = password_hash($new_password, PASSWORD_DEFAULT);
    $stmt = $db->prepare("UPDATE users SET password = ? WHERE id = ?");
    $stmt->execute([$new_password_hash, $user['user_id']]);
    
    echo json_encode([
        'success' => true,
        'message' => 'Mot de passe modifié avec succès'
    ]);
}

/**
 * Récupérer les informations du profil
 */
function handleGetProfile($user) {
    $db = getDB();
    
    $stmt = $db->prepare("
        SELECT id, email, nom, prenom, role, status, date_creation, derniere_connexion
        FROM users 
        WHERE id = ?
    ");
    $stmt->execute([$user['user_id']]);
    $profile = $stmt->fetch();
    
    if (!$profile) {
        throw new Exception('Profil utilisateur non trouvé');
    }
    
    echo json_encode([
        'success' => true,
        'data' => [
            'id' => $profile['id'],
            'email' => $profile['email'],
            'nom' => $profile['nom'],
            'prenom' => $profile['prenom'],
            'nom_complet' => $profile['prenom'] . ' ' . $profile['nom'],
            'role' => $profile['role'],
            'status' => $profile['status'],
            'date_creation' => $profile['date_creation'],
            'derniere_connexion' => $profile['derniere_connexion']
        ]
    ]);
}
?> 
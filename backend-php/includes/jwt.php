<?php
/**
 * Gestion des JWT pour l'authentification
 * Utilise firebase/php-jwt
 */

require_once __DIR__ . '/../vendor/autoload.php';

use Firebase\JWT\JWT;
use Firebase\JWT\Key;

class JWTManager {
    private static $secret_key = 'isend_secret_key_2024_very_secure';
    private static $algorithm = 'HS256';
    private static $expiration_time = 3600; // 1 heure
    
    /**
     * Génère un token JWT
     */
    public static function generateToken($user_data) {
        $issued_at = time();
        $expiration = $issued_at + self::$expiration_time;
        
        $payload = [
            'iat' => $issued_at,
            'exp' => $expiration,
            'user_id' => $user_data['id'],
            'email' => $user_data['email'],
            'role' => $user_data['role']
        ];
        
        try {
            return JWT::encode($payload, self::$secret_key, self::$algorithm);
        } catch (Exception $e) {
            error_log("Erreur de génération JWT: " . $e->getMessage());
            throw new Exception("Erreur de génération du token");
        }
    }
    
    /**
     * Vérifie et décode un token JWT
     */
    public static function verifyToken($token) {
        try {
            $decoded = JWT::decode($token, new Key(self::$secret_key, self::$algorithm));
            return (array) $decoded;
        } catch (Exception $e) {
            error_log("Erreur de vérification JWT: " . $e->getMessage());
            return false;
        }
    }
    
    /**
     * Extrait le token du header Authorization ou du paramètre GET
     */
    public static function getTokenFromHeader() {
        // Essayer d'abord le paramètre GET (pour MAMP)
        if (isset($_GET['token'])) {
            return $_GET['token'];
        }
        
        // Essayer d'abord getallheaders()
        $headers = getallheaders();
        
        if (isset($headers['Authorization'])) {
            $auth_header = $headers['Authorization'];
        } elseif (isset($headers['authorization'])) {
            $auth_header = $headers['authorization'];
        } else {
            // Fallback vers $_SERVER
            $auth_header = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
        }
        
        if (empty($auth_header) || strpos($auth_header, 'Bearer ') !== 0) {
            return null;
        }
        
        return substr($auth_header, 7);
    }
    
    /**
     * Vérifie si l'utilisateur est authentifié
     */
    public static function isAuthenticated() {
        $token = self::getTokenFromHeader();
        
        if (!$token) {
            return false;
        }
        
        $payload = self::verifyToken($token);
        
        if (!$payload) {
            return false;
        }
        
        // Vérifier si le token n'est pas expiré
        if (isset($payload['exp']) && $payload['exp'] < time()) {
            return false;
        }
        
        return $payload;
    }
    
    /**
     * Vérifie si l'utilisateur a un rôle spécifique
     */
    public static function hasRole($required_role) {
        $payload = self::isAuthenticated();
        
        if (!$payload) {
            return false;
        }
        
        return isset($payload['role']) && $payload['role'] === $required_role;
    }
    
    /**
     * Génère un token temporaire pour l'accès aux documents
     */
    public static function generateAccessToken($document_id, $email, $expiration_hours = 24) {
        $issued_at = time();
        $expiration = $issued_at + ($expiration_hours * 3600);
        
        $payload = [
            'iat' => $issued_at,
            'exp' => $expiration,
            'document_id' => $document_id,
            'email' => $email,
            'type' => 'document_access'
        ];
        
        try {
            return JWT::encode($payload, self::$secret_key, self::$algorithm);
        } catch (Exception $e) {
            error_log("Erreur de génération token d'accès: " . $e->getMessage());
            throw new Exception("Erreur de génération du token d'accès");
        }
    }
}

// Fonctions utilitaires
function generateJWT($user_data) {
    return JWTManager::generateToken($user_data);
}

function verifyJWT($token) {
    return JWTManager::verifyToken($token);
}

function isAuthenticated() {
    return JWTManager::isAuthenticated();
}

function requireAuth() {
    $headers = getallheaders();
    $token = null;
    
    // Récupérer le token depuis les headers ou les paramètres
    if (isset($headers['Authorization'])) {
        $auth = $headers['Authorization'];
        if (strpos($auth, 'Bearer ') === 0) {
            $token = substr($auth, 7);
        }
    } elseif (isset($_GET['token'])) {
        $token = $_GET['token'];
    }
    
    if (!$token) {
        http_response_code(401);
        echo json_encode([
            'success' => false,
            'message' => 'Token d\'authentification requis'
        ]);
        exit;
    }
    
    $payload = verifyJWT($token);
    if (!$payload) {
        http_response_code(401);
        echo json_encode([
            'success' => false,
            'message' => 'Token invalide ou expiré'
        ]);
        exit;
    }
    
    return $payload;
}

function requireRole($role) {
    $user = requireAuth();
    if (!JWTManager::hasRole($role)) {
        http_response_code(403);
        echo json_encode([
            'success' => false,
            'message' => 'Permissions insuffisantes'
        ]);
        exit;
    }
    return $user;
}

/**
 * Génère un token de rafraîchissement
 */
function generateRefreshToken($user_id) {
    $payload = [
        'iss' => 'iSend Document Flow',
        'aud' => 'iSend Refresh',
        'iat' => time(),
        'nbf' => time(),
        'exp' => time() + (60 * 60 * 24 * 30), // 30 jours
        'user_id' => $user_id,
        'type' => 'refresh'
    ];
    
    try {
        return JWT::encode($payload, JWTManager::$secret_key, JWTManager::$algorithm);
    } catch (Exception $e) {
        error_log("Erreur lors de la génération du refresh token: " . $e->getMessage());
        return false;
    }
}

/**
 * Vérifie un token de rafraîchissement
 */
function verifyRefreshToken($token) {
    try {
        $decoded = JWT::decode($token, new Key(JWTManager::$secret_key, JWTManager::$algorithm));
        return (array) $decoded;
    } catch (Exception $e) {
        error_log("Erreur lors de la vérification du refresh token: " . $e->getMessage());
        return false;
    }
}

/**
 * Fonction utilitaire pour envoyer une réponse JSON avec headers CORS
 */
function sendJSONResponse($data, $status_code = 200) {
    http_response_code($status_code);
    header('Content-Type: application/json');
    header('Access-Control-Allow-Origin: *');
    header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
    header('Access-Control-Allow-Headers: Content-Type, Authorization');
    
    if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
        http_response_code(200);
        exit();
    }
    
    echo json_encode($data, JSON_UNESCAPED_UNICODE);
    exit();
}

/**
 * Fonction pour valider les données d'entrée
 */
function validateInput($data, $required_fields = []) {
    $errors = [];
    
    foreach ($required_fields as $field) {
        if (!isset($data[$field]) || empty(trim($data[$field]))) {
            $errors[] = "Le champ '$field' est requis";
        }
    }
    
    return $errors;
}

/**
 * Fonction pour nettoyer les données d'entrée
 */
function sanitizeInput($data) {
    if (is_array($data)) {
        return array_map('sanitizeInput', $data);
    }
    
    return htmlspecialchars(strip_tags(trim($data)), ENT_QUOTES, 'UTF-8');
}
?> 
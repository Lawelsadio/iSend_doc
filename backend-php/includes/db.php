<?php
/**
 * Connexion à la base de données MySQL avec PDO
 * Configuration pour iSend Document Flow
 */

class Database {
    private static $instance = null;
    private $pdo;
    
    private function __construct() {
        $host = 'localhost';
        $port = '8889'; // Port MySQL par défaut sur MAMP
        $dbname = 'isend_document_flow';
        $username = 'root';
        $password = 'root'; // Mot de passe par défaut MAMP
        $charset = 'utf8mb4';
        
        $dsn = "mysql:host=$host;port=$port;dbname=$dbname;charset=$charset";
        $options = [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES => false,
        ];
        
        try {
            $this->pdo = new PDO($dsn, $username, $password, $options);
        } catch (PDOException $e) {
            error_log("Erreur de connexion à la base de données: " . $e->getMessage());
            throw new Exception("Erreur de connexion à la base de données");
        }
    }
    
    public static function getInstance() {
        if (self::$instance === null) {
            self::$instance = new self();
        }
        return self::$instance;
    }
    
    public function getConnection() {
        return $this->pdo;
    }
    
    public function query($sql, $params = []) {
        try {
            $stmt = $this->pdo->prepare($sql);
            $stmt->execute($params);
            return $stmt;
        } catch (PDOException $e) {
            error_log("Erreur de requête SQL: " . $e->getMessage());
            throw new Exception("Erreur de base de données");
        }
    }
    
    public function lastInsertId() {
        return $this->pdo->lastInsertId();
    }
}

// Fonction utilitaire pour obtenir la connexion
function getDB() {
    return Database::getInstance()->getConnection();
}

/**
 * Fonction utilitaire pour échapper les données
 */
function escape($data) {
    return htmlspecialchars(strip_tags(trim($data)));
}

/**
 * Fonction pour valider un email
 */
function isValidEmail($email) {
    return filter_var($email, FILTER_VALIDATE_EMAIL) !== false;
}

/**
 * Fonction pour générer un UUID v4
 */
function generateUUID() {
    return sprintf('%04x%04x-%04x-%04x-%04x-%04x%04x%04x',
        mt_rand(0, 0xffff), mt_rand(0, 0xffff),
        mt_rand(0, 0xffff),
        mt_rand(0, 0x0fff) | 0x4000,
        mt_rand(0, 0x3fff) | 0x8000,
        mt_rand(0, 0xffff), mt_rand(0, 0xffff), mt_rand(0, 0xffff)
    );
}

/**
 * Fonction pour logger les accès
 */
function logDatabaseAccess($token, $email, $status, $message = '') {
    $db = getDB();
    
    try {
        $stmt = $db->prepare("
            INSERT INTO logs_acces (token, email, status, message, date_acces, ip_address)
            VALUES (?, ?, ?, ?, NOW(), ?)
        ");
        
        $stmt->execute([
            $token,
            $email,
            $status,
            $message,
            $_SERVER['REMOTE_ADDR'] ?? 'unknown'
        ]);
        
        return true;
    } catch (PDOException $e) {
        error_log("Erreur lors du logging: " . $e->getMessage());
        return false;
    }
}

/**
 * Fonction pour vérifier si un utilisateur existe
 */
function userExists($email) {
    $db = getDB();
    
    try {
        $stmt = $db->prepare("SELECT id, email, password, nom, prenom FROM users WHERE email = ?");
        $stmt->execute([$email]);
        return $stmt->fetch();
    } catch (PDOException $e) {
        error_log("Erreur lors de la vérification utilisateur: " . $e->getMessage());
        return false;
    }
}

/**
 * Fonction pour vérifier si un abonné existe
 */
function recipientExists($email) {
    $db = getDB();
    
    try {
        $stmt = $db->prepare("SELECT id, email, nom, prenom, status FROM abonnes WHERE email = ?");
        $stmt->execute([$email]);
        return $stmt->fetch();
    } catch (PDOException $e) {
        error_log("Erreur lors de la vérification abonné: " . $e->getMessage());
        return false;
    }
}

/**
 * Fonction pour vérifier si un lien existe et est valide
 */
function linkExists($token) {
    $db = getDB();
    
    try {
        $stmt = $db->prepare("
            SELECT l.*, d.nom, d.description, d.fichier_path 
            FROM liens l 
            JOIN documents d ON l.document_id = d.id 
            WHERE l.token = ? AND l.date_expiration > NOW()
        ");
        $stmt->execute([$token]);
        return $stmt->fetch();
    } catch (PDOException $e) {
        error_log("Erreur lors de la vérification lien: " . $e->getMessage());
        return false;
    }
}
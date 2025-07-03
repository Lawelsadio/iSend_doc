<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

require_once '../includes/db.php';
require_once '../includes/jwt.php';

// Récupérer le token depuis les paramètres GET (pour test)
$token = $_GET['token'] ?? null;

if (!$token) {
    echo json_encode([
        'success' => false,
        'message' => 'Token requis'
    ]);
    exit;
}

// Valider le token
$payload = JWTManager::verifyToken($token);
if (!$payload) {
    echo json_encode([
        'success' => false,
        'message' => 'Token invalide'
    ]);
    exit;
}

$user = $payload;
$db = getDB();

try {
    switch ($_SERVER['REQUEST_METHOD']) {
        case 'GET':
            // Récupération des destinataires
            $stmt = $db->prepare("
                SELECT id, nom, prenom, email, numero, entreprise, status, 
                       date_expiration, date_ajout, date_modification
                FROM destinataires 
                WHERE user_id = ? AND status != 'expire'
                ORDER BY date_ajout DESC
            ");
            $stmt->execute([$user['user_id']]);
            $destinataires = $stmt->fetchAll();
            
            echo json_encode([
                'success' => true,
                'data' => $destinataires
            ]);
            break;
            
        case 'POST':
            // Création d'un destinataire
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
            
            // Vérification si l'email existe déjà
            $stmt = $db->prepare("
                SELECT id FROM destinataires 
                WHERE user_id = ? AND email = ? AND status != 'expire'
            ");
            $stmt->execute([$user['user_id'], $input['email']]);
            
            if ($stmt->fetch()) {
                throw new Exception('Cet email existe déjà dans vos destinataires');
            }
            
            // Insertion du destinataire
            $stmt = $db->prepare("
                INSERT INTO destinataires (user_id, nom, prenom, email, numero, entreprise, status)
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
                FROM destinataires 
                WHERE id = ?
            ");
            $stmt->execute([$destinataire_id]);
            $destinataire = $stmt->fetch();
            
            echo json_encode([
                'success' => true,
                'message' => 'Destinataire créé avec succès',
                'data' => $destinataire
            ]);
            break;
            
        default:
            echo json_encode([
                'success' => false,
                'message' => 'Méthode non supportée'
            ]);
    }
    
} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ]);
}
?> 
<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

require_once '../includes/db.php';
require_once '../includes/jwt.php';

// Récupérer le token depuis les paramètres GET (pour test)
$token = $_GET['token'] ?? null;

if ($token) {
    // Valider le token manuellement
    $payload = JWTManager::verifyToken($token);
    
    if ($payload) {
        // Simuler l'authentification réussie
        $user = $payload;
        
        // Récupérer les destinataires
        $db = getDB();
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
    } else {
        echo json_encode([
            'success' => false,
            'message' => 'Token invalide'
        ]);
    }
} else {
    echo json_encode([
        'success' => false,
        'message' => 'Token requis'
    ]);
}
?> 
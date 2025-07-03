<?php
/**
 * API d'affichage de documents PDF - iSend Document Flow
 * Endpoint dédié pour l'affichage dans un iframe
 */

// Gestion des requêtes OPTIONS (CORS)
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    header('Access-Control-Allow-Origin: *');
    header('Access-Control-Allow-Methods: GET, OPTIONS');
    header('Access-Control-Allow-Headers: Content-Type');
    http_response_code(200);
    exit;
}

require_once '../includes/db.php';

try {
    $token = $_GET['token'] ?? null;
    $email = $_GET['email'] ?? null;
    
    if (!$token || !$email) {
        http_response_code(400);
        header('Content-Type: application/json');
        echo json_encode([
            'success' => false,
            'message' => 'Token et email requis'
        ]);
        exit;
    }
    
    $db = getDB();
    
    // Vérification du lien d'accès
    $stmt = $db->prepare("
        SELECT l.*, d.nom, d.description, d.fichier_path, d.fichier_original, d.taille,
               u.nom as user_nom, u.prenom as user_prenom
        FROM liens l
        JOIN documents d ON l.document_id = d.id
        JOIN users u ON d.user_id = u.id
        WHERE l.token = ? AND l.email = ? AND l.status = 'actif'
    ");
    $stmt->execute([$token, $email]);
    $link = $stmt->fetch();
    
    if (!$link) {
        http_response_code(403);
        header('Content-Type: application/json');
        echo json_encode([
            'success' => false,
            'message' => 'Lien invalide ou expiré'
        ]);
        exit;
    }
    
    // Vérification de l'expiration
    if ($link['date_expiration'] && strtotime($link['date_expiration']) < time()) {
        http_response_code(403);
        header('Content-Type: application/json');
        echo json_encode([
            'success' => false,
            'message' => 'Lien expiré'
        ]);
        exit;
    }
    
    // Vérification de l'abonnement de l'expéditeur
    $stmt = $db->prepare("
        SELECT a.status, a.date_fin
        FROM abonnements a
        JOIN documents d ON d.abonne_id = a.abonne_id
        WHERE d.id = ? AND a.status = 'actif' AND (a.date_fin IS NULL OR a.date_fin > NOW())
        ORDER BY a.date_debut DESC
        LIMIT 1
    ");
    $stmt->execute([$link['document_id']]);
    $subscription = $stmt->fetch();
    
    if (!$subscription) {
        http_response_code(403);
        header('Content-Type: application/json');
        echo json_encode([
            'success' => false,
            'message' => 'Accès temporairement indisponible'
        ]);
        exit;
    }
    
    // Utilisation du chemin absolu vers le dossier uploads
    $filepath = dirname(__DIR__) . '/uploads/' . $link['fichier_path'];
    
    // Vérification que le fichier existe
    if (!file_exists($filepath)) {
        http_response_code(404);
        header('Content-Type: application/json');
        echo json_encode([
            'success' => false,
            'message' => 'Fichier non trouvé: ' . $filepath
        ]);
        exit;
    }
    
    // Mise à jour du nombre d'accès
    $stmt = $db->prepare("
        UPDATE liens 
        SET nombre_acces = nombre_acces + 1, date_derniere_utilisation = NOW()
        WHERE token = ?
    ");
    $stmt->execute([$token]);
    
    // Journalisation de l'accès
    $stmt = $db->prepare("
        INSERT INTO logs_acces (token, email, status, message, ip_address, user_agent)
        VALUES (?, ?, ?, ?, ?, ?)
    ");
    $stmt->execute([
        $token,
        $email,
        'succes',
        'Accès autorisé',
        $_SERVER['REMOTE_ADDR'] ?? '',
        $_SERVER['HTTP_USER_AGENT'] ?? ''
    ]);
    
    // Retour du fichier PDF
    header('Content-Type: application/pdf');
    header('Content-Disposition: inline; filename="' . $link['fichier_original'] . '"');
    header('Content-Length: ' . filesize($filepath));
    header('Cache-Control: no-cache, must-revalidate');
    header('Pragma: no-cache');
    header('Access-Control-Allow-Origin: *');
    
    readfile($filepath);
    exit;
    
} catch (Exception $e) {
    error_log("Erreur dans view-document.php: " . $e->getMessage());
    http_response_code(500);
    header('Content-Type: application/json');
    echo json_encode([
        'success' => false,
        'message' => 'Erreur serveur: ' . $e->getMessage()
    ]);
}
?> 
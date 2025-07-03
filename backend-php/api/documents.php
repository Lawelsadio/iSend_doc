<?php
/**
 * API de gestion des documents - iSend Document Flow
 * Upload, récupération, modification et suppression de documents
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

// Gestion de l'aperçu ou du téléchargement du PDF
if ((isset($_GET['preview']) && $_GET['preview'] == '1') || (isset($_GET['download']) && $_GET['download'] == '1')) {
    $document_id = $_GET['id'] ?? null;
    if (!$document_id) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'ID du document requis']);
        exit;
    }
    $db = getDB();
    $stmt = $db->prepare("SELECT fichier_path, fichier_original, user_id FROM documents WHERE id = ? AND status != 'supprime'");
    $stmt->execute([$document_id]);
    $doc = $stmt->fetch();
    if (!$doc || $doc['user_id'] != $user['user_id']) {
        http_response_code(403);
        echo json_encode(['success' => false, 'message' => 'Accès refusé']);
        exit;
    }
    $filepath = '../uploads/' . $doc['fichier_path'];
    if (!file_exists($filepath)) {
        http_response_code(404);
        echo json_encode(['success' => false, 'message' => 'Fichier non trouvé']);
        exit;
    }
    header('Content-Type: application/pdf');
    if (isset($_GET['download']) && $_GET['download'] == '1') {
        header('Content-Disposition: attachment; filename="' . $doc['fichier_original'] . '"');
    } else {
        header('Content-Disposition: inline; filename="' . $doc['fichier_original'] . '"');
    }
    header('Content-Length: ' . filesize($filepath));
    header('Cache-Control: no-cache, must-revalidate');
    header('Pragma: no-cache');
    readfile($filepath);
    exit;
}

try {
    switch ($_SERVER['REQUEST_METHOD']) {
        case 'GET':
            handleGetDocuments($user);
            break;
        case 'POST':
            handleUploadDocument($user);
            break;
        case 'PUT':
            handleUpdateDocument($user);
            break;
        case 'DELETE':
            handleDeleteDocument($user);
            break;
        default:
            http_response_code(405);
            echo json_encode([
                'success' => false,
                'message' => 'Méthode non autorisée'
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
 * Récupération des documents de l'utilisateur
 */
function handleGetDocuments($user) {
    $db = getDB();
    
    $document_id = $_GET['id'] ?? null;
    
    if ($document_id) {
        // Récupération d'un document spécifique
        $stmt = $db->prepare("
            SELECT id, nom as titre, description, fichier_path as chemin_fichier, 
                   fichier_original as nom_fichier, taille, type_mime, tags, 
                   status as statut, date_upload, date_modification, user_id as utilisateur_id
            FROM documents 
            WHERE id = ? AND user_id = ? AND status != 'supprime'
        ");
        $stmt->execute([$document_id, $user['user_id']]);
        $document = $stmt->fetch();
        
        if (!$document) {
            http_response_code(404);
            echo json_encode([
                'success' => false,
                'message' => 'Document non trouvé'
            ]);
            return;
        }
        
        echo json_encode([
            'success' => true,
            'data' => $document
        ]);
    } else {
        // Récupération de tous les documents
        $stmt = $db->prepare("
            SELECT id, nom as titre, description, fichier_path as chemin_fichier, 
                   fichier_original as nom_fichier, taille, type_mime, tags, 
                   status as statut, date_upload, date_modification, user_id as utilisateur_id
            FROM documents 
            WHERE user_id = ? AND status != 'supprime'
            ORDER BY date_upload DESC
        ");
        $stmt->execute([$user['user_id']]);
        $documents = $stmt->fetchAll();
        
        echo json_encode([
            'success' => true,
            'data' => $documents
        ]);
    }
}

/**
 * Upload d'un nouveau document
 */
function handleUploadDocument($user) {
    // Vérification de l'upload
    if (!isset($_FILES['document']) || $_FILES['document']['error'] !== UPLOAD_ERR_OK) {
        throw new Exception('Erreur lors de l\'upload du fichier');
    }
    
    $file = $_FILES['document'];
    $titre = $_POST['titre'] ?? $_POST['nom'] ?? $file['name'];
    $description = $_POST['description'] ?? '';
    $tags = $_POST['tags'] ?? '';
    
    // Validation du fichier
    $allowed_types = ['application/pdf'];
    $max_size = 10 * 1024 * 1024; // 10 MB
    
    if (!in_array($file['type'], $allowed_types)) {
        throw new Exception('Seuls les fichiers PDF sont autorisés');
    }
    
    if ($file['size'] > $max_size) {
        throw new Exception('Le fichier est trop volumineux (max 10 MB)');
    }
    
    // Création du dossier uploads s'il n'existe pas
    $upload_dir = '../uploads/';
    if (!is_dir($upload_dir)) {
        mkdir($upload_dir, 0755, true);
    }
    
    // Génération d'un nom de fichier unique
    $extension = pathinfo($file['name'], PATHINFO_EXTENSION);
    $filename = uniqid() . '_' . time() . '.' . $extension;
    $filepath = $upload_dir . $filename;
    
    // Déplacement du fichier
    if (!move_uploaded_file($file['tmp_name'], $filepath)) {
        throw new Exception('Erreur lors du déplacement du fichier');
    }
    
    $db = getDB();
    
    // Récupérer l'abonne_id lié à l'utilisateur connecté
    $stmt = $db->prepare("SELECT id FROM abonnes WHERE user_id = ? LIMIT 1");
    $stmt->execute([$user['user_id']]);
    $abonne = $stmt->fetch();
    if (!$abonne) {
        throw new Exception('Aucun abonné associé à cet utilisateur');
    }
    $abonne_id = $abonne['id'];
    
    // Insertion en base de données avec abonne_id
    $stmt = $db->prepare("
        INSERT INTO documents (abonne_id, user_id, nom, description, fichier_path, fichier_original, 
                              taille, type_mime, tags, status)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'actif')
    ");
    $stmt->execute([
        $abonne_id,
        $user['user_id'],
        $titre,
        $description,
        $filename,
        $file['name'],
        $file['size'],
        $file['type'],
        $tags
    ]);
    
    $document_id = $db->lastInsertId();
    
    // Récupération du document créé avec les noms de champs cohérents
    $stmt = $db->prepare("
        SELECT id, nom as titre, description, fichier_path as chemin_fichier, 
               fichier_original as nom_fichier, taille, type_mime, tags, 
               status as statut, date_upload, user_id as utilisateur_id
        FROM documents 
        WHERE id = ?
    ");
    $stmt->execute([$document_id]);
    $document = $stmt->fetch();
    
    echo json_encode([
        'success' => true,
        'message' => 'Document uploadé avec succès',
        'data' => [
            'document_id' => $document_id,
            'document' => $document
        ]
    ]);
}

/**
 * Mise à jour d'un document
 */
function handleUpdateDocument($user) {
    $input = json_decode(file_get_contents('php://input'), true);
    
    if (!$input || empty($input['id'])) {
        throw new Exception('ID du document requis');
    }
    
    $db = getDB();
    
    // Vérification que le document appartient à l'utilisateur
    $stmt = $db->prepare("
        SELECT id FROM documents 
        WHERE id = ? AND user_id = ? AND status != 'supprime'
    ");
    $stmt->execute([$input['id'], $user['user_id']]);
    
    if (!$stmt->fetch()) {
        http_response_code(404);
        echo json_encode([
            'success' => false,
            'message' => 'Document non trouvé'
        ]);
        return;
    }
    
    // Construction de la requête de mise à jour
    $update_fields = [];
    $params = [];
    
    // Gestion des noms de champs cohérents (frontend -> backend)
    if (isset($input['titre']) || isset($input['nom'])) {
        $update_fields[] = 'nom = ?';
        $params[] = $input['titre'] ?? $input['nom'];
    }
    
    if (isset($input['description'])) {
        $update_fields[] = 'description = ?';
        $params[] = $input['description'];
    }
    
    if (isset($input['tags'])) {
        $update_fields[] = 'tags = ?';
        $params[] = $input['tags'];
    }
    
    if (isset($input['statut']) || isset($input['status'])) {
        $update_fields[] = 'status = ?';
        $params[] = $input['statut'] ?? $input['status'];
    }
    
    if (empty($update_fields)) {
        throw new Exception('Aucun champ à mettre à jour');
    }
    
    $params[] = $input['id'];
    $params[] = $user['user_id'];
    
    $sql = "UPDATE documents SET " . implode(', ', $update_fields) . 
           ", date_modification = NOW() WHERE id = ? AND user_id = ?";
    
    $stmt = $db->prepare($sql);
    $stmt->execute($params);
    
    echo json_encode([
        'success' => true,
        'message' => 'Document mis à jour avec succès'
    ]);
}

/**
 * Suppression d'un document (soft delete)
 */
function handleDeleteDocument($user) {
    $document_id = $_GET['id'] ?? null;
    
    if (!$document_id) {
        throw new Exception('ID du document requis');
    }
    
    $db = getDB();
    
    // Vérification que le document appartient à l'utilisateur
    $stmt = $db->prepare("
        SELECT id FROM documents 
        WHERE id = ? AND user_id = ? AND status != 'supprime'
    ");
    $stmt->execute([$document_id, $user['user_id']]);
    
    if (!$stmt->fetch()) {
        http_response_code(404);
        echo json_encode([
            'success' => false,
            'message' => 'Document non trouvé'
        ]);
        return;
    }
    
    // Soft delete
    $stmt = $db->prepare("
        UPDATE documents 
        SET status = 'supprime', date_modification = NOW() 
        WHERE id = ? AND user_id = ?
    ");
    $stmt->execute([$document_id, $user['user_id']]);
    
    echo json_encode([
        'success' => true,
        'message' => 'Document supprimé avec succès'
    ]);
}
?> 
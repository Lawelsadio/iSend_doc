<?php
/**
 * API de statistiques - iSend Document Flow
 * Statistiques d'utilisation des documents et accès
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
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
if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    echo json_encode([
        'success' => false,
        'message' => 'Méthode non autorisée'
    ]);
    exit;
}

try {
    $type = $_GET['type'] ?? 'general';
    $action = $_GET['action'] ?? null;
    
    // Gérer les actions spéciales
    if ($action === 'report') {
        handleReportGeneration($user);
        exit;
    }
    
    switch ($type) {
        case 'document':
        case 'documents':
            handleDocumentStats($user);
            break;
        case 'destinataire':
        case 'recipients':
            handleRecipientStats($user);
            break;
        case 'general':
        default:
            handleGeneralStats($user);
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
 * Statistiques générales de l'utilisateur
 */
function handleGeneralStats($user) {
    $db = getDB();
    
    // Statistiques des documents
    $stmt = $db->prepare("
        SELECT 
            COUNT(*) as total_documents,
            COUNT(CASE WHEN status = 'actif' THEN 1 END) as documents_actifs,
            SUM(taille) as total_taille
        FROM documents 
        WHERE user_id = ? AND status != 'supprime'
    ");
    $stmt->execute([$user['user_id']]);
    $documents_stats = $stmt->fetch();
    
    // Statistiques des destinataires
    $stmt = $db->prepare("
        SELECT COUNT(*) as total_destinataires
        FROM destinataires 
        WHERE user_id = ? AND status = 'actif'
    ");
    $stmt->execute([$user['user_id']]);
    $recipients_stats = $stmt->fetch();
    
    // Statistiques des envois
    $stmt = $db->prepare("
        SELECT 
            COUNT(*) as total_envois,
            COUNT(DISTINCT document_id) as documents_envoyes,
            COUNT(DISTINCT email) as destinataires_uniques
        FROM liens 
        WHERE document_id IN (
            SELECT id FROM documents WHERE user_id = ?
        )
    ");
    $stmt->execute([$user['user_id']]);
    $sends_stats = $stmt->fetch();
    
    // Statistiques des accès (vues)
    $stmt = $db->prepare("
        SELECT 
            COUNT(*) as total_acces,
            COUNT(CASE WHEN status = 'succes' THEN 1 END) as acces_reussis,
            COUNT(CASE WHEN status = 'refuse' THEN 1 END) as acces_refuses
        FROM logs_acces 
        WHERE token IN (
            SELECT token FROM liens WHERE document_id IN (
                SELECT id FROM documents WHERE user_id = ?
            )
        )
    ");
    $stmt->execute([$user['user_id']]);
    $access_stats = $stmt->fetch();
    
    // Documents ce mois-ci
    $stmt = $db->prepare("
        SELECT COUNT(*) as documents_ce_mois
        FROM documents 
        WHERE user_id = ? AND status != 'supprime' 
        AND MONTH(date_upload) = MONTH(NOW()) 
        AND YEAR(date_upload) = YEAR(NOW())
    ");
    $stmt->execute([$user['user_id']]);
    $monthly_docs = $stmt->fetch();
    
    // Vues ce mois-ci
    $stmt = $db->prepare("
        SELECT COUNT(*) as vues_ce_mois
        FROM logs_acces 
        WHERE token IN (
            SELECT token FROM liens WHERE document_id IN (
                SELECT id FROM documents WHERE user_id = ?
            )
        ) AND MONTH(date_acces) = MONTH(NOW()) 
        AND YEAR(date_acces) = YEAR(NOW())
        AND status = 'succes'
    ");
    $stmt->execute([$user['user_id']]);
    $monthly_views = $stmt->fetch();
    
    // Nouveaux destinataires ce mois-ci
    $stmt = $db->prepare("
        SELECT COUNT(DISTINCT email) as nouveaux_destinataires_ce_mois
        FROM liens 
        WHERE document_id IN (
            SELECT id FROM documents WHERE user_id = ?
        ) AND MONTH(date_creation) = MONTH(NOW()) 
        AND YEAR(date_creation) = YEAR(NOW())
    ");
    $stmt->execute([$user['user_id']]);
    $monthly_recipients = $stmt->fetch();
    
    // Calcul du taux de lecture
    $total_sent = $sends_stats['total_envois'] ?? 0;
    $total_views = $access_stats['acces_reussis'] ?? 0;
    $taux_lecture = $total_sent > 0 ? round(($total_views / $total_sent) * 100, 2) : 0;
    
    // Structure attendue par le frontend
    $global_stats = [
        'total_documents' => $documents_stats['total_documents'] ?? 0,
        'total_destinataires' => $recipients_stats['total_destinataires'] ?? 0,
        'total_envoyes' => $sends_stats['total_envois'] ?? 0,
        'total_vues' => $access_stats['acces_reussis'] ?? 0,
        'taux_lecture' => $taux_lecture,
        'documents_ce_mois' => $monthly_docs['documents_ce_mois'] ?? 0,
        'vues_ce_mois' => $monthly_views['vues_ce_mois'] ?? 0,
        'nouveaux_destinataires_ce_mois' => $monthly_recipients['nouveaux_destinataires_ce_mois'] ?? 0
    ];
    
    echo json_encode([
        'success' => true,
        'data' => $global_stats
    ]);
}

/**
 * Statistiques par document
 */
function handleDocumentStats($user) {
    $db = getDB();
    $document_id = $_GET['document_id'] ?? null;
    
    if ($document_id) {
        // Statistiques d'un document spécifique
        $stmt = $db->prepare("
            SELECT 
                d.id, d.nom, d.description, d.date_upload,
                COUNT(l.id) as total_envois,
                COUNT(DISTINCT l.email) as destinataires_uniques,
                SUM(l.nombre_acces) as total_acces
            FROM documents d
            LEFT JOIN liens l ON d.id = l.document_id
            WHERE d.id = ? AND d.user_id = ? AND d.status != 'supprime'
            GROUP BY d.id
        ");
        $stmt->execute([$document_id, $user['user_id']]);
        $document_stats = $stmt->fetch();
        
        if (!$document_stats) {
            http_response_code(404);
            echo json_encode([
                'success' => false,
                'message' => 'Document non trouvé'
            ]);
            return;
        }
        
        // Détail des accès par destinataire
        $stmt = $db->prepare("
            SELECT 
                l.email,
                l.nombre_acces,
                l.date_creation,
                l.date_derniere_utilisation,
                COUNT(la.id) as acces_reussis,
                COUNT(CASE WHEN la.status = 'refuse' THEN 1 END) as acces_refuses
            FROM liens l
            LEFT JOIN logs_acces la ON l.token = la.token
            WHERE l.document_id = ?
            GROUP BY l.id
            ORDER BY l.date_creation DESC
        ");
        $stmt->execute([$document_id]);
        $recipients_detail = $stmt->fetchAll();
        
        echo json_encode([
            'success' => true,
            'data' => [
                'document' => $document_stats,
                'destinataires' => $recipients_detail
            ]
        ]);
    } else {
        // Statistiques de tous les documents
        $stmt = $db->prepare("
            SELECT 
                d.id, 
                d.nom as titre, 
                d.fichier_original as nom_fichier,
                d.date_upload,
                COUNT(l.id) as total_envois,
                COUNT(DISTINCT l.email) as destinataires,
                SUM(l.nombre_acces) as vues,
                MAX(l.date_derniere_utilisation) as dernier_acces
            FROM documents d
            LEFT JOIN liens l ON d.id = l.document_id
            WHERE d.user_id = ? AND d.status != 'supprime'
            GROUP BY d.id
            ORDER BY d.date_upload DESC
        ");
        $stmt->execute([$user['user_id']]);
        $documents_stats = $stmt->fetchAll();
        
        // Calculer le taux de lecture pour chaque document
        $formatted_stats = [];
        foreach ($documents_stats as $doc) {
            $taux_lecture = $doc['total_envois'] > 0 ? round(($doc['vues'] / $doc['total_envois']) * 100, 2) : 0;
            
            $formatted_stats[] = [
                'id' => $doc['id'],
                'nom_fichier' => $doc['nom_fichier'],
                'titre' => $doc['titre'],
                'vues' => $doc['vues'] ?? 0,
                'destinataires' => $doc['destinataires'] ?? 0,
                'date_upload' => $doc['date_upload'],
                'dernier_acces' => $doc['dernier_acces'],
                'taux_lecture' => $taux_lecture
            ];
        }
        
        echo json_encode([
            'success' => true,
            'data' => $formatted_stats
        ]);
    }
}

/**
 * Statistiques par destinataire
 */
function handleRecipientStats($user) {
    $db = getDB();
    $email = $_GET['email'] ?? null;
    
    if ($email) {
        // Statistiques d'un destinataire spécifique
        $stmt = $db->prepare("
            SELECT 
                d.nom, d.prenom, d.email, d.date_ajout,
                COUNT(l.id) as documents_recus,
                SUM(l.nombre_acces) as total_acces
            FROM destinataires d
            LEFT JOIN liens l ON d.email = l.email
            LEFT JOIN documents doc ON l.document_id = doc.id
            WHERE d.user_id = ? AND d.email = ? AND d.status = 'actif'
            GROUP BY d.id
        ");
        $stmt->execute([$user['user_id'], $email]);
        $recipient_stats = $stmt->fetch();
        
        if (!$recipient_stats) {
            http_response_code(404);
            echo json_encode([
                'success' => false,
                'message' => 'Destinataire non trouvé'
            ]);
            return;
        }
        
        // Détail des documents reçus
        $stmt = $db->prepare("
            SELECT 
                doc.nom as document_nom,
                doc.description as document_description,
                l.date_creation,
                l.nombre_acces,
                l.date_derniere_utilisation
            FROM liens l
            JOIN documents doc ON l.document_id = doc.id
            WHERE l.email = ? AND doc.user_id = ?
            ORDER BY l.date_creation DESC
        ");
        $stmt->execute([$email, $user['user_id']]);
        $documents_received = $stmt->fetchAll();
        
        echo json_encode([
            'success' => true,
            'data' => [
                'destinataire' => $recipient_stats,
                'documents_recus' => $documents_received
            ]
        ]);
    } else {
        // Statistiques de tous les destinataires
        $stmt = $db->prepare("
            SELECT 
                d.nom, d.prenom, d.email, d.date_ajout,
                COUNT(l.id) as documents_recus,
                SUM(l.nombre_acces) as total_acces
            FROM destinataires d
            LEFT JOIN liens l ON d.email = l.email
            LEFT JOIN documents doc ON l.document_id = doc.id
            WHERE d.user_id = ? AND d.status = 'actif'
            GROUP BY d.id
            ORDER BY d.date_ajout DESC
        ");
        $stmt->execute([$user['user_id']]);
        $recipients_stats = $stmt->fetchAll();
        
        echo json_encode([
            'success' => true,
            'data' => $recipients_stats
        ]);
    }
}

/**
 * Mise à jour des statistiques (appelée automatiquement)
 */
function updateStats($user_id, $document_id, $type, $date = null) {
    if (!$date) {
        $date = date('Y-m-d');
    }
    
    $db = getDB();
    
    // Vérification si une entrée existe déjà
    $stmt = $db->prepare("
        SELECT id, compteur FROM statistiques 
        WHERE user_id = ? AND document_id = ? AND type = ? AND date_stat = ?
    ");
    $stmt->execute([$user_id, $document_id, $type, $date]);
    $existing = $stmt->fetch();
    
    if ($existing) {
        // Mise à jour du compteur
        $stmt = $db->prepare("
            UPDATE statistiques 
            SET compteur = compteur + 1 
            WHERE id = ?
        ");
        $stmt->execute([$existing['id']]);
    } else {
        // Création d'une nouvelle entrée
        $stmt = $db->prepare("
            INSERT INTO statistiques (user_id, document_id, type, compteur, date_stat)
            VALUES (?, ?, ?, 1, ?)
        ");
        $stmt->execute([$user_id, $document_id, $type, $date]);
    }
}

/**
 * Génération de rapport PDF
 */
function handleReportGeneration($user) {
    $period = $_GET['period'] ?? 'month';
    
    // Récupérer les statistiques
    $db = getDB();
    
    // Statistiques globales
    $stmt = $db->prepare("
        SELECT 
            COUNT(*) as total_documents,
            SUM(taille) as total_taille
        FROM documents 
        WHERE user_id = ? AND status != 'supprime'
    ");
    $stmt->execute([$user['user_id']]);
    $documents_stats = $stmt->fetch();
    
    // Statistiques des envois
    $stmt = $db->prepare("
        SELECT COUNT(*) as total_envois
        FROM liens 
        WHERE document_id IN (
            SELECT id FROM documents WHERE user_id = ?
        )
    ");
    $stmt->execute([$user['user_id']]);
    $sends_stats = $stmt->fetch();
    
    // Statistiques des accès
    $stmt = $db->prepare("
        SELECT COUNT(*) as total_acces
        FROM logs_acces 
        WHERE token IN (
            SELECT token FROM liens WHERE document_id IN (
                SELECT id FROM documents WHERE user_id = ?
            )
        ) AND status = 'succes'
    ");
    $stmt->execute([$user['user_id']]);
    $access_stats = $stmt->fetch();
    
    // Générer le contenu HTML du rapport
    $html = generateReportHTML($user, $documents_stats, $sends_stats, $access_stats, $period);
    
    // Pour l'instant, retourner le HTML (on pourrait utiliser une librairie PDF plus tard)
    header('Content-Type: text/html; charset=utf-8');
    header('Content-Disposition: attachment; filename="rapport_statistiques_' . $period . '_' . date('Y-m-d') . '.html"');
    
    echo $html;
}

/**
 * Générer le HTML du rapport
 */
function generateReportHTML($user, $documents_stats, $sends_stats, $access_stats, $period) {
    $date = date('d/m/Y H:i');
    $period_label = [
        'week' => 'cette semaine',
        'month' => 'ce mois',
        'year' => 'cette année'
    ][$period] ?? 'ce mois';
    
    $html = '
    <!DOCTYPE html>
    <html lang="fr">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Rapport Statistiques iSend</title>
        <style>
            body { font-family: Arial, sans-serif; margin: 20px; }
            .header { text-align: center; border-bottom: 2px solid #2563eb; padding-bottom: 20px; margin-bottom: 30px; }
            .stats-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px; margin-bottom: 30px; }
            .stat-card { border: 1px solid #e5e7eb; border-radius: 8px; padding: 20px; text-align: center; }
            .stat-number { font-size: 2em; font-weight: bold; color: #2563eb; }
            .stat-label { color: #6b7280; margin-top: 5px; }
            .section { margin-bottom: 30px; }
            .section-title { font-size: 1.5em; font-weight: bold; margin-bottom: 15px; color: #1f2937; }
            table { width: 100%; border-collapse: collapse; margin-top: 10px; }
            th, td { border: 1px solid #e5e7eb; padding: 10px; text-align: left; }
            th { background-color: #f9fafb; font-weight: bold; }
            .footer { margin-top: 40px; text-align: center; color: #6b7280; font-size: 0.9em; }
        </style>
    </head>
    <body>
        <div class="header">
            <h1>Rapport Statistiques iSend</h1>
            <p>Généré le ' . $date . ' pour ' . $period_label . '</p>
        </div>
        
        <div class="stats-grid">
            <div class="stat-card">
                <div class="stat-number">' . ($documents_stats['total_documents'] ?? 0) . '</div>
                <div class="stat-label">Documents</div>
            </div>
            <div class="stat-card">
                <div class="stat-number">' . ($sends_stats['total_envois'] ?? 0) . '</div>
                <div class="stat-label">Envois</div>
            </div>
            <div class="stat-card">
                <div class="stat-number">' . ($access_stats['total_acces'] ?? 0) . '</div>
                <div class="stat-label">Vues</div>
            </div>
            <div class="stat-card">
                <div class="stat-number">' . round((($access_stats['total_acces'] ?? 0) / max(1, ($sends_stats['total_envois'] ?? 1))) * 100, 1) . '%</div>
                <div class="stat-label">Taux de lecture</div>
            </div>
        </div>
        
        <div class="footer">
            <p>Rapport généré automatiquement par iSend Document Flow</p>
        </div>
    </body>
    </html>';
    
    return $html;
}
?> 
<?php
/**
 * API d'administration des statistiques - iSend Document Flow
 * Statistiques globales avec vérification des droits admin
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
if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    echo json_encode([
        'success' => false,
        'message' => 'Méthode non autorisée'
    ]);
    exit;
}

try {
    $action = $_GET['action'] ?? 'global';
    
    switch ($action) {
        case 'global':
            handleGlobalStats();
            break;
        case 'detailed':
            handleDetailedStats();
            break;
        default:
            throw new Exception('Action non reconnue');
    }
    
} catch (Exception $e) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ]);
}

/**
 * Statistiques globales
 */
function handleGlobalStats() {
    $db = getDB();
    
    // Total utilisateurs
    $stmt = $db->prepare("SELECT COUNT(*) as total FROM users");
    $stmt->execute();
    $total_users = $stmt->fetch()['total'];
    
    // Utilisateurs actifs
    $stmt = $db->prepare("SELECT COUNT(*) as total FROM users WHERE status = 'actif'");
    $stmt->execute();
    $active_users = $stmt->fetch()['total'];
    
    // Total abonnements
    $stmt = $db->prepare("SELECT COUNT(*) as total FROM abonnements");
    $stmt->execute();
    $total_subscriptions = $stmt->fetch()['total'];
    
    // Abonnements actifs
    $stmt = $db->prepare("SELECT COUNT(*) as total FROM abonnements WHERE status = 'actif'");
    $stmt->execute();
    $active_subscriptions = $stmt->fetch()['total'];
    
    // Total documents
    $stmt = $db->prepare("SELECT COUNT(*) as total FROM documents");
    $stmt->execute();
    $total_documents = $stmt->fetch()['total'];
    
    // Total vues
    $stmt = $db->prepare("SELECT COUNT(*) as total FROM liens WHERE date_derniere_utilisation IS NOT NULL");
    $stmt->execute();
    $total_views = $stmt->fetch()['total'];
    
    // Documents ce mois-ci
    $stmt = $db->prepare("
        SELECT COUNT(*) as total 
        FROM documents 
        WHERE MONTH(date_upload) = MONTH(CURRENT_DATE()) 
        AND YEAR(date_upload) = YEAR(CURRENT_DATE())
    ");
    $stmt->execute();
    $documents_this_month = $stmt->fetch()['total'];
    
    // Revenus ce mois-ci (simulation - à adapter selon votre modèle de paiement)
    $revenue_this_month = 0; // À implémenter selon votre logique de paiement
    
    echo json_encode([
        'success' => true,
        'data' => [
            'total_users' => (int)$total_users,
            'active_users' => (int)$active_users,
            'total_subscriptions' => (int)$total_subscriptions,
            'active_subscriptions' => (int)$active_subscriptions,
            'total_documents' => (int)$total_documents,
            'total_views' => (int)$total_views,
            'documents_this_month' => (int)$documents_this_month,
            'revenue_this_month' => $revenue_this_month
        ]
    ]);
}

/**
 * Statistiques détaillées
 */
function handleDetailedStats() {
    $period = $_GET['period'] ?? 'month';
    
    if (!in_array($period, ['day', 'week', 'month', 'year'])) {
        throw new Exception('Période invalide');
    }
    
    $db = getDB();
    $data = [];
    
    switch ($period) {
        case 'day':
            // Statistiques par heure pour aujourd'hui
            $stmt = $db->prepare("
                SELECT 
                    HOUR(date_upload) as hour,
                    COUNT(*) as documents,
                    COUNT(DISTINCT user_id) as users
                FROM documents 
                WHERE DATE(date_upload) = CURRENT_DATE()
                GROUP BY HOUR(date_upload)
                ORDER BY hour
            ");
            $stmt->execute();
            $results = $stmt->fetchAll();
            
            foreach ($results as $row) {
                $data[] = [
                    'date' => sprintf('%02d:00', $row['hour']),
                    'documents' => (int)$row['documents'],
                    'views' => 0, // À calculer selon vos besoins
                    'users' => (int)$row['users']
                ];
            }
            break;
            
        case 'week':
            // Statistiques par jour pour cette semaine
            $stmt = $db->prepare("
                SELECT 
                    DATE(date_upload) as date,
                    COUNT(*) as documents,
                    COUNT(DISTINCT user_id) as users
                FROM documents 
                WHERE YEARWEEK(date_upload) = YEARWEEK(CURRENT_DATE())
                GROUP BY DATE(date_upload)
                ORDER BY date
            ");
            $stmt->execute();
            $results = $stmt->fetchAll();
            
            foreach ($results as $row) {
                $data[] = [
                    'date' => $row['date'],
                    'documents' => (int)$row['documents'],
                    'views' => 0, // À calculer selon vos besoins
                    'users' => (int)$row['users']
                ];
            }
            break;
            
        case 'month':
            // Statistiques par jour pour ce mois
            $stmt = $db->prepare("
                SELECT 
                    DATE(date_upload) as date,
                    COUNT(*) as documents,
                    COUNT(DISTINCT user_id) as users
                FROM documents 
                WHERE MONTH(date_upload) = MONTH(CURRENT_DATE()) 
                AND YEAR(date_upload) = YEAR(CURRENT_DATE())
                GROUP BY DATE(date_upload)
                ORDER BY date
            ");
            $stmt->execute();
            $results = $stmt->fetchAll();
            
            foreach ($results as $row) {
                $data[] = [
                    'date' => $row['date'],
                    'documents' => (int)$row['documents'],
                    'views' => 0, // À calculer selon vos besoins
                    'users' => (int)$row['users']
                ];
            }
            break;
            
        case 'year':
            // Statistiques par mois pour cette année
            $stmt = $db->prepare("
                SELECT 
                    DATE_FORMAT(date_upload, '%Y-%m') as date,
                    COUNT(*) as documents,
                    COUNT(DISTINCT user_id) as users
                FROM documents 
                WHERE YEAR(date_upload) = YEAR(CURRENT_DATE())
                GROUP BY DATE_FORMAT(date_upload, '%Y-%m')
                ORDER BY date
            ");
            $stmt->execute();
            $results = $stmt->fetchAll();
            
            foreach ($results as $row) {
                $data[] = [
                    'date' => $row['date'],
                    'documents' => (int)$row['documents'],
                    'views' => 0, // À calculer selon vos besoins
                    'users' => (int)$row['users']
                ];
            }
            break;
    }
    
    echo json_encode([
        'success' => true,
        'data' => [
            'period' => $period,
            'data' => $data
        ]
    ]);
}
?> 
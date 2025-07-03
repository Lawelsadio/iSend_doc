<?php
/**
 * Middleware de maintenance - iSend Document Flow
 * Vérifie si le site est en mode maintenance
 */

require_once 'settings.php';

/**
 * Vérifie si le site est en mode maintenance
 * Retourne true si en maintenance, false sinon
 */
function checkMaintenanceMode() {
    $settings = SystemSettings::getInstance();
    return $settings->isMaintenanceMode();
}

/**
 * Affiche la page de maintenance
 */
function showMaintenancePage() {
    $settings = SystemSettings::getInstance();
    $message = $settings->getMaintenanceMessage();
    $platformName = $settings->getPlatformName();
    
    http_response_code(503);
    
    if (isApiRequest()) {
        echo json_encode([
            'success' => false,
            'message' => $message,
            'maintenance' => true
        ]);
    } else {
        ?>
        <!DOCTYPE html>
        <html lang="fr">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title><?php echo htmlspecialchars($platformName); ?> - Maintenance</title>
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                    margin: 0;
                    padding: 0;
                    min-height: 100vh;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                }
                .maintenance-container {
                    background: white;
                    border-radius: 12px;
                    padding: 3rem;
                    text-align: center;
                    box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1);
                    max-width: 500px;
                    margin: 1rem;
                }
                .maintenance-icon {
                    width: 80px;
                    height: 80px;
                    background: #fef3c7;
                    border-radius: 50%;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    margin: 0 auto 2rem;
                }
                .maintenance-icon svg {
                    width: 40px;
                    height: 40px;
                    color: #f59e0b;
                }
                h1 {
                    color: #1f2937;
                    margin-bottom: 1rem;
                    font-size: 1.875rem;
                    font-weight: 700;
                }
                p {
                    color: #6b7280;
                    margin-bottom: 2rem;
                    font-size: 1.125rem;
                    line-height: 1.75;
                }
                .status {
                    background: #fef3c7;
                    color: #92400e;
                    padding: 0.75rem 1.5rem;
                    border-radius: 0.5rem;
                    font-weight: 600;
                    display: inline-block;
                }
            </style>
        </head>
        <body>
            <div class="maintenance-container">
                <div class="maintenance-icon">
                    <svg fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"></path>
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"></path>
                    </svg>
                </div>
                <h1>Site en maintenance</h1>
                <p><?php echo htmlspecialchars($message); ?></p>
                <div class="status">Maintenance en cours</div>
            </div>
        </body>
        </html>
        <?php
    }
    exit;
}

/**
 * Vérifie si la requête est une requête API
 */
function isApiRequest() {
    $contentType = $_SERVER['CONTENT_TYPE'] ?? '';
    $accept = $_SERVER['HTTP_ACCEPT'] ?? '';
    
    return strpos($contentType, 'application/json') !== false ||
           strpos($accept, 'application/json') !== false ||
           strpos($_SERVER['REQUEST_URI'] ?? '', '/api/') !== false;
}

/**
 * Middleware principal à inclure au début de chaque fichier
 */
function maintenanceMiddleware() {
    if (checkMaintenanceMode()) {
        // Permettre l'accès aux admins même en maintenance
        if (isset($_GET['token'])) {
            try {
                require_once 'jwt.php';
                $payload = verifyJWT($_GET['token']);
                if ($payload && $payload['role'] === 'admin') {
                    return; // L'admin peut passer
                }
            } catch (Exception $e) {
                // Token invalide, afficher la page de maintenance
            }
        }
        
        showMaintenancePage();
    }
}

// Exécuter le middleware automatiquement si le fichier est inclus
maintenanceMiddleware();
?> 
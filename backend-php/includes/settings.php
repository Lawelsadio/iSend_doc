<?php
/**
 * Classe de gestion des paramètres système
 * Permet de récupérer et utiliser les paramètres dans toute l'application
 */

require_once 'db.php';

class SystemSettings {
    private static $instance = null;
    private $settings = array();
    private $db = null;
    
    private function __construct() {
        $this->db = getDB();
        $this->loadSettings();
    }
    
    public static function getInstance() {
        if (self::$instance === null) {
            self::$instance = new self();
        }
        return self::$instance;
    }
    
    /**
     * Charge tous les paramètres en cache
     */
    private function loadSettings() {
        try {
            $stmt = $this->db->prepare("
                SELECT categorie, cle, valeur, type 
                FROM parametres_systeme
            ");
            $stmt->execute();
            $results = $stmt->fetchAll();
            
            foreach ($results as $row) {
                $this->settings[$row['categorie']][$row['cle']] = array(
                    'valeur' => $this->convertValue($row['valeur'], $row['type']),
                    'type' => $row['type']
                );
            }
        } catch (Exception $e) {
            error_log("Erreur lors du chargement des paramètres: " . $e->getMessage());
        }
    }
    
    /**
     * Récupère un paramètre par catégorie et clé
     */
    public function get($categorie, $cle, $default = null) {
        if (isset($this->settings[$categorie][$cle])) {
            return $this->settings[$categorie][$cle]['valeur'];
        }
        return $default;
    }
    
    /**
     * Récupère tous les paramètres d'une catégorie
     */
    public function getCategory($categorie) {
        return isset($this->settings[$categorie]) ? $this->settings[$categorie] : array();
    }
    
    /**
     * Récupère tous les paramètres
     */
    public function getAll() {
        return $this->settings;
    }
    
    /**
     * Met à jour un paramètre
     */
    public function set($categorie, $cle, $valeur) {
        try {
            $stmt = $this->db->prepare("
                UPDATE parametres_systeme 
                SET valeur = ?, date_modification = NOW() 
                WHERE categorie = ? AND cle = ?
            ");
            $stmt->execute(array($valeur, $categorie, $cle));
            
            // Mettre à jour le cache immédiatement
            if (isset($this->settings[$categorie][$cle])) {
                $this->settings[$categorie][$cle]['valeur'] = $this->convertValue($valeur, $this->settings[$categorie][$cle]['type']);
            }
            
            // Notifier les autres instances (si en mode multi-processus)
            $this->notifySettingsChange($categorie, $cle, $valeur);
            
            return true;
        } catch (Exception $e) {
            error_log("Erreur lors de la mise à jour du paramètre: " . $e->getMessage());
            return false;
        }
    }
    
    /**
     * Recharge les paramètres depuis la base de données
     */
    public function reload() {
        $this->settings = array();
        $this->loadSettings();
    }
    
    /**
     * Force le rechargement du cache (utile après modifications via API)
     */
    public function forceReload() {
        $this->reload();
    }
    
    /**
     * Notifier les changements de paramètres (pour cache distribué)
     */
    private function notifySettingsChange($categorie, $cle, $valeur) {
        // Ici on pourrait implémenter un système de notification
        // pour invalider le cache sur d'autres instances
        // Par exemple avec Redis ou un fichier de cache partagé
        
        // Pour l'instant, on log le changement
        error_log("Paramètre modifié: {$categorie}.{$cle} = {$valeur}");
    }
    
    /**
     * Convertit la valeur selon le type
     */
    private function convertValue($valeur, $type) {
        switch ($type) {
            case 'number':
                return (float) $valeur;
            case 'boolean':
                return $valeur === 'true' || $valeur === '1';
            case 'json':
                try {
                    return json_decode($valeur, true);
                } catch (Exception $e) {
                    return $valeur;
                }
            default:
                return $valeur;
        }
    }
    
    // Méthodes utilitaires pour les paramètres courants
    
    /**
     * Nom de la plateforme
     */
    public function getPlatformName() {
        return $this->get('general', 'nom_plateforme', 'iSend Document Flow');
    }
    
    /**
     * Email de contact
     */
    public function getContactEmail() {
        return $this->get('general', 'email_contact', 'contact@isend.com');
    }
    
    /**
     * Configuration SMTP
     */
    public function getSMTPConfig() {
        // Configuration Gmail pour l'envoi d'emails en local
        return array(
            'host' => 'smtp.gmail.com',
            'port' => 587,
            'username' => 'mellowrime@gmail.com',
            'password' => 'rlybcfnnkvdsnytb',
            'encryption' => 'tls',
            'from_email' => 'mellowrime@gmail.com',
            'from_name' => 'iSend Document Flow'
        );
    }
    
    /**
     * Limites d'abonnement par type
     */
    public function getSubscriptionLimits($type) {
        $limits = array(
            'gratuit' => array(
                'documents' => $this->get('abonnements', 'limite_documents_gratuit', 10),
                'destinataires' => $this->get('abonnements', 'limite_destinataires_gratuit', 50)
            ),
            'premium' => array(
                'documents' => $this->get('abonnements', 'limite_documents_premium', 1000),
                'destinataires' => $this->get('abonnements', 'limite_destinataires_premium', 500)
            ),
            'entreprise' => array(
                'documents' => $this->get('abonnements', 'limite_documents_entreprise', 2000),
                'destinataires' => $this->get('abonnements', 'limite_destinataires_entreprise', 1500)
            ),
            'illimite' => array(
                'documents' => -1,
                'destinataires' => -1
            )
        );
        
        return isset($limits[$type]) ? $limits[$type] : $limits['gratuit'];
    }
    
    /**
     * Configuration de sécurité
     */
    public function getSecurityConfig() {
        return array(
            'jwt_duration' => $this->get('securite', 'duree_token_jwt', 3600),
            'refresh_duration' => $this->get('securite', 'duree_refresh_token', 604800),
            'min_password_length' => $this->get('securite', 'longueur_min_mot_de_passe', 8),
            'password_complexity' => $this->get('securite', 'complexite_mot_de_passe', true),
            'session_duration' => $this->get('securite', 'duree_session', 28800),
            'max_login_attempts' => $this->get('securite', 'max_tentatives_connexion', 5),
            'lockout_duration' => $this->get('securite', 'duree_blocage', 900)
        );
    }
    
    /**
     * Mode maintenance
     */
    public function isMaintenanceMode() {
        return $this->get('systeme', 'maintenance_mode', false);
    }
    
    /**
     * Message de maintenance
     */
    public function getMaintenanceMessage() {
        return $this->get('systeme', 'maintenance_message', 'Site en maintenance');
    }
    
    /**
     * Timezone par défaut
     */
    public function getTimezone() {
        return $this->get('systeme', 'timezone', 'Europe/Paris');
    }
    
    /**
     * Langue par défaut
     */
    public function getDefaultLanguage() {
        return $this->get('systeme', 'langue_defaut', 'fr');
    }
}

// Fonction utilitaire pour accéder facilement aux paramètres
function getSystemSetting($categorie, $cle, $default = null) {
    return SystemSettings::getInstance()->get($categorie, $cle, $default);
}

// Fonction pour vérifier le mode maintenance
function isMaintenanceMode() {
    return SystemSettings::getInstance()->isMaintenanceMode();
}
?> 
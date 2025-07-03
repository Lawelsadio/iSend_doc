-- =====================================================
-- Script SQL pour iSend Document Flow
-- Création de la base de données et des tables
-- =====================================================

-- Création de la base de données
CREATE DATABASE IF NOT EXISTS `isend_document_flow` 
CHARACTER SET utf8mb4 
COLLATE utf8mb4_unicode_ci;

USE `isend_document_flow`;

-- =====================================================
-- Table des utilisateurs
-- =====================================================
CREATE TABLE `users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `email` varchar(255) NOT NULL UNIQUE,
  `password` varchar(255) NOT NULL,
  `nom` varchar(100) NOT NULL,
  `prenom` varchar(100) NOT NULL,
  `role` enum('admin','user') DEFAULT 'user',
  `status` enum('actif','inactif','suspendu') DEFAULT 'actif',
  `date_creation` datetime DEFAULT CURRENT_TIMESTAMP,
  `derniere_connexion` datetime NULL,
  `date_modification` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `email_unique` (`email`),
  KEY `idx_status` (`status`),
  KEY `idx_date_creation` (`date_creation`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- Table des documents
-- =====================================================
CREATE TABLE `documents` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `nom` varchar(255) NOT NULL,
  `description` text NULL,
  `fichier_path` varchar(500) NOT NULL,
  `fichier_original` varchar(255) NOT NULL,
  `taille` bigint(20) NOT NULL,
  `type_mime` varchar(100) DEFAULT 'application/pdf',
  `tags` varchar(500) NULL,
  `status` enum('actif','supprime','archive') DEFAULT 'actif',
  `date_upload` datetime DEFAULT CURRENT_TIMESTAMP,
  `date_modification` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_status` (`status`),
  KEY `idx_date_upload` (`date_upload`),
  FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- Table des destinataires
-- =====================================================
CREATE TABLE `destinataires` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `nom` varchar(100) NOT NULL,
  `prenom` varchar(100) NOT NULL,
  `email` varchar(255) NOT NULL,
  `numero` varchar(20) NULL,
  `entreprise` varchar(255) NULL,
  `status` enum('actif','inactif','expire') DEFAULT 'actif',
  `date_expiration` date NULL,
  `date_ajout` datetime DEFAULT CURRENT_TIMESTAMP,
  `date_modification` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `user_email_unique` (`user_id`, `email`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_email` (`email`),
  KEY `idx_status` (`status`),
  KEY `idx_date_ajout` (`date_ajout`),
  FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- Table des liens d'accès
-- =====================================================
CREATE TABLE `liens` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `document_id` int(11) NOT NULL,
  `email` varchar(255) NOT NULL,
  `token` varchar(255) NOT NULL UNIQUE,
  `date_creation` datetime DEFAULT CURRENT_TIMESTAMP,
  `date_expiration` datetime NULL,
  `date_derniere_utilisation` datetime NULL,
  `nombre_acces` int(11) DEFAULT 0,
  `status` enum('actif','expire','revoke') DEFAULT 'actif',
  PRIMARY KEY (`id`),
  UNIQUE KEY `token_unique` (`token`),
  KEY `idx_document_id` (`document_id`),
  KEY `idx_email` (`email`),
  KEY `idx_status` (`status`),
  KEY `idx_date_creation` (`date_creation`),
  KEY `idx_date_expiration` (`date_expiration`),
  FOREIGN KEY (`document_id`) REFERENCES `documents`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- Table des logs d'accès
-- =====================================================
CREATE TABLE `logs_acces` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `token` varchar(255) NOT NULL,
  `email` varchar(255) NOT NULL,
  `status` enum('succes','erreur','refuse') NOT NULL,
  `message` text NULL,
  `ip_address` varchar(45) NULL,
  `user_agent` text NULL,
  `date_acces` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_token` (`token`),
  KEY `idx_email` (`email`),
  KEY `idx_status` (`status`),
  KEY `idx_date_acces` (`date_acces`),
  KEY `idx_ip_address` (`ip_address`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- Table des abonnements (optionnel)
-- =====================================================
CREATE TABLE `abonnements` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `type` enum('gratuit','basique','premium','entreprise') DEFAULT 'gratuit',
  `status` enum('actif','expire','annule') DEFAULT 'actif',
  `date_debut` datetime DEFAULT CURRENT_TIMESTAMP,
  `date_fin` datetime NULL,
  `limite_documents` int(11) DEFAULT 10,
  `limite_destinataires` int(11) DEFAULT 50,
  `date_creation` datetime DEFAULT CURRENT_TIMESTAMP,
  `date_modification` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_status` (`status`),
  KEY `idx_date_fin` (`date_fin`),
  FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- Table des statistiques (optionnel)
-- =====================================================
CREATE TABLE `statistiques` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `document_id` int(11) NULL,
  `type` enum('upload','envoi','acces','telechargement') NOT NULL,
  `compteur` int(11) DEFAULT 1,
  `date_stat` date NOT NULL,
  `date_creation` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_stat` (`user_id`, `document_id`, `type`, `date_stat`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_document_id` (`document_id`),
  KEY `idx_type` (`type`),
  KEY `idx_date_stat` (`date_stat`),
  FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`document_id`) REFERENCES `documents`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- Insertion des données de test
-- =====================================================

-- Utilisateur de test (mot de passe: password123)
INSERT INTO `users` (`email`, `password`, `nom`, `prenom`, `role`) VALUES
('admin@isend.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Admin', 'iSend', 'admin'),
('test@example.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Test', 'User', 'user');

-- Destinataires de test
INSERT INTO `destinataires` (`user_id`, `nom`, `prenom`, `email`, `numero`, `status`) VALUES
(2, 'Dupont', 'Jean', 'jean.dupont@example.com', '+33123456789', 'actif'),
(2, 'Martin', 'Marie', 'marie.martin@example.com', '+33987654321', 'actif'),
(2, 'Bernard', 'Pierre', 'pierre.bernard@example.com', NULL, 'actif');

-- =====================================================
-- Index supplémentaires pour optimiser les performances
-- =====================================================

-- Index composites pour les requêtes fréquentes
CREATE INDEX `idx_documents_user_status` ON `documents` (`user_id`, `status`);
CREATE INDEX `idx_liens_document_email` ON `liens` (`document_id`, `email`);
CREATE INDEX `idx_logs_token_status` ON `logs_acces` (`token`, `status`);
CREATE INDEX `idx_destinataires_user_status` ON `destinataires` (`user_id`, `status`);

-- =====================================================
-- Vues utiles pour les statistiques
-- =====================================================

-- Vue des statistiques par utilisateur
CREATE VIEW `vue_stats_utilisateur` AS
SELECT 
    u.id as user_id,
    u.email,
    u.nom,
    u.prenom,
    COUNT(DISTINCT d.id) as nb_documents,
    COUNT(DISTINCT dest.id) as nb_destinataires,
    COUNT(DISTINCT l.id) as nb_liens,
    COUNT(la.id) as nb_acces
FROM users u
LEFT JOIN documents d ON u.id = d.user_id AND d.status = 'actif'
LEFT JOIN destinataires dest ON u.id = dest.user_id AND dest.status = 'actif'
LEFT JOIN liens l ON d.id = l.document_id AND l.status = 'actif'
LEFT JOIN logs_acces la ON l.token = la.token AND la.status = 'succes'
GROUP BY u.id, u.email, u.nom, u.prenom;

-- Vue des statistiques par document
CREATE VIEW `vue_stats_document` AS
SELECT 
    d.id as document_id,
    d.nom,
    d.user_id,
    u.email as user_email,
    COUNT(l.id) as nb_liens,
    COUNT(la.id) as nb_acces,
    COUNT(DISTINCT l.email) as nb_destinataires_uniques,
    d.date_upload
FROM documents d
JOIN users u ON d.user_id = u.id
LEFT JOIN liens l ON d.id = l.document_id AND l.status = 'actif'
LEFT JOIN logs_acces la ON l.token = la.token AND la.status = 'succes'
WHERE d.status = 'actif'
GROUP BY d.id, d.nom, d.user_id, u.email, d.date_upload;

-- =====================================================
-- Procédures stockées utiles
-- =====================================================

DELIMITER //

-- Procédure pour nettoyer les liens expirés
CREATE PROCEDURE `nettoyer_liens_expires`()
BEGIN
    UPDATE liens 
    SET status = 'expire' 
    WHERE date_expiration < NOW() AND status = 'actif';
    
    SELECT ROW_COUNT() as liens_expires;
END //

-- Procédure pour obtenir les statistiques d'un utilisateur
CREATE PROCEDURE `stats_utilisateur`(IN user_id_param INT)
BEGIN
    SELECT 
        u.email,
        u.nom,
        u.prenom,
        COUNT(DISTINCT d.id) as nb_documents,
        COUNT(DISTINCT dest.id) as nb_destinataires,
        COUNT(DISTINCT l.id) as nb_liens_envoyes,
        COUNT(la.id) as nb_acces_total
    FROM users u
    LEFT JOIN documents d ON u.id = d.user_id AND d.status = 'actif'
    LEFT JOIN destinataires dest ON u.id = dest.user_id AND dest.status = 'actif'
    LEFT JOIN liens l ON d.id = l.document_id AND l.status = 'actif'
    LEFT JOIN logs_acces la ON l.token = la.token AND la.status = 'succes'
    WHERE u.id = user_id_param
    GROUP BY u.id, u.email, u.nom, u.prenom;
END //

DELIMITER ;

-- =====================================================
-- Triggers pour maintenir la cohérence
-- =====================================================

DELIMITER //

-- Trigger pour mettre à jour le nombre d'accès dans la table liens
CREATE TRIGGER `update_nombre_acces` 
AFTER INSERT ON `logs_acces`
FOR EACH ROW
BEGIN
    IF NEW.status = 'succes' THEN
        UPDATE liens 
        SET nombre_acces = nombre_acces + 1,
            date_derniere_utilisation = NOW()
        WHERE token = NEW.token;
    END IF;
END //

-- Trigger pour vérifier l'expiration des abonnements
CREATE TRIGGER `check_abonnement_expire`
BEFORE UPDATE ON `abonnements`
FOR EACH ROW
BEGIN
    IF NEW.date_fin < NOW() AND NEW.status = 'actif' THEN
        SET NEW.status = 'expire';
    END IF;
END //

DELIMITER ;

-- =====================================================
-- Permissions (à adapter selon votre configuration)
-- =====================================================

-- Créer un utilisateur pour l'application (optionnel)
-- CREATE USER 'isend_user'@'localhost' IDENTIFIED BY 'votre_mot_de_passe_securise';
-- GRANT SELECT, INSERT, UPDATE, DELETE ON isend_document_flow.* TO 'isend_user'@'localhost';
-- FLUSH PRIVILEGES;

-- =====================================================
-- Message de fin
-- =====================================================
SELECT 'Base de données iSend Document Flow créée avec succès !' as message; 
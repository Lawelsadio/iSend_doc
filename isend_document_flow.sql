-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Hôte : localhost:8889
-- Généré le : mer. 02 juil. 2025 à 23:59
-- Version du serveur : 8.0.40
-- Version de PHP : 8.3.14

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de données : `isend_document_flow`
--

DELIMITER $$
--
-- Procédures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `nettoyer_liens_expires` ()   BEGIN
    UPDATE liens 
    SET status = 'expire' 
    WHERE date_expiration < NOW() AND status = 'actif';
    
    SELECT ROW_COUNT() as liens_expires;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `stats_utilisateur` (IN `user_id_param` INT)   BEGIN
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
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Structure de la table `abonnements`
--

CREATE TABLE `abonnements` (
  `id` int NOT NULL,
  `abonne_id` int NOT NULL,
  `type` enum('gratuit','basique','premium','entreprise','illimite') COLLATE utf8mb4_unicode_ci DEFAULT 'gratuit',
  `status` enum('actif','expire','annule') COLLATE utf8mb4_unicode_ci DEFAULT 'actif',
  `date_debut` datetime DEFAULT CURRENT_TIMESTAMP,
  `date_fin` datetime DEFAULT NULL,
  `limite_documents` int DEFAULT '10',
  `limite_destinataires` int DEFAULT '50',
  `date_creation` datetime DEFAULT CURRENT_TIMESTAMP,
  `date_modification` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Déchargement des données de la table `abonnements`
--

INSERT INTO `abonnements` (`id`, `abonne_id`, `type`, `status`, `date_debut`, `date_fin`, `limite_documents`, `limite_destinataires`, `date_creation`, `date_modification`) VALUES
(14, 2, 'premium', 'actif', '2025-07-02 00:00:00', NULL, 1000, 500, '2025-07-03 00:33:37', '2025-07-03 00:33:37');

--
-- Déclencheurs `abonnements`
--
DELIMITER $$
CREATE TRIGGER `check_abonnement_expire` BEFORE UPDATE ON `abonnements` FOR EACH ROW BEGIN
    IF NEW.date_fin < NOW() AND NEW.status = 'actif' THEN
        SET NEW.status = 'expire';
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Structure de la table `abonnes`
--

CREATE TABLE `abonnes` (
  `id` int NOT NULL,
  `user_id` int NOT NULL,
  `nom` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `prenom` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `email` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `type_abonnement` enum('gratuit','premium','entreprise','illimite') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'gratuit',
  `statut` enum('actif','inactif','suspendu') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'actif',
  `date_inscription` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `date_derniere_activite` timestamp NULL DEFAULT NULL,
  `date_expiration` date DEFAULT NULL,
  `date_ajout` datetime DEFAULT CURRENT_TIMESTAMP,
  `limite_documents` int DEFAULT '1000',
  `limite_destinataires` int DEFAULT '500',
  `notes` text COLLATE utf8mb4_unicode_ci,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `numero` varchar(21) COLLATE utf8mb4_unicode_ci NOT NULL,
  `status` enum('actif','inactif','expire') COLLATE utf8mb4_unicode_ci DEFAULT 'actif'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Déchargement des données de la table `abonnes`
--

INSERT INTO `abonnes` (`id`, `user_id`, `nom`, `prenom`, `email`, `type_abonnement`, `statut`, `date_inscription`, `date_derniere_activite`, `date_expiration`, `date_ajout`, `limite_documents`, `limite_destinataires`, `notes`, `created_at`, `updated_at`, `numero`, `status`) VALUES
(2, 1, 'sadio', 'mamane', 'mamanelawelsadio@gmail.com', 'gratuit', 'actif', '2025-07-02 19:39:46', NULL, NULL, '2025-07-02 21:39:46', 1000, 500, NULL, '2025-07-02 19:39:46', '2025-07-02 19:40:02', '+33605917194', 'actif');

-- --------------------------------------------------------

--
-- Structure de la table `destinataires`
--

CREATE TABLE `destinataires` (
  `id` int NOT NULL,
  `user_id` int NOT NULL,
  `nom` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `prenom` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `email` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `numero` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `entreprise` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `status` enum('actif','inactif','expire') COLLATE utf8mb4_unicode_ci DEFAULT 'actif',
  `date_expiration` date DEFAULT NULL,
  `date_ajout` datetime DEFAULT CURRENT_TIMESTAMP,
  `date_modification` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Déchargement des données de la table `destinataires`
--

INSERT INTO `destinataires` (`id`, `user_id`, `nom`, `prenom`, `email`, `numero`, `entreprise`, `status`, `date_expiration`, `date_ajout`, `date_modification`) VALUES
(1, 2, 'Dupont', 'Jean', 'jean.dupont@example.com', '+33123456789', NULL, 'actif', NULL, '2025-06-22 01:51:12', '2025-06-22 01:51:12'),
(2, 2, 'Martin', 'Marie', 'marie.martin@example.com', '+33987654321', NULL, 'actif', NULL, '2025-06-22 01:51:12', '2025-06-22 01:51:12'),
(3, 2, 'Bernard', 'Pierre', 'pierre.bernard@example.com', NULL, NULL, 'actif', NULL, '2025-06-22 01:51:12', '2025-06-22 01:51:12'),
(8, 5, 'sadio', 'mamane', 'sadio@sadio.com', '+33709878745', NULL, 'actif', NULL, '2025-06-22 05:33:35', '2025-06-22 05:33:39'),
(16, 1, 'mamane lawel', 'mamane', 'mamanelawelsadio@gmail.com', '+33605917194', NULL, 'actif', NULL, '2025-06-24 23:35:09', '2025-06-24 23:35:09');

-- --------------------------------------------------------

--
-- Structure de la table `documents`
--

CREATE TABLE `documents` (
  `id` int NOT NULL,
  `abonne_id` int DEFAULT NULL,
  `user_id` int NOT NULL,
  `nom` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` text COLLATE utf8mb4_unicode_ci,
  `fichier_path` varchar(500) COLLATE utf8mb4_unicode_ci NOT NULL,
  `fichier_original` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `taille` bigint NOT NULL,
  `type_mime` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT 'application/pdf',
  `tags` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `status` enum('actif','supprime','archive') COLLATE utf8mb4_unicode_ci DEFAULT 'actif',
  `date_upload` datetime DEFAULT CURRENT_TIMESTAMP,
  `date_modification` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Déchargement des données de la table `documents`
--

INSERT INTO `documents` (`id`, `abonne_id`, `user_id`, `nom`, `description`, `fichier_path`, `fichier_original`, `taille`, `type_mime`, `tags`, `status`, `date_upload`, `date_modification`) VALUES
(10, 2, 1, 'Document de test pour aperçu', 'Document de test pour vérifier l\'aperçu PDF', 'test_document.pdf', 'test_document.pdf', 1024, 'application/pdf', 'test,aperçu', 'actif', '2025-06-22 04:14:31', '2025-07-02 23:38:39'),
(11, 2, 5, 'Recours_gracieux_naturalisation (1)', '', '6857794b96af7_1750563147.pdf', 'Recours_gracieux_naturalisation (1).pdf', 29196, 'application/pdf', '', 'actif', '2025-06-22 05:32:27', '2025-07-02 23:38:39'),
(12, 2, 5, 'Test Document', 'Test upload', '6857869a021d1_1750566554.pdf', 'test.pdf', 17, 'application/pdf', '', 'actif', '2025-06-22 06:29:14', '2025-07-02 23:38:39'),
(13, 2, 5, 'Document de test', 'Document de test pour validation', '685786d75aebe_1750566615.pdf', 'test-document.pdf', 462, 'application/pdf', '', 'actif', '2025-06-22 06:30:15', '2025-07-02 23:38:39'),
(14, 2, 5, 'Document de test', 'Document de test pour validation', '685787434edd8_1750566723.pdf', 'test-document.pdf', 462, 'application/pdf', '', 'actif', '2025-06-22 06:32:03', '2025-07-02 23:38:39'),
(15, 2, 5, 'Document de test', 'Document de test pour validation', '685787a104eb8_1750566817.pdf', 'test-document.pdf', 462, 'application/pdf', '', 'actif', '2025-06-22 06:33:37', '2025-07-02 23:38:39'),
(16, 2, 5, 'Document de test', 'Document de test pour validation', '685787cdc402b_1750566861.pdf', 'test-document.pdf', 462, 'application/pdf', '', 'actif', '2025-06-22 06:34:21', '2025-07-02 23:38:39'),
(17, 2, 5, 'Document de test', 'Document de test pour validation', '685788d113d1e_1750567121.pdf', 'test-document.pdf', 462, 'application/pdf', '', 'actif', '2025-06-22 06:38:41', '2025-07-02 23:38:39'),
(18, 2, 5, 'Document de test', 'Document de test pour validation', '685788e79ab5c_1750567143.pdf', 'test-document.pdf', 462, 'application/pdf', '', 'actif', '2025-06-22 06:39:03', '2025-07-02 23:38:39'),
(19, 2, 5, 'Recours_gracieux_naturalisation (1)', '', '68578e797d9c0_1750568569.pdf', 'Recours_gracieux_naturalisation (1).pdf', 29196, 'application/pdf', '', 'actif', '2025-06-22 07:02:49', '2025-07-02 23:38:39'),
(20, 2, 1, 'Recours_gracieux_naturalisation (1)', '', '685846174f8b4_1750615575.pdf', 'Recours_gracieux_naturalisation (1).pdf', 29196, 'application/pdf', '', 'actif', '2025-06-22 20:06:15', '2025-07-02 23:38:39'),
(21, 2, 1, 'Recours_gracieux_naturalisation (1)', '', '68586eee419fd_1750626030.pdf', 'Recours_gracieux_naturalisation (1).pdf', 29196, 'application/pdf', '', 'actif', '2025-06-22 23:00:30', '2025-07-02 23:38:39'),
(22, 2, 1, 'Recours_gracieux_naturalisation (1)', '', '68586f33b18cb_1750626099.pdf', 'Recours_gracieux_naturalisation (1).pdf', 29196, 'application/pdf', '', 'actif', '2025-06-22 23:01:39', '2025-07-02 23:38:39'),
(23, 2, 1, 'acte_de_naissance_papa_sadio', '', '685b10f35afd2_1750798579.pdf', 'acte_de_naissance_papa_sadio.pdf', 84211, 'application/pdf', '', 'actif', '2025-06-24 22:56:19', '2025-07-02 23:38:39'),
(24, 2, 1, 'acte_de_naissance_papa_sadio (1)', '', '685b13aa9ab74_1750799274.pdf', 'acte_de_naissance_papa_sadio (1).pdf', 84211, 'application/pdf', '', 'actif', '2025-06-24 23:07:54', '2025-07-02 23:38:39'),
(25, 2, 1, 'acte_de_naissance_papa_sadio (1)', '', '685b1de69b20c_1750801894.pdf', 'acte_de_naissance_papa_sadio (1).pdf', 84211, 'application/pdf', '', 'actif', '2025-06-24 23:51:34', '2025-07-02 23:38:39'),
(26, 2, 1, 'acte_de_naissance_papa_sadio (1)', '', '685c4c0044505_1750879232.pdf', 'acte_de_naissance_papa_sadio (1).pdf', 84211, 'application/pdf', '', 'actif', '2025-06-25 21:20:32', '2025-07-02 23:38:39'),
(27, 2, 1, 'acte_de_naissance_papa_sadio (1)', '', '685c4e1cb395c_1750879772.pdf', 'acte_de_naissance_papa_sadio (1).pdf', 84211, 'application/pdf', '', 'actif', '2025-06-25 21:29:32', '2025-07-02 23:38:39'),
(28, 2, 1, 'acte_de_naissance_papa_sadio (1)', '', '685c4e5cef59e_1750879836.pdf', 'acte_de_naissance_papa_sadio (1).pdf', 84211, 'application/pdf', '', 'actif', '2025-06-25 21:30:36', '2025-07-02 23:38:39'),
(29, 2, 1, 'acte_de_naissance_papa_sadio (1)', '', '685c50d64949e_1750880470.pdf', 'acte_de_naissance_papa_sadio (1).pdf', 84211, 'application/pdf', '', 'actif', '2025-06-25 21:41:10', '2025-07-02 23:38:39'),
(30, 2, 1, 'acte_de_naissance_papa_sadio (1)', '', '685c518f88225_1750880655.pdf', 'acte_de_naissance_papa_sadio (1).pdf', 84211, 'application/pdf', '', 'actif', '2025-06-25 21:44:15', '2025-07-02 23:38:39'),
(31, 2, 1, 'acte_de_naissance_papa_sadio (1)', '', '685c51c6cd5d2_1750880710.pdf', 'acte_de_naissance_papa_sadio (1).pdf', 84211, 'application/pdf', '', 'actif', '2025-06-25 21:45:10', '2025-07-02 23:38:39'),
(32, 2, 1, 'acte_de_naissance_papa_sadio (1)', '', '685c57816a6a3_1750882177.pdf', 'acte_de_naissance_papa_sadio (1).pdf', 84211, 'application/pdf', '', 'actif', '2025-06-25 22:09:37', '2025-07-02 23:38:39'),
(33, 2, 1, 'Timbres-electroniques_I250501502493', '', '685c59dfc54f7_1750882783.pdf', 'Timbres-electroniques_I250501502493.pdf', 62864, 'application/pdf', '', 'actif', '2025-06-25 22:19:43', '2025-07-02 23:38:39'),
(34, 2, 1, 'acte_de_naissance_papa_sadio (1)', '', '685c5af42c9bd_1750883060.pdf', 'acte_de_naissance_papa_sadio (1).pdf', 84211, 'application/pdf', '', 'actif', '2025-06-25 22:24:20', '2025-07-02 23:38:39'),
(35, 2, 1, 'acte_de_naissance_papa_sadio (1)', '', '685c5d512ea86_1750883665.pdf', 'acte_de_naissance_papa_sadio (1).pdf', 84211, 'application/pdf', '', 'actif', '2025-06-25 22:34:25', '2025-07-02 23:38:39'),
(36, 2, 1, 'acte_de_naissance_papa_sadio (1)', '', '685c675430085_1750886228.pdf', 'acte_de_naissance_papa_sadio (1).pdf', 84211, 'application/pdf', '', 'actif', '2025-06-25 23:17:08', '2025-07-02 23:38:39'),
(37, 2, 1, 'acte_de_naissance_papa_sadio (1)', '', '685c678834de0_1750886280.pdf', 'acte_de_naissance_papa_sadio (1).pdf', 84211, 'application/pdf', '', 'actif', '2025-06-25 23:18:00', '2025-07-02 23:38:39'),
(38, 2, 1, 'Document de test final', NULL, '/Applications/MAMP/htdocs/isend-document-flow/backend-php/uploads/test_document.pdf', 'test_document.pdf', 84211, 'application/pdf', NULL, 'actif', '2025-06-25 23:31:58', '2025-07-02 23:38:39'),
(39, 2, 1, 'Document de test final', NULL, '/Applications/MAMP/htdocs/isend-document-flow/backend-php/uploads/test_document.pdf', 'test_document.pdf', 84211, 'application/pdf', NULL, 'actif', '2025-06-25 23:33:43', '2025-07-02 23:38:39'),
(40, 2, 1, 'Document de test final', NULL, '/Applications/MAMP/htdocs/isend-document-flow/backend-php/uploads/test_document.pdf', 'test_document.pdf', 84211, 'application/pdf', NULL, 'actif', '2025-06-25 23:36:17', '2025-07-02 23:38:39'),
(41, 2, 1, 'Document de test final', NULL, '/Applications/MAMP/htdocs/isend-document-flow/backend-php/uploads/test_document.pdf', 'test_document.pdf', 84211, 'application/pdf', NULL, 'actif', '2025-06-25 23:39:18', '2025-07-02 23:38:39'),
(42, 2, 1, 'acte_de_naissance_papa_sadio (1)', '', '685c6cb6baab9_1750887606.pdf', 'acte_de_naissance_papa_sadio (1).pdf', 84211, 'application/pdf', '', 'actif', '2025-06-25 23:40:06', '2025-07-02 23:38:39'),
(43, 2, 1, 'Document de test frontend', NULL, 'uploads/6857524c51ea3_1750553164.pdf', '6857524c51ea3_1750553164.pdf', 461, 'application/pdf', NULL, 'actif', '2025-06-26 00:08:10', '2025-07-02 23:38:39'),
(44, 2, 1, 'acte_de_naissance_papa_sadio (1)', '', '685c7c08075cd_1750891528.pdf', 'acte_de_naissance_papa_sadio (1).pdf', 84211, 'application/pdf', '', 'actif', '2025-06-26 00:45:28', '2025-07-02 23:38:39'),
(45, 2, 1, 'acte de naissance', NULL, 'uploads/6857524c51ea3_1750553164.pdf', '6857524c51ea3_1750553164.pdf', 461, 'application/pdf', NULL, 'actif', '2025-06-26 00:45:55', '2025-07-02 23:38:39'),
(46, 2, 1, 'acte_de_naissance_papa_sadio', '', '685c7eb3eb6fd_1750892211.pdf', 'acte_de_naissance_papa_sadio.pdf', 84211, 'application/pdf', '', 'actif', '2025-06-26 00:56:52', '2025-07-02 23:38:39'),
(47, 2, 1, 'test', NULL, 'uploads/6857524c51ea3_1750553164.pdf', '6857524c51ea3_1750553164.pdf', 461, 'application/pdf', NULL, 'actif', '2025-06-26 00:57:04', '2025-07-02 23:38:39'),
(48, 2, 1, 'facture_3', '', '685f08553b0fc_1751058517.pdf', 'facture_3.pdf', 143060, 'application/pdf', '', 'actif', '2025-06-27 23:08:37', '2025-07-02 23:38:39'),
(49, 2, 1, 'facture', NULL, 'uploads/6857524c51ea3_1750553164.pdf', '6857524c51ea3_1750553164.pdf', 461, 'application/pdf', NULL, 'actif', '2025-06-27 23:09:07', '2025-07-02 23:38:39'),
(50, 2, 1, 'acte_de_naissance_papa_sadio (1)', '', '685fb4d944aa0_1751102681.pdf', 'acte_de_naissance_papa_sadio (1).pdf', 84211, 'application/pdf', '', 'actif', '2025-06-28 11:24:41', '2025-07-02 23:38:39'),
(51, 2, 1, 'acte de naissance', NULL, 'uploads/6857524c51ea3_1750553164.pdf', '6857524c51ea3_1750553164.pdf', 461, 'application/pdf', NULL, 'actif', '2025-06-28 11:25:12', '2025-07-02 23:38:39'),
(52, 2, 1, 'acte_de_naissance_papa_sadio (1)', '', '685fbcf4ec793_1751104756.pdf', 'acte_de_naissance_papa_sadio (1).pdf', 84211, 'application/pdf', '', 'actif', '2025-06-28 11:59:16', '2025-07-02 23:38:39'),
(53, 2, 1, 'acte de naissance', NULL, 'uploads/6857524c51ea3_1750553164.pdf', '6857524c51ea3_1750553164.pdf', 461, 'application/pdf', NULL, 'actif', '2025-06-28 11:59:42', '2025-07-02 23:38:39'),
(54, 2, 1, 'acte_de_naissance_papa_sadio (1)', '', '685fbddf36b6d_1751104991.pdf', 'acte_de_naissance_papa_sadio (1).pdf', 84211, 'application/pdf', '', 'actif', '2025-06-28 12:03:11', '2025-07-02 23:38:39'),
(55, 2, 1, 'acte de naissance', NULL, 'uploads/6857524c51ea3_1750553164.pdf', '6857524c51ea3_1750553164.pdf', 461, 'application/pdf', NULL, 'actif', '2025-06-28 12:03:30', '2025-07-02 23:38:39'),
(56, 2, 1, 'acte_de_naissance_papa_sadio (1)', '', '685fbec565bb2_1751105221.pdf', 'acte_de_naissance_papa_sadio (1).pdf', 84211, 'application/pdf', '', 'actif', '2025-06-28 12:07:01', '2025-07-02 23:38:39'),
(57, 2, 1, 'acte de naissance', NULL, 'uploads/6857524c51ea3_1750553164.pdf', '6857524c51ea3_1750553164.pdf', 461, 'application/pdf', NULL, 'actif', '2025-06-28 12:07:20', '2025-07-02 23:38:39'),
(58, 2, 1, 'acte_de_naissance_papa_sadio (1)', '', '685fdc506cd68_1751112784.pdf', 'acte_de_naissance_papa_sadio (1).pdf', 84211, 'application/pdf', '', 'actif', '2025-06-28 14:13:04', '2025-07-02 23:38:39'),
(59, 2, 1, 'acte de naissance', NULL, '6857524c51ea3_1750553164.pdf', '6857524c51ea3_1750553164.pdf', 461, 'application/pdf', NULL, 'actif', '2025-06-28 14:13:38', '2025-07-02 23:38:39'),
(60, 2, 1, 'acte_de_naissance_papa_sadio (1)', '', '685fdca4dcd40_1751112868.pdf', 'acte_de_naissance_papa_sadio (1).pdf', 84211, 'application/pdf', '', 'actif', '2025-06-28 14:14:28', '2025-07-02 23:38:39'),
(61, 2, 1, 'acte de naissance', NULL, '6857524c51ea3_1750553164.pdf', '6857524c51ea3_1750553164.pdf', 461, 'application/pdf', NULL, 'actif', '2025-06-28 14:14:42', '2025-07-02 23:38:39'),
(62, 2, 1, 'acte_de_naissance_papa_sadio (1)', '', '685fdf37a08d3_1751113527.pdf', 'acte_de_naissance_papa_sadio (1).pdf', 84211, 'application/pdf', '', 'actif', '2025-06-28 14:25:27', '2025-07-02 23:38:39'),
(63, 2, 1, 'acte_de_naissance_papa_sadio (1)', '', '685fdf54e6cec_1751113556.pdf', 'acte_de_naissance_papa_sadio (1).pdf', 84211, 'application/pdf', '', 'actif', '2025-06-28 14:25:56', '2025-07-02 23:38:39'),
(64, 2, 1, 'test', NULL, '685fdf6fbe37c_1751113583_6857524c51ea3_1750553164.pdf', '6857524c51ea3_1750553164.pdf', 461, 'application/pdf', NULL, 'actif', '2025-06-28 14:26:23', '2025-07-02 23:38:39'),
(65, 2, 1, 'acte_de_naissance_papa_sadio (1)', '', '685fe3bc14d52_1751114684.pdf', 'acte_de_naissance_papa_sadio (1).pdf', 84211, 'application/pdf', '', 'actif', '2025-06-28 14:44:44', '2025-07-02 23:38:39'),
(66, 2, 1, 'test envoi', NULL, '685fe3da9505c_1751114714_6857524c51ea3_1750553164.pdf', '6857524c51ea3_1750553164.pdf', 461, 'application/pdf', NULL, 'actif', '2025-06-28 14:45:14', '2025-07-02 23:38:39'),
(67, 2, 1, 'acte_de_naissance_papa_sadio (1)', '', '685fe72bf3409_1751115564.pdf', 'acte_de_naissance_papa_sadio (1).pdf', 84211, 'application/pdf', '', 'actif', '2025-06-28 14:59:24', '2025-07-02 23:38:39'),
(68, 2, 1, 'building', NULL, '685fe7410dbb7_1751115585_6857524c51ea3_1750553164.pdf', '6857524c51ea3_1750553164.pdf', 461, 'application/pdf', NULL, 'actif', '2025-06-28 14:59:45', '2025-07-02 23:38:39'),
(69, 2, 1, 'acte_de_naissance_papa_sadio (1)', '', '685fe94a7d68e_1751116106.pdf', 'acte_de_naissance_papa_sadio (1).pdf', 84211, 'application/pdf', '', 'actif', '2025-06-28 15:08:26', '2025-07-02 23:38:39'),
(70, 2, 1, 'acte_de_naissance_papa_sadio (1)', '', '685fe9e6f3e6c_1751116262.pdf', 'acte_de_naissance_papa_sadio (1).pdf', 84211, 'application/pdf', '', 'actif', '2025-06-28 15:11:03', '2025-07-02 23:38:39'),
(71, 2, 1, 'acte_de_naissance_papa_sadio (1)', '', '685febebdf781_1751116779.pdf', 'acte_de_naissance_papa_sadio (1).pdf', 84211, 'application/pdf', '', 'actif', '2025-06-28 15:19:39', '2025-07-02 23:38:39'),
(72, 2, 1, 'acte_de_naissance_papa_sadio (1)', '', '685fec480f866_1751116872.pdf', 'acte_de_naissance_papa_sadio (1).pdf', 84211, 'application/pdf', '', 'actif', '2025-06-28 15:21:12', '2025-07-02 23:38:39'),
(73, 2, 1, 'acte_de_naissance_papa_sadio (1)', '', '685ff2f887913_1751118584.pdf', 'acte_de_naissance_papa_sadio (1).pdf', 84211, 'application/pdf', '', 'actif', '2025-06-28 15:49:44', '2025-07-02 23:38:39'),
(74, 2, 1, 'test', NULL, '685ff3128c2be_1751118610_685ff2f887913_1751118584.pdf', '685ff2f887913_1751118584.pdf', 461, 'application/pdf', NULL, 'actif', '2025-06-28 15:50:10', '2025-07-02 23:38:39'),
(75, 2, 1, 'acte_de_naissance_papa_sadio (1)', '', '685ff32da99a7_1751118637.pdf', 'acte_de_naissance_papa_sadio (1).pdf', 84211, 'application/pdf', '', 'actif', '2025-06-28 15:50:37', '2025-07-02 23:38:39'),
(76, 2, 1, 'acte_de_naissance_papa_sadio (1)', '', '685ff639b38a6_1751119417.pdf', 'acte_de_naissance_papa_sadio (1).pdf', 84211, 'application/pdf', '', 'actif', '2025-06-28 16:03:37', '2025-07-02 23:38:39'),
(77, 2, 1, 'acte de naissance', NULL, '685ff65492f81_1751119444_685ff639b38a6_1751119417.pdf', '685ff639b38a6_1751119417.pdf', 84211, 'application/pdf', NULL, 'actif', '2025-06-28 16:04:04', '2025-07-02 23:38:39'),
(78, 2, 1, 'Recours_gracieux_naturalisation (1) (1)', '', '685ff6870d861_1751119495.pdf', 'Recours_gracieux_naturalisation (1) (1).pdf', 29196, 'application/pdf', '', 'actif', '2025-06-28 16:04:55', '2025-07-02 23:38:39'),
(79, 2, 1, 'recou', NULL, '685ff69f66ee3_1751119519_685ff6870d861_1751119495.pdf', '685ff6870d861_1751119495.pdf', 29196, 'application/pdf', NULL, 'actif', '2025-06-28 16:05:19', '2025-07-02 23:38:39'),
(80, 2, 1, 'acte_de_naissance_papa_sadio (1)', '', '685ff70200826_1751119618.pdf', 'acte_de_naissance_papa_sadio (1).pdf', 84211, 'application/pdf', '', 'actif', '2025-06-28 16:06:58', '2025-07-02 23:38:39'),
(81, 2, 1, 'acte_de_naissance_papa_sadio (1)', '', '685ff943b00fb_1751120195.pdf', 'acte_de_naissance_papa_sadio (1).pdf', 84211, 'application/pdf', '', 'actif', '2025-06-28 16:16:35', '2025-07-02 23:38:39'),
(82, 2, 1, 'acte_de_naissance_papa_sadio (1)', '', '685ffa2e98cd0_1751120430.pdf', 'acte_de_naissance_papa_sadio (1).pdf', 84211, 'application/pdf', '', 'actif', '2025-06-28 16:20:30', '2025-07-02 23:38:39'),
(83, 2, 1, 'acte_de_naissance_papa_sadio (1)', '', '685ffa7b3e49c_1751120507.pdf', 'acte_de_naissance_papa_sadio (1).pdf', 84211, 'application/pdf', '', 'actif', '2025-06-28 16:21:47', '2025-07-02 23:38:39'),
(84, 2, 1, 'acte_de_naissance_papa_sadio (1)', '', '685ffc5ad6012_1751120986.pdf', 'acte_de_naissance_papa_sadio (1).pdf', 84211, 'application/pdf', '', 'actif', '2025-06-28 16:29:46', '2025-07-02 23:38:39'),
(85, 2, 1, 'acte_de_naissance_papa_sadio (1)', '', '685ffe1594268_1751121429.pdf', 'acte_de_naissance_papa_sadio (1).pdf', 84211, 'application/pdf', '', 'actif', '2025-06-28 16:37:09', '2025-07-02 23:38:39'),
(86, 2, 1, 'acte_de_naissance_papa_sadio (1)', '', '6860017c95237_1751122300.pdf', 'acte_de_naissance_papa_sadio (1).pdf', 84211, 'application/pdf', '', 'actif', '2025-06-28 16:51:40', '2025-07-02 23:38:39'),
(87, 2, 1, 'acte_de_naissance_papa_sadio (1)', '', '6860020650250_1751122438.pdf', 'acte_de_naissance_papa_sadio (1).pdf', 84211, 'application/pdf', '', 'actif', '2025-06-28 16:53:58', '2025-07-02 23:38:39'),
(88, 2, 1, 'acte_de_naissance_papa_sadio (1)', '', '6860034b0057f_1751122763.pdf', 'acte_de_naissance_papa_sadio (1).pdf', 84211, 'application/pdf', '', 'actif', '2025-06-28 16:59:23', '2025-07-02 23:38:39'),
(89, 2, 1, 'Avisdimpotrevenus2022AvisDimpotrevenus2022 3', '', '686007743059b_1751123828.pdf', 'Avisdimpotrevenus2022AvisDimpotrevenus2022 3.pdf', 162921, 'application/pdf', '', 'actif', '2025-06-28 17:17:08', '2025-07-02 23:38:39'),
(90, 2, 1, 'avis', NULL, '686007854ea25_1751123845_686007743059b_1751123828.pdf', '686007743059b_1751123828.pdf', 162921, 'application/pdf', NULL, 'actif', '2025-06-28 17:17:25', '2025-07-02 23:38:39'),
(91, 2, 1, 'Recours_gracieux_naturalisation (1)', '', '68600801418bd_1751123969.pdf', 'Recours_gracieux_naturalisation (1).pdf', 29196, 'application/pdf', '', 'actif', '2025-06-28 17:19:29', '2025-07-02 23:38:39'),
(92, 2, 1, 'facture_3', '', '686009e38493a_1751124451.pdf', 'facture_3.pdf', 143060, 'application/pdf', '', 'actif', '2025-06-28 17:27:31', '2025-07-02 23:38:39'),
(93, 2, 1, 'acte_de_naissance_papa_sadio (1)', '', '68603beb94e6c_1751137259.pdf', 'acte_de_naissance_papa_sadio (1).pdf', 84211, 'application/pdf', '', 'actif', '2025-06-28 21:00:59', '2025-07-02 23:38:39'),
(94, 2, 1, 'RecoursAdministratif_18-06-2025', '', '68603d3ea1d96_1751137598.pdf', 'RecoursAdministratif_18-06-2025.pdf', 41664, 'application/pdf', '', 'actif', '2025-06-28 21:06:38', '2025-07-02 23:38:39'),
(95, 2, 1, '20240714-135823-etci-acte-naissance-conjoint-6693b6eccb069-2', '', '68603eea35c0e_1751138026.pdf', '20240714-135823-etci-acte-naissance-conjoint-6693b6eccb069-2.pdf', 487914, 'application/pdf', '', 'actif', '2025-06-28 21:13:46', '2025-07-02 23:38:39'),
(96, 2, 1, 'Scan 2023-10-06 11.56.25', '', '686064a890225_1751147688.pdf', 'Scan 2023-10-06 11.56.25.pdf', 2098378, 'application/pdf', '', 'actif', '2025-06-28 23:54:48', '2025-07-02 23:38:39'),
(97, 2, 1, 'ZIBO_ADAMOU_Haoua', '', '6860854945f66_1751156041.pdf', 'ZIBO_ADAMOU_Haoua.pdf', 189429, 'application/pdf', '', 'actif', '2025-06-29 02:14:01', '2025-07-02 23:38:39'),
(98, 2, 1, 'acte_de_naissance_papa_sadio (1)', '', '6860863085f2d_1751156272.pdf', 'acte_de_naissance_papa_sadio (1).pdf', 84211, 'application/pdf', '', 'actif', '2025-06-29 02:17:53', '2025-07-02 23:38:39'),
(99, 2, 1, 'Nationalité maman', '', '68610ea98aba6_1751191209.pdf', 'Nationalité maman.pdf', 682621, 'application/pdf', '', 'actif', '2025-06-29 12:00:09', '2025-07-02 23:38:39'),
(100, 2, 1, 'Document de test - Vérification abonnement', 'Document pour tester la vérification d\'abonnement', 'test_document.pdf', 'test_document.pdf', 1024, 'application/pdf', NULL, 'actif', '2025-06-29 12:15:46', '2025-07-02 23:38:39'),
(101, 2, 1, 'ZIBO_ADAMOU_Haoua', '', '686162d9a5552_1751212761.pdf', 'ZIBO_ADAMOU_Haoua.pdf', 189429, 'application/pdf', '', 'actif', '2025-06-29 17:59:21', '2025-07-02 23:38:39'),
(102, 2, 1, 'acte_de_naissance_papa_sadio (1)', '', '68616364f304b_1751212900.pdf', 'acte_de_naissance_papa_sadio (1).pdf', 84211, 'application/pdf', '', 'actif', '2025-06-29 18:01:40', '2025-07-02 23:38:39'),
(103, 2, 1, 'acte_de_naissance_papa_sadio (1)', '', '68616b8a9d855_1751214986.pdf', 'acte_de_naissance_papa_sadio (1).pdf', 84211, 'application/pdf', '', 'actif', '2025-06-29 18:36:26', '2025-07-02 23:38:39'),
(104, 2, 1, 'journal du jour', NULL, '68616bd31d5af_1751215059_68616b8a9d855_1751214986.pdf', '68616b8a9d855_1751214986.pdf', 84211, 'application/pdf', NULL, 'actif', '2025-06-29 18:37:39', '2025-07-02 23:38:39'),
(105, 2, 1, 'acte_de_naissance_papa_sadio (1)', '', '6861bab9a715e_1751235257.pdf', 'acte_de_naissance_papa_sadio (1).pdf', 84211, 'application/pdf', '', 'actif', '2025-06-30 00:14:17', '2025-07-02 23:38:39'),
(106, 2, 1, 'acte_de_naissance_papa_sadio (1)', '', '68642fc703d57_1751396295.pdf', 'acte_de_naissance_papa_sadio (1).pdf', 84211, 'application/pdf', '', 'actif', '2025-07-01 20:58:15', '2025-07-02 23:38:39'),
(107, 2, 1, 'acte_de_naissance_papa_sadio (1)', '', '686430611b51f_1751396449.pdf', 'acte_de_naissance_papa_sadio (1).pdf', 84211, 'application/pdf', '', 'actif', '2025-07-01 21:00:49', '2025-07-02 23:38:39'),
(108, 2, 1, 'acte_de_naissance_papa_sadio (1)', '', '686430b564a40_1751396533.pdf', 'acte_de_naissance_papa_sadio (1).pdf', 84211, 'application/pdf', '', 'actif', '2025-07-01 21:02:13', '2025-07-02 23:38:39'),
(109, 2, 1, 'test', NULL, '686430ba721c4_1751396538_686430b564a40_1751396533.pdf', '686430b564a40_1751396533.pdf', 84211, 'application/pdf', NULL, 'actif', '2025-07-01 21:02:18', '2025-07-02 23:38:39'),
(110, 2, 1, 'acte_de_naissance_papa_sadio (1)', '', '68659cefead57_1751489775.pdf', 'acte_de_naissance_papa_sadio (1).pdf', 84211, 'application/pdf', '', 'actif', '2025-07-02 22:56:15', '2025-07-02 23:38:39'),
(111, 2, 1, 'test', NULL, '68659cfdaa575_1751489789_68659cefead57_1751489775.pdf', '68659cefead57_1751489775.pdf', 84211, 'application/pdf', NULL, 'actif', '2025-07-02 22:56:29', '2025-07-02 23:38:39'),
(112, 2, 1, 'acte_de_naissance_papa_sadio (1)', '', '68659d7ad5523_1751489914.pdf', 'acte_de_naissance_papa_sadio (1).pdf', 84211, 'application/pdf', '', 'actif', '2025-07-02 22:58:34', '2025-07-02 23:38:39'),
(113, 2, 1, 'acte_de_naissance_papa_sadio (1)', '', '68659f1bd5287_1751490331.pdf', 'acte_de_naissance_papa_sadio (1).pdf', 84211, 'application/pdf', '', 'actif', '2025-07-02 23:05:31', '2025-07-02 23:38:39'),
(114, 2, 1, 'acte_de_naissance_papa_sadio (1)', '', '68659fc81388f_1751490504.pdf', 'acte_de_naissance_papa_sadio (1).pdf', 84211, 'application/pdf', '', 'actif', '2025-07-02 23:08:24', '2025-07-02 23:38:39'),
(115, 2, 1, 'acte_de_naissance_papa_sadio (1)', '', '6865a048992e8_1751490632.pdf', 'acte_de_naissance_papa_sadio (1).pdf', 84211, 'application/pdf', '', 'actif', '2025-07-02 23:10:32', '2025-07-02 23:38:39'),
(116, 2, 1, 'acte_de_naissance_papa_sadio (1)', '', '6865a199b06b0_1751490969.pdf', 'acte_de_naissance_papa_sadio (1).pdf', 84211, 'application/pdf', '', 'actif', '2025-07-02 23:16:09', '2025-07-02 23:37:44'),
(117, NULL, 1, 'acte_de_naissance_papa_sadio (1)', '', '6865a6f1d8209_1751492337.pdf', 'acte_de_naissance_papa_sadio (1).pdf', 84211, 'application/pdf', '', 'actif', '2025-07-02 23:38:57', '2025-07-02 23:38:57'),
(118, NULL, 1, 'acte_de_naissance_papa_sadio (1)', '', '6865a8fdd8e92_1751492861.pdf', 'acte_de_naissance_papa_sadio (1).pdf', 84211, 'application/pdf', '', 'actif', '2025-07-02 23:47:41', '2025-07-02 23:47:41'),
(119, NULL, 1, 'acte_de_naissance_papa_sadio (1)', '', '6865a9e859a74_1751493096.pdf', 'acte_de_naissance_papa_sadio (1).pdf', 84211, 'application/pdf', '', 'actif', '2025-07-02 23:51:36', '2025-07-02 23:51:36'),
(120, NULL, 1, 'Avisdimpotrevenus2022AvisDimpotrevenus2022', '', '6865aa51389e9_1751493201.pdf', 'Avisdimpotrevenus2022AvisDimpotrevenus2022.pdf', 162834, 'application/pdf', '', 'actif', '2025-07-02 23:53:21', '2025-07-02 23:53:21'),
(121, NULL, 1, 'uuu', NULL, '6865aac0937e1_1751493312_6865aa51389e9_1751493201.pdf', '6865aa51389e9_1751493201.pdf', 162834, 'application/pdf', NULL, 'actif', '2025-07-02 23:55:12', '2025-07-02 23:55:12'),
(122, NULL, 1, 'acte_de_naissance_papa_sadio (1)', '', '6865ab7767ad9_1751493495.pdf', 'acte_de_naissance_papa_sadio (1).pdf', 84211, 'application/pdf', '', 'actif', '2025-07-02 23:58:15', '2025-07-02 23:58:15'),
(123, NULL, 1, 'acte_de_naissance_papa_sadio (1)', '', '6865ac4eca28f_1751493710.pdf', 'acte_de_naissance_papa_sadio (1).pdf', 84211, 'application/pdf', '', 'actif', '2025-07-03 00:01:50', '2025-07-03 00:01:50'),
(124, NULL, 1, 'acte_de_naissance_papa_sadio (1)', '', '6865aed86fbc8_1751494360.pdf', 'acte_de_naissance_papa_sadio (1).pdf', 84211, 'application/pdf', '', 'actif', '2025-07-03 00:12:40', '2025-07-03 00:12:40'),
(125, NULL, 1, '6865aa51389e9_1751493201', '', '6865b3f667ef2_1751495670.pdf', '6865aa51389e9_1751493201.pdf', 162834, 'application/pdf', '', 'actif', '2025-07-03 00:34:30', '2025-07-03 00:34:30'),
(126, NULL, 1, '6865aa51389e9_1751493201', '', '6865b82db649f_1751496749.pdf', '6865aa51389e9_1751493201.pdf', 162834, 'application/pdf', '', 'actif', '2025-07-03 00:52:29', '2025-07-03 00:52:29'),
(127, 2, 1, '6865aa51389e9_1751493201', '', '6865bbbb1139f_1751497659.pdf', '6865aa51389e9_1751493201.pdf', 162834, 'application/pdf', '', 'actif', '2025-07-03 01:07:39', '2025-07-03 01:07:39'),
(128, 2, 1, 'acte_de_naissance_papa_sadio (1)', '', '6865bf6ef2241_1751498606.pdf', 'acte_de_naissance_papa_sadio (1).pdf', 84211, 'application/pdf', '', 'actif', '2025-07-03 01:23:26', '2025-07-03 01:23:26'),
(129, 2, 1, '6865aa51389e9_1751493201', '', '6865c2a54fd49_1751499429.pdf', '6865aa51389e9_1751493201.pdf', 162834, 'application/pdf', '', 'actif', '2025-07-03 01:37:09', '2025-07-03 01:37:09'),
(130, NULL, 1, 'gg', NULL, '6865c2ac04960_1751499436_6865c2a54fd49_1751499429.pdf', '6865c2a54fd49_1751499429.pdf', 162834, 'application/pdf', NULL, 'actif', '2025-07-03 01:37:16', '2025-07-03 01:37:16'),
(131, 2, 1, '6865aa51389e9_1751493201', '', '6865c2b899c45_1751499448.pdf', '6865aa51389e9_1751493201.pdf', 162834, 'application/pdf', '', 'actif', '2025-07-03 01:37:28', '2025-07-03 01:37:28'),
(132, 2, 1, '6865aa51389e9_1751493201', '', '6865c2c82d141_1751499464.pdf', '6865aa51389e9_1751493201.pdf', 162834, 'application/pdf', '', 'actif', '2025-07-03 01:37:44', '2025-07-03 01:37:44'),
(133, 2, 1, '6865aa51389e9_1751493201', '', '6865c4af40550_1751499951.pdf', '6865aa51389e9_1751493201.pdf', 162834, 'application/pdf', '', 'actif', '2025-07-03 01:45:51', '2025-07-03 01:45:51'),
(134, 2, 1, '6865aa51389e9_1751493201', '', '6865c5bd77ee1_1751500221.pdf', '6865aa51389e9_1751493201.pdf', 162834, 'application/pdf', '', 'actif', '2025-07-03 01:50:21', '2025-07-03 01:50:21'),
(135, 2, 1, '6865aa51389e9_1751493201', '', '6865c65992c68_1751500377.pdf', '6865aa51389e9_1751493201.pdf', 162834, 'application/pdf', '', 'actif', '2025-07-03 01:52:57', '2025-07-03 01:52:57'),
(136, 2, 1, '6865aa51389e9_1751493201', '', '6865c66f1a175_1751500399.pdf', '6865aa51389e9_1751493201.pdf', 162834, 'application/pdf', '', 'actif', '2025-07-03 01:53:19', '2025-07-03 01:53:19'),
(137, 2, 1, '6865aa51389e9_1751493201', '', '6865c67d76255_1751500413.pdf', '6865aa51389e9_1751493201.pdf', 162834, 'application/pdf', '', 'actif', '2025-07-03 01:53:33', '2025-07-03 01:53:33'),
(138, 2, 1, '6865aa51389e9_1751493201', '', '6865c79b024a1_1751500699.pdf', '6865aa51389e9_1751493201.pdf', 162834, 'application/pdf', '', 'actif', '2025-07-03 01:58:19', '2025-07-03 01:58:19');

-- --------------------------------------------------------

--
-- Structure de la table `liens`
--

CREATE TABLE `liens` (
  `id` int NOT NULL,
  `document_id` int NOT NULL,
  `email` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `token` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `date_creation` datetime DEFAULT CURRENT_TIMESTAMP,
  `date_expiration` datetime DEFAULT NULL,
  `date_derniere_utilisation` datetime DEFAULT NULL,
  `nombre_acces` int DEFAULT '0',
  `status` enum('actif','expire','revoke') COLLATE utf8mb4_unicode_ci DEFAULT 'actif'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Déchargement des données de la table `liens`
--

INSERT INTO `liens` (`id`, `document_id`, `email`, `token`, `date_creation`, `date_expiration`, `date_derniere_utilisation`, `nombre_acces`, `status`) VALUES
(23, 25, 'mamanelawelsadio@gmail.com', 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTA4MDE5MDcsImV4cCI6MTc1MDg4ODMwNywiZG9jdW1lbnRfaWQiOiIyNSIsImVtYWlsIjoibWFtYW5lbGF3ZWxzYWRpb0BnbWFpbC5jb20iLCJ0eXBlIjoiZG9jdW1lbnRfYWNjZXNzIn0.h_bfebWSLr-55r4jU2UWAsbqGGVYGMqYCQcLoSs4yy8', '2025-06-24 23:51:47', '2025-06-25 23:51:47', '2025-06-24 23:51:47', 1, 'actif'),
(24, 30, 'sadio@sadio.com', 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTA4ODA2ODYsImV4cCI6MTc1MDk2NzA4NiwiZG9jdW1lbnRfaWQiOiIzMCIsImVtYWlsIjoic2FkaW9Ac2FkaW8uY29tIiwidHlwZSI6ImRvY3VtZW50X2FjY2VzcyJ9.q2blpAVui9bJ3FLXnPxprHhmzmw39BToGd3DTCn4um0', '2025-06-25 21:44:46', '2025-06-26 21:44:46', NULL, 0, 'actif'),
(25, 30, 'mamanelawelsadio@gmail.com', 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTA4ODA2ODYsImV4cCI6MTc1MDk2NzA4NiwiZG9jdW1lbnRfaWQiOiIzMCIsImVtYWlsIjoibWFtYW5lbGF3ZWxzYWRpb0BnbWFpbC5jb20iLCJ0eXBlIjoiZG9jdW1lbnRfYWNjZXNzIn0.kgb-CzT8f0ClogrQXi2erBGXMYog4lHlsge3SA2HK6U', '2025-06-25 21:44:46', '2025-06-26 21:44:46', NULL, 0, 'actif'),
(26, 30, 'test.hard.delete@example.com', 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTA4ODA2ODYsImV4cCI6MTc1MDk2NzA4NiwiZG9jdW1lbnRfaWQiOiIzMCIsImVtYWlsIjoidGVzdC5oYXJkLmRlbGV0ZUBleGFtcGxlLmNvbSIsInR5cGUiOiJkb2N1bWVudF9hY2Nlc3MifQ.eW_N5QX3tzw7SdgBC5OnEmrW68H4nYaw7GI4Waa_Ax8', '2025-06-25 21:44:46', '2025-06-26 21:44:46', NULL, 0, 'actif'),
(27, 30, 'test.final@example.com', 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTA4ODA2ODYsImV4cCI6MTc1MDk2NzA4NiwiZG9jdW1lbnRfaWQiOiIzMCIsImVtYWlsIjoidGVzdC5maW5hbEBleGFtcGxlLmNvbSIsInR5cGUiOiJkb2N1bWVudF9hY2Nlc3MifQ.Q0eZPgRTI1taeVy2Vnxt28zX_Iirr0C64T2Y_to7jpg', '2025-06-25 21:44:46', '2025-06-26 21:44:46', NULL, 0, 'actif'),
(28, 30, 'frontend.test@example.com', 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTA4ODA2ODYsImV4cCI6MTc1MDk2NzA4NiwiZG9jdW1lbnRfaWQiOiIzMCIsImVtYWlsIjoiZnJvbnRlbmQudGVzdEBleGFtcGxlLmNvbSIsInR5cGUiOiJkb2N1bWVudF9hY2Nlc3MifQ.4P4y8uP4gJrm3ttDyy3eZymp1jPn7Czg6_EQPEZOz_I', '2025-06-25 21:44:46', '2025-06-26 21:44:46', '2025-06-25 21:44:46', 5, 'actif'),
(29, 40, 'test1@example.com', 'c11d3a351c1fc233b184ee266ba75f9fced10b9f2bfaa460b26aa94a2c5a3af9', '2025-06-25 23:36:17', '2025-07-25 21:36:17', NULL, 0, 'actif'),
(30, 40, 'test2@example.com', '627dcd43d8b10085a08fb98abeb4f7c36d228c8b2ae2ea01c00dd64482d5e763', '2025-06-25 23:36:17', '2025-07-25 21:36:17', NULL, 0, 'actif'),
(31, 41, 'test1@example.com', '95723bf044e20dc2974049084e76e9563fa0c0caece501ec4b9cae363ebbabc0', '2025-06-25 23:39:18', '2025-07-25 21:39:18', NULL, 0, 'actif'),
(32, 41, 'test2@example.com', '080c950b5936e60420861a54c4dcc7c75c05bd637d4e8a5affc7b5f4b61d6bbb', '2025-06-25 23:39:18', '2025-07-25 21:39:18', NULL, 0, 'actif'),
(33, 43, 'test@example.com', 'ad47e747ff7fb199bc5cec57632846b04e097b93d4c498be0ca9778763cda3ac', '2025-06-26 00:08:10', '2025-07-25 22:08:10', NULL, 0, 'actif'),
(34, 43, 'admin@isend.com', '4cfb78eac927bec4b79f42086e9f0bc79b67d24679a38283e0702cd270f41502', '2025-06-26 00:08:10', '2025-07-25 22:08:10', NULL, 0, 'actif'),
(35, 45, 'mamanelawelsadio@gmail.com', 'c2fea09ebae8feaa2a33ad5e330088fd7dd4c9f41e27214df519051d9f31d7fe', '2025-06-26 00:45:55', '2025-07-25 22:45:55', NULL, 0, 'actif'),
(36, 47, 'sadio@sadio.com', 'c7205d6361a712360472fb88459301577ee372e0fb279ea46427d51bd32075b6', '2025-06-26 00:57:04', '2025-07-25 22:57:04', NULL, 0, 'actif'),
(37, 47, 'mamanelawelsadio@gmail.com', '648ec74779441b2c3e26e29480bd8544831c94cd5020006ec63e2148353c51a4', '2025-06-26 00:57:04', '2025-07-25 22:57:04', NULL, 0, 'actif'),
(38, 47, 'test.hard.delete@example.com', '01343bb9b33a9e7a97387204c703e73767e28111c94f2d3c813a94af02237e76', '2025-06-26 00:57:05', '2025-07-25 22:57:05', NULL, 0, 'actif'),
(39, 47, 'test.final@example.com', '50f6f9961339925f3edd15e4a5bfbb506db4a7fcdcdb3eaeeda89803fd68d8d5', '2025-06-26 00:57:05', '2025-07-25 22:57:05', NULL, 0, 'actif'),
(40, 47, 'frontend.test@example.com', '0caada81c3b114f4f5785b0e87ec8bbdb8d4ea138b9f0d0e620945d308ae5564', '2025-06-26 00:57:05', '2025-07-25 22:57:05', NULL, 0, 'actif'),
(41, 49, 'mamanelawelsadio@gmail.com', '45819c832f84548a7239facfaa62b1c2e7945d83a239d6dd74a15c76fdb64a7d', '2025-06-27 23:09:07', '2025-07-27 21:09:07', NULL, 0, 'actif'),
(42, 51, 'mamanelawelsadio@gmail.com', '31f99c9a25a97705e114f3d17171737c55deb417841209f316df42de57140c99', '2025-06-28 11:25:12', '2025-07-28 09:25:12', NULL, 0, 'actif'),
(43, 69, 'mamanelawelsadio@gmail.com', 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTExMTYxMjUsImV4cCI6MTc1MTIwMjUyNSwiZG9jdW1lbnRfaWQiOiI2OSIsImVtYWlsIjoibWFtYW5lbGF3ZWxzYWRpb0BnbWFpbC5jb20iLCJ0eXBlIjoiZG9jdW1lbnRfYWNjZXNzIn0.hEqUj0hJEEMVsLrLvKYr8CgG7bTb8KREeVOnaQ7B7EQ', '2025-06-28 15:08:45', '2025-06-29 15:08:45', NULL, 0, 'actif'),
(44, 85, 'mamanelawelsadio@gmail.com', 'PDF_SECURE_1751121453', '2025-06-28 16:37:33', '2025-07-28 16:37:33', '2025-06-28 16:37:33', 1, 'actif'),
(45, 88, 'mamanelawelsadio@gmail.com', 'PDF_SECURE_1751122794', '2025-06-28 16:59:54', '2025-07-28 16:59:54', '2025-06-28 16:59:54', 1, 'actif'),
(46, 91, 'mamanelawelsadio@gmail.com', 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTExMjM5OTQsImV4cCI6MTc1MTIxMDM5NCwiZG9jdW1lbnRfaWQiOiI5MSIsImVtYWlsIjoibWFtYW5lbGF3ZWxzYWRpb0BnbWFpbC5jb20iLCJ0eXBlIjoiZG9jdW1lbnRfYWNjZXNzIn0.aSx0LzuDO0vCmC8lxvO9MpqbNHn682IjcmozOALVGUg', '2025-06-28 17:19:54', '2025-06-29 17:19:54', NULL, 0, 'actif'),
(47, 92, 'mamanelawelsadio@gmail.com', 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTExMjQ0ODUsImV4cCI6MTc1MTIxMDg4NSwiZG9jdW1lbnRfaWQiOiI5MiIsImVtYWlsIjoibWFtYW5lbGF3ZWxzYWRpb0BnbWFpbC5jb20iLCJ0eXBlIjoiZG9jdW1lbnRfYWNjZXNzIn0.Q6uOHRQlk6Ifnx5vCVthnb-mJ9gN3AydSREIQGaS_P4', '2025-06-28 17:28:05', '2025-06-29 17:28:05', '2025-06-28 17:28:07', 1, 'actif'),
(48, 93, 'mamanelawelsadio@gmail.com', 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTExMzcyNzgsImV4cCI6MTc1MTIyMzY3OCwiZG9jdW1lbnRfaWQiOiI5MyIsImVtYWlsIjoibWFtYW5lbGF3ZWxzYWRpb0BnbWFpbC5jb20iLCJ0eXBlIjoiZG9jdW1lbnRfYWNjZXNzIn0.XaWf_26Eid0j3zv6J63KLGh1e85Zn_vkVfUI2lhu5aI', '2025-06-28 21:01:18', '2025-06-29 21:01:18', NULL, 0, 'actif'),
(49, 94, 'mamanelawelsadio@gmail.com', 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTExMzc2MTYsImV4cCI6MTc1MTIyNDAxNiwiZG9jdW1lbnRfaWQiOiI5NCIsImVtYWlsIjoibWFtYW5lbGF3ZWxzYWRpb0BnbWFpbC5jb20iLCJ0eXBlIjoiZG9jdW1lbnRfYWNjZXNzIn0.uPNZcKR8yh8Fs8jOoTGMMs2T0GT4O3yK0THiTQGpnlQ', '2025-06-28 21:06:56', '2025-06-29 21:06:56', '2025-06-28 21:06:58', 1, 'actif'),
(50, 95, 'mamanelawelsadio@gmail.com', 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTExMzgwNDEsImV4cCI6MTc1MTIyNDQ0MSwiZG9jdW1lbnRfaWQiOiI5NSIsImVtYWlsIjoibWFtYW5lbGF3ZWxzYWRpb0BnbWFpbC5jb20iLCJ0eXBlIjoiZG9jdW1lbnRfYWNjZXNzIn0.cpfaEl7P17ABx9emnt7vnPFkVy1ESBA8KBPcCZGKJmE', '2025-06-28 21:14:01', '2025-06-29 21:14:01', '2025-06-28 23:53:12', 25, 'actif'),
(51, 96, 'mamanelawelsadio@gmail.com', 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTExNDc3MjEsImV4cCI6MTc1MTIzNDEyMSwiZG9jdW1lbnRfaWQiOiI5NiIsImVtYWlsIjoibWFtYW5lbGF3ZWxzYWRpb0BnbWFpbC5jb20iLCJ0eXBlIjoiZG9jdW1lbnRfYWNjZXNzIn0.ISNkZy99eh8iOeRiFxz3pd6MNtOVHeOPS093nD6w4fc', '2025-06-28 23:55:21', '2025-06-29 23:55:21', '2025-06-28 23:58:27', 25, 'actif'),
(52, 97, 'mamanelawelsadio@gmail.com', 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTExNTYwNzEsImV4cCI6MTc1MTI0MjQ3MSwiZG9jdW1lbnRfaWQiOiI5NyIsImVtYWlsIjoibWFtYW5lbGF3ZWxzYWRpb0BnbWFpbC5jb20iLCJ0eXBlIjoiZG9jdW1lbnRfYWNjZXNzIn0.Vwi4_mQtN_lv9CLNqdNuqpblscRkV4HRkJa8_ihfoKg', '2025-06-29 02:14:31', '2025-06-30 02:14:31', '2025-06-29 02:14:32', 1, 'actif'),
(53, 98, 'mamanelawelsadio@gmail.com', 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTExNTYzMjEsImV4cCI6MTc1MTI0MjcyMSwiZG9jdW1lbnRfaWQiOiI5OCIsImVtYWlsIjoibWFtYW5lbGF3ZWxzYWRpb0BnbWFpbC5jb20iLCJ0eXBlIjoiZG9jdW1lbnRfYWNjZXNzIn0.L_pwOdXrS1DId-HJy2NDbj_5OaU7dxFXcoTALYgkZKs', '2025-06-29 02:18:41', '2025-06-30 02:18:41', '2025-06-29 02:18:44', 1, 'actif'),
(54, 99, 'mamanelawelsadio@gmail.com', 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTExOTEyMjQsImV4cCI6MTc1MTI3NzYyNCwiZG9jdW1lbnRfaWQiOiI5OSIsImVtYWlsIjoibWFtYW5lbGF3ZWxzYWRpb0BnbWFpbC5jb20iLCJ0eXBlIjoiZG9jdW1lbnRfYWNjZXNzIn0.-hlUI8_rtno9ePSK90JB7JnGl_N5q0i3B_aAtdy2i0Q', '2025-06-29 12:00:24', '2025-06-30 12:00:24', '2025-06-29 12:00:26', 1, 'actif'),
(55, 100, 'test-no-subscription@example.com', '073cf0aa1025f52aa9df9960602fc64e313b83cb74211fbdd0acb0fceea0faa9', '2025-06-29 12:15:46', '2025-06-30 12:15:46', NULL, 0, 'actif'),
(56, 100, 'test-with-subscription@example.com', '1b1b2868335accac1edad3c4825e2ff010b70961e118d1ad6343e865f971c180', '2025-06-29 12:15:46', '2025-06-30 12:15:46', '2025-06-29 12:16:33', 4, 'actif'),
(57, 101, 'mamanelawelsadio@gmail.com', 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTEyMTI3ODEsImV4cCI6MTc1MTI5OTE4MSwiZG9jdW1lbnRfaWQiOiIxMDEiLCJlbWFpbCI6Im1hbWFuZWxhd2Vsc2FkaW9AZ21haWwuY29tIiwidHlwZSI6ImRvY3VtZW50X2FjY2VzcyJ9.3IH4Ztj5YiNGYQwUfimp5F1Uc9RqhLNVmb4r2uqnFac', '2025-06-29 17:59:41', '2025-06-30 17:59:41', '2025-06-29 17:59:42', 1, 'actif'),
(58, 102, 'mamanelawelsadio@gmail.com', 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTEyMTI5MTUsImV4cCI6MTc1MTI5OTMxNSwiZG9jdW1lbnRfaWQiOiIxMDIiLCJlbWFpbCI6Im1hbWFuZWxhd2Vsc2FkaW9AZ21haWwuY29tIiwidHlwZSI6ImRvY3VtZW50X2FjY2VzcyJ9.r1B8hyoWlyhmm_XG8fr0v7HrtUPhyuGwFUi7T4OqNas', '2025-06-29 18:01:55', '2025-06-30 18:01:55', '2025-06-29 18:01:57', 1, 'actif'),
(59, 106, 'mamanelawelsadio@gmail.com', 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTEzOTYzMjEsImV4cCI6MTc1MTQ4MjcyMSwiZG9jdW1lbnRfaWQiOiIxMDYiLCJlbWFpbCI6Im1hbWFuZWxhd2Vsc2FkaW9AZ21haWwuY29tIiwidHlwZSI6ImRvY3VtZW50X2FjY2VzcyJ9.o3F3hULHNXCTYV-CID1_wc2iG9QilCV7FuVw669bPyY', '2025-07-01 20:58:41', '2025-07-02 20:58:41', '2025-07-01 20:59:16', 7, 'actif'),
(60, 107, 'mamanelawelsadio@gmail.com', 'PDF_SECURE_1751396457', '2025-07-01 21:00:57', '2025-07-31 21:00:57', '2025-07-01 21:00:57', 1, 'actif'),
(61, 119, 'mamanelawelsadio@gmail.com', 'PDF_SECURE_1751493108', '2025-07-02 23:51:48', '2025-08-01 23:51:48', '2025-07-02 23:51:48', 1, 'actif'),
(62, 123, 'mamanelawelsadio@gmail.com', 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTE0OTM3MjUsImV4cCI6MTc1MTU4MDEyNSwiZG9jdW1lbnRfaWQiOiIxMjMiLCJlbWFpbCI6Im1hbWFuZWxhd2Vsc2FkaW9AZ21haWwuY29tIiwidHlwZSI6ImRvY3VtZW50X2FjY2VzcyJ9.esaCE3VbeQ2pWgB-tc0YKkSh8byqMxLrfMYeEbcJKLU', '2025-07-03 00:02:05', '2025-07-04 00:02:05', '2025-07-03 00:02:07', 1, 'actif'),
(63, 124, 'mamanelawelsadio@gmail.com', 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTE0OTQzNzUsImV4cCI6MTc1MTU4MDc3NSwiZG9jdW1lbnRfaWQiOiIxMjQiLCJlbWFpbCI6Im1hbWFuZWxhd2Vsc2FkaW9AZ21haWwuY29tIiwidHlwZSI6ImRvY3VtZW50X2FjY2VzcyJ9.IjbwUqNpGL5O6kx_ZxZmWmFB6VVpKEmnKBDVTHcBruw', '2025-07-03 00:12:55', '2025-07-04 00:12:55', '2025-07-03 00:12:56', 1, 'actif'),
(64, 125, 'mamanelawelsadio@gmail.com', 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTE0OTU2NzYsImV4cCI6MTc1MTU4MjA3NiwiZG9jdW1lbnRfaWQiOiIxMjUiLCJlbWFpbCI6Im1hbWFuZWxhd2Vsc2FkaW9AZ21haWwuY29tIiwidHlwZSI6ImRvY3VtZW50X2FjY2VzcyJ9.ZmYEsLzTP9kWzNwDy4XzJgencDh0hPFY-iGDQWZFvGM', '2025-07-03 00:34:36', '2025-07-04 00:34:36', '2025-07-03 00:34:37', 1, 'actif'),
(65, 126, 'mamanelawelsadio@gmail.com', 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTE0OTY3NTUsImV4cCI6MTc1MTU4MzE1NSwiZG9jdW1lbnRfaWQiOiIxMjYiLCJlbWFpbCI6Im1hbWFuZWxhd2Vsc2FkaW9AZ21haWwuY29tIiwidHlwZSI6ImRvY3VtZW50X2FjY2VzcyJ9.G3CBTY-BhrKJ3iTm1Bv4sfpYbd0j9yZ-5MmgEcaMdU4', '2025-07-03 00:52:35', '2025-07-04 00:52:35', '2025-07-03 00:52:36', 1, 'actif'),
(66, 127, 'mamanelawelsadio@gmail.com', 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTE0OTc2NjUsImV4cCI6MTc1MTU4NDA2NSwiZG9jdW1lbnRfaWQiOiIxMjciLCJlbWFpbCI6Im1hbWFuZWxhd2Vsc2FkaW9AZ21haWwuY29tIiwidHlwZSI6ImRvY3VtZW50X2FjY2VzcyJ9.wpdET89ql9W6HRacV8MUnwM3p6vp2XcE3GbIOZnwYZ0', '2025-07-03 01:07:45', '2025-07-04 01:07:45', '2025-07-03 01:34:57', 27, 'actif'),
(67, 128, 'mamanelawelsadio@gmail.com', 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTE0OTg2MTEsImV4cCI6MTc1MTU4NTAxMSwiZG9jdW1lbnRfaWQiOiIxMjgiLCJlbWFpbCI6Im1hbWFuZWxhd2Vsc2FkaW9AZ21haWwuY29tIiwidHlwZSI6ImRvY3VtZW50X2FjY2VzcyJ9.xILfxQBy7Ew1Nd2l7HZXoST2L6TfHXaagn2JahUBzls', '2025-07-03 01:23:31', '2025-07-04 01:23:31', '2025-07-03 01:36:48', 23, 'actif'),
(68, 131, 'mamanelawelsadio@gmail.com', '471b6c02e1a8f42ab50417093e3a74d37d94c917cca4a1903d2087343f68c99e', '2025-07-03 01:37:34', '2025-08-02 01:37:34', NULL, 0, 'actif'),
(69, 133, 'mamanelawelsadio@gmail.com', 'f60d08d8b1aa2f4b4f4a8a77cac7d61430b78d43542804aba67d0866c2572457', '2025-07-03 01:46:46', '2025-08-02 01:46:46', NULL, 0, 'actif'),
(70, 134, 'mamanelawelsadio@gmail.com', 'c5db1a0b5c76f2347e1e1f1dc88bc956d9c994578cceb6f3aa80cac095dd179b', '2025-07-03 01:50:29', '2025-08-02 01:50:29', NULL, 0, 'actif'),
(71, 135, 'mamanelawelsadio@gmail.com', 'e7c89a60840e5c36552bf25de16da968fa776cc08bebe951fa0eecd30d9d06a4', '2025-07-03 01:53:04', '2025-08-02 01:53:04', NULL, 0, 'actif'),
(72, 138, 'mamanelawelsadio@gmail.com', 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTE1MDA3MDUsImV4cCI6MTc1MTU4NzEwNSwiZG9jdW1lbnRfaWQiOiIxMzgiLCJlbWFpbCI6Im1hbWFuZWxhd2Vsc2FkaW9AZ21haWwuY29tIiwidHlwZSI6ImRvY3VtZW50X2FjY2VzcyJ9.Q6oSxyUAi8AERmqnLxoQy_0-cgxM8g1v7q9sZSRuGDY', '2025-07-03 01:58:25', '2025-07-04 01:58:25', '2025-07-03 01:58:42', 7, 'actif');

-- --------------------------------------------------------

--
-- Structure de la table `login_attempts`
--

CREATE TABLE `login_attempts` (
  `id` int NOT NULL,
  `email` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `ip_address` varchar(45) COLLATE utf8mb4_unicode_ci NOT NULL,
  `user_agent` text COLLATE utf8mb4_unicode_ci,
  `success` tinyint(1) NOT NULL DEFAULT '0',
  `attempt_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Déchargement des données de la table `login_attempts`
--

INSERT INTO `login_attempts` (`id`, `email`, `ip_address`, `user_agent`, `success`, `attempt_time`, `created_at`) VALUES
(1, 'admin@isend.com', '::1', NULL, 1, '2025-06-22 17:36:10', '2025-06-22 15:36:10'),
(2, 'admin@isend.com', '::1', NULL, 1, '2025-06-22 17:36:14', '2025-06-22 15:36:14'),
(3, 'admin@isend.com', '::1', NULL, 1, '2025-06-22 17:36:33', '2025-06-22 15:36:33'),
(4, 'admin@isend.com', '::1', NULL, 1, '2025-06-22 17:36:43', '2025-06-22 15:36:43'),
(5, 'admin@isend.com', '::1', NULL, 1, '2025-06-22 17:37:11', '2025-06-22 15:37:11'),
(6, 'admin@isend.com', '::1', NULL, 1, '2025-06-22 17:37:32', '2025-06-22 15:37:32'),
(7, 'admin@isend.com', '::1', NULL, 1, '2025-06-22 17:50:06', '2025-06-22 15:50:06'),
(8, 'admin@isend.com', '::1', NULL, 1, '2025-06-22 17:54:47', '2025-06-22 15:54:47'),
(9, 'invalid@test.com', '::1', NULL, 0, '2025-06-22 17:54:47', '2025-06-22 15:54:47'),
(10, 'admin@isend.com', '::1', NULL, 1, '2025-06-22 17:55:32', '2025-06-22 15:55:32'),
(11, 'admin@isend.com', '::1', NULL, 1, '2025-06-22 17:55:33', '2025-06-22 15:55:33'),
(12, 'invalid@test.com', '::1', NULL, 0, '2025-06-22 17:55:33', '2025-06-22 15:55:33'),
(13, 'admin@isend.com', '::1', NULL, 1, '2025-06-22 17:57:15', '2025-06-22 15:57:15'),
(14, 'admin@isend.com', '::1', NULL, 1, '2025-06-22 18:23:46', '2025-06-22 16:23:46'),
(15, 'admin@isend.com', '::1', NULL, 1, '2025-06-22 18:24:15', '2025-06-22 16:24:15'),
(16, 'admin@isend.com', '::1', NULL, 1, '2025-06-22 18:24:56', '2025-06-22 16:24:56'),
(17, 'admin@isend.com', '::1', NULL, 1, '2025-06-22 18:27:59', '2025-06-22 16:27:59'),
(18, 'admin@isend.com', '::1', NULL, 1, '2025-06-22 18:28:30', '2025-06-22 16:28:30'),
(19, 'admin@isend.com', '::1', NULL, 1, '2025-06-22 19:04:39', '2025-06-22 17:04:39'),
(20, 'admin@isend.com', '::1', NULL, 1, '2025-06-22 20:05:11', '2025-06-22 18:05:11'),
(21, 'admin@isend.com', '::1', NULL, 0, '2025-06-22 22:58:56', '2025-06-22 20:58:56'),
(22, 'admin@isend.com', '::1', NULL, 1, '2025-06-22 22:59:24', '2025-06-22 20:59:24'),
(23, 'admin@isend.com', '::1', NULL, 1, '2025-06-24 22:38:36', '2025-06-24 20:38:36'),
(24, 'admin@isend.com', '::1', NULL, 0, '2025-06-24 23:16:26', '2025-06-24 21:16:26'),
(25, 'admin@isend.com', '::1', NULL, 1, '2025-06-24 23:17:31', '2025-06-24 21:17:31'),
(26, 'admin@isend.com', '::1', NULL, 1, '2025-06-24 23:18:14', '2025-06-24 21:18:14'),
(27, 'admin@isend.com', '::1', NULL, 1, '2025-06-24 23:18:35', '2025-06-24 21:18:35'),
(28, 'admin@isend.com', '::1', NULL, 1, '2025-06-25 00:19:33', '2025-06-24 22:19:33'),
(29, 'admin@isend.com', '::1', NULL, 1, '2025-06-25 21:03:57', '2025-06-25 19:03:57'),
(30, 'admin@isend.com', '::1', NULL, 1, '2025-06-25 22:09:27', '2025-06-25 20:09:27'),
(31, 'admin@isend.com', '::1', NULL, 1, '2025-06-25 23:16:50', '2025-06-25 21:16:50'),
(32, 'admin@isend.com', '::1', NULL, 1, '2025-06-26 00:45:06', '2025-06-25 22:45:06'),
(33, 'admin@isend.com', '::1', NULL, 1, '2025-06-27 22:49:24', '2025-06-27 20:49:24'),
(34, 'admin@isend.com', '::1', NULL, 1, '2025-06-28 11:24:26', '2025-06-28 09:24:26'),
(35, 'admin@isend.com', '::1', NULL, 1, '2025-06-28 14:12:12', '2025-06-28 12:12:12'),
(36, 'admin@isend.com', '::1', NULL, 1, '2025-06-28 15:18:54', '2025-06-28 13:18:54'),
(37, 'admin@isend.com', '::1', NULL, 1, '2025-06-28 15:20:56', '2025-06-28 13:20:56'),
(38, 'admin@isend.com', '::1', NULL, 1, '2025-06-28 16:21:33', '2025-06-28 14:21:33'),
(39, 'admin@isend.com', '::1', NULL, 1, '2025-06-28 17:26:43', '2025-06-28 15:26:43'),
(40, 'admin@isend.com', '::1', NULL, 1, '2025-06-28 21:00:45', '2025-06-28 19:00:45'),
(41, 'admin@isend.com', '::1', NULL, 1, '2025-06-28 23:54:16', '2025-06-28 21:54:16'),
(42, 'admin@isend.com', '::1', NULL, 1, '2025-06-29 02:13:39', '2025-06-29 00:13:39'),
(43, 'admin@isend.com', '::1', NULL, 1, '2025-06-29 11:59:50', '2025-06-29 09:59:50'),
(44, 'admin@isend.com', '::1', NULL, 1, '2025-06-29 17:59:04', '2025-06-29 15:59:04'),
(45, 'admin@isend.com', '::1', NULL, 1, '2025-06-29 19:06:26', '2025-06-29 17:06:26'),
(46, 'test@isend.com', '::1', NULL, 0, '2025-06-29 19:17:59', '2025-06-29 17:17:59'),
(47, 'admin@isend.com', '::1', NULL, 1, '2025-06-29 20:18:06', '2025-06-29 18:18:06'),
(48, 'admin@isend.com', '::1', NULL, 1, '2025-06-29 21:52:15', '2025-06-29 19:52:15'),
(49, 'admin@isend.com', '::1', NULL, 1, '2025-06-29 22:52:42', '2025-06-29 20:52:42'),
(50, 'admin@isend.com', '::1', NULL, 1, '2025-06-29 23:10:25', '2025-06-29 21:10:25'),
(51, 'admin@isend.com', '::1', NULL, 1, '2025-06-29 23:53:09', '2025-06-29 21:53:09'),
(52, 'admin@isend.com', '::1', NULL, 1, '2025-07-01 20:57:21', '2025-07-01 18:57:21'),
(53, 'admin@isend.com', '::1', NULL, 1, '2025-07-01 23:45:19', '2025-07-01 21:45:19'),
(54, 'admin@isend.com', '::1', NULL, 1, '2025-07-02 20:52:28', '2025-07-02 18:52:28'),
(55, 'admin@isend.com', '::1', NULL, 1, '2025-07-02 20:56:23', '2025-07-02 18:56:23'),
(56, 'admin@isend.com', '::1', NULL, 1, '2025-07-02 22:12:36', '2025-07-02 20:12:36'),
(57, 'admin@isend.com', '::1', NULL, 1, '2025-07-02 23:15:59', '2025-07-02 21:15:59'),
(58, 'admin@isend.com', '::1', NULL, 1, '2025-07-03 00:24:17', '2025-07-02 22:24:17'),
(59, 'admin@isend.com', '::1', NULL, 1, '2025-07-03 01:36:59', '2025-07-02 23:36:59');

-- --------------------------------------------------------

--
-- Structure de la table `logs_acces`
--

CREATE TABLE `logs_acces` (
  `id` int NOT NULL,
  `token` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `email` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `status` enum('succes','erreur','refuse') COLLATE utf8mb4_unicode_ci NOT NULL,
  `message` text COLLATE utf8mb4_unicode_ci,
  `ip_address` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `user_agent` text COLLATE utf8mb4_unicode_ci,
  `date_acces` datetime DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Déchargement des données de la table `logs_acces`
--

INSERT INTO `logs_acces` (`id`, `token`, `email`, `status`, `message`, `ip_address`, `user_agent`, `date_acces`) VALUES
(1, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTA1NTMzMjcsImV4cCI6MTc1MDYzOTcyNywiZG9jdW1lbnRfaWQiOjEsImVtYWlsIjoidGVzdEBleGFtcGxlLmNvbSIsInR5cGUiOiJkb2N1bWVudF9hY2Nlc3MifQ.XHZjtFB6mKSGoPoqfq82g_isUP_E_djgzz9HnopR2Zk', 'test@example.com', 'succes', 'Email envoyé avec succès', '::1', 'curl/8.7.1', '2025-06-22 02:48:47'),
(2, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTA1NTMzNzgsImV4cCI6MTc1MDYzOTc3OCwiZG9jdW1lbnRfaWQiOjEsImVtYWlsIjoiZGVzdGluYXRhaXJlMkBleGFtcGxlLmNvbSIsInR5cGUiOiJkb2N1bWVudF9hY2Nlc3MifQ.BFSEW77rhgZ9S7sh9FjxkITaDW2yg0uILNJ-R4Qk6uk', 'destinataire1@example.com', 'succes', 'Email envoyé avec succès', '::1', 'curl/8.7.1', '2025-06-22 02:49:38'),
(3, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTA1NTMzNzgsImV4cCI6MTc1MDYzOTc3OCwiZG9jdW1lbnRfaWQiOjEsImVtYWlsIjoiZGVzdGluYXRhaXJlMkBleGFtcGxlLmNvbSIsInR5cGUiOiJkb2N1bWVudF9hY2Nlc3MifQ.BFSEW77rhgZ9S7sh9FjxkITaDW2yg0uILNJ-R4Qk6uk', 'destinataire2@example.com', 'succes', 'Email envoyé avec succès', '::1', 'curl/8.7.1', '2025-06-22 02:49:38'),
(4, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTA1NTM2NDEsImV4cCI6MTc1MDY0MDA0MSwiZG9jdW1lbnRfaWQiOjEsImVtYWlsIjoidGVzdC1mcm9udGVuZEBleGFtcGxlLmNvbSIsInR5cGUiOiJkb2N1bWVudF9hY2Nlc3MifQ.NuBGPfDhELajMgOQuPxTl9v6hAfASVd3V0Xs37LWI_o', 'test-frontend@example.com', 'succes', 'Email envoyé avec succès', '::1', 'curl/8.7.1', '2025-06-22 02:54:01'),
(5, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTA1NTM2NjIsImV4cCI6MTc1MDY0MDA2MiwiZG9jdW1lbnRfaWQiOiI0IiwiZW1haWwiOiJtYW1hbmVsYXdlbHNhZGlvQGdtYWlsLmNvbSIsInR5cGUiOiJkb2N1bWVudF9hY2Nlc3MifQ.zIDOw4jdrpoXPF2YTBSRen-r5Dn4tPt-KwJ5fWoWwRs', 'mamanelawelsadio@gmail.com', 'succes', 'Email envoyé avec succès', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-22 02:54:22'),
(6, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTA1NTM2OTUsImV4cCI6MTc1MDY0MDA5NSwiZG9jdW1lbnRfaWQiOiI1IiwiZW1haWwiOiJtYW1hbmVsYXdlbHNhZGlvQGdtYWlsLmNvbSIsInR5cGUiOiJkb2N1bWVudF9hY2Nlc3MifQ.jx2-Gh91owbShAQXbhuRPnVfqOOPNM2L4lLeyq96MW4', 'mamanelawelsadio@gmail.com', 'succes', 'Email envoyé avec succès', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-22 02:54:55'),
(7, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTA1NTM5OTYsImV4cCI6MTc1MDY0MDM5NiwiZG9jdW1lbnRfaWQiOiI2IiwiZW1haWwiOiJtYW1hbmVsYXdlbHNhZGlvQGdtYWlsLmNvbSIsInR5cGUiOiJkb2N1bWVudF9hY2Nlc3MifQ.AgJzEjTWLZlCCtkwK1C0fm2cdfYUEO76eGwv_3Wgza8', 'mamanelawelsadio@gmail.com', 'succes', 'Email envoyé avec succès', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-22 02:59:56'),
(8, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTA1NTQxNjMsImV4cCI6MTc1MDY0MDU2MywiZG9jdW1lbnRfaWQiOiI3IiwiZW1haWwiOiJtZWxsb3dAdGVzdC5jb20iLCJ0eXBlIjoiZG9jdW1lbnRfYWNjZXNzIn0.HoVt0PCSQNxWgxytRL4sJ_7kax-zrOoLeGuCMY1Utos', 'mellow@test.com', 'succes', 'Email envoyé avec succès', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-22 03:02:43'),
(9, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTA1NTU1MTAsImV4cCI6MTc1MDY0MTkxMCwiZG9jdW1lbnRfaWQiOiI4IiwiZW1haWwiOiJtZWxsb3dyaW1lQGdtYWlsLmNvbSIsInR5cGUiOiJkb2N1bWVudF9hY2Nlc3MifQ.bKKOvFzLwRtv2SV-9Ejvt6elJQLmBXXHpNvqerXBCWE', 'mellowrime@gmail.com', 'succes', 'Email envoyé avec succès', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-22 03:25:10'),
(10, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTA1NTYyNzQsImV4cCI6MTc1MDY0MjY3NCwiZG9jdW1lbnRfaWQiOiI5IiwiZW1haWwiOiJ0ZXN0QHRlc3QuY29tIiwidHlwZSI6ImRvY3VtZW50X2FjY2VzcyJ9.a88igwJ6WraqZu2smUf5BvAeYkHPID45wqFVfoLwD9Y', 'test@test.com', 'succes', 'Email envoyé avec succès', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-22 03:37:54'),
(11, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTA1NjMxNjcsImV4cCI6MTc1MDY0OTU2NywiZG9jdW1lbnRfaWQiOiIxMSIsImVtYWlsIjoidGVzdEB0ZXN0LmNvbSIsInR5cGUiOiJkb2N1bWVudF9hY2Nlc3MifQ.7psmaYC-7Ts2WajNCsguTUiOXnS6aOe7yk8b2iFRdG0', 'test@test.com', 'succes', 'Email envoyé avec succès', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-22 05:32:47'),
(12, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTA1NjY1NjAsImV4cCI6MTc1MDY1Mjk2MCwiZG9jdW1lbnRfaWQiOjEyLCJlbWFpbCI6InNhZGlvQHNhZGlvLmNvbSIsInR5cGUiOiJkb2N1bWVudF9hY2Nlc3MifQ.-RMM_7YdxpjUR4RiQY4AGoUSFItnZapNRZKkml8lteU', 'sadio@sadio.com', 'succes', 'Email envoyé avec succès', '::1', 'curl/8.7.1', '2025-06-22 06:29:20'),
(13, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTA1NjY2MTUsImV4cCI6MTc1MDY1MzAxNSwiZG9jdW1lbnRfaWQiOiIxMyIsImVtYWlsIjoic2FkaW9Ac2FkaW8uY29tIiwidHlwZSI6ImRvY3VtZW50X2FjY2VzcyJ9.g0yfHvgVorz_bVnYrEM2tcG9HCMdpJMhAgyWRntbQFw', 'sadio@sadio.com', 'succes', 'Email envoyé avec succès', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-22 06:30:15'),
(14, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTA1NjY3MjMsImV4cCI6MTc1MDY1MzEyMywiZG9jdW1lbnRfaWQiOiIxNCIsImVtYWlsIjoic2FkaW9Ac2FkaW8uY29tIiwidHlwZSI6ImRvY3VtZW50X2FjY2VzcyJ9.GZa0RwxddLfOCTk_UMpjALJV98jbDpu07_SrxVAqus8', 'sadio@sadio.com', 'succes', 'Email envoyé avec succès', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-22 06:32:03'),
(15, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTA1NjY4MTcsImV4cCI6MTc1MDY1MzIxNywiZG9jdW1lbnRfaWQiOiIxNSIsImVtYWlsIjoic2FkaW9Ac2FkaW8uY29tIiwidHlwZSI6ImRvY3VtZW50X2FjY2VzcyJ9.1ySFH_NJkrAkxYm7rBoqdm5BjVW_DI5uJtlfv7sMWcc', 'sadio@sadio.com', 'succes', 'Email envoyé avec succès', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-22 06:33:37'),
(16, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTA1NjY4NjEsImV4cCI6MTc1MDY1MzI2MSwiZG9jdW1lbnRfaWQiOiIxNiIsImVtYWlsIjoic2FkaW9Ac2FkaW8uY29tIiwidHlwZSI6ImRvY3VtZW50X2FjY2VzcyJ9.rdEQ72Sl4FmUbE07wCBWSnKzu9yyxJIfuGjCc3J2YME', 'sadio@sadio.com', 'succes', 'Email envoyé avec succès', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-22 06:34:21'),
(17, 'test', 'test@test.com', 'refuse', 'Lien invalide ou expiré', '::1', 'curl/8.7.1', '2025-06-22 06:37:58'),
(18, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTA1NjcxMjEsImV4cCI6MTc1MDY1MzUyMSwiZG9jdW1lbnRfaWQiOiIxNyIsImVtYWlsIjoic2FkaW9Ac2FkaW8uY29tIiwidHlwZSI6ImRvY3VtZW50X2FjY2VzcyJ9.KUwV3HW-CYaUOi6n1p6WwrstQUaIm6xJGgiGMHAlhXw', 'sadio@sadio.com', 'succes', 'Email envoyé avec succès', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.5 Safari/605.1.15', '2025-06-22 06:38:41'),
(19, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTA1NjcxMjEsImV4cCI6MTc1MDY1MzUyMSwiZG9jdW1lbnRfaWQiOiIxNyIsImVtYWlsIjoic2FkaW9Ac2FkaW8uY29tIiwidHlwZSI6ImRvY3VtZW50X2FjY2VzcyJ9.KUwV3HW-CYaUOi6n1p6WwrstQUaIm6xJGgiGMHAlhXw', 'sadio@sadio.com', 'refuse', 'Abonnement expiré', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.5 Safari/605.1.15', '2025-06-22 06:38:41'),
(20, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTA1NjcxNDMsImV4cCI6MTc1MDY1MzU0MywiZG9jdW1lbnRfaWQiOiIxOCIsImVtYWlsIjoic2FkaW9Ac2FkaW8uY29tIiwidHlwZSI6ImRvY3VtZW50X2FjY2VzcyJ9.8F4vYJI-VUGKYwkT6KKAWlRVX8L7XkEZFz77DC97pes', 'sadio@sadio.com', 'succes', 'Email envoyé avec succès', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-22 06:39:03'),
(21, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTA1NjcxNDMsImV4cCI6MTc1MDY1MzU0MywiZG9jdW1lbnRfaWQiOiIxOCIsImVtYWlsIjoic2FkaW9Ac2FkaW8uY29tIiwidHlwZSI6ImRvY3VtZW50X2FjY2VzcyJ9.8F4vYJI-VUGKYwkT6KKAWlRVX8L7XkEZFz77DC97pes', 'sadio@sadio.com', 'refuse', 'Abonnement expiré', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-22 06:39:03'),
(22, 'test', 'test@test.com', 'refuse', 'Lien invalide ou expiré', '::1', 'curl/8.7.1', '2025-06-22 06:40:21'),
(23, '010a0f04e106c92f30b43845655d35090b801d2aad9562dae9c8c8688250919c', 'sadio@sadio.com', 'succes', 'Accès autorisé', '::1', '', '2025-06-22 06:58:19'),
(24, 'TOKEN_ACCES', 'sadio@sadio.com', 'refuse', 'Lien invalide ou expiré', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-22 06:58:56'),
(25, '010a0f04e106c92f30b43845655d35090b801d2aad9562dae9c8c8688250919c', 'sadio@sadio.com', 'succes', 'Accès autorisé', '::1', 'curl/8.7.1', '2025-06-22 07:01:20'),
(26, 'TOKEN_ACCES', 'sadio@sadio.com', 'refuse', 'Lien invalide ou expiré', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-22 07:01:40'),
(27, 'TOKEN_ACCES', 'sadio@sadio.com', 'refuse', 'Lien invalide ou expiré', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-22 07:02:03'),
(28, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTA1Njg1OTYsImV4cCI6MTc1MDY1NDk5NiwiZG9jdW1lbnRfaWQiOiIxOSIsImVtYWlsIjoic2FkaW9Ac2FkaW8uY29tIiwidHlwZSI6ImRvY3VtZW50X2FjY2VzcyJ9.YGdutn5ngFJJ6txGNlTmE39wqOjwluxYgjWc03UQ--0', 'sadio@sadio.com', 'succes', 'Email envoyé avec succès', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-22 07:03:16'),
(29, 'TOKEN_ACCES', 'sadio@sadio.com', 'refuse', 'Lien invalide ou expiré', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-22 07:03:30'),
(30, '010a0f04e106c92f30b43845655d35090b801d2aad9562dae9c8c8688250919c', 'sadio@sadio.com', 'succes', 'Accès autorisé', '::1', 'curl/8.7.1', '2025-06-22 07:04:31'),
(31, 'TOKEN_ACCES', 'sadio@sadio.com', 'refuse', 'Lien invalide ou expiré', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-22 07:06:01'),
(32, '010a0f04e106c92f30b43845655d35090b801d2aad9562dae9c8c8688250919c', 'sadio@sadio.com', 'succes', 'Accès autorisé', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-22 07:06:44'),
(33, '010a0f04e106c92f30b43845655d35090b801d2aad9562dae9c8c8688250919c', 'sadio@sadio.com', 'succes', 'Accès autorisé', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-22 07:09:31'),
(34, '010a0f04e106c92f30b43845655d35090b801d2aad9562dae9c8c8688250919c', 'sadio@sadio.com', 'succes', 'Accès autorisé', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-22 07:09:32'),
(35, '010a0f04e106c92f30b43845655d35090b801d2aad9562dae9c8c8688250919c', 'sadio@sadio.com', 'succes', 'Accès autorisé', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-22 07:10:45'),
(36, '010a0f04e106c92f30b43845655d35090b801d2aad9562dae9c8c8688250919c', 'sadio@sadio.com', 'succes', 'Accès autorisé', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-22 07:10:45'),
(37, '010a0f04e106c92f30b43845655d35090b801d2aad9562dae9c8c8688250919c', 'sadio@sadio.com', 'succes', 'Accès autorisé', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-22 07:11:17'),
(38, '010a0f04e106c92f30b43845655d35090b801d2aad9562dae9c8c8688250919c', 'sadio@sadio.com', 'succes', 'Accès autorisé', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-22 07:11:17'),
(39, 'TOKEN', 'sadio@sadio.com', 'refuse', 'Lien invalide ou expiré', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-22 07:11:24'),
(40, '010a0f04e106c92f30b43845655d35090b801d2aad9562dae9c8c8688250919c', 'sadio@sadio.com', 'succes', 'Accès autorisé', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-22 07:11:33'),
(41, '010a0f04e106c92f30b43845655d35090b801d2aad9562dae9c8c8688250919c', 'sadio@sadio.com', 'succes', 'Accès autorisé', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-22 07:11:33'),
(42, '010a0f04e106c92f30b43845655d35090b801d2aad9562dae9c8c8688250919c', 'sadio@sadio.com', 'succes', 'Accès autorisé', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-22 07:11:58'),
(43, '010a0f04e106c92f30b43845655d35090b801d2aad9562dae9c8c8688250919c', 'sadio@sadio.com', 'succes', 'Accès autorisé', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-22 07:11:58'),
(44, '010a0f04e106c92f30b43845655d35090b801d2aad9562dae9c8c8688250919c', 'sadio@sadio.com', 'succes', 'Accès autorisé', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-22 07:12:49'),
(45, '010a0f04e106c92f30b43845655d35090b801d2aad9562dae9c8c8688250919c', 'sadio@sadio.com', 'succes', 'Accès autorisé', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-22 07:12:49'),
(46, '010a0f04e106c92f30b43845655d35090b801d2aad9562dae9c8c8688250919c', 'sadio@sadio.com', 'succes', 'Accès autorisé', '::1', 'curl/8.7.1', '2025-06-22 07:12:56'),
(47, '010a0f04e106c92f30b43845655d35090b801d2aad9562dae9c8c8688250919c', 'sadio@sadio.com', 'succes', 'Accès autorisé', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-22 07:13:19'),
(48, '010a0f04e106c92f30b43845655d35090b801d2aad9562dae9c8c8688250919c', 'sadio@sadio.com', 'succes', 'Accès autorisé', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-22 07:13:19'),
(49, '010a0f04e106c92f30b43845655d35090b801d2aad9562dae9c8c8688250919c', 'sadio@sadio.com', 'succes', 'Accès autorisé', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-22 07:13:19'),
(50, '010a0f04e106c92f30b43845655d35090b801d2aad9562dae9c8c8688250919c', 'sadio@sadio.com', 'succes', 'Accès autorisé', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-22 07:14:04'),
(51, '010a0f04e106c92f30b43845655d35090b801d2aad9562dae9c8c8688250919c', 'sadio@sadio.com', 'succes', 'Accès autorisé', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-22 07:14:04'),
(52, '010a0f04e106c92f30b43845655d35090b801d2aad9562dae9c8c8688250919c', 'sadio@sadio.com', 'succes', 'Accès autorisé', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-22 07:14:12'),
(53, '010a0f04e106c92f30b43845655d35090b801d2aad9562dae9c8c8688250919c', 'sadio@sadio.com', 'succes', 'Accès autorisé', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-22 07:14:12'),
(54, '010a0f04e106c92f30b43845655d35090b801d2aad9562dae9c8c8688250919c', 'sadio@sadio.com', 'succes', 'Accès autorisé', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-22 07:14:20'),
(55, '010a0f04e106c92f30b43845655d35090b801d2aad9562dae9c8c8688250919c', 'sadio@sadio.com', 'succes', 'Accès autorisé', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-22 07:14:20'),
(56, '010a0f04e106c92f30b43845655d35090b801d2aad9562dae9c8c8688250919c', 'sadio@sadio.com', 'succes', 'Accès autorisé', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-22 07:14:39'),
(57, '010a0f04e106c92f30b43845655d35090b801d2aad9562dae9c8c8688250919c', 'sadio@sadio.com', 'succes', 'Accès autorisé', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-22 07:14:39'),
(58, '010a0f04e106c92f30b43845655d35090b801d2aad9562dae9c8c8688250919c', 'sadio@sadio.com', 'succes', 'Accès autorisé', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-22 07:19:05'),
(59, '010a0f04e106c92f30b43845655d35090b801d2aad9562dae9c8c8688250919c', 'sadio@sadio.com', 'succes', 'Accès autorisé', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-22 07:19:05'),
(60, '010a0f04e106c92f30b43845655d35090b801d2aad9562dae9c8c8688250919c', 'sadio@sadio.com', 'succes', 'Accès autorisé', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-22 07:19:05'),
(61, '010a0f04e106c92f30b43845655d35090b801d2aad9562dae9c8c8688250919c', 'sadio@sadio.com', 'succes', 'Accès autorisé', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-22 07:19:05'),
(62, '010a0f04e106c92f30b43845655d35090b801d2aad9562dae9c8c8688250919c', 'sadio@sadio.com', 'succes', 'Accès autorisé', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-22 13:17:32'),
(63, '010a0f04e106c92f30b43845655d35090b801d2aad9562dae9c8c8688250919c', 'sadio@sadio.com', 'succes', 'Accès autorisé', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-22 13:17:32'),
(64, '010a0f04e106c92f30b43845655d35090b801d2aad9562dae9c8c8688250919c', 'sadio@sadio.com', 'succes', 'Accès autorisé', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-22 13:44:17'),
(65, '010a0f04e106c92f30b43845655d35090b801d2aad9562dae9c8c8688250919c', 'sadio@sadio.com', 'succes', 'Accès autorisé', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-22 13:44:18'),
(66, '010a0f04e106c92f30b43845655d35090b801d2aad9562dae9c8c8688250919c', 'sadio@sadio.com', 'succes', 'Accès autorisé', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-22 15:44:01'),
(67, '010a0f04e106c92f30b43845655d35090b801d2aad9562dae9c8c8688250919c', 'sadio@sadio.com', 'succes', 'Accès autorisé', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-22 15:44:02'),
(68, '010a0f04e106c92f30b43845655d35090b801d2aad9562dae9c8c8688250919c', 'sadio@sadio.com', 'succes', 'Accès autorisé', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-22 16:40:12'),
(69, '010a0f04e106c92f30b43845655d35090b801d2aad9562dae9c8c8688250919c', 'sadio@sadio.com', 'succes', 'Accès autorisé', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-22 16:40:12'),
(70, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTA2MTU2MjAsImV4cCI6MTc1MDcwMjAyMCwiZG9jdW1lbnRfaWQiOiIyMCIsImVtYWlsIjoiZnJvbnRlbmQudGVzdEBleGFtcGxlLmNvbSIsInR5cGUiOiJkb2N1bWVudF9hY2Nlc3MifQ.NmKZopbXNIyWseLkEpHRVsrbKGQkOxRtEj7-XG3cVS8', 'frontend.test@example.com', 'succes', 'Email envoyé avec succès', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-22 20:07:00'),
(71, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTA3OTg2MjEsImV4cCI6MTc1MDg4NTAyMSwiZG9jdW1lbnRfaWQiOiIyMyIsImVtYWlsIjoibWFtYW5lbGF3ZWxzYWRpb0BnbWFpbC5jb20iLCJ0eXBlIjoiZG9jdW1lbnRfYWNjZXNzIn0.mQPzfTYXMpnSl3Icnei4f1emufVIxYLqjvbw98lE2uE', 'mamanelawelsadio@gmail.com', 'succes', 'Email envoyé avec succès', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-24 22:57:01'),
(72, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTA4MDE5MDcsImV4cCI6MTc1MDg4ODMwNywiZG9jdW1lbnRfaWQiOiIyNSIsImVtYWlsIjoibWFtYW5lbGF3ZWxzYWRpb0BnbWFpbC5jb20iLCJ0eXBlIjoiZG9jdW1lbnRfYWNjZXNzIn0.h_bfebWSLr-55r4jU2UWAsbqGGVYGMqYCQcLoSs4yy8', 'mamanelawelsadio@gmail.com', 'succes', 'Email envoyé avec succès', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-24 23:51:47'),
(73, '010a0f04e106c92f30b43845655d35090b801d2aad9562dae9c8c8688250919c', 'sadio@sadio.com', 'refuse', 'Lien invalide ou expiré', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-25 21:17:56'),
(74, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTA4ODA2ODYsImV4cCI6MTc1MDk2NzA4NiwiZG9jdW1lbnRfaWQiOiIzMCIsImVtYWlsIjoiZnJvbnRlbmQudGVzdEBleGFtcGxlLmNvbSIsInR5cGUiOiJkb2N1bWVudF9hY2Nlc3MifQ.4P4y8uP4gJrm3ttDyy3eZymp1jPn7Czg6_EQPEZOz_I', 'sadio@sadio.com', 'succes', 'Email envoyé avec succès', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-25 21:44:46'),
(75, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTA4ODA2ODYsImV4cCI6MTc1MDk2NzA4NiwiZG9jdW1lbnRfaWQiOiIzMCIsImVtYWlsIjoiZnJvbnRlbmQudGVzdEBleGFtcGxlLmNvbSIsInR5cGUiOiJkb2N1bWVudF9hY2Nlc3MifQ.4P4y8uP4gJrm3ttDyy3eZymp1jPn7Czg6_EQPEZOz_I', 'mamanelawelsadio@gmail.com', 'succes', 'Email envoyé avec succès', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-25 21:44:46'),
(76, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTA4ODA2ODYsImV4cCI6MTc1MDk2NzA4NiwiZG9jdW1lbnRfaWQiOiIzMCIsImVtYWlsIjoiZnJvbnRlbmQudGVzdEBleGFtcGxlLmNvbSIsInR5cGUiOiJkb2N1bWVudF9hY2Nlc3MifQ.4P4y8uP4gJrm3ttDyy3eZymp1jPn7Czg6_EQPEZOz_I', 'test.hard.delete@example.com', 'succes', 'Email envoyé avec succès', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-25 21:44:46'),
(77, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTA4ODA2ODYsImV4cCI6MTc1MDk2NzA4NiwiZG9jdW1lbnRfaWQiOiIzMCIsImVtYWlsIjoiZnJvbnRlbmQudGVzdEBleGFtcGxlLmNvbSIsInR5cGUiOiJkb2N1bWVudF9hY2Nlc3MifQ.4P4y8uP4gJrm3ttDyy3eZymp1jPn7Czg6_EQPEZOz_I', 'test.final@example.com', 'succes', 'Email envoyé avec succès', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-25 21:44:46'),
(78, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTA4ODA2ODYsImV4cCI6MTc1MDk2NzA4NiwiZG9jdW1lbnRfaWQiOiIzMCIsImVtYWlsIjoiZnJvbnRlbmQudGVzdEBleGFtcGxlLmNvbSIsInR5cGUiOiJkb2N1bWVudF9hY2Nlc3MifQ.4P4y8uP4gJrm3ttDyy3eZymp1jPn7Czg6_EQPEZOz_I', 'frontend.test@example.com', 'succes', 'Email envoyé avec succès', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-25 21:44:46'),
(79, 'PDF_SECURE_1750882814', 'mamanelawelsadio@gmail.com', 'erreur', 'Fichier PDF original non trouvé', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-25 22:20:14'),
(80, 'PDF_SECURE_1750886265', 'mamanelawelsadio@gmail.com', 'erreur', 'Fichier PDF original non trouvé', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-25 23:17:45'),
(81, 'ENVOI_NORMAL_1750887558', 'admin@isend.com', 'succes', 'Envoi PDF normal - Document: Document de test final, Destinataires: 2', '::1', '', '2025-06-25 23:39:18'),
(82, 'PDF_SECURE_1750887697', 'mamanelawelsadio@gmail.com', 'erreur', 'Fichier PDF original non trouvé', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-25 23:41:37'),
(83, 'ENVOI_NORMAL_1750889290', 'admin@isend.com', 'succes', 'Envoi PDF normal - Document: Document de test frontend, Destinataires: 2', '::1', '', '2025-06-26 00:08:10'),
(84, 'ENVOI_NORMAL_1750891555', 'admin@isend.com', 'succes', 'Envoi PDF normal - Document: acte de naissance, Destinataires: 1', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-26 00:45:55'),
(85, 'ENVOI_NORMAL_1750892225', 'admin@isend.com', 'succes', 'Envoi PDF normal - Document: test, Destinataires: 5', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-26 00:57:05'),
(86, 'ENVOI_NORMAL_1751058548', 'admin@isend.com', 'succes', 'Envoi PDF normal - Document: facture, Destinataires: 1', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-27 23:09:08'),
(87, 'ENVOI_NORMAL_1751102713', 'admin@isend.com', 'succes', 'Envoi PDF normal - Document: acte de naissance, Destinataires: 1', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-28 11:25:13'),
(88, 'ENVOI_NORMAL_1751104784', 'admin@isend.com', 'succes', 'Envoi PDF normal - Document: acte de naissance, Destinataires: 1', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-28 11:59:44'),
(89, 'ENVOI_NORMAL_1751105013', 'admin@isend.com', 'succes', 'Envoi PDF normal - Document: acte de naissance, Destinataires: 1', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-28 12:03:33'),
(90, 'ENVOI_NORMAL_1751105242', 'admin@isend.com', 'succes', 'Envoi PDF normal - Document: acte de naissance, Destinataires: 1', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-28 12:07:22'),
(91, 'ENVOI_NORMAL_1751112820', 'admin@isend.com', 'succes', 'Envoi PDF normal - Document: acte de naissance, Destinataires: 1', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-28 14:13:40'),
(92, 'ENVOI_NORMAL_1751112889', 'admin@isend.com', 'succes', 'Envoi PDF normal - Document: acte de naissance, Destinataires: 5', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-28 14:14:49'),
(93, 'ENVOI_NORMAL_1751113585', 'admin@isend.com', 'succes', 'Envoi PDF normal - Document: test, Destinataires: 1', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-28 14:26:25'),
(94, 'ENVOI_NORMAL_1751114718', 'admin@isend.com', 'succes', 'Envoi PDF normal - Document: test envoi, Destinataires: 1', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-28 14:45:18'),
(95, 'ENVOI_NORMAL_1751115586', 'admin@isend.com', 'succes', 'Envoi PDF normal - Document: building, Destinataires: 1', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-28 14:59:46'),
(96, 'PDF_SECURE_1751116139', 'mamanelawelsadio@gmail.com', 'erreur', 'Fichier PDF original non trouvé', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-28 15:08:59'),
(97, 'ENVOI_NORMAL_1751118612', 'admin@isend.com', 'succes', 'Envoi PDF normal - Document: test, Destinataires: 1', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-28 15:50:12'),
(98, 'PDF_SECURE_1751118658', 'mamanelawelsadio@gmail.com', 'erreur', 'Fichier PDF original non trouvé', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-28 15:50:58'),
(99, 'ENVOI_NORMAL_1751119446', 'admin@isend.com', 'succes', 'Envoi PDF normal - Document: acte de naissance, Destinataires: 1', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-28 16:04:06'),
(100, 'ENVOI_NORMAL_1751119521', 'admin@isend.com', 'succes', 'Envoi PDF normal - Document: recou, Destinataires: 1', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-28 16:05:21'),
(101, 'PDF_SECURE_1751119655', 'mamanelawelsadio@gmail.com', 'erreur', 'Fichier PDF original non trouvé', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-28 16:07:35'),
(102, 'PDF_SECURE_1751120244', 'mamanelawelsadio@gmail.com', 'erreur', 'Fichier PDF original non trouvé', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-28 16:17:24'),
(103, 'PDF_SECURE_1751120452', 'mamanelawelsadio@gmail.com', 'erreur', 'Fichier PDF original non trouvé', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-28 16:20:52'),
(104, 'PDF_SECURE_1751120527', 'mamanelawelsadio@gmail.com', 'erreur', 'Fichier PDF original non trouvé', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-28 16:22:07'),
(105, 'PDF_SECURE_1751121453', 'mamanelawelsadio@gmail.com', 'succes', 'PDF sécurisé envoyé avec succès', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-28 16:37:33'),
(106, 'PDF_SECURE_1751122794', 'mamanelawelsadio@gmail.com', 'succes', 'PDF sécurisé envoyé avec succès', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-28 16:59:54'),
(107, 'ENVOI_NORMAL_1751123848', 'admin@isend.com', 'succes', 'Envoi PDF normal - Document: avis, Destinataires: 1', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-28 17:17:28'),
(108, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTExMjQ0ODUsImV4cCI6MTc1MTIxMDg4NSwiZG9jdW1lbnRfaWQiOiI5MiIsImVtYWlsIjoibWFtYW5lbGF3ZWxzYWRpb0BnbWFpbC5jb20iLCJ0eXBlIjoiZG9jdW1lbnRfYWNjZXNzIn0.Q6uOHRQlk6Ifnx5vCVthnb-mJ9gN3AydSREIQGaS_P4', 'mamanelawelsadio@gmail.com', 'succes', 'Email envoyé avec succès', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-28 17:28:07'),
(109, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTExMzc2MTYsImV4cCI6MTc1MTIyNDAxNiwiZG9jdW1lbnRfaWQiOiI5NCIsImVtYWlsIjoibWFtYW5lbGF3ZWxzYWRpb0BnbWFpbC5jb20iLCJ0eXBlIjoiZG9jdW1lbnRfYWNjZXNzIn0.uPNZcKR8yh8Fs8jOoTGMMs2T0GT4O3yK0THiTQGpnlQ', 'mamanelawelsadio@gmail.com', 'succes', 'Email envoyé avec succès', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-28 21:06:58'),
(110, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTExMzgwNDEsImV4cCI6MTc1MTIyNDQ0MSwiZG9jdW1lbnRfaWQiOiI5NSIsImVtYWlsIjoibWFtYW5lbGF3ZWxzYWRpb0BnbWFpbC5jb20iLCJ0eXBlIjoiZG9jdW1lbnRfYWNjZXNzIn0.cpfaEl7P17ABx9emnt7vnPFkVy1ESBA8KBPcCZGKJmE', 'mamanelawelsadio@gmail.com', 'succes', 'Email envoyé avec succès', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-28 21:14:02'),
(111, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTExMzgwNDEsImV4cCI6MTc1MTIyNDQ0MSwiZG9jdW1lbnRfaWQiOiI5NSIsImVtYWlsIjoibWFtYW5lbGF3ZWxzYWRpb0BnbWFpbC5jb20iLCJ0eXBlIjoiZG9jdW1lbnRfYWNjZXNzIn0.cpfaEl7P17ABx9emnt7vnPFkVy1ESBA8KBPcCZGKJmE', 'mamanelawelsadio@gmail.com', 'succes', 'Accès autorisé', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-28 21:14:31'),
(112, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTExMzgwNDEsImV4cCI6MTc1MTIyNDQ0MSwiZG9jdW1lbnRfaWQiOiI5NSIsImVtYWlsIjoibWFtYW5lbGF3ZWxzYWRpb0BnbWFpbC5jb20iLCJ0eXBlIjoiZG9jdW1lbnRfYWNjZXNzIn0.cpfaEl7P17ABx9emnt7vnPFkVy1ESBA8KBPcCZGKJmE', 'mamanelawelsadio@gmail.com', 'succes', 'Accès autorisé', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-28 21:14:31'),
(113, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTExMzgwNDEsImV4cCI6MTc1MTIyNDQ0MSwiZG9jdW1lbnRfaWQiOiI5NSIsImVtYWlsIjoibWFtYW5lbGF3ZWxzYWRpb0BnbWFpbC5jb20iLCJ0eXBlIjoiZG9jdW1lbnRfYWNjZXNzIn0.cpfaEl7P17ABx9emnt7vnPFkVy1ESBA8KBPcCZGKJmE', 'mamanelawelsadio@gmail.com', 'succes', 'Accès autorisé', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-28 21:14:31'),
(114, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTExMzgwNDEsImV4cCI6MTc1MTIyNDQ0MSwiZG9jdW1lbnRfaWQiOiI5NSIsImVtYWlsIjoibWFtYW5lbGF3ZWxzYWRpb0BnbWFpbC5jb20iLCJ0eXBlIjoiZG9jdW1lbnRfYWNjZXNzIn0.cpfaEl7P17ABx9emnt7vnPFkVy1ESBA8KBPcCZGKJmE', 'mamanelawelsadio@gmail.com', 'succes', 'Accès autorisé', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-28 21:14:55'),
(115, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTExMzgwNDEsImV4cCI6MTc1MTIyNDQ0MSwiZG9jdW1lbnRfaWQiOiI5NSIsImVtYWlsIjoibWFtYW5lbGF3ZWxzYWRpb0BnbWFpbC5jb20iLCJ0eXBlIjoiZG9jdW1lbnRfYWNjZXNzIn0.cpfaEl7P17ABx9emnt7vnPFkVy1ESBA8KBPcCZGKJmE', 'mamanelawelsadio@gmail.com', 'succes', 'Accès autorisé', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-28 21:14:55'),
(116, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTExMzgwNDEsImV4cCI6MTc1MTIyNDQ0MSwiZG9jdW1lbnRfaWQiOiI5NSIsImVtYWlsIjoibWFtYW5lbGF3ZWxzYWRpb0BnbWFpbC5jb20iLCJ0eXBlIjoiZG9jdW1lbnRfYWNjZXNzIn0.cpfaEl7P17ABx9emnt7vnPFkVy1ESBA8KBPcCZGKJmE', 'mamanelawelsadio@gmail.com', 'succes', 'Accès autorisé', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-28 21:14:55'),
(117, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTExMzgwNDEsImV4cCI6MTc1MTIyNDQ0MSwiZG9jdW1lbnRfaWQiOiI5NSIsImVtYWlsIjoibWFtYW5lbGF3ZWxzYWRpb0BnbWFpbC5jb20iLCJ0eXBlIjoiZG9jdW1lbnRfYWNjZXNzIn0.cpfaEl7P17ABx9emnt7vnPFkVy1ESBA8KBPcCZGKJmE', 'mamanelawelsadio@gmail.com', 'succes', 'Accès autorisé', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-28 23:53:11'),
(118, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTExMzgwNDEsImV4cCI6MTc1MTIyNDQ0MSwiZG9jdW1lbnRfaWQiOiI5NSIsImVtYWlsIjoibWFtYW5lbGF3ZWxzYWRpb0BnbWFpbC5jb20iLCJ0eXBlIjoiZG9jdW1lbnRfYWNjZXNzIn0.cpfaEl7P17ABx9emnt7vnPFkVy1ESBA8KBPcCZGKJmE', 'mamanelawelsadio@gmail.com', 'succes', 'Accès autorisé', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-28 23:53:11'),
(119, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTExMzgwNDEsImV4cCI6MTc1MTIyNDQ0MSwiZG9jdW1lbnRfaWQiOiI5NSIsImVtYWlsIjoibWFtYW5lbGF3ZWxzYWRpb0BnbWFpbC5jb20iLCJ0eXBlIjoiZG9jdW1lbnRfYWNjZXNzIn0.cpfaEl7P17ABx9emnt7vnPFkVy1ESBA8KBPcCZGKJmE', 'mamanelawelsadio@gmail.com', 'succes', 'Accès autorisé', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-28 23:53:11'),
(120, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTExMzgwNDEsImV4cCI6MTc1MTIyNDQ0MSwiZG9jdW1lbnRfaWQiOiI5NSIsImVtYWlsIjoibWFtYW5lbGF3ZWxzYWRpb0BnbWFpbC5jb20iLCJ0eXBlIjoiZG9jdW1lbnRfYWNjZXNzIn0.cpfaEl7P17ABx9emnt7vnPFkVy1ESBA8KBPcCZGKJmE', 'mamanelawelsadio@gmail.com', 'succes', 'Accès autorisé', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-28 23:53:11'),
(121, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTExMzgwNDEsImV4cCI6MTc1MTIyNDQ0MSwiZG9jdW1lbnRfaWQiOiI5NSIsImVtYWlsIjoibWFtYW5lbGF3ZWxzYWRpb0BnbWFpbC5jb20iLCJ0eXBlIjoiZG9jdW1lbnRfYWNjZXNzIn0.cpfaEl7P17ABx9emnt7vnPFkVy1ESBA8KBPcCZGKJmE', 'mamanelawelsadio@gmail.com', 'succes', 'Accès autorisé', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-28 23:53:12'),
(122, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTExMzgwNDEsImV4cCI6MTc1MTIyNDQ0MSwiZG9jdW1lbnRfaWQiOiI5NSIsImVtYWlsIjoibWFtYW5lbGF3ZWxzYWRpb0BnbWFpbC5jb20iLCJ0eXBlIjoiZG9jdW1lbnRfYWNjZXNzIn0.cpfaEl7P17ABx9emnt7vnPFkVy1ESBA8KBPcCZGKJmE', 'mamanelawelsadio@gmail.com', 'succes', 'Accès autorisé', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-28 23:53:12'),
(123, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTExNDc3MjEsImV4cCI6MTc1MTIzNDEyMSwiZG9jdW1lbnRfaWQiOiI5NiIsImVtYWlsIjoibWFtYW5lbGF3ZWxzYWRpb0BnbWFpbC5jb20iLCJ0eXBlIjoiZG9jdW1lbnRfYWNjZXNzIn0.ISNkZy99eh8iOeRiFxz3pd6MNtOVHeOPS093nD6w4fc', 'mamanelawelsadio@gmail.com', 'succes', 'Email envoyé avec succès', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-28 23:55:22'),
(124, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTExNDc3MjEsImV4cCI6MTc1MTIzNDEyMSwiZG9jdW1lbnRfaWQiOiI5NiIsImVtYWlsIjoibWFtYW5lbGF3ZWxzYWRpb0BnbWFpbC5jb20iLCJ0eXBlIjoiZG9jdW1lbnRfYWNjZXNzIn0.ISNkZy99eh8iOeRiFxz3pd6MNtOVHeOPS093nD6w4fc', 'mamanelawelsadio@gmail.com', 'succes', 'Accès autorisé', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-28 23:55:57'),
(125, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTExNDc3MjEsImV4cCI6MTc1MTIzNDEyMSwiZG9jdW1lbnRfaWQiOiI5NiIsImVtYWlsIjoibWFtYW5lbGF3ZWxzYWRpb0BnbWFpbC5jb20iLCJ0eXBlIjoiZG9jdW1lbnRfYWNjZXNzIn0.ISNkZy99eh8iOeRiFxz3pd6MNtOVHeOPS093nD6w4fc', 'mamanelawelsadio@gmail.com', 'succes', 'Accès autorisé', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-28 23:55:57'),
(126, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTExNDc3MjEsImV4cCI6MTc1MTIzNDEyMSwiZG9jdW1lbnRfaWQiOiI5NiIsImVtYWlsIjoibWFtYW5lbGF3ZWxzYWRpb0BnbWFpbC5jb20iLCJ0eXBlIjoiZG9jdW1lbnRfYWNjZXNzIn0.ISNkZy99eh8iOeRiFxz3pd6MNtOVHeOPS093nD6w4fc', 'mamanelawelsadio@gmail.com', 'succes', 'Accès autorisé', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-28 23:55:57'),
(127, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTExNDc3MjEsImV4cCI6MTc1MTIzNDEyMSwiZG9jdW1lbnRfaWQiOiI5NiIsImVtYWlsIjoibWFtYW5lbGF3ZWxzYWRpb0BnbWFpbC5jb20iLCJ0eXBlIjoiZG9jdW1lbnRfYWNjZXNzIn0.ISNkZy99eh8iOeRiFxz3pd6MNtOVHeOPS093nD6w4fc', 'mamanelawelsadio@gmail.com', 'succes', 'Accès autorisé', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-28 23:56:21'),
(128, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTExNDc3MjEsImV4cCI6MTc1MTIzNDEyMSwiZG9jdW1lbnRfaWQiOiI5NiIsImVtYWlsIjoibWFtYW5lbGF3ZWxzYWRpb0BnbWFpbC5jb20iLCJ0eXBlIjoiZG9jdW1lbnRfYWNjZXNzIn0.ISNkZy99eh8iOeRiFxz3pd6MNtOVHeOPS093nD6w4fc', 'mamanelawelsadio@gmail.com', 'succes', 'Accès autorisé', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-28 23:56:21'),
(129, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTExNDc3MjEsImV4cCI6MTc1MTIzNDEyMSwiZG9jdW1lbnRfaWQiOiI5NiIsImVtYWlsIjoibWFtYW5lbGF3ZWxzYWRpb0BnbWFpbC5jb20iLCJ0eXBlIjoiZG9jdW1lbnRfYWNjZXNzIn0.ISNkZy99eh8iOeRiFxz3pd6MNtOVHeOPS093nD6w4fc', 'mamanelawelsadio@gmail.com', 'succes', 'Accès autorisé', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-28 23:56:21'),
(130, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTExNDc3MjEsImV4cCI6MTc1MTIzNDEyMSwiZG9jdW1lbnRfaWQiOiI5NiIsImVtYWlsIjoibWFtYW5lbGF3ZWxzYWRpb0BnbWFpbC5jb20iLCJ0eXBlIjoiZG9jdW1lbnRfYWNjZXNzIn0.ISNkZy99eh8iOeRiFxz3pd6MNtOVHeOPS093nD6w4fc', 'mamanelawelsadio@gmail.com', 'succes', 'Accès autorisé', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-28 23:58:13'),
(131, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTExNDc3MjEsImV4cCI6MTc1MTIzNDEyMSwiZG9jdW1lbnRfaWQiOiI5NiIsImVtYWlsIjoibWFtYW5lbGF3ZWxzYWRpb0BnbWFpbC5jb20iLCJ0eXBlIjoiZG9jdW1lbnRfYWNjZXNzIn0.ISNkZy99eh8iOeRiFxz3pd6MNtOVHeOPS093nD6w4fc', 'mamanelawelsadio@gmail.com', 'succes', 'Accès autorisé', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-28 23:58:13'),
(132, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTExNDc3MjEsImV4cCI6MTc1MTIzNDEyMSwiZG9jdW1lbnRfaWQiOiI5NiIsImVtYWlsIjoibWFtYW5lbGF3ZWxzYWRpb0BnbWFpbC5jb20iLCJ0eXBlIjoiZG9jdW1lbnRfYWNjZXNzIn0.ISNkZy99eh8iOeRiFxz3pd6MNtOVHeOPS093nD6w4fc', 'mamanelawelsadio@gmail.com', 'succes', 'Accès autorisé', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-28 23:58:13'),
(133, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTExNDc3MjEsImV4cCI6MTc1MTIzNDEyMSwiZG9jdW1lbnRfaWQiOiI5NiIsImVtYWlsIjoibWFtYW5lbGF3ZWxzYWRpb0BnbWFpbC5jb20iLCJ0eXBlIjoiZG9jdW1lbnRfYWNjZXNzIn0.ISNkZy99eh8iOeRiFxz3pd6MNtOVHeOPS093nD6w4fc', 'mamanelawelsadio@gmail.com', 'succes', 'Accès autorisé', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-28 23:58:27'),
(134, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTExNDc3MjEsImV4cCI6MTc1MTIzNDEyMSwiZG9jdW1lbnRfaWQiOiI5NiIsImVtYWlsIjoibWFtYW5lbGF3ZWxzYWRpb0BnbWFpbC5jb20iLCJ0eXBlIjoiZG9jdW1lbnRfYWNjZXNzIn0.ISNkZy99eh8iOeRiFxz3pd6MNtOVHeOPS093nD6w4fc', 'mamanelawelsadio@gmail.com', 'succes', 'Accès autorisé', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-28 23:58:27'),
(135, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTExNDc3MjEsImV4cCI6MTc1MTIzNDEyMSwiZG9jdW1lbnRfaWQiOiI5NiIsImVtYWlsIjoibWFtYW5lbGF3ZWxzYWRpb0BnbWFpbC5jb20iLCJ0eXBlIjoiZG9jdW1lbnRfYWNjZXNzIn0.ISNkZy99eh8iOeRiFxz3pd6MNtOVHeOPS093nD6w4fc', 'mamanelawelsadio@gmail.com', 'succes', 'Accès autorisé', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-28 23:58:27'),
(136, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTExNDc3MjEsImV4cCI6MTc1MTIzNDEyMSwiZG9jdW1lbnRfaWQiOiI5NiIsImVtYWlsIjoibWFtYW5lbGF3ZWxzYWRpb0BnbWFpbC5jb20iLCJ0eXBlIjoiZG9jdW1lbnRfYWNjZXNzIn0.ISNkZy99eh8iOeRiFxz3pd6MNtOVHeOPS093nD6w4fc', 'mamanelawelsadio@gmail.com', 'refuse', 'Abonnement requis pour accéder aux documents', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-29 00:57:32'),
(137, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTExNDc3MjEsImV4cCI6MTc1MTIzNDEyMSwiZG9jdW1lbnRfaWQiOiI5NiIsImVtYWlsIjoibWFtYW5lbGF3ZWxzYWRpb0BnbWFpbC5jb20iLCJ0eXBlIjoiZG9jdW1lbnRfYWNjZXNzIn0.ISNkZy99eh8iOeRiFxz3pd6MNtOVHeOPS093nD6w4fc', 'mamanelawelsadio@gmail.com', 'refuse', 'Abonnement requis pour accéder aux documents', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-29 01:02:47'),
(138, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTExNDc3MjEsImV4cCI6MTc1MTIzNDEyMSwiZG9jdW1lbnRfaWQiOiI5NiIsImVtYWlsIjoibWFtYW5lbGF3ZWxzYWRpb0BnbWFpbC5jb20iLCJ0eXBlIjoiZG9jdW1lbnRfYWNjZXNzIn0.ISNkZy99eh8iOeRiFxz3pd6MNtOVHeOPS093nD6w4fc', 'mamanelawelsadio@gmail.com', 'refuse', 'Abonnement requis pour accéder aux documents', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-29 01:08:46'),
(139, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTExNDc3MjEsImV4cCI6MTc1MTIzNDEyMSwiZG9jdW1lbnRfaWQiOiI5NiIsImVtYWlsIjoibWFtYW5lbGF3ZWxzYWRpb0BnbWFpbC5jb20iLCJ0eXBlIjoiZG9jdW1lbnRfYWNjZXNzIn0.ISNkZy99eh8iOeRiFxz3pd6MNtOVHeOPS093nD6w4fc', 'mamanelawelsadio@gmail.com', 'refuse', 'Abonnement requis pour accéder aux documents', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-29 01:09:10'),
(140, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTExNDc3MjEsImV4cCI6MTc1MTIzNDEyMSwiZG9jdW1lbnRfaWQiOiI5NiIsImVtYWlsIjoibWFtYW5lbGF3ZWxzYWRpb0BnbWFpbC5jb20iLCJ0eXBlIjoiZG9jdW1lbnRfYWNjZXNzIn0.ISNkZy99eh8iOeRiFxz3pd6MNtOVHeOPS093nD6w4fc', 'mamanelawelsadio@gmail.com', 'refuse', 'Abonnement requis pour accéder aux documents', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-29 01:10:13'),
(141, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTExNDc3MjEsImV4cCI6MTc1MTIzNDEyMSwiZG9jdW1lbnRfaWQiOiI5NiIsImVtYWlsIjoibWFtYW5lbGF3ZWxzYWRpb0BnbWFpbC5jb20iLCJ0eXBlIjoiZG9jdW1lbnRfYWNjZXNzIn0.ISNkZy99eh8iOeRiFxz3pd6MNtOVHeOPS093nD6w4fc', 'mamanelawelsadio@gmail.com', 'refuse', 'Abonnement requis pour accéder aux documents', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-29 01:10:40');
INSERT INTO `logs_acces` (`id`, `token`, `email`, `status`, `message`, `ip_address`, `user_agent`, `date_acces`) VALUES
(142, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTExNDc3MjEsImV4cCI6MTc1MTIzNDEyMSwiZG9jdW1lbnRfaWQiOiI5NiIsImVtYWlsIjoibWFtYW5lbGF3ZWxzYWRpb0BnbWFpbC5jb20iLCJ0eXBlIjoiZG9jdW1lbnRfYWNjZXNzIn0.ISNkZy99eh8iOeRiFxz3pd6MNtOVHeOPS093nD6w4fc', 'mamanelawelsadio@gmail.com', 'refuse', 'Abonnement requis pour accéder aux documents', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-29 01:11:33'),
(143, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTExNDc3MjEsImV4cCI6MTc1MTIzNDEyMSwiZG9jdW1lbnRfaWQiOiI5NiIsImVtYWlsIjoibWFtYW5lbGF3ZWxzYWRpb0BnbWFpbC5jb20iLCJ0eXBlIjoiZG9jdW1lbnRfYWNjZXNzIn0.ISNkZy99eh8iOeRiFxz3pd6MNtOVHeOPS093nD6w4fc', 'mamanelawelsadio@gmail.com', 'refuse', 'Abonnement requis pour accéder aux documents', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-29 01:12:04'),
(144, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTExNDc3MjEsImV4cCI6MTc1MTIzNDEyMSwiZG9jdW1lbnRfaWQiOiI5NiIsImVtYWlsIjoibWFtYW5lbGF3ZWxzYWRpb0BnbWFpbC5jb20iLCJ0eXBlIjoiZG9jdW1lbnRfYWNjZXNzIn0.ISNkZy99eh8iOeRiFxz3pd6MNtOVHeOPS093nD6w4fc', 'mamanelawelsadio@gmail.com', 'refuse', 'Abonnement requis pour accéder aux documents', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-29 01:13:04'),
(145, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTExNDc3MjEsImV4cCI6MTc1MTIzNDEyMSwiZG9jdW1lbnRfaWQiOiI5NiIsImVtYWlsIjoibWFtYW5lbGF3ZWxzYWRpb0BnbWFpbC5jb20iLCJ0eXBlIjoiZG9jdW1lbnRfYWNjZXNzIn0.ISNkZy99eh8iOeRiFxz3pd6MNtOVHeOPS093nD6w4fc', 'mamanelawelsadio@gmail.com', 'refuse', 'Abonnement requis pour accéder aux documents', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-29 01:13:52'),
(146, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTExNTYwNzEsImV4cCI6MTc1MTI0MjQ3MSwiZG9jdW1lbnRfaWQiOiI5NyIsImVtYWlsIjoibWFtYW5lbGF3ZWxzYWRpb0BnbWFpbC5jb20iLCJ0eXBlIjoiZG9jdW1lbnRfYWNjZXNzIn0.Vwi4_mQtN_lv9CLNqdNuqpblscRkV4HRkJa8_ihfoKg', 'mamanelawelsadio@gmail.com', 'succes', 'Email envoyé avec succès', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-29 02:14:32'),
(147, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTExNTYwNzEsImV4cCI6MTc1MTI0MjQ3MSwiZG9jdW1lbnRfaWQiOiI5NyIsImVtYWlsIjoibWFtYW5lbGF3ZWxzYWRpb0BnbWFpbC5jb20iLCJ0eXBlIjoiZG9jdW1lbnRfYWNjZXNzIn0.Vwi4_mQtN_lv9CLNqdNuqpblscRkV4HRkJa8_ihfoKg', 'mamanelawelsadio@gmail.com', 'refuse', 'Abonnement requis pour accéder aux documents', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-29 02:16:25'),
(148, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTExNTYwNzEsImV4cCI6MTc1MTI0MjQ3MSwiZG9jdW1lbnRfaWQiOiI5NyIsImVtYWlsIjoibWFtYW5lbGF3ZWxzYWRpb0BnbWFpbC5jb20iLCJ0eXBlIjoiZG9jdW1lbnRfYWNjZXNzIn0.Vwi4_mQtN_lv9CLNqdNuqpblscRkV4HRkJa8_ihfoKg', 'mamanelawelsadio@gmail.com', 'refuse', 'Abonnement requis pour accéder aux documents', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-29 02:17:03'),
(149, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTExNTYzMjEsImV4cCI6MTc1MTI0MjcyMSwiZG9jdW1lbnRfaWQiOiI5OCIsImVtYWlsIjoibWFtYW5lbGF3ZWxzYWRpb0BnbWFpbC5jb20iLCJ0eXBlIjoiZG9jdW1lbnRfYWNjZXNzIn0.L_pwOdXrS1DId-HJy2NDbj_5OaU7dxFXcoTALYgkZKs', 'mamanelawelsadio@gmail.com', 'succes', 'Email envoyé avec succès', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', '2025-06-29 02:18:44'),
(150, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTExOTEyMjQsImV4cCI6MTc1MTI3NzYyNCwiZG9jdW1lbnRfaWQiOiI5OSIsImVtYWlsIjoibWFtYW5lbGF3ZWxzYWRpb0BnbWFpbC5jb20iLCJ0eXBlIjoiZG9jdW1lbnRfYWNjZXNzIn0.-hlUI8_rtno9ePSK90JB7JnGl_N5q0i3B_aAtdy2i0Q', 'mamanelawelsadio@gmail.com', 'succes', 'Email envoyé avec succès', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36 Edg/138.0.0.0', '2025-06-29 12:00:26'),
(151, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTExOTEyMjQsImV4cCI6MTc1MTI3NzYyNCwiZG9jdW1lbnRfaWQiOiI5OSIsImVtYWlsIjoibWFtYW5lbGF3ZWxzYWRpb0BnbWFpbC5jb20iLCJ0eXBlIjoiZG9jdW1lbnRfYWNjZXNzIn0.-hlUI8_rtno9ePSK90JB7JnGl_N5q0i3B_aAtdy2i0Q', 'mamanelawelsadio@gmail.com', 'refuse', 'Abonnement requis pour accéder aux documents', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36 Edg/138.0.0.0', '2025-06-29 12:00:42'),
(152, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTExOTEyMjQsImV4cCI6MTc1MTI3NzYyNCwiZG9jdW1lbnRfaWQiOiI5OSIsImVtYWlsIjoibWFtYW5lbGF3ZWxzYWRpb0BnbWFpbC5jb20iLCJ0eXBlIjoiZG9jdW1lbnRfYWNjZXNzIn0.-hlUI8_rtno9ePSK90JB7JnGl_N5q0i3B_aAtdy2i0Q', 'mamanelawelsadio@gmail.com', 'refuse', 'Abonnement requis pour accéder aux documents', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36 Edg/138.0.0.0', '2025-06-29 12:00:49'),
(153, '073cf0aa1025f52aa9df9960602fc64e313b83cb74211fbdd0acb0fceea0faa9', 'test-no-subscription@example.com', 'refuse', 'Abonnement requis pour accéder aux documents', '::1', '', '2025-06-29 12:15:46'),
(154, '1b1b2868335accac1edad3c4825e2ff010b70961e118d1ad6343e865f971c180', 'test-with-subscription@example.com', 'succes', 'Accès autorisé', '::1', '', '2025-06-29 12:15:46'),
(155, '073cf0aa1025f52aa9df9960602fc64e313b83cb74211fbdd0acb0fceea0faa9', 'test-no-subscription@example.com', 'refuse', 'Abonnement requis pour accéder aux documents', '::1', 'node', '2025-06-29 12:16:33'),
(156, '1b1b2868335accac1edad3c4825e2ff010b70961e118d1ad6343e865f971c180', 'test-with-subscription@example.com', 'succes', 'Accès autorisé', '::1', 'node', '2025-06-29 12:16:33'),
(157, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTEyMTI3ODEsImV4cCI6MTc1MTI5OTE4MSwiZG9jdW1lbnRfaWQiOiIxMDEiLCJlbWFpbCI6Im1hbWFuZWxhd2Vsc2FkaW9AZ21haWwuY29tIiwidHlwZSI6ImRvY3VtZW50X2FjY2VzcyJ9.3IH4Ztj5YiNGYQwUfimp5F1Uc9RqhLNVmb4r2uqnFac', 'mamanelawelsadio@gmail.com', 'succes', 'Email envoyé avec succès', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36 Edg/138.0.0.0', '2025-06-29 17:59:42'),
(158, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTEyMTI3ODEsImV4cCI6MTc1MTI5OTE4MSwiZG9jdW1lbnRfaWQiOiIxMDEiLCJlbWFpbCI6Im1hbWFuZWxhd2Vsc2FkaW9AZ21haWwuY29tIiwidHlwZSI6ImRvY3VtZW50X2FjY2VzcyJ9.3IH4Ztj5YiNGYQwUfimp5F1Uc9RqhLNVmb4r2uqnFac', 'mamanelawelsadio@gmail.com', 'refuse', 'Abonnement requis pour accéder aux documents', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36 Edg/138.0.0.0', '2025-06-29 18:00:02'),
(159, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTEyMTI3ODEsImV4cCI6MTc1MTI5OTE4MSwiZG9jdW1lbnRfaWQiOiIxMDEiLCJlbWFpbCI6Im1hbWFuZWxhd2Vsc2FkaW9AZ21haWwuY29tIiwidHlwZSI6ImRvY3VtZW50X2FjY2VzcyJ9.3IH4Ztj5YiNGYQwUfimp5F1Uc9RqhLNVmb4r2uqnFac', 'mamanelawelsadio@gmail.com', 'refuse', 'Abonnement requis pour accéder aux documents', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36 Edg/138.0.0.0', '2025-06-29 18:01:25'),
(160, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTEyMTI5MTUsImV4cCI6MTc1MTI5OTMxNSwiZG9jdW1lbnRfaWQiOiIxMDIiLCJlbWFpbCI6Im1hbWFuZWxhd2Vsc2FkaW9AZ21haWwuY29tIiwidHlwZSI6ImRvY3VtZW50X2FjY2VzcyJ9.r1B8hyoWlyhmm_XG8fr0v7HrtUPhyuGwFUi7T4OqNas', 'mamanelawelsadio@gmail.com', 'succes', 'Email envoyé avec succès', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36 Edg/138.0.0.0', '2025-06-29 18:01:57'),
(161, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTEyMTI5MTUsImV4cCI6MTc1MTI5OTMxNSwiZG9jdW1lbnRfaWQiOiIxMDIiLCJlbWFpbCI6Im1hbWFuZWxhd2Vsc2FkaW9AZ21haWwuY29tIiwidHlwZSI6ImRvY3VtZW50X2FjY2VzcyJ9.r1B8hyoWlyhmm_XG8fr0v7HrtUPhyuGwFUi7T4OqNas', 'mamanelawelsadio@gmail.com', 'refuse', 'Abonnement requis pour accéder aux documents', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36 Edg/138.0.0.0', '2025-06-29 18:02:06'),
(162, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTEyMTI5MTUsImV4cCI6MTc1MTI5OTMxNSwiZG9jdW1lbnRfaWQiOiIxMDIiLCJlbWFpbCI6Im1hbWFuZWxhd2Vsc2FkaW9AZ21haWwuY29tIiwidHlwZSI6ImRvY3VtZW50X2FjY2VzcyJ9.r1B8hyoWlyhmm_XG8fr0v7HrtUPhyuGwFUi7T4OqNas', 'mamanelawelsadio@gmail.com', 'refuse', 'Abonnement requis pour accéder aux documents', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36 Edg/138.0.0.0', '2025-06-29 18:02:21'),
(163, 'ENVOI_NORMAL_1751215060', 'admin@isend.com', 'succes', 'Envoi PDF normal - Document: journal du jour, Destinataires: 1', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36 Edg/138.0.0.0', '2025-06-29 18:37:40'),
(164, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTEzOTYzMjEsImV4cCI6MTc1MTQ4MjcyMSwiZG9jdW1lbnRfaWQiOiIxMDYiLCJlbWFpbCI6Im1hbWFuZWxhd2Vsc2FkaW9AZ21haWwuY29tIiwidHlwZSI6ImRvY3VtZW50X2FjY2VzcyJ9.o3F3hULHNXCTYV-CID1_wc2iG9QilCV7FuVw669bPyY', 'mamanelawelsadio@gmail.com', 'succes', 'Email envoyé avec succès', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36 Edg/138.0.0.0', '2025-07-01 20:58:42'),
(165, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTEzOTYzMjEsImV4cCI6MTc1MTQ4MjcyMSwiZG9jdW1lbnRfaWQiOiIxMDYiLCJlbWFpbCI6Im1hbWFuZWxhd2Vsc2FkaW9AZ21haWwuY29tIiwidHlwZSI6ImRvY3VtZW50X2FjY2VzcyJ9.o3F3hULHNXCTYV-CID1_wc2iG9QilCV7FuVw669bPyY', 'mamanelawelsadio@gmail.com', 'succes', 'Accès autorisé', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36 Edg/138.0.0.0', '2025-07-01 20:59:16'),
(166, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTEzOTYzMjEsImV4cCI6MTc1MTQ4MjcyMSwiZG9jdW1lbnRfaWQiOiIxMDYiLCJlbWFpbCI6Im1hbWFuZWxhd2Vsc2FkaW9AZ21haWwuY29tIiwidHlwZSI6ImRvY3VtZW50X2FjY2VzcyJ9.o3F3hULHNXCTYV-CID1_wc2iG9QilCV7FuVw669bPyY', 'mamanelawelsadio@gmail.com', 'succes', 'Accès autorisé', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36 Edg/138.0.0.0', '2025-07-01 20:59:16'),
(167, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTEzOTYzMjEsImV4cCI6MTc1MTQ4MjcyMSwiZG9jdW1lbnRfaWQiOiIxMDYiLCJlbWFpbCI6Im1hbWFuZWxhd2Vsc2FkaW9AZ21haWwuY29tIiwidHlwZSI6ImRvY3VtZW50X2FjY2VzcyJ9.o3F3hULHNXCTYV-CID1_wc2iG9QilCV7FuVw669bPyY', 'mamanelawelsadio@gmail.com', 'succes', 'Accès autorisé', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36 Edg/138.0.0.0', '2025-07-01 20:59:16'),
(168, 'PDF_SECURE_1751396457', 'mamanelawelsadio@gmail.com', 'succes', 'PDF sécurisé envoyé avec succès', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36 Edg/138.0.0.0', '2025-07-01 21:00:57'),
(169, 'ENVOI_NORMAL_1751396539', 'admin@isend.com', 'succes', 'Envoi PDF normal - Document: test, Destinataires: 1', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36 Edg/138.0.0.0', '2025-07-01 21:02:19'),
(170, 'ENVOI_NORMAL_1751489791', 'admin@isend.com', 'succes', 'Envoi PDF normal - Document: test, Destinataires: 1', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36 Edg/138.0.0.0', '2025-07-02 22:56:31'),
(171, 'PDF_SECURE_1751493108', 'mamanelawelsadio@gmail.com', 'succes', 'PDF sécurisé envoyé avec succès', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36 Edg/138.0.0.0', '2025-07-02 23:51:48'),
(172, 'ENVOI_NORMAL_1751493316', 'admin@isend.com', 'succes', 'Envoi PDF normal - Document: uuu, Destinataires: 1', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36 Edg/138.0.0.0', '2025-07-02 23:55:16'),
(173, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTE0OTM3MjUsImV4cCI6MTc1MTU4MDEyNSwiZG9jdW1lbnRfaWQiOiIxMjMiLCJlbWFpbCI6Im1hbWFuZWxhd2Vsc2FkaW9AZ21haWwuY29tIiwidHlwZSI6ImRvY3VtZW50X2FjY2VzcyJ9.esaCE3VbeQ2pWgB-tc0YKkSh8byqMxLrfMYeEbcJKLU', 'mamanelawelsadio@gmail.com', 'succes', 'Email envoyé avec succès', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36 Edg/138.0.0.0', '2025-07-03 00:02:07'),
(174, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTE0OTQzNzUsImV4cCI6MTc1MTU4MDc3NSwiZG9jdW1lbnRfaWQiOiIxMjQiLCJlbWFpbCI6Im1hbWFuZWxhd2Vsc2FkaW9AZ21haWwuY29tIiwidHlwZSI6ImRvY3VtZW50X2FjY2VzcyJ9.IjbwUqNpGL5O6kx_ZxZmWmFB6VVpKEmnKBDVTHcBruw', 'mamanelawelsadio@gmail.com', 'succes', 'Email envoyé avec succès', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36 Edg/138.0.0.0', '2025-07-03 00:12:56'),
(175, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTE0OTQzNzUsImV4cCI6MTc1MTU4MDc3NSwiZG9jdW1lbnRfaWQiOiIxMjQiLCJlbWFpbCI6Im1hbWFuZWxhd2Vsc2FkaW9AZ21haWwuY29tIiwidHlwZSI6ImRvY3VtZW50X2FjY2VzcyJ9.IjbwUqNpGL5O6kx_ZxZmWmFB6VVpKEmnKBDVTHcBruw', 'mamanelawelsadio@gmail.com', 'refuse', 'Abonnement expiré', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36 Edg/138.0.0.0', '2025-07-03 00:13:15'),
(176, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTE0OTQzNzUsImV4cCI6MTc1MTU4MDc3NSwiZG9jdW1lbnRfaWQiOiIxMjQiLCJlbWFpbCI6Im1hbWFuZWxhd2Vsc2FkaW9AZ21haWwuY29tIiwidHlwZSI6ImRvY3VtZW50X2FjY2VzcyJ9.IjbwUqNpGL5O6kx_ZxZmWmFB6VVpKEmnKBDVTHcBruw', 'mamanelawelsadio@gmail.com', 'refuse', 'Abonnement expiré', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36 Edg/138.0.0.0', '2025-07-03 00:18:28'),
(177, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTE0OTQzNzUsImV4cCI6MTc1MTU4MDc3NSwiZG9jdW1lbnRfaWQiOiIxMjQiLCJlbWFpbCI6Im1hbWFuZWxhd2Vsc2FkaW9AZ21haWwuY29tIiwidHlwZSI6ImRvY3VtZW50X2FjY2VzcyJ9.IjbwUqNpGL5O6kx_ZxZmWmFB6VVpKEmnKBDVTHcBruw', 'mamanelawelsadio@gmail.com', 'refuse', 'Abonnement expiré', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36 Edg/138.0.0.0', '2025-07-03 00:24:11'),
(178, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTE0OTQzNzUsImV4cCI6MTc1MTU4MDc3NSwiZG9jdW1lbnRfaWQiOiIxMjQiLCJlbWFpbCI6Im1hbWFuZWxhd2Vsc2FkaW9AZ21haWwuY29tIiwidHlwZSI6ImRvY3VtZW50X2FjY2VzcyJ9.IjbwUqNpGL5O6kx_ZxZmWmFB6VVpKEmnKBDVTHcBruw', 'mamanelawelsadio@gmail.com', 'refuse', 'Abonnement expiré', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36 Edg/138.0.0.0', '2025-07-03 00:24:32'),
(179, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTE0OTU2NzYsImV4cCI6MTc1MTU4MjA3NiwiZG9jdW1lbnRfaWQiOiIxMjUiLCJlbWFpbCI6Im1hbWFuZWxhd2Vsc2FkaW9AZ21haWwuY29tIiwidHlwZSI6ImRvY3VtZW50X2FjY2VzcyJ9.ZmYEsLzTP9kWzNwDy4XzJgencDh0hPFY-iGDQWZFvGM', 'mamanelawelsadio@gmail.com', 'succes', 'Email envoyé avec succès', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36 Edg/138.0.0.0', '2025-07-03 00:34:37'),
(180, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTE0OTU2NzYsImV4cCI6MTc1MTU4MjA3NiwiZG9jdW1lbnRfaWQiOiIxMjUiLCJlbWFpbCI6Im1hbWFuZWxhd2Vsc2FkaW9AZ21haWwuY29tIiwidHlwZSI6ImRvY3VtZW50X2FjY2VzcyJ9.ZmYEsLzTP9kWzNwDy4XzJgencDh0hPFY-iGDQWZFvGM', 'mamanelawelsadio@gmail.com', 'refuse', 'Abonnement expiré', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36 Edg/138.0.0.0', '2025-07-03 00:34:49'),
(181, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTE0OTU2NzYsImV4cCI6MTc1MTU4MjA3NiwiZG9jdW1lbnRfaWQiOiIxMjUiLCJlbWFpbCI6Im1hbWFuZWxhd2Vsc2FkaW9AZ21haWwuY29tIiwidHlwZSI6ImRvY3VtZW50X2FjY2VzcyJ9.ZmYEsLzTP9kWzNwDy4XzJgencDh0hPFY-iGDQWZFvGM', 'mamanelawelsadio@gmail.com', 'refuse', 'Abonnement expiré', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36 Edg/138.0.0.0', '2025-07-03 00:43:40'),
(182, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTE0OTY3NTUsImV4cCI6MTc1MTU4MzE1NSwiZG9jdW1lbnRfaWQiOiIxMjYiLCJlbWFpbCI6Im1hbWFuZWxhd2Vsc2FkaW9AZ21haWwuY29tIiwidHlwZSI6ImRvY3VtZW50X2FjY2VzcyJ9.G3CBTY-BhrKJ3iTm1Bv4sfpYbd0j9yZ-5MmgEcaMdU4', 'mamanelawelsadio@gmail.com', 'succes', 'Email envoyé avec succès', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36 Edg/138.0.0.0', '2025-07-03 00:52:36'),
(183, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTE0OTY3NTUsImV4cCI6MTc1MTU4MzE1NSwiZG9jdW1lbnRfaWQiOiIxMjYiLCJlbWFpbCI6Im1hbWFuZWxhd2Vsc2FkaW9AZ21haWwuY29tIiwidHlwZSI6ImRvY3VtZW50X2FjY2VzcyJ9.G3CBTY-BhrKJ3iTm1Bv4sfpYbd0j9yZ-5MmgEcaMdU4', 'mamanelawelsadio@gmail.com', 'refuse', 'Abonnement expiré', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36 Edg/138.0.0.0', '2025-07-03 00:52:48'),
(184, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTE0OTY3NTUsImV4cCI6MTc1MTU4MzE1NSwiZG9jdW1lbnRfaWQiOiIxMjYiLCJlbWFpbCI6Im1hbWFuZWxhd2Vsc2FkaW9AZ21haWwuY29tIiwidHlwZSI6ImRvY3VtZW50X2FjY2VzcyJ9.G3CBTY-BhrKJ3iTm1Bv4sfpYbd0j9yZ-5MmgEcaMdU4', 'mamanelawelsadio@gmail.com', 'refuse', 'Abonnement expiré', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36 Edg/138.0.0.0', '2025-07-03 00:53:06'),
(185, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTE0OTY3NTUsImV4cCI6MTc1MTU4MzE1NSwiZG9jdW1lbnRfaWQiOiIxMjYiLCJlbWFpbCI6Im1hbWFuZWxhd2Vsc2FkaW9AZ21haWwuY29tIiwidHlwZSI6ImRvY3VtZW50X2FjY2VzcyJ9.G3CBTY-BhrKJ3iTm1Bv4sfpYbd0j9yZ-5MmgEcaMdU4', 'mamanelawelsadio@gmail.com', 'refuse', 'Abonnement expiré', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36 Edg/138.0.0.0', '2025-07-03 00:53:23'),
(186, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTE0OTY3NTUsImV4cCI6MTc1MTU4MzE1NSwiZG9jdW1lbnRfaWQiOiIxMjYiLCJlbWFpbCI6Im1hbWFuZWxhd2Vsc2FkaW9AZ21haWwuY29tIiwidHlwZSI6ImRvY3VtZW50X2FjY2VzcyJ9.G3CBTY-BhrKJ3iTm1Bv4sfpYbd0j9yZ-5MmgEcaMdU4', 'mamanelawelsadio@gmail.com', 'refuse', 'Abonnement expiré', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36 Edg/138.0.0.0', '2025-07-03 01:02:24'),
(187, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTE0OTc2NjUsImV4cCI6MTc1MTU4NDA2NSwiZG9jdW1lbnRfaWQiOiIxMjciLCJlbWFpbCI6Im1hbWFuZWxhd2Vsc2FkaW9AZ21haWwuY29tIiwidHlwZSI6ImRvY3VtZW50X2FjY2VzcyJ9.wpdET89ql9W6HRacV8MUnwM3p6vp2XcE3GbIOZnwYZ0', 'mamanelawelsadio@gmail.com', 'succes', 'Email envoyé avec succès', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36 Edg/138.0.0.0', '2025-07-03 01:07:47'),
(188, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTE0OTc2NjUsImV4cCI6MTc1MTU4NDA2NSwiZG9jdW1lbnRfaWQiOiIxMjciLCJlbWFpbCI6Im1hbWFuZWxhd2Vsc2FkaW9AZ21haWwuY29tIiwidHlwZSI6ImRvY3VtZW50X2FjY2VzcyJ9.wpdET89ql9W6HRacV8MUnwM3p6vp2XcE3GbIOZnwYZ0', 'mamanelawelsadio@gmail.com', 'succes', 'Accès autorisé', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36 Edg/138.0.0.0', '2025-07-03 01:07:58'),
(189, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTE0OTc2NjUsImV4cCI6MTc1MTU4NDA2NSwiZG9jdW1lbnRfaWQiOiIxMjciLCJlbWFpbCI6Im1hbWFuZWxhd2Vsc2FkaW9AZ21haWwuY29tIiwidHlwZSI6ImRvY3VtZW50X2FjY2VzcyJ9.wpdET89ql9W6HRacV8MUnwM3p6vp2XcE3GbIOZnwYZ0', 'mamanelawelsadio@gmail.com', 'succes', 'Accès autorisé', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36 Edg/138.0.0.0', '2025-07-03 01:07:58'),
(190, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTE0OTc2NjUsImV4cCI6MTc1MTU4NDA2NSwiZG9jdW1lbnRfaWQiOiIxMjciLCJlbWFpbCI6Im1hbWFuZWxhd2Vsc2FkaW9AZ21haWwuY29tIiwidHlwZSI6ImRvY3VtZW50X2FjY2VzcyJ9.wpdET89ql9W6HRacV8MUnwM3p6vp2XcE3GbIOZnwYZ0', 'mamanelawelsadio@gmail.com', 'succes', 'Accès autorisé', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36 Edg/138.0.0.0', '2025-07-03 01:09:21'),
(191, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTE0OTc2NjUsImV4cCI6MTc1MTU4NDA2NSwiZG9jdW1lbnRfaWQiOiIxMjciLCJlbWFpbCI6Im1hbWFuZWxhd2Vsc2FkaW9AZ21haWwuY29tIiwidHlwZSI6ImRvY3VtZW50X2FjY2VzcyJ9.wpdET89ql9W6HRacV8MUnwM3p6vp2XcE3GbIOZnwYZ0', 'mamanelawelsadio@gmail.com', 'succes', 'Accès autorisé', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36 Edg/138.0.0.0', '2025-07-03 01:12:03'),
(192, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTE0OTc2NjUsImV4cCI6MTc1MTU4NDA2NSwiZG9jdW1lbnRfaWQiOiIxMjciLCJlbWFpbCI6Im1hbWFuZWxhd2Vsc2FkaW9AZ21haWwuY29tIiwidHlwZSI6ImRvY3VtZW50X2FjY2VzcyJ9.wpdET89ql9W6HRacV8MUnwM3p6vp2XcE3GbIOZnwYZ0', 'mamanelawelsadio@gmail.com', 'succes', 'Accès autorisé', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36 Edg/138.0.0.0', '2025-07-03 01:18:48'),
(193, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTE0OTc2NjUsImV4cCI6MTc1MTU4NDA2NSwiZG9jdW1lbnRfaWQiOiIxMjciLCJlbWFpbCI6Im1hbWFuZWxhd2Vsc2FkaW9AZ21haWwuY29tIiwidHlwZSI6ImRvY3VtZW50X2FjY2VzcyJ9.wpdET89ql9W6HRacV8MUnwM3p6vp2XcE3GbIOZnwYZ0', 'mamanelawelsadio@gmail.com', 'succes', 'Accès autorisé', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36 Edg/138.0.0.0', '2025-07-03 01:18:52'),
(194, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTE0OTc2NjUsImV4cCI6MTc1MTU4NDA2NSwiZG9jdW1lbnRfaWQiOiIxMjciLCJlbWFpbCI6Im1hbWFuZWxhd2Vsc2FkaW9AZ21haWwuY29tIiwidHlwZSI6ImRvY3VtZW50X2FjY2VzcyJ9.wpdET89ql9W6HRacV8MUnwM3p6vp2XcE3GbIOZnwYZ0', 'mamanelawelsadio@gmail.com', 'succes', 'Accès autorisé', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36 Edg/138.0.0.0', '2025-07-03 01:19:26'),
(195, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTE0OTc2NjUsImV4cCI6MTc1MTU4NDA2NSwiZG9jdW1lbnRfaWQiOiIxMjciLCJlbWFpbCI6Im1hbWFuZWxhd2Vsc2FkaW9AZ21haWwuY29tIiwidHlwZSI6ImRvY3VtZW50X2FjY2VzcyJ9.wpdET89ql9W6HRacV8MUnwM3p6vp2XcE3GbIOZnwYZ0', 'mamanelawelsadio@gmail.com', 'succes', 'Accès autorisé', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36 Edg/138.0.0.0', '2025-07-03 01:19:26'),
(196, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTE0OTc2NjUsImV4cCI6MTc1MTU4NDA2NSwiZG9jdW1lbnRfaWQiOiIxMjciLCJlbWFpbCI6Im1hbWFuZWxhd2Vsc2FkaW9AZ21haWwuY29tIiwidHlwZSI6ImRvY3VtZW50X2FjY2VzcyJ9.wpdET89ql9W6HRacV8MUnwM3p6vp2XcE3GbIOZnwYZ0', 'mamanelawelsadio@gmail.com', 'succes', 'Accès autorisé', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36 Edg/138.0.0.0', '2025-07-03 01:23:06'),
(197, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTE0OTc2NjUsImV4cCI6MTc1MTU4NDA2NSwiZG9jdW1lbnRfaWQiOiIxMjciLCJlbWFpbCI6Im1hbWFuZWxhd2Vsc2FkaW9AZ21haWwuY29tIiwidHlwZSI6ImRvY3VtZW50X2FjY2VzcyJ9.wpdET89ql9W6HRacV8MUnwM3p6vp2XcE3GbIOZnwYZ0', 'mamanelawelsadio@gmail.com', 'succes', 'Accès autorisé', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36 Edg/138.0.0.0', '2025-07-03 01:23:09'),
(198, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTE0OTc2NjUsImV4cCI6MTc1MTU4NDA2NSwiZG9jdW1lbnRfaWQiOiIxMjciLCJlbWFpbCI6Im1hbWFuZWxhd2Vsc2FkaW9AZ21haWwuY29tIiwidHlwZSI6ImRvY3VtZW50X2FjY2VzcyJ9.wpdET89ql9W6HRacV8MUnwM3p6vp2XcE3GbIOZnwYZ0', 'mamanelawelsadio@gmail.com', 'succes', 'Accès autorisé', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36 Edg/138.0.0.0', '2025-07-03 01:23:13'),
(199, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTE0OTc2NjUsImV4cCI6MTc1MTU4NDA2NSwiZG9jdW1lbnRfaWQiOiIxMjciLCJlbWFpbCI6Im1hbWFuZWxhd2Vsc2FkaW9AZ21haWwuY29tIiwidHlwZSI6ImRvY3VtZW50X2FjY2VzcyJ9.wpdET89ql9W6HRacV8MUnwM3p6vp2XcE3GbIOZnwYZ0', 'mamanelawelsadio@gmail.com', 'succes', 'Accès autorisé', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36 Edg/138.0.0.0', '2025-07-03 01:23:13'),
(200, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTE0OTg2MTEsImV4cCI6MTc1MTU4NTAxMSwiZG9jdW1lbnRfaWQiOiIxMjgiLCJlbWFpbCI6Im1hbWFuZWxhd2Vsc2FkaW9AZ21haWwuY29tIiwidHlwZSI6ImRvY3VtZW50X2FjY2VzcyJ9.xILfxQBy7Ew1Nd2l7HZXoST2L6TfHXaagn2JahUBzls', 'mamanelawelsadio@gmail.com', 'succes', 'Email envoyé avec succès', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36 Edg/138.0.0.0', '2025-07-03 01:23:32'),
(201, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTE0OTg2MTEsImV4cCI6MTc1MTU4NTAxMSwiZG9jdW1lbnRfaWQiOiIxMjgiLCJlbWFpbCI6Im1hbWFuZWxhd2Vsc2FkaW9AZ21haWwuY29tIiwidHlwZSI6ImRvY3VtZW50X2FjY2VzcyJ9.xILfxQBy7Ew1Nd2l7HZXoST2L6TfHXaagn2JahUBzls', 'mamanelawelsadio@gmail.com', 'succes', 'Accès autorisé', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36 Edg/138.0.0.0', '2025-07-03 01:23:41'),
(202, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTE0OTg2MTEsImV4cCI6MTc1MTU4NTAxMSwiZG9jdW1lbnRfaWQiOiIxMjgiLCJlbWFpbCI6Im1hbWFuZWxhd2Vsc2FkaW9AZ21haWwuY29tIiwidHlwZSI6ImRvY3VtZW50X2FjY2VzcyJ9.xILfxQBy7Ew1Nd2l7HZXoST2L6TfHXaagn2JahUBzls', 'mamanelawelsadio@gmail.com', 'succes', 'Accès autorisé', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36 Edg/138.0.0.0', '2025-07-03 01:23:41'),
(203, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTE0OTg2MTEsImV4cCI6MTc1MTU4NTAxMSwiZG9jdW1lbnRfaWQiOiIxMjgiLCJlbWFpbCI6Im1hbWFuZWxhd2Vsc2FkaW9AZ21haWwuY29tIiwidHlwZSI6ImRvY3VtZW50X2FjY2VzcyJ9.xILfxQBy7Ew1Nd2l7HZXoST2L6TfHXaagn2JahUBzls', 'mamanelawelsadio@gmail.com', 'succes', 'Accès autorisé', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36 Edg/138.0.0.0', '2025-07-03 01:23:44'),
(204, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTE0OTg2MTEsImV4cCI6MTc1MTU4NTAxMSwiZG9jdW1lbnRfaWQiOiIxMjgiLCJlbWFpbCI6Im1hbWFuZWxhd2Vsc2FkaW9AZ21haWwuY29tIiwidHlwZSI6ImRvY3VtZW50X2FjY2VzcyJ9.xILfxQBy7Ew1Nd2l7HZXoST2L6TfHXaagn2JahUBzls', 'mamanelawelsadio@gmail.com', 'succes', 'Accès autorisé', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36 Edg/138.0.0.0', '2025-07-03 01:24:00'),
(205, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTE0OTg2MTEsImV4cCI6MTc1MTU4NTAxMSwiZG9jdW1lbnRfaWQiOiIxMjgiLCJlbWFpbCI6Im1hbWFuZWxhd2Vsc2FkaW9AZ21haWwuY29tIiwidHlwZSI6ImRvY3VtZW50X2FjY2VzcyJ9.xILfxQBy7Ew1Nd2l7HZXoST2L6TfHXaagn2JahUBzls', 'mamanelawelsadio@gmail.com', 'succes', 'Accès autorisé', '::1', 'curl/8.7.1', '2025-07-03 01:27:56'),
(206, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTE0OTg2MTEsImV4cCI6MTc1MTU4NTAxMSwiZG9jdW1lbnRfaWQiOiIxMjgiLCJlbWFpbCI6Im1hbWFuZWxhd2Vsc2FkaW9AZ21haWwuY29tIiwidHlwZSI6ImRvY3VtZW50X2FjY2VzcyJ9.xILfxQBy7Ew1Nd2l7HZXoST2L6TfHXaagn2JahUBzls', 'mamanelawelsadio@gmail.com', 'succes', 'Accès autorisé', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36 Edg/138.0.0.0', '2025-07-03 01:28:37'),
(207, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTE0OTg2MTEsImV4cCI6MTc1MTU4NTAxMSwiZG9jdW1lbnRfaWQiOiIxMjgiLCJlbWFpbCI6Im1hbWFuZWxhd2Vsc2FkaW9AZ21haWwuY29tIiwidHlwZSI6ImRvY3VtZW50X2FjY2VzcyJ9.xILfxQBy7Ew1Nd2l7HZXoST2L6TfHXaagn2JahUBzls', 'mamanelawelsadio@gmail.com', 'succes', 'Accès autorisé', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36 Edg/138.0.0.0', '2025-07-03 01:28:38'),
(208, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTE0OTg2MTEsImV4cCI6MTc1MTU4NTAxMSwiZG9jdW1lbnRfaWQiOiIxMjgiLCJlbWFpbCI6Im1hbWFuZWxhd2Vsc2FkaW9AZ21haWwuY29tIiwidHlwZSI6ImRvY3VtZW50X2FjY2VzcyJ9.xILfxQBy7Ew1Nd2l7HZXoST2L6TfHXaagn2JahUBzls', 'mamanelawelsadio@gmail.com', 'succes', 'Accès autorisé', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36 Edg/138.0.0.0', '2025-07-03 01:34:57'),
(209, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTE0OTc2NjUsImV4cCI6MTc1MTU4NDA2NSwiZG9jdW1lbnRfaWQiOiIxMjciLCJlbWFpbCI6Im1hbWFuZWxhd2Vsc2FkaW9AZ21haWwuY29tIiwidHlwZSI6ImRvY3VtZW50X2FjY2VzcyJ9.wpdET89ql9W6HRacV8MUnwM3p6vp2XcE3GbIOZnwYZ0', 'mamanelawelsadio@gmail.com', 'succes', 'Accès autorisé', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36 Edg/138.0.0.0', '2025-07-03 01:34:57'),
(210, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTE0OTg2MTEsImV4cCI6MTc1MTU4NTAxMSwiZG9jdW1lbnRfaWQiOiIxMjgiLCJlbWFpbCI6Im1hbWFuZWxhd2Vsc2FkaW9AZ21haWwuY29tIiwidHlwZSI6ImRvY3VtZW50X2FjY2VzcyJ9.xILfxQBy7Ew1Nd2l7HZXoST2L6TfHXaagn2JahUBzls', 'mamanelawelsadio@gmail.com', 'succes', 'Accès autorisé', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36 Edg/138.0.0.0', '2025-07-03 01:36:26'),
(211, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTE0OTg2MTEsImV4cCI6MTc1MTU4NTAxMSwiZG9jdW1lbnRfaWQiOiIxMjgiLCJlbWFpbCI6Im1hbWFuZWxhd2Vsc2FkaW9AZ21haWwuY29tIiwidHlwZSI6ImRvY3VtZW50X2FjY2VzcyJ9.xILfxQBy7Ew1Nd2l7HZXoST2L6TfHXaagn2JahUBzls', 'mamanelawelsadio@gmail.com', 'succes', 'Accès autorisé', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36 Edg/138.0.0.0', '2025-07-03 01:36:48'),
(212, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTE0OTg2MTEsImV4cCI6MTc1MTU4NTAxMSwiZG9jdW1lbnRfaWQiOiIxMjgiLCJlbWFpbCI6Im1hbWFuZWxhd2Vsc2FkaW9AZ21haWwuY29tIiwidHlwZSI6ImRvY3VtZW50X2FjY2VzcyJ9.xILfxQBy7Ew1Nd2l7HZXoST2L6TfHXaagn2JahUBzls', 'mamanelawelsadio@gmail.com', 'succes', 'Accès autorisé', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36 Edg/138.0.0.0', '2025-07-03 01:36:48'),
(213, 'ENVOI_NORMAL_1751499439', 'admin@isend.com', 'succes', 'Envoi PDF normal - Document: gg, Destinataires: 1', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36 Edg/138.0.0.0', '2025-07-03 01:37:19'),
(214, 'PDF_SECURE_1751499454', 'mamanelawelsadio@gmail.com', 'succes', 'PDF sécurisé envoyé avec succès', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36 Edg/138.0.0.0', '2025-07-03 01:37:34'),
(215, 'PDF_SECURE_1751500006', 'mamanelawelsadio@gmail.com', 'succes', 'PDF sécurisé envoyé avec succès', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36 Edg/138.0.0.0', '2025-07-03 01:46:46'),
(216, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTE1MDA3MDUsImV4cCI6MTc1MTU4NzEwNSwiZG9jdW1lbnRfaWQiOiIxMzgiLCJlbWFpbCI6Im1hbWFuZWxhd2Vsc2FkaW9AZ21haWwuY29tIiwidHlwZSI6ImRvY3VtZW50X2FjY2VzcyJ9.Q6oSxyUAi8AERmqnLxoQy_0-cgxM8g1v7q9sZSRuGDY', 'mamanelawelsadio@gmail.com', 'succes', 'Email envoyé avec succès', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36 Edg/138.0.0.0', '2025-07-03 01:58:26'),
(217, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTE1MDA3MDUsImV4cCI6MTc1MTU4NzEwNSwiZG9jdW1lbnRfaWQiOiIxMzgiLCJlbWFpbCI6Im1hbWFuZWxhd2Vsc2FkaW9AZ21haWwuY29tIiwidHlwZSI6ImRvY3VtZW50X2FjY2VzcyJ9.Q6oSxyUAi8AERmqnLxoQy_0-cgxM8g1v7q9sZSRuGDY', 'mamanelawelsadio@gmail.com', 'succes', 'Accès autorisé', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36 Edg/138.0.0.0', '2025-07-03 01:58:42'),
(218, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTE1MDA3MDUsImV4cCI6MTc1MTU4NzEwNSwiZG9jdW1lbnRfaWQiOiIxMzgiLCJlbWFpbCI6Im1hbWFuZWxhd2Vsc2FkaW9AZ21haWwuY29tIiwidHlwZSI6ImRvY3VtZW50X2FjY2VzcyJ9.Q6oSxyUAi8AERmqnLxoQy_0-cgxM8g1v7q9sZSRuGDY', 'mamanelawelsadio@gmail.com', 'succes', 'Accès autorisé', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36 Edg/138.0.0.0', '2025-07-03 01:58:42'),
(219, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTE1MDA3MDUsImV4cCI6MTc1MTU4NzEwNSwiZG9jdW1lbnRfaWQiOiIxMzgiLCJlbWFpbCI6Im1hbWFuZWxhd2Vsc2FkaW9AZ21haWwuY29tIiwidHlwZSI6ImRvY3VtZW50X2FjY2VzcyJ9.Q6oSxyUAi8AERmqnLxoQy_0-cgxM8g1v7q9sZSRuGDY', 'mamanelawelsadio@gmail.com', 'succes', 'Accès autorisé', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36 Edg/138.0.0.0', '2025-07-03 01:58:42');

--
-- Déclencheurs `logs_acces`
--
DELIMITER $$
CREATE TRIGGER `update_nombre_acces` AFTER INSERT ON `logs_acces` FOR EACH ROW BEGIN
    IF NEW.status = 'succes' THEN
        UPDATE liens 
        SET nombre_acces = nombre_acces + 1,
            date_derniere_utilisation = NOW()
        WHERE token = NEW.token;
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Structure de la table `parametres_systeme`
--

CREATE TABLE `parametres_systeme` (
  `id` int NOT NULL,
  `categorie` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `cle` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `valeur` text COLLATE utf8mb4_unicode_ci,
  `type` enum('string','number','boolean','json','email') COLLATE utf8mb4_unicode_ci DEFAULT 'string',
  `description` text COLLATE utf8mb4_unicode_ci,
  `date_creation` datetime DEFAULT CURRENT_TIMESTAMP,
  `date_modification` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Déchargement des données de la table `parametres_systeme`
--

INSERT INTO `parametres_systeme` (`id`, `categorie`, `cle`, `valeur`, `type`, `description`, `date_creation`, `date_modification`) VALUES
(1, 'general', 'nom_plateforme', 'iSend Document Flow - Nouveau Nom', 'string', 'Nom de la plateforme', '2025-06-22 16:17:30', '2025-06-22 17:26:03'),
(2, 'general', 'logo_url', '', 'string', 'URL du logo de l\'entreprise', '2025-06-22 16:17:30', '2025-06-22 16:17:30'),
(3, 'general', 'email_contact', 'contact@isend.com', 'email', 'Email de contact principal', '2025-06-22 16:17:30', '2025-06-22 16:17:30'),
(4, 'general', 'telephone_contact', '+33 1 23 45 67 89', 'string', 'Téléphone de contact', '2025-06-22 16:17:30', '2025-06-22 18:27:59'),
(5, 'general', 'adresse_entreprise', 'Test 1750606603207', 'string', 'Adresse de l\'entreprise', '2025-06-22 16:17:30', '2025-06-22 17:36:43'),
(6, 'email', 'smtp_host', 'smtp.gmail.com', 'string', 'Serveur SMTP', '2025-06-22 16:17:30', '2025-06-22 16:17:30'),
(7, 'email', 'smtp_port', '587', 'number', 'Port SMTP', '2025-06-22 16:17:30', '2025-06-22 16:17:30'),
(8, 'email', 'smtp_username', '', 'string', 'Nom d\'utilisateur SMTP', '2025-06-22 16:17:30', '2025-06-22 16:17:30'),
(9, 'email', 'smtp_password', '', 'string', 'Mot de passe SMTP', '2025-06-22 16:17:30', '2025-06-22 16:17:30'),
(10, 'email', 'smtp_encryption', 'tls', 'string', 'Type de chiffrement SMTP', '2025-06-22 16:17:30', '2025-06-22 16:17:30'),
(11, 'email', 'email_expediteur', 'noreply@isend.com', 'email', 'Email expéditeur par défaut', '2025-06-22 16:17:30', '2025-06-22 16:17:30'),
(12, 'email', 'nom_expediteur', 'iSend Document Flow', 'string', 'Nom de l\'expéditeur', '2025-06-22 16:17:30', '2025-06-22 16:17:30'),
(13, 'abonnements', 'limite_documents_gratuit', '10', 'number', 'Limite documents pour abonnement gratuit', '2025-06-22 16:17:30', '2025-06-22 16:17:30'),
(14, 'abonnements', 'limite_destinataires_gratuit', '50', 'number', 'Limite destinataires pour abonnement gratuit', '2025-06-22 16:17:30', '2025-06-22 16:17:30'),
(15, 'abonnements', 'limite_documents_premium', '1000', 'number', 'Limite documents pour abonnement premium', '2025-06-22 16:17:30', '2025-06-22 16:17:30'),
(16, 'abonnements', 'limite_destinataires_premium', '500', 'number', 'Limite destinataires pour abonnement premium', '2025-06-22 16:17:30', '2025-06-22 16:17:30'),
(17, 'abonnements', 'limite_documents_entreprise', '2000', 'number', 'Limite documents pour abonnement entreprise', '2025-06-22 16:17:30', '2025-06-22 16:17:30'),
(18, 'abonnements', 'limite_destinataires_entreprise', '1500', 'number', 'Limite destinataires pour abonnement entreprise', '2025-06-22 16:17:30', '2025-06-22 16:17:30'),
(19, 'securite', 'duree_token_jwt', '3600', 'number', 'Durée de validité des tokens JWT (en secondes)', '2025-06-22 16:17:30', '2025-06-22 16:17:30'),
(20, 'securite', 'duree_refresh_token', '604800', 'number', 'Durée de validité des refresh tokens (en secondes)', '2025-06-22 16:17:30', '2025-06-22 16:17:30'),
(21, 'securite', 'longueur_min_mot_de_passe', '8', 'number', 'Longueur minimale des mots de passe', '2025-06-22 16:17:30', '2025-06-22 16:17:30'),
(22, 'securite', 'complexite_mot_de_passe', 'true', 'boolean', 'Exiger la complexité des mots de passe', '2025-06-22 16:17:30', '2025-06-22 16:17:30'),
(23, 'securite', 'duree_session', '28800', 'number', 'Durée de session utilisateur (en secondes)', '2025-06-22 16:17:30', '2025-06-22 16:17:30'),
(24, 'securite', 'max_tentatives_connexion', '5', 'number', 'Nombre maximum de tentatives de connexion', '2025-06-22 16:17:30', '2025-06-22 16:17:30'),
(25, 'securite', 'duree_blocage', '900', 'number', 'Durée de blocage après échecs (en secondes)', '2025-06-22 16:17:30', '2025-06-22 16:17:30'),
(26, 'statistiques', 'retention_donnees_jours', '365', 'number', 'Rétention des données en jours', '2025-06-22 16:17:30', '2025-06-22 16:17:30'),
(27, 'statistiques', 'export_automatique', 'false', 'boolean', 'Activer les exports automatiques', '2025-06-22 16:17:30', '2025-06-22 16:17:30'),
(28, 'statistiques', 'frequence_export', 'weekly', 'string', 'Fréquence des exports (daily, weekly, monthly)', '2025-06-22 16:17:30', '2025-06-22 16:17:30'),
(29, 'statistiques', 'email_rapport', 'mellowrime@gmail.com', 'email', 'Email pour recevoir les rapports automatiques', '2025-06-22 16:17:30', '2025-06-22 17:21:14'),
(30, 'templates', 'email_bienvenue', 'Bienvenue sur iSend Document Flow !', 'string', 'Template email de bienvenue', '2025-06-22 16:17:30', '2025-06-22 16:17:30'),
(31, 'templates', 'email_document_recu', 'Vous avez reçu un nouveau document', 'string', 'Template email de réception de document', '2025-06-22 16:17:30', '2025-06-22 16:17:30'),
(32, 'templates', 'email_expiration', 'Votre abonnement expire bientôt', 'string', 'Template email d\'expiration d\'abonnement', '2025-06-22 16:17:30', '2025-06-22 16:17:30'),
(33, 'systeme', 'maintenance_mode', 'false', 'boolean', 'Mode maintenance', '2025-06-22 16:17:30', '2025-06-22 16:17:30'),
(34, 'systeme', 'maintenance_message', 'Site en maintenance', 'string', 'Message de maintenance', '2025-06-22 16:17:30', '2025-06-22 16:17:30'),
(35, 'systeme', 'timezone', 'Europe/Paris', 'string', 'Fuseau horaire par défaut', '2025-06-22 16:17:30', '2025-06-22 16:17:30'),
(36, 'systeme', 'langue_defaut', 'fr', 'string', 'Langue par défaut', '2025-06-22 16:17:30', '2025-06-22 16:17:30');

-- --------------------------------------------------------

--
-- Structure de la table `statistiques`
--

CREATE TABLE `statistiques` (
  `id` int NOT NULL,
  `user_id` int NOT NULL,
  `document_id` int DEFAULT NULL,
  `type` enum('upload','envoi','acces','telechargement') COLLATE utf8mb4_unicode_ci NOT NULL,
  `compteur` int DEFAULT '1',
  `date_stat` date NOT NULL,
  `date_creation` datetime DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Structure de la table `users`
--

CREATE TABLE `users` (
  `id` int NOT NULL,
  `email` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `password` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `nom` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `prenom` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `role` enum('admin','user') COLLATE utf8mb4_unicode_ci DEFAULT 'user',
  `status` enum('actif','inactif','suspendu') COLLATE utf8mb4_unicode_ci DEFAULT 'actif',
  `derniere_connexion` datetime DEFAULT NULL,
  `date_modification` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `date_creation` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Déchargement des données de la table `users`
--

INSERT INTO `users` (`id`, `email`, `password`, `nom`, `prenom`, `role`, `status`, `derniere_connexion`, `date_modification`, `date_creation`, `updated_at`) VALUES
(1, 'admin@isend.com', '$2y$10$PC/vQW3K0HAW3U6m1FKR/ep3L.uyM0STBROlkoDbEO1TrSEkhR7xm', 'sadio admin', 'iSend admin', 'admin', 'actif', '2025-06-22 16:21:30', '2025-06-24 23:53:45', '2025-06-22 15:29:29', '2025-06-24 21:53:45'),
(2, 'test@example.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Test', 'User', 'user', 'actif', NULL, '2025-06-22 15:35:57', '2025-06-22 15:29:29', '2025-06-22 15:29:29'),
(5, 'mellow@isend.com', '$2y$10$BkywUopUmm84sE1hmzVMqesao5vaS6vT1xD/bs5g1H3Ze6GOISw2W', 'mellow', 'mellows', 'user', 'actif', '2025-06-22 13:56:40', '2025-06-22 15:35:56', '2025-06-22 15:29:29', '2025-06-22 15:29:29'),
(6, 'test.suppression@example.com', '$2y$10$iDQ1ADo86Q9nnP3yzrh69.TNPB/CYHNLDcpebh9pE7yGMD3RVvEIS', 'Test', 'Suppression', 'user', 'inactif', NULL, '2025-06-22 15:36:14', '2025-06-22 15:29:29', '2025-06-22 15:29:29'),
(8, 'mamanelawelsadio@gmail.com', '$2y$10$7Uized4ivTan13KriqF.c.g.3CPzJUDoMRH77h3kEbv6zAAfjaD0a', 'razak', 'abdoul', 'admin', 'actif', NULL, '2025-06-25 00:01:39', '2025-06-24 22:01:39', '2025-06-24 22:01:39'),
(9, 'test-no-subscription@example.com', '$2y$10$t9FYptuoX4SPWiEDFUSJ/OzKoM0jLDuqk5OifrxsCYTq0HXds6BKW', 'Test', 'NoSubscription', 'user', 'actif', NULL, '2025-06-29 12:15:45', '2025-06-29 10:15:45', '2025-06-29 10:15:45'),
(10, 'test-with-subscription@example.com', '$2y$10$QKZel.Cwu2EmlKUIggjlcerUb/YaUbTW630tvHCFVZu5GtgODx5WS', 'Test', 'WithSubscription', 'user', 'actif', NULL, '2025-06-29 12:15:46', '2025-06-29 10:15:46', '2025-06-29 10:15:46');

-- --------------------------------------------------------

--
-- Doublure de structure pour la vue `vue_stats_document`
-- (Voir ci-dessous la vue réelle)
--
CREATE TABLE `vue_stats_document` (
`date_upload` datetime
,`document_id` int
,`nb_acces` bigint
,`nb_destinataires_uniques` bigint
,`nb_liens` bigint
,`nom` varchar(255)
,`user_email` varchar(255)
,`user_id` int
);

-- --------------------------------------------------------

--
-- Doublure de structure pour la vue `vue_stats_utilisateur`
-- (Voir ci-dessous la vue réelle)
--
CREATE TABLE `vue_stats_utilisateur` (
`email` varchar(255)
,`nb_acces` bigint
,`nb_destinataires` bigint
,`nb_documents` bigint
,`nb_liens` bigint
,`nom` varchar(100)
,`prenom` varchar(100)
,`user_id` int
);

-- --------------------------------------------------------

--
-- Structure de la vue `vue_stats_document`
--
DROP TABLE IF EXISTS `vue_stats_document`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vue_stats_document`  AS SELECT `d`.`id` AS `document_id`, `d`.`nom` AS `nom`, `d`.`user_id` AS `user_id`, `u`.`email` AS `user_email`, count(`l`.`id`) AS `nb_liens`, count(`la`.`id`) AS `nb_acces`, count(distinct `l`.`email`) AS `nb_destinataires_uniques`, `d`.`date_upload` AS `date_upload` FROM (((`documents` `d` join `users` `u` on((`d`.`user_id` = `u`.`id`))) left join `liens` `l` on(((`d`.`id` = `l`.`document_id`) and (`l`.`status` = 'actif')))) left join `logs_acces` `la` on(((`l`.`token` = `la`.`token`) and (`la`.`status` = 'succes')))) WHERE (`d`.`status` = 'actif') GROUP BY `d`.`id`, `d`.`nom`, `d`.`user_id`, `u`.`email`, `d`.`date_upload` ;

-- --------------------------------------------------------

--
-- Structure de la vue `vue_stats_utilisateur`
--
DROP TABLE IF EXISTS `vue_stats_utilisateur`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vue_stats_utilisateur`  AS SELECT `u`.`id` AS `user_id`, `u`.`email` AS `email`, `u`.`nom` AS `nom`, `u`.`prenom` AS `prenom`, count(distinct `d`.`id`) AS `nb_documents`, count(distinct `dest`.`id`) AS `nb_destinataires`, count(distinct `l`.`id`) AS `nb_liens`, count(`la`.`id`) AS `nb_acces` FROM ((((`users` `u` left join `documents` `d` on(((`u`.`id` = `d`.`user_id`) and (`d`.`status` = 'actif')))) left join `destinataires` `dest` on(((`u`.`id` = `dest`.`user_id`) and (`dest`.`status` = 'actif')))) left join `liens` `l` on(((`d`.`id` = `l`.`document_id`) and (`l`.`status` = 'actif')))) left join `logs_acces` `la` on(((`l`.`token` = `la`.`token`) and (`la`.`status` = 'succes')))) GROUP BY `u`.`id`, `u`.`email`, `u`.`nom`, `u`.`prenom` ;

--
-- Index pour les tables déchargées
--

--
-- Index pour la table `abonnements`
--
ALTER TABLE `abonnements`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_status` (`status`),
  ADD KEY `idx_date_fin` (`date_fin`),
  ADD KEY `idx_abonne_id` (`abonne_id`);

--
-- Index pour la table `abonnes`
--
ALTER TABLE `abonnes`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `email` (`email`),
  ADD KEY `idx_email` (`email`),
  ADD KEY `idx_statut` (`statut`),
  ADD KEY `idx_type_abonnement` (`type_abonnement`),
  ADD KEY `idx_date_inscription` (`date_inscription`),
  ADD KEY `abonnes_ibfk_1` (`user_id`);

--
-- Index pour la table `destinataires`
--
ALTER TABLE `destinataires`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `user_email_unique` (`user_id`,`email`),
  ADD KEY `idx_user_id` (`user_id`),
  ADD KEY `idx_email` (`email`),
  ADD KEY `idx_status` (`status`),
  ADD KEY `idx_date_ajout` (`date_ajout`),
  ADD KEY `idx_destinataires_user_status` (`user_id`,`status`);

--
-- Index pour la table `documents`
--
ALTER TABLE `documents`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_user_id` (`user_id`),
  ADD KEY `idx_status` (`status`),
  ADD KEY `idx_date_upload` (`date_upload`),
  ADD KEY `idx_documents_user_status` (`user_id`,`status`);

--
-- Index pour la table `liens`
--
ALTER TABLE `liens`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `token` (`token`),
  ADD UNIQUE KEY `token_unique` (`token`),
  ADD KEY `idx_document_id` (`document_id`),
  ADD KEY `idx_email` (`email`),
  ADD KEY `idx_status` (`status`),
  ADD KEY `idx_date_creation` (`date_creation`),
  ADD KEY `idx_date_expiration` (`date_expiration`),
  ADD KEY `idx_liens_document_email` (`document_id`,`email`);

--
-- Index pour la table `login_attempts`
--
ALTER TABLE `login_attempts`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_email` (`email`),
  ADD KEY `idx_ip_address` (`ip_address`),
  ADD KEY `idx_attempt_time` (`attempt_time`),
  ADD KEY `idx_email_time` (`email`,`attempt_time`),
  ADD KEY `idx_ip_time` (`ip_address`,`attempt_time`);

--
-- Index pour la table `logs_acces`
--
ALTER TABLE `logs_acces`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_token` (`token`),
  ADD KEY `idx_email` (`email`),
  ADD KEY `idx_status` (`status`),
  ADD KEY `idx_date_acces` (`date_acces`),
  ADD KEY `idx_ip_address` (`ip_address`),
  ADD KEY `idx_logs_token_status` (`token`,`status`);

--
-- Index pour la table `parametres_systeme`
--
ALTER TABLE `parametres_systeme`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_parametre` (`categorie`,`cle`),
  ADD KEY `idx_categorie` (`categorie`),
  ADD KEY `idx_cle` (`cle`);

--
-- Index pour la table `statistiques`
--
ALTER TABLE `statistiques`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_stat` (`user_id`,`document_id`,`type`,`date_stat`),
  ADD KEY `idx_user_id` (`user_id`),
  ADD KEY `idx_document_id` (`document_id`),
  ADD KEY `idx_type` (`type`),
  ADD KEY `idx_date_stat` (`date_stat`);

--
-- Index pour la table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `email` (`email`),
  ADD UNIQUE KEY `email_unique` (`email`),
  ADD KEY `idx_status` (`status`);

--
-- AUTO_INCREMENT pour les tables déchargées
--

--
-- AUTO_INCREMENT pour la table `abonnements`
--
ALTER TABLE `abonnements`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=15;

--
-- AUTO_INCREMENT pour la table `abonnes`
--
ALTER TABLE `abonnes`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT pour la table `destinataires`
--
ALTER TABLE `destinataires`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=19;

--
-- AUTO_INCREMENT pour la table `documents`
--
ALTER TABLE `documents`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=139;

--
-- AUTO_INCREMENT pour la table `liens`
--
ALTER TABLE `liens`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=73;

--
-- AUTO_INCREMENT pour la table `login_attempts`
--
ALTER TABLE `login_attempts`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=60;

--
-- AUTO_INCREMENT pour la table `logs_acces`
--
ALTER TABLE `logs_acces`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=220;

--
-- AUTO_INCREMENT pour la table `parametres_systeme`
--
ALTER TABLE `parametres_systeme`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=37;

--
-- AUTO_INCREMENT pour la table `statistiques`
--
ALTER TABLE `statistiques`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT pour la table `users`
--
ALTER TABLE `users`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- Contraintes pour les tables déchargées
--

--
-- Contraintes pour la table `abonnements`
--
ALTER TABLE `abonnements`
  ADD CONSTRAINT `abonnements_ibfk_1` FOREIGN KEY (`abonne_id`) REFERENCES `abonnes` (`id`) ON DELETE CASCADE;

--
-- Contraintes pour la table `abonnes`
--
ALTER TABLE `abonnes`
  ADD CONSTRAINT `abonnes_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Contraintes pour la table `destinataires`
--
ALTER TABLE `destinataires`
  ADD CONSTRAINT `destinataires_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Contraintes pour la table `documents`
--
ALTER TABLE `documents`
  ADD CONSTRAINT `documents_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Contraintes pour la table `liens`
--
ALTER TABLE `liens`
  ADD CONSTRAINT `liens_ibfk_1` FOREIGN KEY (`document_id`) REFERENCES `documents` (`id`) ON DELETE CASCADE;

--
-- Contraintes pour la table `statistiques`
--
ALTER TABLE `statistiques`
  ADD CONSTRAINT `statistiques_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `statistiques_ibfk_2` FOREIGN KEY (`document_id`) REFERENCES `documents` (`id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;

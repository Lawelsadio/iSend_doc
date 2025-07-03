-- Script pour ajouter le type d'abonnement 'illimite'
USE isend_document_flow;

-- Modifier l'enum pour inclure 'illimite'
ALTER TABLE abonnements MODIFY COLUMN type enum('gratuit','basique','premium','entreprise','illimite') DEFAULT 'gratuit';

-- Créer un abonnement illimité de test pour l'admin
INSERT INTO abonnements (user_id, type, status, limite_documents, limite_destinataires, date_debut) 
VALUES (1, 'illimite', 'actif', -1, -1, NOW())
ON DUPLICATE KEY UPDATE 
type = 'illimite',
limite_documents = -1,
limite_destinataires = -1,
status = 'actif';

-- Afficher les types d'abonnement disponibles
SELECT DISTINCT type FROM abonnements; 
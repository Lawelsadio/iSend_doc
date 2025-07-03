<?php
/**
 * Test de l'API d'envoi de PDF normaux
 * Usage: php test-normal-pdf.php
 */

require_once 'includes/db.php';
require_once 'vendor/autoload.php';

use Firebase\JWT\JWT;

// Configuration
$apiUrl = 'http://localhost:8888/isend-document-flow/backend-php/api/send-normal-pdf.php';
$testEmail = 'test@example.com'; // Email de test

// Générer un token de test
$payload = [
    'user_id' => 1,
    'email' => $testEmail,
    'role' => 'admin',
    'exp' => time() + 3600
];

$token = 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjoxLCJlbWFpbCI6ImFkbWluQGlzZW5kLmNvbSIsInJvbGUiOiJhZG1pbiIsImV4cCI6MTc1MTEwNjE5N30.F2Cn_iuj-Oa-mIAsOwMjR28tgmvD1rgGuuM5JRYP3MU';

// Données de test
$testData = [
    'destinataires' => [
        [
            'email' => 'destinataire1@example.com',
            'nom' => 'Destinataire 1'
        ],
        [
            'email' => 'destinataire2@example.com',
            'nom' => 'Destinataire 2'
        ]
    ],
    'nom_document' => 'Document de test normal',
    'chemin_fichier' => 'uploads/test_document.pdf',
    'metadata' => [
        'categorie' => 'test',
        'priorite' => 'normale',
        'description' => 'Document de test pour l\'envoi normal'
    ]
];

echo "=== Test API Envoi PDF Normal ===\n";
echo "URL: $apiUrl\n";
echo "Token: " . substr($token, 0, 50) . "...\n\n";

// Préparer la requête cURL
$ch = curl_init();

curl_setopt_array($ch, [
    CURLOPT_URL => $apiUrl,
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_POST => true,
    CURLOPT_POSTFIELDS => json_encode($testData),
    CURLOPT_HTTPHEADER => [
        'Content-Type: application/json',
        'Authorization: Bearer ' . $token
    ],
    CURLOPT_TIMEOUT => 30,
    CURLOPT_VERBOSE => true
]);

// Exécuter la requête
echo "Envoi de la requête...\n";
$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$error = curl_error($ch);

curl_close($ch);

// Afficher les résultats
echo "\n=== Résultats ===\n";
echo "Code HTTP: $httpCode\n";

if ($error) {
    echo "Erreur cURL: $error\n";
} else {
    echo "Réponse:\n";
    $decodedResponse = json_decode($response, true);
    
    if ($decodedResponse) {
        if (isset($decodedResponse['success']) && $decodedResponse['success']) {
            echo "✅ SUCCÈS\n";
            echo "Message: " . $decodedResponse['message'] . "\n";
            
            if (isset($decodedResponse['data'])) {
                echo "Document ID: " . $decodedResponse['data']['document_id'] . "\n";
                echo "Emails envoyés: " . $decodedResponse['data']['emails_envoyes'] . "\n";
                echo "Emails échoués: " . count($decodedResponse['data']['emails_echoues']) . "\n";
                
                if (!empty($decodedResponse['data']['emails_echoues'])) {
                    echo "Détails des échecs:\n";
                    foreach ($decodedResponse['data']['emails_echoues'] as $echec) {
                        echo "  - {$echec['email']}: {$echec['erreur']}\n";
                    }
                }
            }
        } else {
            echo "❌ ÉCHEC\n";
            echo "Erreur: " . ($decodedResponse['error'] ?? 'Erreur inconnue') . "\n";
            echo "Code: " . ($decodedResponse['code'] ?? 'N/A') . "\n";
        }
    } else {
        echo "❌ Réponse invalide\n";
        echo "Réponse brute: $response\n";
    }
}

echo "\n=== Test terminé ===\n";
?>

<?php
/**
 * Script de test pour déboguer l'envoi de PDF normal
 */

require_once 'includes/db.php';
require_once 'includes/jwt.php';

// Simuler les données reçues du frontend
$testData = [
    'destinataires' => [
        ['email' => 'test@example.com', 'nom' => 'Test User']
    ],
    'nom_document' => 'Document de test',
    'chemin_fichier' => 'uploads/6857524c51ea3_1750553164.pdf',
    'metadata' => [
        'description' => 'Test description',
        'tags' => 'test, debug',
        'date_creation' => date('c')
    ]
];

echo "=== TEST DÉBOGAGE ENVOI PDF NORMAL ===\n\n";

echo "1. Données reçues du frontend:\n";
echo "   - Chemin fichier: " . $testData['chemin_fichier'] . "\n";
echo "   - Nom document: " . $testData['nom_document'] . "\n";
echo "   - Destinataires: " . json_encode($testData['destinataires']) . "\n\n";

echo "2. Construction du chemin absolu:\n";
$cheminAbsolu = __DIR__ . '/../' . $testData['chemin_fichier'];
echo "   - Chemin absolu: $cheminAbsolu\n";
echo "   - Fichier existe: " . (file_exists($cheminAbsolu) ? 'OUI' : 'NON') . "\n\n";

echo "3. Génération du nom unique:\n";
$nomFichierUnique = uniqid() . '_' . time() . '_' . basename($testData['chemin_fichier']);
$cheminComplet = __DIR__ . '/../uploads/' . $nomFichierUnique;
echo "   - Nom unique: $nomFichierUnique\n";
echo "   - Chemin complet: $cheminComplet\n\n";

echo "4. Copie du fichier:\n";
if (file_exists($cheminAbsolu)) {
    if (copy($cheminAbsolu, $cheminComplet)) {
        echo "   - Copie réussie\n";
        echo "   - Taille fichier source: " . filesize($cheminAbsolu) . " bytes\n";
        echo "   - Taille fichier copié: " . filesize($cheminComplet) . " bytes\n";
    } else {
        echo "   - Échec de la copie\n";
    }
} else {
    echo "   - Fichier source n'existe pas\n";
}

echo "\n5. Vérification des fichiers dans uploads:\n";
$uploadDir = __DIR__ . '/../uploads/';
$files = glob($uploadDir . '*.pdf');
echo "   - Nombre de fichiers PDF: " . count($files) . "\n";
foreach ($files as $file) {
    echo "   - " . basename($file) . " (" . filesize($file) . " bytes)\n";
}

echo "\n=== FIN DU TEST ===\n";
?> 
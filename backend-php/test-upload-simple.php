<?php
/**
 * Test simple d'upload de PDF
 */

require_once 'includes/db.php';
require_once 'includes/jwt.php';

echo "=== TEST UPLOAD SIMPLE ===\n\n";

// Créer un fichier PDF de test
$testPdfContent = "%PDF-1.4\n1 0 obj\n<<\n/Type /Catalog\n/Pages 2 0 R\n>>\nendobj\n2 0 obj\n<<\n/Type /Pages\n/Kids [3 0 R]\n/Count 1\n>>\nendobj\n3 0 obj\n<<\n/Type /Page\n/Parent 2 0 R\n/MediaBox [0 0 612 792]\n/Contents 4 0 R\n>>\nendobj\n4 0 obj\n<<\n/Length 44\n>>\nstream\nBT\n/F1 12 Tf\n72 720 Td\n(Document de test unique) Tj\nET\nendstream\nendobj\nxref\n0 5\n0000000000 65535 f \n0000000009 00000 n \n0000000058 00000 n \n0000000115 00000 n \n0000000204 00000 n \ntrailer\n<<\n/Size 5\n/Root 1 0 R\n>>\nstartxref\n297\n%%EOF";

$filename = uniqid() . '_' . time() . '_test.pdf';
$filepath = '../uploads/' . $filename;

// Créer le fichier
file_put_contents($filepath, $testPdfContent);

echo "1. Fichier créé:\n";
echo "   - Nom: $filename\n";
echo "   - Chemin: $filepath\n";
echo "   - Taille: " . filesize($filepath) . " bytes\n\n";

// Simuler l'insertion en base
$db = getDB();
$stmt = $db->prepare("
    INSERT INTO documents (user_id, nom, description, fichier_path, fichier_original, 
                          taille, type_mime, tags, status)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'actif')
");

$user_id = 1; // ID utilisateur admin
$nom = 'Document de test unique';
$description = 'Test upload simple';
$fichier_original = 'test.pdf';
$taille = filesize($filepath);
$type_mime = 'application/pdf';
$tags = 'test, debug';

$stmt->execute([
    $user_id,
    $nom,
    $description,
    $filename,
    $fichier_original,
    $taille,
    $type_mime,
    $tags
]);

$document_id = $db->lastInsertId();

echo "2. Document inséré en base:\n";
echo "   - ID: $document_id\n";
echo "   - Nom: $nom\n";
echo "   - Fichier: $filename\n\n";

// Récupérer le document
$stmt = $db->prepare("
    SELECT id, nom, fichier_path, taille, date_upload
    FROM documents 
    WHERE id = ?
");
$stmt->execute([$document_id]);
$document = $stmt->fetch();

echo "3. Document récupéré:\n";
echo "   - ID: " . $document['id'] . "\n";
echo "   - Nom: " . $document['nom'] . "\n";
echo "   - Fichier: " . $document['fichier_path'] . "\n";
echo "   - Taille: " . $document['taille'] . " bytes\n";
echo "   - Date: " . $document['date_upload'] . "\n\n";

echo "4. Vérification du fichier:\n";
$cheminComplet = '../uploads/' . $document['fichier_path'];
echo "   - Chemin complet: $cheminComplet\n";
echo "   - Existe: " . (file_exists($cheminComplet) ? 'OUI' : 'NON') . "\n";
echo "   - Taille réelle: " . (file_exists($cheminComplet) ? filesize($cheminComplet) : 'N/A') . " bytes\n";

echo "\n=== FIN DU TEST ===\n";
echo "DocumentId à utiliser: $document_id\n";
?> 
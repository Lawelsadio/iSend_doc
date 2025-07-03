// Script de test pour la partie destinataire
// À exécuter dans la console du navigateur sur http://localhost:8080

console.log('🧪 Tests de la partie destinataire - iSend Document Flow');

// Configuration des tests
const BASE_URL = 'http://localhost:8080';
const TEST_TOKEN = 'test-token-123';
const VALID_EMAILS = ['marie.martin@entreprise.com', 'jean.dupont@societe.fr'];
const INVALID_EMAILS = ['invalid@test.com', 'wrong@email.fr'];

// Fonction utilitaire pour tester une URL
async function testUrl(url, description) {
  console.log(`\n🔍 Test: ${description}`);
  console.log(`URL: ${url}`);
  
  try {
    const response = await fetch(url);
    console.log(`✅ Status: ${response.status}`);
    console.log(`📄 Type: ${response.headers.get('content-type')}`);
    return response.ok;
  } catch (error) {
    console.log(`❌ Erreur: ${error.message}`);
    return false;
  }
}

// Tests des routes destinataires
async function runRecipientTests() {
  console.log('\n🚀 Démarrage des tests destinataires...\n');
  
  // Test 1: Page d'accès au document
  await testUrl(
    `${BASE_URL}/d/${TEST_TOKEN}`,
    'Page d\'accès au document'
  );
  
  // Test 2: Visionneuse sécurisée (avec email valide)
  await testUrl(
    `${BASE_URL}/d/${TEST_TOKEN}/view?email=${encodeURIComponent(VALID_EMAILS[0])}`,
    'Visionneuse sécurisée (email valide)'
  );
  
  // Test 3: Page d'erreur - email invalide
  await testUrl(
    `${BASE_URL}/d/${TEST_TOKEN}/error?type=invalid-email`,
    'Page d\'erreur - email invalide'
  );
  
  // Test 4: Page d'erreur - abonnement expiré
  await testUrl(
    `${BASE_URL}/d/${TEST_TOKEN}/error?type=expired`,
    'Page d\'erreur - abonnement expiré'
  );
  
  // Test 5: Page d'erreur - accès non autorisé
  await testUrl(
    `${BASE_URL}/d/${TEST_TOKEN}/error?type=unauthorized`,
    'Page d\'erreur - accès non autorisé'
  );
  
  // Test 6: Page de confirmation
  await testUrl(
    `${BASE_URL}/d/${TEST_TOKEN}/confirmation?email=${encodeURIComponent(VALID_EMAILS[0])}`,
    'Page de confirmation de lecture'
  );
  
  console.log('\n✅ Tests terminés !');
}

// Fonction pour tester le flux complet
function testCompleteFlow() {
  console.log('\n🔄 Test du flux complet destinataire...');
  
  // Simulation du flux utilisateur
  const steps = [
    {
      step: 1,
      action: 'Accès à la page de consultation',
      url: `${BASE_URL}/d/${TEST_TOKEN}`,
      expected: 'Formulaire de saisie email'
    },
    {
      step: 2,
      action: 'Saisie email valide',
      url: `${BASE_URL}/d/${TEST_TOKEN}/view?email=${encodeURIComponent(VALID_EMAILS[0])}`,
      expected: 'Visionneuse PDF sécurisée'
    },
    {
      step: 3,
      action: 'Fermeture du document',
      url: `${BASE_URL}/d/${TEST_TOKEN}/confirmation?email=${encodeURIComponent(VALID_EMAILS[0])}`,
      expected: 'Page de confirmation'
    }
  ];
  
  steps.forEach(step => {
    console.log(`\n📋 Étape ${step.step}: ${step.action}`);
    console.log(`   URL: ${step.url}`);
    console.log(`   Attendu: ${step.expected}`);
  });
}

// Fonction pour tester les emails valides/invalides
function testEmailValidation() {
  console.log('\n📧 Test de validation des emails...');
  
  console.log('\n✅ Emails valides (devraient accéder au document):');
  VALID_EMAILS.forEach(email => {
    console.log(`   - ${email}`);
  });
  
  console.log('\n❌ Emails invalides (devraient générer une erreur):');
  INVALID_EMAILS.forEach(email => {
    console.log(`   - ${email}`);
  });
}

// Exécution des tests
console.log('🎯 Pour exécuter les tests, utilisez une de ces commandes :');
console.log('   - runRecipientTests() : Tests des routes');
console.log('   - testCompleteFlow() : Test du flux complet');
console.log('   - testEmailValidation() : Test des emails');

// Export des fonctions pour utilisation
window.runRecipientTests = runRecipientTests;
window.testCompleteFlow = testCompleteFlow;
window.testEmailValidation = testEmailValidation; 
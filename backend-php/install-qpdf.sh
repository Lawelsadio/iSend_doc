#!/bin/bash

echo "🔧 Installation de qpdf pour le chiffrement PDF..."

# Vérifier si Homebrew est installé
if ! command -v brew &> /dev/null; then
    echo "❌ Homebrew n'est pas installé. Installation de Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Installer qpdf
echo "📦 Installation de qpdf..."
brew install qpdf

# Vérifier l'installation
if command -v qpdf &> /dev/null; then
    echo "✅ qpdf installé avec succès!"
    echo "📍 Chemin: $(which qpdf)"
    echo "📋 Version: $(qpdf --version | head -1)"
else
    echo "❌ Échec de l'installation de qpdf"
    exit 1
fi

echo ""
echo "🎉 Installation terminée!"
echo "📝 Le chiffrement PDF sera maintenant disponible dans l'application."

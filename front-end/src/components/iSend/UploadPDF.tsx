import { useState } from 'react';
import { Button } from '@/components/ui/button';
import { Card, CardHeader, CardContent, CardTitle } from '@/components/ui/card';
import { Upload, FileText, ArrowLeft, AlertCircle } from 'lucide-react';
import { documentService } from '@/services';
import type { DocumentMetadata } from '@/services/documentService';

interface UploadPDFProps {
  onNext: (data: { file: File | null; documentId?: number; initialMetadata: DocumentMetadata }) => void;
  onBack: () => void;
}

const UploadPDF = ({ onNext, onBack }: UploadPDFProps) => {
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const [dragOver, setDragOver] = useState(false);
  const [isUploading, setIsUploading] = useState(false);
  const [error, setError] = useState('');

  const handleFileSelect = (file: File) => {
    if (file.type === 'application/pdf') {
      setSelectedFile(file);
      setError('');
    } else {
      setError('Veuillez sélectionner un fichier PDF.');
    }
  };

  const handleDrop = (e: React.DragEvent) => {
    e.preventDefault();
    setDragOver(false);
    const file = e.dataTransfer.files[0];
    if (file) handleFileSelect(file);
  };

  const handleFileInput = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) handleFileSelect(file);
  };

  const handleNext = async () => {
    if (!selectedFile) return;

    setIsUploading(true);
    setError('');

    try {
      // Upload du document avec métadonnées temporaires
      const metadata: DocumentMetadata = {
        titre: selectedFile.name.replace('.pdf', ''),
        description: '',
        tags: []
      };

      const response = await documentService.uploadDocument(selectedFile, metadata);

      if (response.success && response.data) {
        // Les métadonnées seront mises à jour dans l'étape suivante (AddMetadata)
        onNext({ 
          file: selectedFile, 
          documentId: response.data.document_id,
          initialMetadata: metadata
        });
      } else {
        setError(response.error || 'Erreur lors de l\'upload');
      }
    } catch (err) {
      setError('Erreur lors de l\'upload du fichier');
      console.error('Erreur upload:', err);
    } finally {
      setIsUploading(false);
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center space-x-4">
        <Button variant="outline" onClick={onBack} disabled={isUploading}>
          <ArrowLeft className="h-4 w-4 mr-2" />
          Retour
        </Button>
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Upload de PDF</h1>
          <p className="text-gray-600 mt-1">Sélectionnez le document à distribuer</p>
        </div>
      </div>

      <Card className="max-w-2xl">
        <CardHeader>
          <CardTitle>Télécharger votre document PDF</CardTitle>
        </CardHeader>
        <CardContent>
          {error && (
            <div className="flex items-center space-x-2 p-3 bg-red-50 border border-red-200 rounded-lg mb-4">
              <AlertCircle className="h-4 w-4 text-red-600" />
              <span className="text-sm text-red-600">{error}</span>
            </div>
          )}

          <div
            className={`border-2 border-dashed rounded-lg p-8 text-center transition-colors ${
              dragOver 
                ? 'border-blue-400 bg-blue-50' 
                : selectedFile 
                  ? 'border-green-400 bg-green-50' 
                  : 'border-gray-300 hover:border-gray-400'
            }`}
            onDragOver={(e) => { e.preventDefault(); setDragOver(true); }}
            onDragLeave={() => setDragOver(false)}
            onDrop={handleDrop}
          >
            {selectedFile ? (
              <div className="space-y-4">
                <FileText className="h-16 w-16 text-green-600 mx-auto" />
                <div>
                  <p className="text-lg font-medium text-gray-900">{selectedFile.name}</p>
                  <p className="text-sm text-gray-500">
                    {(selectedFile.size / 1024 / 1024).toFixed(2)} MB
                  </p>
                </div>
                <Button 
                  variant="outline" 
                  onClick={() => setSelectedFile(null)}
                  disabled={isUploading}
                >
                  Changer de fichier
                </Button>
              </div>
            ) : (
              <div className="space-y-4">
                <Upload className="h-16 w-16 text-gray-400 mx-auto" />
                <div>
                  <p className="text-lg font-medium text-gray-900 mb-2">
                    Glissez-déposez votre PDF ici
                  </p>
                  <p className="text-gray-500 mb-4">ou</p>
                  <label className="cursor-pointer">
                    <Button variant="outline" className="relative" disabled={isUploading}>
                      Parcourir les fichiers
                      <input
                        type="file"
                        accept=".pdf"
                        onChange={handleFileInput}
                        className="absolute inset-0 w-full h-full opacity-0 cursor-pointer"
                        disabled={isUploading}
                      />
                    </Button>
                  </label>
                </div>
                <p className="text-sm text-gray-500">
                  Seuls les fichiers PDF sont acceptés (max 50MB)
                </p>
              </div>
            )}
          </div>

          {selectedFile && (
            <div className="mt-6 flex justify-end">
              <Button 
                onClick={handleNext} 
                className="bg-blue-600 hover:bg-blue-700"
                disabled={isUploading}
              >
                {isUploading ? (
                  <>
                    <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2"></div>
                    Upload en cours...
                  </>
                ) : (
                  'Suivant'
                )}
              </Button>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
};

export default UploadPDF;

import React, { useState } from 'react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { Card, CardHeader, CardContent, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { ArrowLeft, Plus, X } from 'lucide-react';
import { DocumentMetadata } from '@/services/documentService';
import DocumentService from '@/services/documentService';

const documentService = new DocumentService();

interface AddMetadataProps {
  onNext: (data: { title: string; description: string; tags: string[] }) => void;
  onBack: () => void;
  initialData: { title: string; description: string; tags: string[] };
  documentId?: number;
}

const AddMetadata = ({ onNext, onBack, initialData, documentId }: AddMetadataProps) => {
  const [title, setTitle] = useState(initialData.title || '');
  const [description, setDescription] = useState(initialData.description || '');
  const [tags, setTags] = useState<string[]>(initialData.tags || []);
  const [newTag, setNewTag] = useState('');
  const [isUpdating, setIsUpdating] = useState(false);

  const addTag = () => {
    if (newTag.trim() && !tags.includes(newTag.trim())) {
      setTags([...tags, newTag.trim()]);
      setNewTag('');
    }
  };

  const removeTag = (tagToRemove: string) => {
    setTags(tags.filter(tag => tag !== tagToRemove));
  };

  const handleNext = async () => {
    if (title.trim()) {
      setIsUpdating(true);
      
      try {
        // Mettre à jour les métadonnées du document si un documentId est fourni
        if (documentId) {
          const metadata: DocumentMetadata = {
            titre: title,
            description,
            tags
          };
          
          const response = await documentService.updateDocument(documentId, metadata);
          
          if (!response.success) {
            console.error('Erreur lors de la mise à jour des métadonnées:', response.error);
            // Continuer quand même, les métadonnées seront sauvegardées localement
          }
        }
        
        onNext({ title, description, tags });
      } catch (error) {
        console.error('Erreur lors de la mise à jour des métadonnées:', error);
        // Continuer quand même
        onNext({ title, description, tags });
      } finally {
        setIsUpdating(false);
      }
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center space-x-4">
        <Button variant="outline" onClick={onBack}>
          <ArrowLeft className="h-4 w-4 mr-2" />
          Retour
        </Button>
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Métadonnées du document</h1>
          <p className="text-gray-600 mt-1">Ajoutez les informations descriptives</p>
        </div>
      </div>

      <Card className="max-w-2xl">
        <CardHeader>
          <CardTitle>Informations du document</CardTitle>
        </CardHeader>
        <CardContent className="space-y-6">
          <div className="space-y-2">
            <Label htmlFor="title">Titre du document *</Label>
            <Input
              id="title"
              placeholder="Ex: Rapport mensuel Mars 2024"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              required
            />
          </div>

          <div className="space-y-2">
            <Label htmlFor="description">Description</Label>
            <Textarea
              id="description"
              placeholder="Description optionnelle du contenu du document..."
              rows={4}
              value={description}
              onChange={(e) => setDescription(e.target.value)}
            />
          </div>

          <div className="space-y-2">
            <Label>Tags optionnels</Label>
            <div className="flex space-x-2">
              <Input
                placeholder="Ajouter un tag"
                value={newTag}
                onChange={(e) => setNewTag(e.target.value)}
                onKeyPress={(e) => e.key === 'Enter' && addTag()}
              />
              <Button onClick={addTag} variant="outline">
                <Plus className="h-4 w-4" />
              </Button>
            </div>
            {tags.length > 0 && (
              <div className="flex flex-wrap gap-2 mt-3">
                {tags.map((tag, index) => (
                  <Badge key={index} variant="secondary" className="flex items-center space-x-1">
                    <span>{tag}</span>
                    <X 
                      className="h-3 w-3 cursor-pointer hover:text-red-600" 
                      onClick={() => removeTag(tag)}
                    />
                  </Badge>
                ))}
              </div>
            )}
          </div>

          <div className="flex justify-end">
            <Button 
              onClick={handleNext} 
              disabled={!title.trim() || isUpdating}
              className="w-full"
            >
              {isUpdating ? 'Mise à jour...' : 'Continuer'}
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
};

export default AddMetadata;

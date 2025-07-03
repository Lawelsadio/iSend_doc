import { Button } from '@/components/ui/button';
import { Card, CardHeader, CardContent, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { ArrowLeft, FileText, Eye, Send, Download } from 'lucide-react';

interface DocumentDetailsProps {
  onBack: () => void;
}

const DocumentDetails = ({ onBack }: DocumentDetailsProps) => {
  const documentInfo = {
    name: 'Rapport_Mensuel_Janvier_2024.pdf',
    sentDate: '15 janvier 2024, 14:30',
    totalViews: 12,
    size: '2.4 MB'
  };

  const recipients = [
    {
      email: 'marie.martin@entreprise.com',
      openDate: '15 janvier 2024, 15:45',
      views: 3,
      status: 'Vu',
      statusColor: 'bg-green-100 text-green-800'
    },
    {
      email: 'pierre.durand@client.fr',
      openDate: '16 janvier 2024, 09:20',
      views: 2,
      status: 'Vu',
      statusColor: 'bg-green-100 text-green-800'
    },
    {
      email: 'sophie.bernard@partenaire.com',
      openDate: '-',
      views: 0,
      status: 'Non vu',
      statusColor: 'bg-gray-100 text-gray-600'
    },
    {
      email: 'thomas.petit@fournisseur.net',
      openDate: '17 janvier 2024, 11:15',
      views: 7,
      status: 'Vu',
      statusColor: 'bg-green-100 text-green-800'
    }
  ];

  const handleResend = () => {
    alert('Lien renvoyé avec succès !');
  };

  const handleExport = () => {
    alert('Données exportées avec succès !');
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center space-x-4">
        <Button variant="outline" onClick={onBack}>
          <ArrowLeft className="h-4 w-4 mr-2" />
          Retour
        </Button>
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Détails du document</h1>
          <p className="text-gray-600 mt-1">Suivi et statistiques d'accès</p>
        </div>
      </div>

      <Card>
        <CardHeader>
          <CardTitle className="flex items-center space-x-2">
            <FileText className="h-5 w-5" />
            <span>Aperçu du document</span>
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
            <div>
              <p className="text-sm text-gray-500">Nom du fichier</p>
              <p className="font-medium">{documentInfo.name}</p>
            </div>
            <div>
              <p className="text-sm text-gray-500">Date d'envoi</p>
              <p className="font-medium">{documentInfo.sentDate}</p>
            </div>
            <div>
              <p className="text-sm text-gray-500">Taille</p>
              <p className="font-medium">{documentInfo.size}</p>
            </div>
            <div>
              <p className="text-sm text-gray-500">Nombre total de vues</p>
              <p className="text-2xl font-bold text-blue-600">{documentInfo.totalViews}</p>
            </div>
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle className="flex items-center justify-between">
            <span className="flex items-center space-x-2">
              <Eye className="h-5 w-5" />
              <span>Liste des destinataires ({recipients.length})</span>
            </span>
            <div className="flex space-x-2">
              <Button variant="outline" onClick={handleResend}>
                <Send className="h-4 w-4 mr-2" />
                Renvoyer le lien
              </Button>
              <Button variant="outline" onClick={handleExport}>
                <Download className="h-4 w-4 mr-2" />
                Exporter les données
              </Button>
            </div>
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="max-h-96 overflow-y-auto">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Email</TableHead>
                  <TableHead>Date d'ouverture</TableHead>
                  <TableHead>Nombre de vues</TableHead>
                  <TableHead>Statut</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {recipients.map((recipient, index) => (
                  <TableRow key={index}>
                    <TableCell className="font-medium">{recipient.email}</TableCell>
                    <TableCell>{recipient.openDate}</TableCell>
                    <TableCell>
                      <span className="font-semibold">{recipient.views}</span>
                    </TableCell>
                    <TableCell>
                      <Badge className={recipient.statusColor}>
                        {recipient.status}
                      </Badge>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
        </CardContent>
      </Card>
    </div>
  );
};

export default DocumentDetails;

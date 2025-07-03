import { useState, useEffect } from 'react';
import LoginScreen from '@/components/iSend/LoginScreen';
import Dashboard from '@/components/iSend/Dashboard';
import UploadPDF from '@/components/iSend/UploadPDF';
import AddMetadata from '@/components/iSend/AddMetadata';
import SelectRecipients from '@/components/iSend/SelectRecipients';
import SendSummary from '@/components/iSend/SendSummary';
import Statistics from '@/components/iSend/Statistics';
import AccessDetails from '@/components/iSend/AccessDetails';
import SubscriberManagement from '@/components/iSend/SubscriberManagement';
import UserSettings from '@/components/iSend/UserSettings';
import AdminDashboard from '@/components/iSend/AdminDashboard';
import Sidebar from '@/components/iSend/Sidebar';
import DocumentDetails from '@/components/iSend/DocumentDetails';
import ErrorPage from '@/components/iSend/ErrorPage';
import SecurePDFViewer from '@/components/iSend/SecurePDFViewer';
import authService from '@/services/authService';

const Index = () => {
  const [isLoggedIn, setIsLoggedIn] = useState(false);
  const [isLoading, setIsLoading] = useState(true);
  const [currentScreen, setCurrentScreen] = useState('dashboard');
  const [userRole, setUserRole] = useState<'user' | 'admin'>('user');
  const [uploadData, setUploadData] = useState({
    file: null,
    title: '',
    description: '',
    tags: [],
    recipients: [],
    documentId: null
  });
  const [selectedDocumentId, setSelectedDocumentId] = useState<number | null>(null);

  // Vérifier l'état d'authentification au chargement
  useEffect(() => {
    const checkAuth = () => {
      const auth = authService.getInstance();
      const isAuthenticated = auth.isAuthenticated();
      setIsLoggedIn(isAuthenticated);
      
      if (isAuthenticated) {
        const user = auth.getCurrentUser();
        if (user && user.role) {
          setUserRole(user.role);
        }
      }
      
      setIsLoading(false);
    };

    checkAuth();
  }, []);

  const handleLogin = () => {
    setIsLoggedIn(true);
    setCurrentScreen('dashboard');
    
    // Récupérer le rôle de l'utilisateur après connexion
    const auth = authService.getInstance();
    const user = auth.getCurrentUser();
    if (user && user.role) {
      setUserRole(user.role);
    }
  };

  const handleLogout = () => {
    const auth = authService.getInstance();
    auth.logout();
    setIsLoggedIn(false);
    setCurrentScreen('dashboard');
    setUserRole('user');
  };

  const handleNavigate = (screen: string, docId?: number) => {
    // Vérifier les permissions pour l'accès admin
    if (screen === 'admin' && userRole !== 'admin') {
      console.warn('Tentative d\'accès à l\'administration sans droits');
      return;
    }
    
    setCurrentScreen(screen);
    if (docId !== undefined) setSelectedDocumentId(docId);
  };

  const renderScreen = () => {
    switch (currentScreen) {
      case 'dashboard':
        return <Dashboard onNewDocument={() => setCurrentScreen('upload')} onNavigate={handleNavigate} />;
      case 'upload':
        return <UploadPDF onNext={(data) => { setUploadData(prev => ({ ...prev, ...data })); setCurrentScreen('metadata'); }} onBack={() => setCurrentScreen('dashboard')} />;
      case 'metadata':
        return <AddMetadata onNext={(data) => { setUploadData(prev => ({ ...prev, ...data })); setCurrentScreen('recipients'); }} onBack={() => setCurrentScreen('upload')} initialData={uploadData} />;
      case 'recipients':
        return <SelectRecipients onNext={(data) => { setUploadData(prev => ({ ...prev, ...data })); setCurrentScreen('summary'); }} onBack={() => setCurrentScreen('metadata')} initialData={uploadData} />;
      case 'summary':
        return <SendSummary 
          data={uploadData} 
          onSend={() => setCurrentScreen('dashboard')} 
          onBack={() => setCurrentScreen('recipients')} 
          onDocumentIdUpdate={(id) => setUploadData(prev => ({ ...prev, documentId: id }))}
        />;
      case 'statistics':
        return <Statistics onNavigate={handleNavigate} />;
      case 'access-details':
        if (!selectedDocumentId) {
          setCurrentScreen('dashboard');
          return <Dashboard onNewDocument={() => setCurrentScreen('upload')} onNavigate={handleNavigate} />;
        }
        return <AccessDetails onBack={() => setCurrentScreen('dashboard')} documentId={selectedDocumentId} />;
      case 'document-details':
        return <DocumentDetails onBack={() => setCurrentScreen('statistics')} />;
      case 'error-expired':
        return <ErrorPage onBackHome={() => setCurrentScreen('dashboard')} errorType="expired" />;
      case 'error-unauthorized':
        return <ErrorPage onBackHome={() => setCurrentScreen('dashboard')} errorType="unauthorized" />;
      case 'pdf-viewer':
        return <SecurePDFViewer onClose={() => setCurrentScreen('dashboard')} />;
      case 'subscribers':
        return <SubscriberManagement />;
      case 'settings':
        return <UserSettings />;
      case 'admin':
        return userRole === 'admin' ? <AdminDashboard /> : <Dashboard onNewDocument={() => setCurrentScreen('upload')} onNavigate={handleNavigate} />;
      default:
        return <Dashboard onNewDocument={() => setCurrentScreen('upload')} onNavigate={handleNavigate} />;
    }
  };

  if (isLoading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto mb-4"></div>
          <p className="text-gray-600">Chargement...</p>
        </div>
      </div>
    );
  }

  if (!isLoggedIn) {
    return <LoginScreen onLogin={handleLogin} />;
  }

  return (
    <div className="min-h-screen bg-gray-50 flex w-full">
      <Sidebar currentScreen={currentScreen} onNavigate={handleNavigate} onLogout={handleLogout} userRole={userRole} />
      <main className="flex-1 p-6">
        {renderScreen()}
      </main>
    </div>
  );
};

export default Index;

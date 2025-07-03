import { 
  LayoutDashboard, 
  FileText, 
  BarChart3, 
  Users, 
  Settings, 
  Mail,
  LogOut,
  Shield,
  Crown
} from 'lucide-react';
import { cn } from '@/lib/utils';

interface SidebarProps {
  currentScreen: string;
  onNavigate: (screen: string) => void;
  onLogout: () => void;
  userRole?: 'user' | 'admin';
}

const Sidebar = ({ currentScreen, onNavigate, onLogout, userRole = 'user' }: SidebarProps) => {
  const menuItems = [
    { id: 'dashboard', label: 'Tableau de bord', icon: LayoutDashboard },
    { id: 'statistics', label: 'Statistiques', icon: BarChart3 },
    { id: 'subscribers', label: 'Abonnés', icon: Users },
    { id: 'settings', label: 'Paramètres', icon: Settings },
  ];

  // Ajouter l'option d'administration pour les admins
  if (userRole === 'admin') {
    menuItems.push({ id: 'admin', label: 'Administration', icon: Crown });
  }

  return (
    <div className="w-64 bg-white border-r border-gray-200 h-screen flex flex-col">
      <div className="p-6 border-b border-gray-200">
        <div className="flex items-center space-x-2">
          <div className="w-8 h-8 bg-blue-600 rounded-lg flex items-center justify-center">
            <Mail className="h-5 w-5 text-white" />
          </div>
          <span className="text-xl font-bold text-gray-900">iSend</span>
          {userRole === 'admin' && (
            <div className="ml-2">
              <Crown className="h-4 w-4 text-yellow-500" />
            </div>
          )}
        </div>
      </div>
      
      <nav className="flex-1 p-4">
        <ul className="space-y-2">
          {menuItems.map((item) => (
            <li key={item.id}>
              <button
                onClick={() => onNavigate(item.id)}
                className={cn(
                  "w-full flex items-center space-x-3 px-3 py-2 rounded-lg text-left transition-colors",
                  currentScreen === item.id
                    ? "bg-blue-50 text-blue-700 border border-blue-200"
                    : "text-gray-600 hover:bg-gray-50 hover:text-gray-900"
                )}
              >
                <item.icon className="h-5 w-5" />
                <span className="font-medium">{item.label}</span>
                {item.id === 'admin' && (
                  <Shield className="h-3 w-3 text-yellow-500 ml-auto" />
                )}
              </button>
            </li>
          ))}
        </ul>
      </nav>

      <div className="p-4 border-t border-gray-200">
        <button
          onClick={onLogout}
          className="w-full flex items-center space-x-3 px-3 py-2 rounded-lg text-left transition-colors text-red-600 hover:bg-red-50"
        >
          <LogOut className="h-5 w-5" />
          <span className="font-medium">Se déconnecter</span>
        </button>
      </div>
    </div>
  );
};

export default Sidebar;

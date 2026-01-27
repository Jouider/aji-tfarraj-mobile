import { Outlet, useLocation, useNavigate } from 'react-router-dom';
import { Home, Calendar, Ticket, User } from 'lucide-react';
import { Language } from '@/app/App';

interface Props {
  language: Language;
}

const translations = {
  fr: {
    home: 'Émissions',
    reservations: 'Réservations',
    ticket: 'Billet',
    profile: 'Profil',
  },
  ar: {
    home: 'البرامج',
    reservations: 'الحجوزات',
    ticket: 'التذكرة',
    profile: 'الملف',
  },
};

export function MainLayout({ language }: Props) {
  const location = useLocation();
  const navigate = useNavigate();
  const t = translations[language];

  const tabs = [
    { path: '/home', label: t.home, icon: Home },
    { path: '/my-reservations', label: t.reservations, icon: Calendar },
    { path: '/ticket', label: t.ticket, icon: Ticket },
    { path: '/profile', label: t.profile, icon: User },
  ];

  return (
    <div className="h-screen flex flex-col bg-white">
      {/* Main Content */}
      <div className="flex-1 overflow-y-auto">
        <Outlet />
      </div>

      {/* Bottom Navigation */}
      <div className="border-t border-zinc-200 bg-white">
        <div className="grid grid-cols-4 gap-1">
          {tabs.map((tab) => {
            const Icon = tab.icon;
            const isActive = location.pathname === tab.path;
            return (
              <button
                key={tab.path}
                onClick={() => navigate(tab.path)}
                className={`py-3 px-2 flex flex-col items-center gap-1 transition-colors ${
                  isActive ? 'text-zinc-800' : 'text-zinc-400'
                }`}
              >
                <Icon className="w-5 h-5" />
                <span className="text-xs font-medium">{tab.label}</span>
              </button>
            );
          })}
        </div>
      </div>
    </div>
  );
}

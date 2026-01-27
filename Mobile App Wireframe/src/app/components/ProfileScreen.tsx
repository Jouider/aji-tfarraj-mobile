import { Language } from '@/app/App';
import { User, Globe, Bell, HelpCircle, MessageCircle, LogOut, ChevronRight } from 'lucide-react';

interface Props {
  language: Language;
  onLanguageChange: (lang: Language) => void;
}

const translations = {
  fr: {
    title: 'Profil',
    account: 'Compte',
    name: 'Nom complet',
    phone: 'Téléphone',
    settings: 'Paramètres',
    language: 'Langue',
    notifications: 'Notifications',
    help: 'Aide & Support',
    faq: 'FAQ',
    contact: 'Contacter le support',
    whatsapp: 'WhatsApp',
    logout: 'Se déconnecter',
    french: 'Français',
    arabic: 'العربية',
  },
  ar: {
    title: 'الملف الشخصي',
    account: 'الحساب',
    name: 'الاسم الكامل',
    phone: 'الهاتف',
    settings: 'الإعدادات',
    language: 'اللغة',
    notifications: 'الإشعارات',
    help: 'المساعدة والدعم',
    faq: 'الأسئلة الشائعة',
    contact: 'اتصل بالدعم',
    whatsapp: 'واتساب',
    logout: 'تسجيل الخروج',
    french: 'Français',
    arabic: 'العربية',
  },
};

export function ProfileScreen({ language, onLanguageChange }: Props) {
  const t = translations[language];

  const user = {
    name: 'Ahmed Bennani',
    phone: '+212 6 12 34 56 78',
  };

  return (
    <div className="h-full flex flex-col bg-white">
      {/* Header */}
      <div className="px-4 py-4 border-b border-zinc-200">
        <h1 className="text-xl font-bold text-zinc-800">{t.title}</h1>
      </div>

      {/* Content */}
      <div className="flex-1 overflow-y-auto">
        {/* Profile Avatar */}
        <div className="p-6 border-b border-zinc-200">
          <div className="flex items-center gap-4">
            <div className="w-16 h-16 rounded-full bg-zinc-200 flex items-center justify-center">
              <User className="w-8 h-8 text-zinc-500" />
            </div>
            <div>
              <div className="font-semibold text-zinc-800">{user.name}</div>
              <div className="text-sm text-zinc-500">{user.phone}</div>
            </div>
          </div>
        </div>

        {/* Settings Section */}
        <div className="p-4 space-y-1">
          <div className="text-xs font-semibold text-zinc-500 uppercase px-3 py-2">
            {t.settings}
          </div>

          {/* Language */}
          <button className="w-full px-4 py-3 flex items-center justify-between hover:bg-zinc-50 rounded-lg transition-colors">
            <div className="flex items-center gap-3">
              <Globe className="w-5 h-5 text-zinc-600" />
              <div className="text-left">
                <div className="font-medium text-zinc-800">{t.language}</div>
                <div className="text-sm text-zinc-500">
                  {language === 'fr' ? t.french : t.arabic}
                </div>
              </div>
            </div>
            <ChevronRight className="w-5 h-5 text-zinc-400" />
          </button>

          {/* Notifications */}
          <button className="w-full px-4 py-3 flex items-center justify-between hover:bg-zinc-50 rounded-lg transition-colors">
            <div className="flex items-center gap-3">
              <Bell className="w-5 h-5 text-zinc-600" />
              <span className="font-medium text-zinc-800">{t.notifications}</span>
            </div>
            <div className="flex items-center gap-2">
              <div className="w-10 h-6 bg-zinc-800 rounded-full relative">
                <div className="absolute right-1 top-1 w-4 h-4 bg-white rounded-full"></div>
              </div>
            </div>
          </button>
        </div>

        {/* Help Section */}
        <div className="p-4 space-y-1 border-t border-zinc-200">
          <div className="text-xs font-semibold text-zinc-500 uppercase px-3 py-2">
            {t.help}
          </div>

          {/* FAQ */}
          <button className="w-full px-4 py-3 flex items-center justify-between hover:bg-zinc-50 rounded-lg transition-colors">
            <div className="flex items-center gap-3">
              <HelpCircle className="w-5 h-5 text-zinc-600" />
              <span className="font-medium text-zinc-800">{t.faq}</span>
            </div>
            <ChevronRight className="w-5 h-5 text-zinc-400" />
          </button>

          {/* Contact Support */}
          <button className="w-full px-4 py-3 flex items-center justify-between hover:bg-zinc-50 rounded-lg transition-colors">
            <div className="flex items-center gap-3">
              <MessageCircle className="w-5 h-5 text-zinc-600" />
              <div className="text-left">
                <div className="font-medium text-zinc-800">{t.contact}</div>
                <div className="text-sm text-zinc-500">{t.whatsapp}</div>
              </div>
            </div>
            <ChevronRight className="w-5 h-5 text-zinc-400" />
          </button>
        </div>

        {/* Logout */}
        <div className="p-4 border-t border-zinc-200">
          <button className="w-full px-4 py-3 flex items-center gap-3 hover:bg-red-50 rounded-lg transition-colors text-red-600">
            <LogOut className="w-5 h-5" />
            <span className="font-medium">{t.logout}</span>
          </button>
        </div>

        {/* App Version */}
        <div className="p-4 text-center text-xs text-zinc-400">
          Aji Tfarraj v1.0.0
        </div>
      </div>
    </div>
  );
}

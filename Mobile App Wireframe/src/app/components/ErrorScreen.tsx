import { useNavigate } from 'react-router-dom';
import { Language } from '@/app/App';
import { WifiOff } from 'lucide-react';

interface Props {
  language: Language;
}

const translations = {
  fr: {
    title: 'Pas de connexion',
    message: 'Vérifiez votre connexion Internet et réessayez',
    retry: 'Réessayer',
  },
  ar: {
    title: 'لا يوجد اتصال',
    message: 'تحقق من اتصالك بالإنترنت وحاول مرة أخرى',
    retry: 'حاول مرة أخرى',
  },
};

export function ErrorScreen({ language }: Props) {
  const navigate = useNavigate();
  const t = translations[language];

  return (
    <div className="h-screen flex flex-col items-center justify-center bg-white p-6">
      <div className="w-full max-w-sm text-center space-y-6">
        {/* Error Icon */}
        <div className="w-20 h-20 mx-auto bg-zinc-100 rounded-full flex items-center justify-center">
          <WifiOff className="w-10 h-10 text-zinc-400" />
        </div>

        {/* Message */}
        <div className="space-y-2">
          <h2 className="text-xl font-semibold text-zinc-800">{t.title}</h2>
          <p className="text-zinc-600 text-sm">{t.message}</p>
        </div>

        {/* Retry Button */}
        <button
          onClick={() => navigate(-1)}
          className="w-full px-6 py-3 bg-zinc-800 text-white rounded-lg font-medium hover:bg-zinc-700 transition-colors"
        >
          {t.retry}
        </button>
      </div>
    </div>
  );
}

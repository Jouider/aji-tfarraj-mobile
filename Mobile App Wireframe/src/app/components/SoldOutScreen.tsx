import { useNavigate, useParams } from 'react-router-dom';
import { Language } from '@/app/App';
import { ChevronLeft, ChevronRight, Calendar, Clock, MapPin } from 'lucide-react';

interface Props {
  language: Language;
}

const translations = {
  fr: {
    soldOut: 'Complet',
    message: 'Toutes les places pour cette émission ont été réservées',
    waitlist: 'Rejoindre la liste d\'attente',
    waitlistInfo: 'Nous vous contacterons si une place se libère',
    backHome: 'Retour à l\'accueil',
    showDetails: 'Détails de l\'émission',
  },
  ar: {
    soldOut: 'ممتلئ',
    message: 'تم حجز جميع المقاعد لهذا البرنامج',
    waitlist: 'انضم إلى قائمة الانتظار',
    waitlistInfo: 'سنتصل بك في حال توفر مقعد',
    backHome: 'العودة إلى الرئيسية',
    showDetails: 'تفاصيل البرنامج',
  },
};

export function SoldOutScreen({ language }: Props) {
  const navigate = useNavigate();
  const { id } = useParams();
  const t = translations[language];
  const BackIcon = language === 'ar' ? ChevronRight : ChevronLeft;

  const show = {
    id: id || '1',
    title: 'Talk Show Maghribi',
    channel: '2M',
    date: '15 Feb 2026',
    time: '20:00',
    location: 'Studio 2M - Casablanca',
  };

  return (
    <div className="h-screen flex flex-col bg-white">
      {/* Header */}
      <div className="px-4 py-4 border-b border-zinc-200">
        <button onClick={() => navigate(-1)} className="p-2 -ml-2">
          <BackIcon className="w-6 h-6 text-zinc-800" />
        </button>
      </div>

      {/* Content */}
      <div className="flex-1 flex flex-col items-center justify-center p-6">
        <div className="w-full max-w-sm text-center space-y-6">
          {/* Sold Out Badge */}
          <div className="inline-flex items-center justify-center px-6 py-3 bg-red-50 border border-red-200 rounded-full">
            <span className="text-red-700 font-semibold">{t.soldOut}</span>
          </div>

          {/* Message */}
          <div className="space-y-2">
            <h2 className="text-xl font-semibold text-zinc-800">{show.title}</h2>
            <p className="text-zinc-600 text-sm">{t.message}</p>
          </div>

          {/* Show Details */}
          <div className="p-4 bg-zinc-50 rounded-lg border border-zinc-200 text-left space-y-2 text-sm">
            <div>
              <span className="inline-block px-2 py-0.5 bg-white text-zinc-700 text-xs rounded border border-zinc-200">
                {show.channel}
              </span>
            </div>
            <div className="flex items-center gap-2 text-zinc-600">
              <Calendar className="w-4 h-4" />
              <span>{show.date}</span>
              <Clock className="w-4 h-4 ml-2" />
              <span>{show.time}</span>
            </div>
            <div className="flex items-center gap-2 text-zinc-600">
              <MapPin className="w-4 h-4" />
              <span>{show.location}</span>
            </div>
          </div>

          {/* Waitlist Option */}
          <div className="space-y-3">
            <button className="w-full px-6 py-3 bg-zinc-800 text-white rounded-lg font-medium hover:bg-zinc-700 transition-colors">
              {t.waitlist}
            </button>
            <p className="text-xs text-zinc-500">{t.waitlistInfo}</p>
          </div>

          {/* Back Home */}
          <button
            onClick={() => navigate('/home')}
            className="w-full px-6 py-3 border border-zinc-300 text-zinc-700 rounded-lg font-medium hover:bg-zinc-50 transition-colors"
          >
            {t.backHome}
          </button>
        </div>
      </div>
    </div>
  );
}

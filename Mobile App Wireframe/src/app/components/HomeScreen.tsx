import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Language } from '@/app/App';
import { Search, MapPin, Filter, Calendar, Clock, Users } from 'lucide-react';

interface Props {
  language: Language;
}

const translations = {
  fr: {
    title: 'Émissions à venir',
    search: 'Rechercher...',
    city: 'Ville',
    category: 'Catégorie',
    channel: 'Chaîne',
    date: 'Date',
    seatsLeft: 'places restantes',
    viewDetails: 'Voir détails',
    noShows: 'Aucune émission disponible',
    loading: 'Chargement...',
    retry: 'Réessayer',
    error: 'Erreur de chargement',
  },
  ar: {
    title: 'البرامج القادمة',
    search: 'بحث...',
    city: 'المدينة',
    category: 'الفئة',
    channel: 'القناة',
    date: 'التاريخ',
    seatsLeft: 'مقعد متبقي',
    viewDetails: 'عرض التفاصيل',
    noShows: 'لا توجد برامج متاحة',
    loading: 'جاري التحميل...',
    retry: 'حاول مرة أخرى',
    error: 'خطأ في التحميل',
  },
};

const mockShows = [
  {
    id: '1',
    title: 'Talk Show Maghribi',
    channel: '2M',
    date: '15 Feb 2026',
    time: '20:00',
    location: 'Studio 2M - Casablanca',
    seatsLeft: 45,
  },
  {
    id: '2',
    title: 'Débat Politique',
    channel: 'Al Aoula',
    date: '18 Feb 2026',
    time: '21:30',
    location: 'Studio Al Aoula - Rabat',
    seatsLeft: 12,
  },
  {
    id: '3',
    title: 'Show Musical',
    channel: '2M',
    date: '20 Feb 2026',
    time: '19:00',
    location: 'Studio 2M - Casablanca',
    seatsLeft: 78,
  },
];

export function HomeScreen({ language }: Props) {
  const navigate = useNavigate();
  const t = translations[language];
  const [view, setView] = useState<'normal' | 'loading' | 'empty' | 'error'>('normal');

  const renderContent = () => {
    if (view === 'loading') {
      return (
        <div className="flex-1 flex items-center justify-center">
          <div className="text-center">
            <div className="w-12 h-12 border-4 border-zinc-300 border-t-zinc-800 rounded-full animate-spin mx-auto mb-4"></div>
            <p className="text-zinc-600">{t.loading}</p>
          </div>
        </div>
      );
    }

    if (view === 'empty') {
      return (
        <div className="flex-1 flex items-center justify-center p-6">
          <div className="text-center">
            <div className="w-20 h-20 bg-zinc-100 rounded-full flex items-center justify-center mx-auto mb-4">
              <Calendar className="w-10 h-10 text-zinc-400" />
            </div>
            <p className="text-zinc-800 font-medium mb-2">{t.noShows}</p>
            <p className="text-sm text-zinc-500">Revenez plus tard</p>
          </div>
        </div>
      );
    }

    if (view === 'error') {
      return (
        <div className="flex-1 flex items-center justify-center p-6">
          <div className="text-center">
            <div className="w-20 h-20 bg-red-50 rounded-full flex items-center justify-center mx-auto mb-4">
              <span className="text-3xl">⚠</span>
            </div>
            <p className="text-zinc-800 font-medium mb-2">{t.error}</p>
            <button
              onClick={() => setView('normal')}
              className="mt-4 px-6 py-2 bg-zinc-800 text-white rounded-lg text-sm"
            >
              {t.retry}
            </button>
          </div>
        </div>
      );
    }

    return (
      <>
        {/* Show List */}
        <div className="p-4 space-y-4">
          {mockShows.map((show) => (
            <div
              key={show.id}
              className="border border-zinc-200 rounded-lg p-4 space-y-3"
            >
              {/* Show Header */}
              <div className="flex items-start justify-between">
                <div className="flex-1">
                  <h3 className="font-semibold text-zinc-800">{show.title}</h3>
                  <span className="inline-block mt-1 px-2 py-0.5 bg-zinc-100 text-zinc-700 text-xs rounded">
                    {show.channel}
                  </span>
                </div>
              </div>

              {/* Show Info */}
              <div className="space-y-2 text-sm text-zinc-600">
                <div className="flex items-center gap-2">
                  <Calendar className="w-4 h-4" />
                  <span>{show.date}</span>
                  <Clock className="w-4 h-4 ml-2" />
                  <span>{show.time}</span>
                </div>
                <div className="flex items-center gap-2">
                  <MapPin className="w-4 h-4" />
                  <span>{show.location}</span>
                </div>
                <div className="flex items-center gap-2">
                  <Users className="w-4 h-4" />
                  <span className="font-medium text-zinc-800">{show.seatsLeft} {t.seatsLeft}</span>
                </div>
              </div>

              {/* CTA */}
              <button
                onClick={() => navigate(`/show/${show.id}`)}
                className="w-full px-4 py-2 bg-zinc-800 text-white rounded-lg text-sm font-medium hover:bg-zinc-700 transition-colors"
              >
                {t.viewDetails}
              </button>
            </div>
          ))}
        </div>
      </>
    );
  };

  return (
    <div className="h-full flex flex-col bg-white">
      {/* Header */}
      <div className="px-4 py-4 border-b border-zinc-200 space-y-4">
        <div className="flex items-center justify-between">
          <h1 className="text-xl font-bold text-zinc-800">{t.title}</h1>
          <button className="flex items-center gap-2 px-3 py-1.5 border border-zinc-300 rounded-lg text-sm">
            <MapPin className="w-4 h-4" />
            <span>Casablanca</span>
          </button>
        </div>

        {/* Search */}
        <div className="relative">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-zinc-400" />
          <input
            type="text"
            placeholder={t.search}
            className="w-full pl-10 pr-4 py-2.5 border border-zinc-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-zinc-400"
          />
        </div>

        {/* Filters */}
        <div className="flex gap-2 overflow-x-auto pb-1">
          <button className="flex items-center gap-1.5 px-3 py-1.5 border border-zinc-300 rounded-full text-sm whitespace-nowrap">
            <Filter className="w-4 h-4" />
            {t.category}
          </button>
          <button className="px-3 py-1.5 border border-zinc-300 rounded-full text-sm whitespace-nowrap">
            2M
          </button>
          <button className="px-3 py-1.5 border border-zinc-300 rounded-full text-sm whitespace-nowrap">
            Al Aoula
          </button>
          <button className="px-3 py-1.5 border border-zinc-300 rounded-full text-sm whitespace-nowrap">
            {t.date}
          </button>
        </div>
      </div>

      {/* View Toggle (for demo) */}
      <div className="px-4 py-2 bg-zinc-50 border-b border-zinc-200 flex gap-2 overflow-x-auto">
        <button
          onClick={() => setView('normal')}
          className={`px-3 py-1 rounded text-xs ${view === 'normal' ? 'bg-zinc-800 text-white' : 'bg-white text-zinc-600'}`}
        >
          Normal
        </button>
        <button
          onClick={() => setView('loading')}
          className={`px-3 py-1 rounded text-xs ${view === 'loading' ? 'bg-zinc-800 text-white' : 'bg-white text-zinc-600'}`}
        >
          Loading
        </button>
        <button
          onClick={() => setView('empty')}
          className={`px-3 py-1 rounded text-xs ${view === 'empty' ? 'bg-zinc-800 text-white' : 'bg-white text-zinc-600'}`}
        >
          Empty
        </button>
        <button
          onClick={() => setView('error')}
          className={`px-3 py-1 rounded text-xs ${view === 'error' ? 'bg-zinc-800 text-white' : 'bg-white text-zinc-600'}`}
        >
          Error
        </button>
      </div>

      {/* Content */}
      {renderContent()}
    </div>
  );
}

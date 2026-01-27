import { useNavigate, useParams } from 'react-router-dom';
import { Language } from '@/app/App';
import { ChevronLeft, ChevronRight, Calendar, Clock, MapPin, Users, Share2, AlertCircle } from 'lucide-react';

interface Props {
  language: Language;
}

const translations = {
  fr: {
    reserve: 'Réserver une place',
    share: 'Partager',
    details: 'Détails',
    rules: 'Règles du studio',
    seatsLeft: 'places restantes',
    age: 'Âge minimum : 18 ans',
    dress: 'Code vestimentaire : Tenue correcte',
    noPhotos: 'Interdiction de photographier pendant l\'enregistrement',
    location: 'Lieu',
    mapPreview: 'Aperçu carte',
  },
  ar: {
    reserve: 'احجز مقعدًا',
    share: 'مشاركة',
    details: 'التفاصيل',
    rules: 'قواعد الاستوديو',
    seatsLeft: 'مقعد متبقي',
    age: 'الحد الأدنى للسن: 18 سنة',
    dress: 'قواعد اللباس: ملابس لائقة',
    noPhotos: 'ممنوع التصوير أثناء التسجيل',
    location: 'الموقع',
    mapPreview: 'معاينة الخريطة',
  },
};

export function ShowDetail({ language }: Props) {
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
    address: '123 Boulevard Zerktouni, Casablanca',
    seatsLeft: 45,
    description: 'Une émission de débat avec des personnalités marocaines influentes.',
  };

  return (
    <div className="h-full flex flex-col bg-white">
      {/* Header */}
      <div className="px-4 py-4 border-b border-zinc-200 flex items-center justify-between">
        <button onClick={() => navigate(-1)} className="p-2 -ml-2">
          <BackIcon className="w-6 h-6 text-zinc-800" />
        </button>
        <button className="p-2 -mr-2">
          <Share2 className="w-5 h-5 text-zinc-800" />
        </button>
      </div>

      {/* Content */}
      <div className="flex-1 overflow-y-auto">
        {/* Hero Image */}
        <div className="w-full h-48 bg-zinc-200 flex items-center justify-center">
          <div className="text-zinc-500 font-mono text-sm">SHOW IMAGE</div>
        </div>

        <div className="p-4 space-y-6">
          {/* Title & Channel */}
          <div>
            <h1 className="text-2xl font-bold text-zinc-800 mb-2">{show.title}</h1>
            <span className="inline-block px-3 py-1 bg-zinc-100 text-zinc-700 text-sm rounded-full">
              {show.channel}
            </span>
          </div>

          {/* Details */}
          <div className="space-y-3 text-sm">
            <div className="flex items-center gap-3 text-zinc-700">
              <Calendar className="w-5 h-5" />
              <span>{show.date}</span>
              <Clock className="w-5 h-5 ml-2" />
              <span>{show.time}</span>
            </div>
            <div className="flex items-start gap-3 text-zinc-700">
              <MapPin className="w-5 h-5 mt-0.5" />
              <div>
                <div className="font-medium">{show.location}</div>
                <div className="text-zinc-500">{show.address}</div>
              </div>
            </div>
            <div className="flex items-center gap-3">
              <Users className="w-5 h-5 text-zinc-700" />
              <span className="font-semibold text-zinc-800">{show.seatsLeft} {t.seatsLeft}</span>
            </div>
          </div>

          {/* Map Preview */}
          <div className="space-y-2">
            <h3 className="font-semibold text-zinc-800">{t.location}</h3>
            <div className="w-full h-40 bg-zinc-100 rounded-lg flex items-center justify-center border border-zinc-200">
              <div className="text-zinc-400 font-mono text-xs">{t.mapPreview}</div>
            </div>
          </div>

          {/* Description */}
          <div className="space-y-2">
            <h3 className="font-semibold text-zinc-800">{t.details}</h3>
            <p className="text-zinc-600 text-sm leading-relaxed">{show.description}</p>
          </div>

          {/* Rules */}
          <div className="space-y-3">
            <h3 className="font-semibold text-zinc-800">{t.rules}</h3>
            <div className="space-y-2">
              <div className="flex items-start gap-2 text-sm text-zinc-600">
                <AlertCircle className="w-4 h-4 mt-0.5 flex-shrink-0" />
                <span>{t.age}</span>
              </div>
              <div className="flex items-start gap-2 text-sm text-zinc-600">
                <AlertCircle className="w-4 h-4 mt-0.5 flex-shrink-0" />
                <span>{t.dress}</span>
              </div>
              <div className="flex items-start gap-2 text-sm text-zinc-600">
                <AlertCircle className="w-4 h-4 mt-0.5 flex-shrink-0" />
                <span>{t.noPhotos}</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Bottom CTA */}
      <div className="p-4 border-t border-zinc-200 bg-white">
        <button
          onClick={() => navigate(`/reserve/${show.id}`)}
          className="w-full px-6 py-3 bg-zinc-800 text-white rounded-lg font-medium hover:bg-zinc-700 transition-colors"
        >
          {t.reserve}
        </button>
      </div>
    </div>
  );
}

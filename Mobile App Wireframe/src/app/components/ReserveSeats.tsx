import { useState } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { Language } from '@/app/App';
import { ChevronLeft, ChevronRight, Minus, Plus, Check } from 'lucide-react';

interface Props {
  language: Language;
}

const translations = {
  fr: {
    title: 'Réserver des places',
    showSummary: 'Résumé de l\'émission',
    seats: 'Nombre de places',
    userInfo: 'Informations de contact',
    name: 'Nom complet',
    phone: 'Téléphone',
    accept: 'J\'accepte les règles du studio',
    confirm: 'Confirmer la demande',
    max: 'Maximum 4 places',
  },
  ar: {
    title: 'حجز المقاعد',
    showSummary: 'ملخص البرنامج',
    seats: 'عدد المقاعد',
    userInfo: 'معلومات الاتصال',
    name: 'الاسم الكامل',
    phone: 'الهاتف',
    accept: 'أوافق على قواعد الاستوديو',
    confirm: 'تأكيد الطلب',
    max: 'حد أقصى 4 مقاعد',
  },
};

export function ReserveSeats({ language }: Props) {
  const navigate = useNavigate();
  const { id } = useParams();
  const t = translations[language];
  const BackIcon = language === 'ar' ? ChevronRight : ChevronLeft;

  const [seats, setSeats] = useState(1);
  const [name, setName] = useState('');
  const [phone, setPhone] = useState('');
  const [accepted, setAccepted] = useState(false);

  const show = {
    title: 'Talk Show Maghribi',
    channel: '2M',
    date: '15 Feb 2026',
    time: '20:00',
    location: 'Studio 2M - Casablanca',
  };

  const handleConfirm = () => {
    if (name && phone && accepted) {
      navigate('/reservation-success');
    }
  };

  return (
    <div className="h-full flex flex-col bg-white">
      {/* Header */}
      <div className="px-4 py-4 border-b border-zinc-200">
        <button onClick={() => navigate(-1)} className="p-2 -ml-2">
          <BackIcon className="w-6 h-6 text-zinc-800" />
        </button>
        <h1 className="text-xl font-bold text-zinc-800 mt-2">{t.title}</h1>
      </div>

      {/* Content */}
      <div className="flex-1 overflow-y-auto p-4 space-y-6">
        {/* Show Summary */}
        <div className="p-4 bg-zinc-50 rounded-lg border border-zinc-200">
          <h3 className="font-semibold text-zinc-800 mb-3 text-sm">{t.showSummary}</h3>
          <div className="space-y-1 text-sm text-zinc-600">
            <div className="font-medium text-zinc-800">{show.title}</div>
            <div>{show.channel}</div>
            <div>{show.date} • {show.time}</div>
            <div>{show.location}</div>
          </div>
        </div>

        {/* Seats Selector */}
        <div className="space-y-3">
          <div className="flex items-center justify-between">
            <div>
              <label className="block font-semibold text-zinc-800">{t.seats}</label>
              <p className="text-xs text-zinc-500 mt-1">{t.max}</p>
            </div>
            <div className="flex items-center gap-3">
              <button
                onClick={() => setSeats(Math.max(1, seats - 1))}
                className="w-10 h-10 rounded-full border border-zinc-300 flex items-center justify-center hover:bg-zinc-50"
                disabled={seats <= 1}
              >
                <Minus className="w-5 h-5 text-zinc-600" />
              </button>
              <div className="w-12 text-center font-bold text-lg text-zinc-800">{seats}</div>
              <button
                onClick={() => setSeats(Math.min(4, seats + 1))}
                className="w-10 h-10 rounded-full border border-zinc-300 flex items-center justify-center hover:bg-zinc-50"
                disabled={seats >= 4}
              >
                <Plus className="w-5 h-5 text-zinc-600" />
              </button>
            </div>
          </div>
        </div>

        {/* User Info */}
        <div className="space-y-4">
          <h3 className="font-semibold text-zinc-800">{t.userInfo}</h3>
          
          <div>
            <label className="block text-sm font-medium text-zinc-700 mb-2">
              {t.name}
            </label>
            <input
              type="text"
              value={name}
              onChange={(e) => setName(e.target.value)}
              className="w-full px-4 py-3 border border-zinc-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-zinc-400"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-zinc-700 mb-2">
              {t.phone}
            </label>
            <input
              type="tel"
              value={phone}
              onChange={(e) => setPhone(e.target.value)}
              placeholder="06XXXXXXXX"
              className="w-full px-4 py-3 border border-zinc-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-zinc-400"
            />
          </div>
        </div>

        {/* Accept Rules */}
        <label className="flex items-start gap-3 cursor-pointer">
          <div className="mt-0.5">
            <div
              onClick={() => setAccepted(!accepted)}
              className={`w-5 h-5 rounded border-2 flex items-center justify-center transition-colors ${
                accepted ? 'bg-zinc-800 border-zinc-800' : 'border-zinc-300'
              }`}
            >
              {accepted && <Check className="w-3.5 h-3.5 text-white" />}
            </div>
          </div>
          <span className="text-sm text-zinc-700">{t.accept}</span>
        </label>
      </div>

      {/* Bottom CTA */}
      <div className="p-4 border-t border-zinc-200 bg-white">
        <button
          onClick={handleConfirm}
          disabled={!name || !phone || !accepted}
          className="w-full px-6 py-3 bg-zinc-800 text-white rounded-lg font-medium hover:bg-zinc-700 transition-colors disabled:bg-zinc-300 disabled:cursor-not-allowed"
        >
          {t.confirm}
        </button>
      </div>
    </div>
  );
}

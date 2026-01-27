import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Language } from '@/app/App';
import { Calendar, Clock, MapPin } from 'lucide-react';

interface Props {
  language: Language;
}

const translations = {
  fr: {
    title: 'Mes réservations',
    pending: 'En attente',
    approved: 'Approuvées',
    past: 'Passées',
    noReservations: 'Aucune réservation',
    viewDetails: 'Voir détails',
  },
  ar: {
    title: 'حجوزاتي',
    pending: 'قيد الانتظار',
    approved: 'مؤكدة',
    past: 'سابقة',
    noReservations: 'لا توجد حجوزات',
    viewDetails: 'عرض التفاصيل',
  },
};

const statusColors = {
  pending: 'bg-amber-50 text-amber-700 border-amber-200',
  contacting: 'bg-blue-50 text-blue-700 border-blue-200',
  approved: 'bg-green-50 text-green-700 border-green-200',
  rejected: 'bg-red-50 text-red-700 border-red-200',
  expired: 'bg-zinc-100 text-zinc-600 border-zinc-200',
  cancelled: 'bg-zinc-100 text-zinc-600 border-zinc-200',
  checkedIn: 'bg-purple-50 text-purple-700 border-purple-200',
};

const statusLabels = {
  fr: {
    pending: 'En cours de vérification',
    contacting: 'Nous vous appelons',
    approved: 'Approuvée',
    rejected: 'Refusée',
    expired: 'Expirée',
    cancelled: 'Annulée',
    checkedIn: 'Présent',
  },
  ar: {
    pending: 'قيد المراجعة',
    contacting: 'نتصل بك',
    approved: 'مؤكدة',
    rejected: 'مرفوضة',
    expired: 'منتهية',
    cancelled: 'ملغاة',
    checkedIn: 'حضور',
  },
};

const mockReservations = {
  pending: [
    {
      id: 'r1',
      showTitle: 'Talk Show Maghribi',
      channel: '2M',
      date: '15 Feb 2026',
      time: '20:00',
      location: 'Studio 2M - Casablanca',
      seats: 2,
      status: 'pending' as const,
    },
    {
      id: 'r2',
      showTitle: 'Débat Politique',
      channel: 'Al Aoula',
      date: '18 Feb 2026',
      time: '21:30',
      location: 'Studio Al Aoula - Rabat',
      seats: 1,
      status: 'contacting' as const,
    },
  ],
  approved: [
    {
      id: 'r3',
      showTitle: 'Show Musical',
      channel: '2M',
      date: '20 Feb 2026',
      time: '19:00',
      location: 'Studio 2M - Casablanca',
      seats: 3,
      status: 'approved' as const,
    },
  ],
  past: [
    {
      id: 'r4',
      showTitle: 'Comedy Night',
      channel: '2M',
      date: '10 Jan 2026',
      time: '20:00',
      location: 'Studio 2M - Casablanca',
      seats: 2,
      status: 'checkedIn' as const,
    },
    {
      id: 'r5',
      showTitle: 'Cultural Show',
      channel: 'Al Aoula',
      date: '5 Jan 2026',
      time: '21:00',
      location: 'Studio Al Aoula - Rabat',
      seats: 1,
      status: 'cancelled' as const,
    },
  ],
};

export function MyReservations({ language }: Props) {
  const navigate = useNavigate();
  const t = translations[language];
  const labels = statusLabels[language];
  const [activeTab, setActiveTab] = useState<'pending' | 'approved' | 'past'>('pending');

  const renderReservationCard = (reservation: typeof mockReservations.pending[0]) => (
    <div
      key={reservation.id}
      className="border border-zinc-200 rounded-lg p-4 space-y-3"
    >
      {/* Title & Status */}
      <div className="flex items-start justify-between gap-3">
        <div className="flex-1">
          <h3 className="font-semibold text-zinc-800">{reservation.showTitle}</h3>
          <span className="inline-block mt-1 px-2 py-0.5 bg-zinc-100 text-zinc-700 text-xs rounded">
            {reservation.channel}
          </span>
        </div>
        <span className={`px-2 py-1 text-xs rounded border ${statusColors[reservation.status]}`}>
          {labels[reservation.status]}
        </span>
      </div>

      {/* Info */}
      <div className="space-y-2 text-sm text-zinc-600">
        <div className="flex items-center gap-2">
          <Calendar className="w-4 h-4" />
          <span>{reservation.date}</span>
          <Clock className="w-4 h-4 ml-2" />
          <span>{reservation.time}</span>
        </div>
        <div className="flex items-center gap-2">
          <MapPin className="w-4 h-4" />
          <span>{reservation.location}</span>
        </div>
        <div className="text-zinc-800 font-medium">
          {reservation.seats} {language === 'fr' ? 'place(s)' : 'مقعد'}
        </div>
      </div>

      {/* CTA */}
      <button
        onClick={() => navigate(`/reservation/${reservation.id}`)}
        className="w-full px-4 py-2 border border-zinc-300 text-zinc-700 rounded-lg text-sm font-medium hover:bg-zinc-50 transition-colors"
      >
        {t.viewDetails}
      </button>
    </div>
  );

  const currentReservations = mockReservations[activeTab];

  return (
    <div className="h-full flex flex-col bg-white">
      {/* Header */}
      <div className="px-4 py-4 border-b border-zinc-200">
        <h1 className="text-xl font-bold text-zinc-800">{t.title}</h1>
      </div>

      {/* Tabs */}
      <div className="border-b border-zinc-200">
        <div className="flex">
          <button
            onClick={() => setActiveTab('pending')}
            className={`flex-1 px-4 py-3 text-sm font-medium border-b-2 transition-colors ${
              activeTab === 'pending'
                ? 'border-zinc-800 text-zinc-800'
                : 'border-transparent text-zinc-500 hover:text-zinc-700'
            }`}
          >
            {t.pending}
          </button>
          <button
            onClick={() => setActiveTab('approved')}
            className={`flex-1 px-4 py-3 text-sm font-medium border-b-2 transition-colors ${
              activeTab === 'approved'
                ? 'border-zinc-800 text-zinc-800'
                : 'border-transparent text-zinc-500 hover:text-zinc-700'
            }`}
          >
            {t.approved}
          </button>
          <button
            onClick={() => setActiveTab('past')}
            className={`flex-1 px-4 py-3 text-sm font-medium border-b-2 transition-colors ${
              activeTab === 'past'
                ? 'border-zinc-800 text-zinc-800'
                : 'border-transparent text-zinc-500 hover:text-zinc-700'
            }`}
          >
            {t.past}
          </button>
        </div>
      </div>

      {/* Content */}
      <div className="flex-1 overflow-y-auto">
        {currentReservations.length > 0 ? (
          <div className="p-4 space-y-4">
            {currentReservations.map(renderReservationCard)}
          </div>
        ) : (
          <div className="flex-1 flex items-center justify-center p-6">
            <div className="text-center">
              <div className="w-16 h-16 bg-zinc-100 rounded-full flex items-center justify-center mx-auto mb-4">
                <Calendar className="w-8 h-8 text-zinc-400" />
              </div>
              <p className="text-zinc-600">{t.noReservations}</p>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}

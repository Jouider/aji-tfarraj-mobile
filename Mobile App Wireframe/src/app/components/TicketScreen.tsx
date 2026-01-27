import { useState } from 'react';
import { Language } from '@/app/App';
import { Calendar, Clock, MapPin, Download, Navigation } from 'lucide-react';

interface Props {
  language: Language;
}

const translations = {
  fr: {
    title: 'Mon billet',
    noTicket: 'Aucun billet disponible',
    noTicketMessage: 'Les billets apparaissent après l\'approbation de votre réservation',
    ticketNumber: 'N° de billet',
    offlineAvailable: 'Disponible hors ligne',
    rules: 'Rappel des règles',
    rule1: 'Arrivez 30 minutes avant',
    rule2: 'Présentez ce QR code à l\'entrée',
    rule3: 'Pas de photos pendant l\'enregistrement',
    addToCalendar: 'Ajouter au calendrier',
    directions: 'Itinéraire',
    seats: 'places',
  },
  ar: {
    title: 'تذكرتي',
    noTicket: 'لا توجد تذكرة متاحة',
    noTicketMessage: 'تظهر التذاكر بعد الموافقة على حجزك',
    ticketNumber: 'رقم التذكرة',
    offlineAvailable: 'متاح دون اتصال',
    rules: 'تذكير بالقواعد',
    rule1: 'احضر قبل 30 دقيقة',
    rule2: 'اعرض رمز QR هذا عند المدخل',
    rule3: 'ممنوع التصوير أثناء التسجيل',
    addToCalendar: 'أضف إلى التقويم',
    directions: 'الاتجاهات',
    seats: 'مقاعد',
  },
};

export function TicketScreen({ language }: Props) {
  const t = translations[language];
  // Change this to 'locked' to see the locked state
  const [ticketState] = useState<'locked' | 'generated'>('generated');

  if (ticketState === 'locked') {
    return (
      <div className="h-full flex flex-col items-center justify-center bg-white p-6">
        <div className="w-full max-w-sm text-center space-y-6">
          {/* Locked Icon */}
          <div className="w-20 h-20 mx-auto bg-zinc-100 rounded-full flex items-center justify-center">
            <div className="w-10 h-10 border-4 border-zinc-400 rounded border-t-transparent"></div>
          </div>

          {/* Message */}
          <div className="space-y-2">
            <h2 className="text-xl font-semibold text-zinc-800">{t.noTicket}</h2>
            <p className="text-zinc-600 text-sm">{t.noTicketMessage}</p>
          </div>
        </div>
      </div>
    );
  }

  const ticket = {
    number: 'AJT-2026-0123',
    showTitle: 'Talk Show Maghribi',
    channel: '2M',
    date: '15 Feb 2026',
    time: '20:00',
    location: 'Studio 2M - Casablanca',
    address: '123 Boulevard Zerktouni, Casablanca',
    seats: 2,
  };

  return (
    <div className="h-full flex flex-col bg-zinc-50">
      {/* Header */}
      <div className="px-4 py-4 border-b border-zinc-200 bg-white">
        <h1 className="text-xl font-bold text-zinc-800">{t.title}</h1>
      </div>

      {/* Content */}
      <div className="flex-1 overflow-y-auto p-4 space-y-4">
        {/* Ticket Card */}
        <div className="bg-white rounded-lg overflow-hidden border border-zinc-200">
          {/* QR Code Section */}
          <div className="p-8 bg-gradient-to-br from-zinc-50 to-white border-b-4 border-dashed border-zinc-200">
            <div className="w-48 h-48 mx-auto bg-white border-4 border-zinc-800 rounded-lg flex items-center justify-center">
              <div className="text-center">
                <div className="grid grid-cols-8 gap-1 p-4">
                  {Array.from({ length: 64 }).map((_, i) => (
                    <div
                      key={i}
                      className={`w-2 h-2 ${Math.random() > 0.5 ? 'bg-zinc-800' : 'bg-white'}`}
                    />
                  ))}
                </div>
              </div>
            </div>
            
            {/* Ticket Number */}
            <div className="text-center mt-4">
              <div className="text-xs text-zinc-500 mb-1">{t.ticketNumber}</div>
              <div className="font-mono font-bold text-zinc-800">{ticket.number}</div>
            </div>

            {/* Offline Badge */}
            <div className="flex items-center justify-center gap-2 mt-4">
              <div className="w-2 h-2 bg-green-500 rounded-full"></div>
              <span className="text-xs text-green-700">{t.offlineAvailable}</span>
            </div>
          </div>

          {/* Show Details */}
          <div className="p-4 space-y-3">
            <div>
              <div className="text-lg font-bold text-zinc-800">{ticket.showTitle}</div>
              <span className="inline-block mt-1 px-2 py-0.5 bg-zinc-100 text-zinc-700 text-xs rounded">
                {ticket.channel}
              </span>
            </div>

            <div className="space-y-2 text-sm text-zinc-600">
              <div className="flex items-center gap-2">
                <Calendar className="w-4 h-4" />
                <span>{ticket.date}</span>
                <Clock className="w-4 h-4 ml-2" />
                <span>{ticket.time}</span>
              </div>
              <div className="flex items-start gap-2">
                <MapPin className="w-4 h-4 mt-0.5" />
                <div>
                  <div className="font-medium text-zinc-800">{ticket.location}</div>
                  <div className="text-zinc-500">{ticket.address}</div>
                </div>
              </div>
              <div className="font-medium text-zinc-800">
                {ticket.seats} {t.seats}
              </div>
            </div>
          </div>
        </div>

        {/* Rules Reminder */}
        <div className="bg-white rounded-lg p-4 border border-zinc-200 space-y-3">
          <h3 className="font-semibold text-zinc-800">{t.rules}</h3>
          <ul className="space-y-2 text-sm text-zinc-600">
            <li className="flex items-start gap-2">
              <span className="text-zinc-400">•</span>
              <span>{t.rule1}</span>
            </li>
            <li className="flex items-start gap-2">
              <span className="text-zinc-400">•</span>
              <span>{t.rule2}</span>
            </li>
            <li className="flex items-start gap-2">
              <span className="text-zinc-400">•</span>
              <span>{t.rule3}</span>
            </li>
          </ul>
        </div>

        {/* Action Buttons */}
        <div className="space-y-3">
          <button className="w-full px-6 py-3 bg-white border border-zinc-300 text-zinc-700 rounded-lg font-medium hover:bg-zinc-50 transition-colors flex items-center justify-center gap-2">
            <Calendar className="w-5 h-5" />
            {t.addToCalendar}
          </button>
          <button className="w-full px-6 py-3 bg-white border border-zinc-300 text-zinc-700 rounded-lg font-medium hover:bg-zinc-50 transition-colors flex items-center justify-center gap-2">
            <Navigation className="w-5 h-5" />
            {t.directions}
          </button>
        </div>
      </div>
    </div>
  );
}

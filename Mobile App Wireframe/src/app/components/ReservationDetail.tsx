import { useState } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { Language } from '@/app/App';
import { ChevronLeft, ChevronRight, Calendar, Clock, MapPin, AlertCircle, Users } from 'lucide-react';

interface Props {
  language: Language;
}

const translations = {
  fr: {
    title: 'Détails de la réservation',
    showInfo: 'Informations sur l\'émission',
    status: 'Statut',
    seats: 'places',
    pendingMessage: 'Notre équipe examinera votre demande et vous contactera par téléphone.',
    contactingMessage: 'Nous essayons de vous joindre. Veuillez répondre à nos appels.',
    approvedMessage: 'Votre réservation est confirmée ! Vous pouvez maintenant générer votre billet.',
    rejectedMessage: 'Raison du refus',
    rejectedReason: 'Émission complète',
    expiredMessage: 'Cette réservation a expiré.',
    cancelledMessage: 'Vous avez annulé cette réservation.',
    generateTicket: 'Générer le billet',
    cancel: 'Annuler la réservation',
    requestAgain: 'Demander à nouveau',
    confirmCancel: 'Êtes-vous sûr de vouloir annuler ?',
    yes: 'Oui, annuler',
    no: 'Non, garder',
  },
  ar: {
    title: 'تفاصيل الحجز',
    showInfo: 'معلومات البرنامج',
    status: 'الحالة',
    seats: 'مقاعد',
    pendingMessage: 'سيقوم فريقنا بمراجعة طلبك والاتصال بك عبر الهاتف.',
    contactingMessage: 'نحاول الوصول إليك. يرجى الرد على مكالماتنا.',
    approvedMessage: 'تم تأكيد حجزك! يمكنك الآن إنشاء تذكرتك.',
    rejectedMessage: 'سبب الرفض',
    rejectedReason: 'البرنامج ممتلئ',
    expiredMessage: 'انتهت صلاحية هذا الحجز.',
    cancelledMessage: 'لقد ألغيت هذا الحجز.',
    generateTicket: 'إنشاء التذكرة',
    cancel: 'إلغاء الحجز',
    requestAgain: 'طلب مرة أخرى',
    confirmCancel: 'هل أنت متأكد من الإلغاء؟',
    yes: 'نعم، إلغاء',
    no: 'لا، احتفظ',
  },
};

const statusColors = {
  pending: 'bg-amber-50 text-amber-700 border-amber-200',
  contacting: 'bg-blue-50 text-blue-700 border-blue-200',
  approved: 'bg-green-50 text-green-700 border-green-200',
  rejected: 'bg-red-50 text-red-700 border-red-200',
  expired: 'bg-zinc-100 text-zinc-600 border-zinc-200',
  cancelled: 'bg-zinc-100 text-zinc-600 border-zinc-200',
};

const statusLabels = {
  fr: {
    pending: 'En cours de vérification',
    contacting: 'Nous vous appelons',
    approved: 'Approuvée',
    rejected: 'Refusée',
    expired: 'Expirée',
    cancelled: 'Annulée',
  },
  ar: {
    pending: 'قيد المراجعة',
    contacting: 'نتصل بك',
    approved: 'مؤكدة',
    rejected: 'مرفوضة',
    expired: 'منتهية',
    cancelled: 'ملغاة',
  },
};

export function ReservationDetail({ language }: Props) {
  const navigate = useNavigate();
  const { id } = useParams();
  const t = translations[language];
  const labels = statusLabels[language];
  const BackIcon = language === 'ar' ? ChevronRight : ChevronLeft;
  const [showCancelDialog, setShowCancelDialog] = useState(false);

  // Mock different states - change this to demo different statuses
  const [reservation] = useState({
    id: id || 'r1',
    showTitle: 'Talk Show Maghribi',
    channel: '2M',
    date: '15 Feb 2026',
    time: '20:00',
    location: 'Studio 2M - Casablanca',
    address: '123 Boulevard Zerktouni, Casablanca',
    seats: 2,
    status: 'approved' as const, // Change to 'pending', 'contacting', 'rejected', 'expired', 'cancelled'
    requestedAt: '27 Jan 2026',
  });

  const handleGenerateTicket = () => {
    navigate('/ticket');
  };

  const handleCancel = () => {
    setShowCancelDialog(false);
    navigate('/my-reservations');
  };

  const handleRequestAgain = () => {
    navigate(`/reserve/${reservation.id}`);
  };

  const renderStatusMessage = () => {
    switch (reservation.status) {
      case 'pending':
        return (
          <div className="flex items-start gap-3 p-4 bg-amber-50 rounded-lg border border-amber-200">
            <AlertCircle className="w-5 h-5 text-amber-700 flex-shrink-0 mt-0.5" />
            <p className="text-sm text-amber-800">{t.pendingMessage}</p>
          </div>
        );
      case 'contacting':
        return (
          <div className="flex items-start gap-3 p-4 bg-blue-50 rounded-lg border border-blue-200">
            <AlertCircle className="w-5 h-5 text-blue-700 flex-shrink-0 mt-0.5" />
            <p className="text-sm text-blue-800">{t.contactingMessage}</p>
          </div>
        );
      case 'approved':
        return (
          <div className="flex items-start gap-3 p-4 bg-green-50 rounded-lg border border-green-200">
            <AlertCircle className="w-5 h-5 text-green-700 flex-shrink-0 mt-0.5" />
            <p className="text-sm text-green-800">{t.approvedMessage}</p>
          </div>
        );
      case 'rejected':
        return (
          <div className="p-4 bg-red-50 rounded-lg border border-red-200 space-y-2">
            <div className="flex items-start gap-3">
              <AlertCircle className="w-5 h-5 text-red-700 flex-shrink-0 mt-0.5" />
              <div className="text-sm text-red-800">
                <div className="font-medium">{t.rejectedMessage}</div>
                <div className="mt-1">{t.rejectedReason}</div>
              </div>
            </div>
          </div>
        );
      case 'expired':
        return (
          <div className="flex items-start gap-3 p-4 bg-zinc-100 rounded-lg border border-zinc-200">
            <AlertCircle className="w-5 h-5 text-zinc-600 flex-shrink-0 mt-0.5" />
            <p className="text-sm text-zinc-700">{t.expiredMessage}</p>
          </div>
        );
      case 'cancelled':
        return (
          <div className="flex items-start gap-3 p-4 bg-zinc-100 rounded-lg border border-zinc-200">
            <AlertCircle className="w-5 h-5 text-zinc-600 flex-shrink-0 mt-0.5" />
            <p className="text-sm text-zinc-700">{t.cancelledMessage}</p>
          </div>
        );
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
        {/* Status */}
        <div className="space-y-3">
          <div className="flex items-center justify-between">
            <span className="text-sm font-medium text-zinc-700">{t.status}</span>
            <span className={`px-3 py-1 text-sm rounded border ${statusColors[reservation.status]}`}>
              {labels[reservation.status]}
            </span>
          </div>
          {renderStatusMessage()}
        </div>

        {/* Show Info */}
        <div className="space-y-3">
          <h3 className="font-semibold text-zinc-800">{t.showInfo}</h3>
          <div className="p-4 bg-zinc-50 rounded-lg border border-zinc-200 space-y-3">
            <div>
              <div className="font-semibold text-zinc-800">{reservation.showTitle}</div>
              <span className="inline-block mt-1 px-2 py-0.5 bg-white text-zinc-700 text-xs rounded border border-zinc-200">
                {reservation.channel}
              </span>
            </div>
            <div className="space-y-2 text-sm text-zinc-600">
              <div className="flex items-center gap-2">
                <Calendar className="w-4 h-4" />
                <span>{reservation.date}</span>
                <Clock className="w-4 h-4 ml-2" />
                <span>{reservation.time}</span>
              </div>
              <div className="flex items-start gap-2">
                <MapPin className="w-4 h-4 mt-0.5" />
                <div>
                  <div className="font-medium text-zinc-800">{reservation.location}</div>
                  <div className="text-zinc-500">{reservation.address}</div>
                </div>
              </div>
              <div className="flex items-center gap-2">
                <Users className="w-4 h-4" />
                <span className="font-medium text-zinc-800">{reservation.seats} {t.seats}</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Bottom Actions */}
      <div className="p-4 border-t border-zinc-200 bg-white space-y-3">
        {reservation.status === 'approved' && (
          <button
            onClick={handleGenerateTicket}
            className="w-full px-6 py-3 bg-zinc-800 text-white rounded-lg font-medium hover:bg-zinc-700 transition-colors"
          >
            {t.generateTicket}
          </button>
        )}

        {(reservation.status === 'pending' || reservation.status === 'contacting') && (
          <button
            onClick={() => setShowCancelDialog(true)}
            className="w-full px-6 py-3 border border-red-300 text-red-600 rounded-lg font-medium hover:bg-red-50 transition-colors"
          >
            {t.cancel}
          </button>
        )}

        {(reservation.status === 'expired' || reservation.status === 'cancelled') && (
          <button
            onClick={handleRequestAgain}
            className="w-full px-6 py-3 bg-zinc-800 text-white rounded-lg font-medium hover:bg-zinc-700 transition-colors"
          >
            {t.requestAgain}
          </button>
        )}
      </div>

      {/* Cancel Dialog */}
      {showCancelDialog && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-6 z-50">
          <div className="bg-white rounded-lg p-6 max-w-sm w-full space-y-4">
            <h3 className="font-semibold text-zinc-800">{t.confirmCancel}</h3>
            <div className="flex gap-3">
              <button
                onClick={handleCancel}
                className="flex-1 px-4 py-2 bg-red-600 text-white rounded-lg font-medium hover:bg-red-700"
              >
                {t.yes}
              </button>
              <button
                onClick={() => setShowCancelDialog(false)}
                className="flex-1 px-4 py-2 border border-zinc-300 text-zinc-700 rounded-lg font-medium hover:bg-zinc-50"
              >
                {t.no}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

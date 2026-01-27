import { useNavigate } from 'react-router-dom';
import { Language } from '@/app/App';
import { CheckCircle2 } from 'lucide-react';

interface Props {
  language: Language;
}

const translations = {
  fr: {
    title: 'Demande envoyée',
    message: 'Votre demande de réservation a été envoyée avec succès.',
    explanation: 'Notre équipe vous contactera par téléphone dans les prochaines heures pour confirmer votre réservation.',
    status: 'Statut actuel : En cours de vérification',
    viewReservations: 'Voir mes réservations',
    backHome: 'Retour à l\'accueil',
  },
  ar: {
    title: 'تم إرسال الطلب',
    message: 'تم إرسال طلب الحجز بنجاح.',
    explanation: 'سيتصل بك فريقنا عبر الهاتف خلال الساعات القادمة لتأكيد حجزك.',
    status: 'الحالة الحالية: قيد المراجعة',
    viewReservations: 'عرض حجوزاتي',
    backHome: 'العودة إلى الرئيسية',
  },
};

export function ReservationSuccess({ language }: Props) {
  const navigate = useNavigate();
  const t = translations[language];

  return (
    <div className="h-full flex flex-col items-center justify-center bg-white p-6">
      <div className="w-full max-w-sm text-center space-y-6">
        {/* Success Icon */}
        <div className="flex justify-center">
          <div className="w-20 h-20 rounded-full bg-green-50 flex items-center justify-center">
            <CheckCircle2 className="w-12 h-12 text-green-600" />
          </div>
        </div>

        {/* Message */}
        <div className="space-y-3">
          <h1 className="text-2xl font-bold text-zinc-800">{t.title}</h1>
          <p className="text-zinc-600">{t.message}</p>
          <p className="text-sm text-zinc-500 leading-relaxed">{t.explanation}</p>
        </div>

        {/* Status Badge */}
        <div className="inline-block px-4 py-2 bg-amber-50 border border-amber-200 rounded-lg">
          <p className="text-sm text-amber-800">{t.status}</p>
        </div>

        {/* Actions */}
        <div className="space-y-3 pt-4">
          <button
            onClick={() => navigate('/my-reservations')}
            className="w-full px-6 py-3 bg-zinc-800 text-white rounded-lg font-medium hover:bg-zinc-700 transition-colors"
          >
            {t.viewReservations}
          </button>
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

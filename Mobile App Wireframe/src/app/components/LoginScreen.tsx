import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Language } from '@/app/App';
import { ChevronLeft, ChevronRight } from 'lucide-react';

interface Props {
  language: Language;
}

const translations = {
  fr: {
    title: 'Connexion',
    phone: 'Numéro de téléphone',
    phonePlaceholder: '06XXXXXXXX',
    code: 'Code de vérification',
    codePlaceholder: 'XXXX',
    sendCode: 'Envoyer le code',
    verify: 'Vérifier',
    guest: 'Continuer en tant qu\'invité',
  },
  ar: {
    title: 'تسجيل الدخول',
    phone: 'رقم الهاتف',
    phonePlaceholder: '06XXXXXXXX',
    code: 'رمز التحقق',
    codePlaceholder: 'XXXX',
    sendCode: 'إرسال الرمز',
    verify: 'تحقق',
    guest: 'متابعة كضيف',
  },
};

export function LoginScreen({ language }: Props) {
  const navigate = useNavigate();
  const t = translations[language];
  const [step, setStep] = useState<'phone' | 'code'>('phone');
  const [phone, setPhone] = useState('');
  const [code, setCode] = useState('');

  const handleSendCode = () => {
    if (phone) {
      setStep('code');
    }
  };

  const handleVerify = () => {
    if (code) {
      navigate('/home');
    }
  };

  const handleGuest = () => {
    navigate('/home');
  };

  const BackIcon = language === 'ar' ? ChevronRight : ChevronLeft;

  return (
    <div className="h-screen flex flex-col bg-white">
      {/* Header */}
      <div className="px-4 py-4 border-b border-zinc-200">
        <button onClick={() => navigate(-1)} className="p-2 -ml-2">
          <BackIcon className="w-6 h-6 text-zinc-800" />
        </button>
      </div>

      {/* Content */}
      <div className="flex-1 p-6">
        <h1 className="text-2xl font-bold text-zinc-800 mb-8">{t.title}</h1>

        <div className="space-y-6">
          {/* Phone Input */}
          <div>
            <label className="block text-sm font-medium text-zinc-700 mb-2">
              {t.phone}
            </label>
            <input
              type="tel"
              value={phone}
              onChange={(e) => setPhone(e.target.value)}
              placeholder={t.phonePlaceholder}
              className="w-full px-4 py-3 border border-zinc-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-zinc-400"
              disabled={step === 'code'}
            />
          </div>

          {/* Code Input (only shown after phone step) */}
          {step === 'code' && (
            <div>
              <label className="block text-sm font-medium text-zinc-700 mb-2">
                {t.code}
              </label>
              <input
                type="text"
                value={code}
                onChange={(e) => setCode(e.target.value)}
                placeholder={t.codePlaceholder}
                maxLength={4}
                className="w-full px-4 py-3 border border-zinc-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-zinc-400"
              />
            </div>
          )}

          {/* Buttons */}
          <div className="space-y-3">
            {step === 'phone' ? (
              <button
                onClick={handleSendCode}
                className="w-full px-6 py-3 bg-zinc-800 text-white rounded-lg font-medium hover:bg-zinc-700 transition-colors"
              >
                {t.sendCode}
              </button>
            ) : (
              <button
                onClick={handleVerify}
                className="w-full px-6 py-3 bg-zinc-800 text-white rounded-lg font-medium hover:bg-zinc-700 transition-colors"
              >
                {t.verify}
              </button>
            )}

            <button
              onClick={handleGuest}
              className="w-full px-6 py-3 text-zinc-600 underline text-sm"
            >
              {t.guest}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}

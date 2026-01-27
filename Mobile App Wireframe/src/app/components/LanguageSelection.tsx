import { useNavigate } from 'react-router-dom';
import { Language } from '@/app/App';

interface Props {
  onSelect: (lang: Language) => void;
}

export function LanguageSelection({ onSelect }: Props) {
  const navigate = useNavigate();

  const handleSelect = (lang: Language) => {
    onSelect(lang);
    navigate('/login');
  };

  return (
    <div className="h-screen flex flex-col items-center justify-center bg-white p-6">
      <div className="w-full max-w-sm">
        <div className="w-20 h-20 mx-auto mb-8 bg-zinc-200 rounded-lg flex items-center justify-center">
          <div className="text-zinc-500 font-mono text-xs">LOGO</div>
        </div>
        
        <h2 className="text-xl font-semibold text-center text-zinc-800 mb-8">Choose Language / اختر اللغة</h2>
        
        <div className="space-y-4">
          <button
            onClick={() => handleSelect('fr')}
            className="w-full px-6 py-4 bg-zinc-800 text-white rounded-lg text-base font-medium hover:bg-zinc-700 transition-colors"
          >
            Français
          </button>
          
          <button
            onClick={() => handleSelect('ar')}
            className="w-full px-6 py-4 bg-zinc-800 text-white rounded-lg text-base font-medium hover:bg-zinc-700 transition-colors"
          >
            العربية
          </button>
        </div>
      </div>
    </div>
  );
}

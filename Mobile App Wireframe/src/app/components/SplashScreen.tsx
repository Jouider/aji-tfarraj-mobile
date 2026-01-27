import { useEffect } from 'react';
import { useNavigate } from 'react-router-dom';

export function SplashScreen() {
  const navigate = useNavigate();

  useEffect(() => {
    const timer = setTimeout(() => {
      navigate('/language');
    }, 2000);
    return () => clearTimeout(timer);
  }, [navigate]);

  return (
    <div className="h-screen flex items-center justify-center bg-zinc-100">
      <div className="text-center">
        <div className="w-32 h-32 mx-auto mb-6 bg-zinc-300 rounded-lg flex items-center justify-center">
          <div className="text-zinc-600 font-mono text-xs">LOGO</div>
        </div>
        <h1 className="text-2xl font-bold text-zinc-800">Aji Tfarraj</h1>
        <p className="text-sm text-zinc-500 mt-2">TV Show Reservations</p>
      </div>
    </div>
  );
}

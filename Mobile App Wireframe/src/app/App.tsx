import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import { useState } from 'react';
import { SplashScreen } from '@/app/components/SplashScreen';
import { LanguageSelection } from '@/app/components/LanguageSelection';
import { LoginScreen } from '@/app/components/LoginScreen';
import { MainLayout } from '@/app/components/MainLayout';
import { HomeScreen } from '@/app/components/HomeScreen';
import { ShowDetail } from '@/app/components/ShowDetail';
import { ReserveSeats } from '@/app/components/ReserveSeats';
import { ReservationSuccess } from '@/app/components/ReservationSuccess';
import { MyReservations } from '@/app/components/MyReservations';
import { ReservationDetail } from '@/app/components/ReservationDetail';
import { TicketScreen } from '@/app/components/TicketScreen';
import { ProfileScreen } from '@/app/components/ProfileScreen';
import { ErrorScreen } from '@/app/components/ErrorScreen';
import { SoldOutScreen } from '@/app/components/SoldOutScreen';

export type Language = 'fr' | 'ar';

function App() {
  const [language, setLanguage] = useState<Language>('fr');
  const [isRTL, setIsRTL] = useState(false);

  const handleLanguageChange = (lang: Language) => {
    setLanguage(lang);
    setIsRTL(lang === 'ar');
  };

  return (
    <div className={`min-h-screen bg-white ${isRTL ? 'rtl' : 'ltr'}`} dir={isRTL ? 'rtl' : 'ltr'}>
      <Router>
        <Routes>
          <Route path="/" element={<SplashScreen />} />
          <Route path="/language" element={<LanguageSelection onSelect={handleLanguageChange} />} />
          <Route path="/login" element={<LoginScreen language={language} />} />
          
          <Route element={<MainLayout language={language} />}>
            <Route path="/home" element={<HomeScreen language={language} />} />
            <Route path="/show/:id" element={<ShowDetail language={language} />} />
            <Route path="/reserve/:id" element={<ReserveSeats language={language} />} />
            <Route path="/reservation-success" element={<ReservationSuccess language={language} />} />
            <Route path="/my-reservations" element={<MyReservations language={language} />} />
            <Route path="/reservation/:id" element={<ReservationDetail language={language} />} />
            <Route path="/ticket" element={<TicketScreen language={language} />} />
            <Route path="/profile" element={<ProfileScreen language={language} onLanguageChange={handleLanguageChange} />} />
            <Route path="/error" element={<ErrorScreen language={language} />} />
            <Route path="/sold-out/:id" element={<SoldOutScreen language={language} />} />
          </Route>
        </Routes>
      </Router>
    </div>
  );
}

export default App;

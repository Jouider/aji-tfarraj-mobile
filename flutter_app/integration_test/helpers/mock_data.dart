import 'package:aji_tfarraj/features/auth/domain/user.dart';
import 'package:aji_tfarraj/features/shows/domain/show.dart';

/// Fake authenticated user for screenshot tests
final mockUser = User(
  id: 1,
  name: 'Mouad Alami',
  email: 'mouad@example.com',
  firstName: 'Mouad',
  lastName: 'Alami',
  cityName: 'Casablanca',
  district: 'Maârif',
  profileComplete: true,
  missingProfileFields: const [],
  createdAt: DateTime(2024, 3, 1),
  updatedAt: DateTime(2024, 3, 1),
  role: 'client',
);

/// Fake shows for home / browse screens
final List<Show> mockShows = [
  Show(
    id: 1,
    title: 'Ach Hada Show',
    description:
        'Le show de divertissement le plus populaire du Maroc, présenté par les meilleurs animateurs.',
    city: 'Casablanca',
    channel: '2M',
    studio: 'Studios 2M — Aïn Sebaâ',
    startsAt: DateTime.now().add(const Duration(days: 7)),
    capacity: 200,
    reservedSeats: 45,
    isActive: true,
    rewardPoints: 50,
  ),
  Show(
    id: 2,
    title: 'Lalla Fatima',
    description:
        'La célèbre émission culinaire qui explore les recettes traditionnelles marocaines.',
    city: 'Rabat',
    channel: 'Al Aoula',
    studio: 'Studios RTM — Rabat',
    startsAt: DateTime.now().add(const Duration(days: 14)),
    capacity: 150,
    reservedSeats: 80,
    isActive: true,
    rewardPoints: 30,
  ),
  Show(
    id: 3,
    title: 'Dar Si Said',
    description:
        'Un talk-show culturel mettant en avant l\'artisanat et le patrimoine marocain.',
    city: 'Marrakech',
    channel: '2M',
    studio: 'Studios Marrakech',
    startsAt: DateTime.now().add(const Duration(days: 21)),
    capacity: 100,
    reservedSeats: 20,
    isActive: true,
    rewardPoints: 40,
  ),
  Show(
    id: 4,
    title: 'Marhba Bikom',
    description:
        'Émission de variétés musicales avec les plus grands artistes marocains.',
    city: 'Casablanca',
    channel: 'Medi1',
    studio: 'Studios Medi1 — Casablanca',
    startsAt: DateTime.now().add(const Duration(days: 30)),
    capacity: 300,
    reservedSeats: 200,
    isActive: true,
    rewardPoints: 60,
  ),
  Show(
    id: 5,
    title: 'Sport Time',
    description:
        'L\'émission sportive qui analyse l\'actualité du football marocain et international.',
    city: 'Casablanca',
    channel: 'Arryadia',
    studio: 'Studios Arryadia',
    startsAt: DateTime.now().add(const Duration(days: 3)),
    capacity: 120,
    reservedSeats: 119,
    isActive: true,
    rewardPoints: 25,
  ),
];

// Le staff photographie un membre pour son book.
//
// Ce qui doit tenir : la liste dit où en est chaque book, l'écran du membre
// montre ce qui manque, et on ne lance pas deux captures à la fois — la caméra
// plus la lecture de posture sont ce que le téléphone fait de plus lourd.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aji_tfarraj/app/localization/app_locale.dart';
import 'package:aji_tfarraj/app/localization/strings.dart';
import 'package:aji_tfarraj/features/casting/domain/casting_models.dart';
import 'package:aji_tfarraj/features/notifications/data/notification_repository.dart'
    show sharedPreferencesProvider;
import 'package:aji_tfarraj/features/casting/domain/casting_pose.dart';
import 'package:aji_tfarraj/features/casting/presentation/pose_capture_screen.dart'
    show poseCopy;
import 'package:aji_tfarraj/features/staff/data/staff_casting_repository.dart';
import 'package:aji_tfarraj/features/staff/presentation/staff_casting_book_screen.dart';
import 'package:aji_tfarraj/features/staff/presentation/staff_casting_screen.dart';

CastingMember _member({
  int id = 7,
  String name = 'Ahmed Bennani',
  int taken = 0,
  int total = 4,
}) =>
    CastingMember.fromJson({
      'id': id,
      'name': name,
      'phone': '+212 612345678',
      'avatar_url': null,
      'photos_taken': taken,
      'poses_total': total,
    });

void main() {
  const s = AppStrings(AppLocale.fr);

  group('ce que le serveur annonce', () {
    test('un book entamé se lit tel quel', () {
      final member = _member(taken: 2);

      expect(member.name, 'Ahmed Bennani');
      expect(member.photosTaken, 2);
      expect(member.isComplete, isFalse);
    });

    test('un book complet se reconnaît', () {
      expect(_member(taken: 4).isComplete, isTrue);
    });

    /// Un serveur qui n'annonce pas le total ne doit pas faire croire que tout
    /// est fait.
    test('sans total annoncé, rien n\'est déclaré complet', () {
      expect(_member(taken: 0, total: 0).isComplete, isFalse);
    });
  });

  group('la liste des membres', () {
    Future<void> pump(WidgetTester tester, List<CastingMember> members) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          castingMembersProvider('').overrideWith((ref) async => members),
        ],
        child: const MaterialApp(home: StaffCastingScreen()),
      ));
      await tester.pump();
      await tester.pump();
    }

    testWidgets('chaque membre montre où en est son book', (tester) async {
      await pump(tester, [
        _member(taken: 2),
        _member(id: 8, name: 'Salma Idrissi', taken: 4),
      ]);

      expect(find.text('Ahmed Bennani'), findsOneWidget);
      expect(find.text('2/4'), findsOneWidget);
      expect(find.text(s.staffCastingBookComplete), findsOneWidget,
          reason: 'le book de Salma est complet');
    });

    /// Le book est réservé aux majeurs : quand rien ne correspond, l'écran le
    /// dit plutôt que de laisser croire à une panne.
    testWidgets('personne ne correspond : l\'écran l\'explique', (tester) async {
      await pump(tester, const []);

      expect(find.text(s.staffCastingNobody), findsOneWidget);
      expect(find.text(s.staffCastingNobodyHint), findsOneWidget);
    });
  });

  group('le book d\'un membre', () {
    Future<void> pump(WidgetTester tester, CastingBook book) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          staffCastingBookProvider(7).overrideWith((ref) async => book),
        ],
        child: MaterialApp(home: StaffCastingBookScreen(member: _member())),
      ));
      await tester.pump();
      await tester.pump();
    }

    testWidgets('une ligne par pose, avec ce qui reste à prendre',
        (tester) async {
      await pump(
        tester,
        CastingBook.fromJson({
          'photos': [
            {'pose': 'portrait', 'url': 'https://x/p.jpg', 'required': true},
          ],
          'missing_poses': ['full_front', 'full_profile', 'portrait_smile'],
          'is_complete': false,
        }),
      );

      // Chaque pose connue de l'app a sa ligne.
      for (final pose in CastingPose.values) {
        expect(find.text(poseCopy(s.casting, pose).label), findsOneWidget,
            reason: pose.key);
      }

      // Celle déjà prise se repropose en « Reprendre », les autres en « Prendre ».
      expect(find.text(s.staffCastingRetake), findsOneWidget);
      expect(find.text(s.casting.bookTake), findsNWidgets(3));
    });

    testWidgets('un book vide propose les quatre poses', (tester) async {
      await pump(tester, CastingBook.fromJson({'photos': [], 'is_complete': false}));

      expect(find.text(s.casting.bookTake), findsNWidgets(CastingPose.values.length));
      expect(find.text(s.staffCastingRetake), findsNothing);
    });
  });
}

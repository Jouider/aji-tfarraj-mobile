// Reproduces the real Rewards screen at phone width with sample data, to catch
// the layout exception that blanks the rewards list (points badge + collect
// button no longer fit side-by-side, so the card is stacked vertically).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aji_tfarraj/features/notifications/data/notification_repository.dart'
    show sharedPreferencesProvider;
import 'package:aji_tfarraj/features/rewards/data/rewards_repository.dart';
import 'package:aji_tfarraj/features/rewards/domain/reward.dart';
import 'package:aji_tfarraj/features/rewards/presentation/rewards_screen.dart';

const _rewards = [
  Reward(
    id: 1,
    title: 'Pack PS5 1 To + EA Sports FC 26',
    titleAr: 'حزمة بلايستيشن 5',
    description: 'Le rêve de tous les gamers.',
    descriptionAr: 'حلم كل اللاعبين.',
    imageUrl: null,
    pointsRequired: 9000,
    canCollect: false,
  ),
  Reward(
    id: 2,
    title: 'Casque Bluetooth Energy',
    titleAr: 'سماعة بلوتوث',
    description: 'Le même son d\'exception.',
    descriptionAr: 'نفس الصوت الاستثنائي.',
    imageUrl: null,
    pointsRequired: 1500,
    canCollect: true,
  ),
];

Future<void> _pumpScreen(WidgetTester tester, {required TextDirection dir}) async {
  await tester.binding.setSurfaceSize(const Size(360, 800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        rewardsListProvider.overrideWith((ref) async => _rewards),
      ],
      child: MaterialApp(
        home: Directionality(
          textDirection: dir,
          child: const RewardsScreen(),
        ),
      ),
    ),
  );
  await tester.pump(); // let the future resolve
  await tester.pump();
}

void main() {
  testWidgets('RewardsScreen (LTR) shows reward points', (tester) async {
    await _pumpScreen(tester, dir: TextDirection.ltr);
    expect(tester.takeException(), isNull);
    expect(find.textContaining('9000'), findsOneWidget);
  });

  testWidgets('RewardsScreen (RTL) shows reward points', (tester) async {
    await _pumpScreen(tester, dir: TextDirection.rtl);
    expect(tester.takeException(), isNull);
    expect(find.textContaining('9000'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aji_tfarraj/app/design_system/image_viewer.dart';

/// The viewer is how someone actually looks at the photo the system holds of
/// them, so it must open, be zoomable, and always be dismissible — a full-screen
/// overlay with no way out would trap the user.
void main() {
  Widget host(VoidCallback onTap) => MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: GestureDetector(
                onTap: onTap,
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );

  group('avatarHeroTag', () {
    test('is stable for the same image', () {
      expect(avatarHeroTag('https://x/a.jpg'), avatarHeroTag('https://x/a.jpg'));
    });

    test('differs between images, so two avatars never share a hero', () {
      expect(
        avatarHeroTag('https://x/a.jpg'),
        isNot(avatarHeroTag('https://x/b.jpg')),
      );
    });
  });

  group('showFullScreenImage', () {
    testWidgets('opens a zoomable full-screen view', (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(builder: (context) {
            ctx = context;
            return const SizedBox.shrink();
          }),
        ),
      ));

      showFullScreenImage(ctx, imageUrl: '/tmp/does-not-exist.jpg');
      await tester.pumpAndSettle();

      // Pinch-zoom is the point: a fixed-size picture would be no better than
      // the thumbnail it came from.
      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('closes when the close button is tapped', (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(builder: (context) {
            ctx = context;
            return const SizedBox.shrink();
          }),
        ),
      ));

      showFullScreenImage(ctx, imageUrl: '/tmp/does-not-exist.jpg');
      await tester.pumpAndSettle();
      expect(find.byType(InteractiveViewer), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.byType(InteractiveViewer), findsNothing);
    });

    testWidgets('closes when tapping the backdrop', (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(builder: (context) {
            ctx = context;
            return const SizedBox.shrink();
          }),
        ),
      ));

      showFullScreenImage(ctx, imageUrl: '/tmp/does-not-exist.jpg');
      await tester.pumpAndSettle();

      // Top-left corner is backdrop, well clear of the picture and the button.
      await tester.tapAt(const Offset(10, 400));
      await tester.pumpAndSettle();

      expect(find.byType(InteractiveViewer), findsNothing);
    });

    testWidgets('a broken image still shows a dismissible view', (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(builder: (context) {
            ctx = context;
            return const SizedBox.shrink();
          }),
        ),
      ));

      showFullScreenImage(ctx, imageUrl: '/tmp/missing.jpg');
      await tester.pumpAndSettle();

      // Even with nothing to render, the way out must still be there.
      expect(find.byIcon(Icons.close), findsOneWidget);
    });
  });
}

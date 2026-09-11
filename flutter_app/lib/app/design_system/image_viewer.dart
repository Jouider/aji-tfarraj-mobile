import 'dart:io';

import 'package:flutter/material.dart';

import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';

/// Opens [imageUrl] full screen, pinch-zoomable, over a dark scrim.
///
/// Small avatars are unreadable at 86px — this is how someone actually checks
/// the photo the system holds of them. Pass the same [heroTag] as the thumbnail
/// so the picture flies out of its circle instead of cutting.
///
/// [imageUrl] may be a network URL or a local file path (a freshly captured
/// photo that has not been uploaded yet).
Future<void> showFullScreenImage(
  BuildContext context, {
  required String imageUrl,
  Object? heroTag,
}) {
  return Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      barrierDismissible: true,
      // The hero needs a real transition window to fly across.
      transitionDuration: const Duration(milliseconds: 260),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, animation, __) => FadeTransition(
        opacity: animation,
        child: _FullScreenImage(imageUrl: imageUrl, heroTag: heroTag),
      ),
    ),
  );
}

class _FullScreenImage extends StatelessWidget {
  const _FullScreenImage({required this.imageUrl, this.heroTag});

  final String imageUrl;
  final Object? heroTag;

  bool get _isLocalFile =>
      !imageUrl.startsWith('http://') && !imageUrl.startsWith('https://');

  @override
  Widget build(BuildContext context) {
    final image = _isLocalFile
        ? Image.file(File(imageUrl), fit: BoxFit.contain)
        : Image.network(
            imageUrl,
            fit: BoxFit.contain,
            loadingBuilder: (_, child, progress) => progress == null
                ? child
                : const Center(
                    child: CircularProgressIndicator(color: Colors.white)),
            errorBuilder: (_, __, ___) => const Center(
              child: Icon(Icons.broken_image_outlined,
                  color: Colors.white54, size: 64),
            ),
          );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Tapping anywhere off the picture closes it — the usual gesture, and
          // it keeps the close button from being the only way out.
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              behavior: HitTestBehavior.opaque,
              child: const SizedBox.expand(),
            ),
          ),
          Center(
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: heroTag != null
                  ? Hero(tag: heroTag!, child: image)
                  : image,
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + AppSpacing.sm,
            right: AppSpacing.md,
            child: Semantics(
              button: true,
              label: MaterialLocalizations.of(context).closeButtonTooltip,
              child: InkWell(
                onTap: () => Navigator.of(context).maybePop(),
                customBorder: const CircleBorder(),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close,
                      color: Colors.white, size: 22),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tag shared between an avatar thumbnail and its full-screen view, so the
/// hero animation matches them up. Keyed by the image itself: two thumbnails of
/// the same person on one screen would otherwise fight over the same tag.
///
/// [scope] separates screens that show the SAME photo and sit on top of each
/// other — the profile and its edit screen. With one shared tag the framework
/// flies the picture between them on every push and pop, and it flies without
/// its round clip: a square block crossing the screen.
Object avatarHeroTag(String imageUrl, {String scope = 'avatar'}) =>
    '$scope::$imageUrl';

/// Placeholder shown while an avatar has no picture at all.
class AvatarFallbackIcon extends StatelessWidget {
  const AvatarFallbackIcon({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.backgroundGrey,
      child: Center(
        child: Icon(Icons.person, size: size, color: AppColors.textLight),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';
import 'package:aji_tfarraj/app/localization/locale_provider.dart';
import 'package:aji_tfarraj/features/casting/domain/casting_pose.dart';
import 'package:aji_tfarraj/features/casting/domain/pose_guides.dart';
import 'package:aji_tfarraj/features/casting/presentation/pose_capture_screen.dart';

/// The instructions for one shot, read *before* the camera opens.
///
/// Deliberately a separate step. Instructions printed over a live preview are
/// not read — the person is already holding a pose and looking at themselves.
/// Read first, then shoot, is the order that produces a usable book.
///
/// Returns the captured file path, or null if they backed out.
Future<String?> showPoseGuide(
  BuildContext context,
  WidgetRef ref, {
  required CastingPose pose,
  int maxSide = 1024,
}) async {
  final s = ref.read(stringsProvider);
  final copy = poseCopy(s.casting, pose);

  final go = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceOverlay,
    shape: const RoundedRectangleBorder(
      borderRadius:
          BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: Text(copy.label,
                        style: AppTypography.h3
                            .copyWith(color: AppColors.textPrimary)),
                  ),
                  _Chip(
                    label: pose.isRequired
                        ? s.casting.bookRequired
                        : s.casting.bookOptional,
                    highlight: pose.isRequired,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _PoseDemo(pose: pose, caption: s.casting.poseDemoCaption),

              for (var i = 0; i < copy.steps.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Text('${i + 1}',
                            style: AppTypography.caption
                                .copyWith(color: AppColors.secondary)),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(copy.steps[i],
                            style: AppTypography.bodyMedium),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.backgroundGrey,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Row(
                  children: [
                    Icon(Icons.group_outlined,
                        size: 18, color: AppColors.textMuted),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(s.casting.bookHelper,
                          style: AppTypography.bodySmall
                              .copyWith(color: AppColors.textMuted)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                height: AppSpacing.buttonHeight,
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(sheetContext).pop(true),
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: Text(s.casting.bookTake),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: AppColors.onSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  if (go != true || !context.mounted) return null;

  return Navigator.of(context).push<String>(
    MaterialPageRoute(
      builder: (_) => PoseCaptureScreen(pose: pose, maxSide: maxSide),
    ),
  );
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.highlight});

  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.secondary.withValues(alpha: 0.15)
            : AppColors.backgroundGrey,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: highlight ? AppColors.secondary : AppColors.textMuted,
        ),
      ),
    );
  }
}

/// La démonstration de la pose : en boucle, muette, lancée d'elle-même.
///
/// Muette parce qu'elle montre sans raconter — et parce qu'un guide qui se met
/// à parler dans une salle d'attente est un guide qu'on referme. Un tap la met
/// en pause pour regarder un détail. Sans clip (serveur plus ancien, pas de
/// réseau), rien n'est dessiné et le guide reste le texte qu'il était.
class _PoseDemo extends ConsumerStatefulWidget {
  const _PoseDemo({required this.pose, required this.caption});

  final CastingPose pose;
  final String caption;

  @override
  ConsumerState<_PoseDemo> createState() => _PoseDemoState();
}

class _PoseDemoState extends ConsumerState<_PoseDemo> {
  VideoPlayerController? _controller;
  Uri? _loaded;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _load(Uri video) {
    if (_loaded == video) return;
    _loaded = video;

    final controller = VideoPlayerController.networkUrl(video);
    _controller = controller;
    controller
      ..setLooping(true)
      ..setVolume(0);
    controller.initialize().then((_) {
      if (!mounted || _controller != controller) return;
      controller.play();
      setState(() {});
    }).catchError((_) {
      // Pas de lecteur (pas de réseau, format refusé) : l'aperçu reste affiché.
    });
  }

  void _toggle() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    controller.value.isPlaying ? controller.pause() : controller.play();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final clip = ref.watch(poseGuideClipProvider(widget.pose));
    if (clip == null) return const SizedBox.shrink();
    _load(clip.video);

    final controller = _controller;
    final ready = controller != null && controller.value.isInitialized;
    // Les démonstrations sont filmées en portrait : on borne la hauteur pour
    // que les consignes et le bouton restent à portée sans défiler.
    final height = MediaQuery.sizeOf(context).height * 0.42;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        children: [
          Center(
            child: GestureDetector(
              onTap: _toggle,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                child: Container(
                  height: height,
                  color: Colors.black,
                  child: AspectRatio(
                    aspectRatio: ready ? controller.value.aspectRatio : 9 / 19.5,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (ready)
                          VideoPlayer(controller)
                        else if (clip.poster != null)
                          Image.network(clip.poster.toString(),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const SizedBox.shrink()),
                        if (!ready)
                          const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white70),
                            ),
                          )
                        else if (!controller.value.isPlaying)
                          const Center(
                            child: Icon(Icons.play_circle_fill,
                                size: 52, color: Colors.white70),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            widget.caption,
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

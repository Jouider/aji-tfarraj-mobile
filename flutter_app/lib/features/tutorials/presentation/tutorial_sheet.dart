import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';
import 'package:aji_tfarraj/app/localization/locale_provider.dart';
import 'package:aji_tfarraj/features/tutorials/domain/tutorial.dart';

/// One clip offered in the sheet.
class TutorialSheetItem {
  const TutorialSheetItem({
    required this.title,
    required this.clip,
    this.topic,
    String? shortTitle,
  }) : shortTitle = shortTitle ?? title;

  final String title;

  /// For the switch between videos, where the full title does not fit.
  final String shortTitle;
  final TutorialClip clip;

  /// Null for a clip that is not one of the server's topics.
  final TutorialTopic? topic;
}

/// Shows the tutorial over the current screen: a sheet three quarters of the
/// height, the screen behind blurred, « J'ai compris » at the bottom.
///
/// The member stays where they were — closing the sheet puts them back on the
/// screen they needed help with. A tap outside closes it too.
Future<void> showTutorialSheet(
  BuildContext context, {
  required List<TutorialSheetItem> items,
  int initialIndex = 0,
}) {
  assert(items.isNotEmpty);

  return showGeneralDialog<void>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    // The blur layer below draws the dimming, animated with the sheet.
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (_, __, ___) => TutorialSheet(
      items: items,
      initialIndex: initialIndex.clamp(0, items.length - 1),
    ),
    transitionBuilder: (context, animation, _, child) {
      final curved =
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);

      return Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: AnimatedBuilder(
                animation: curved,
                builder: (_, __) => BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: 14 * curved.value,
                    sigmaY: 14 * curved.value,
                  ),
                  child: ColoredBox(
                    color: Colors.black.withValues(alpha: 0.4 * curved.value),
                  ),
                ),
              ),
            ),
          ),
          SlideTransition(
            position: Tween(begin: const Offset(0, 1), end: Offset.zero)
                .animate(curved),
            child: child,
          ),
        ],
      );
    },
  );
}

class TutorialSheet extends ConsumerStatefulWidget {
  const TutorialSheet({
    super.key,
    required this.items,
    this.initialIndex = 0,
  });

  final List<TutorialSheetItem> items;
  final int initialIndex;

  @override
  ConsumerState<TutorialSheet> createState() => _TutorialSheetState();
}

class _TutorialSheetState extends ConsumerState<TutorialSheet> {
  late int _index = widget.initialIndex;
  VideoPlayerController? _controller;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load(widget.items[_index].clip);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _load(TutorialClip clip) {
    final previous = _controller;
    final controller = VideoPlayerController.networkUrl(clip.video);
    _controller = controller;
    _failed = false;
    previous?.dispose();

    controller.initialize().then((_) {
      if (!mounted || _controller != controller) return;
      setState(() {});
      controller.play();
    }).catchError((Object _) {
      if (!mounted || _controller != controller) return;
      setState(() => _failed = true);
    });
  }

  void _select(int index) {
    if (index == _index) return;
    setState(() {
      _index = index;
      _load(widget.items[index].clip);
    });
  }

  void _togglePlay() {
    final controller = _controller;
    if (controller == null) return;
    final value = controller.value;
    if (value.isPlaying) {
      controller.pause();
      return;
    }
    final ended =
        value.duration > Duration.zero && value.position >= value.duration;
    if (ended) controller.seekTo(Duration.zero);
    controller.play();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final item = widget.items[_index];
    final duration = formatClipDuration(item.clip.duration);
    final height = MediaQuery.sizeOf(context).height * 0.75;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Material(
        color: AppColors.surfaceOverlay,
        clipBehavior: Clip.antiAlias,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.sm),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Title, and how long it takes.
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: AppTypography.h4.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (duration.isNotEmpty)
                        Text(
                          duration,
                          style: AppTypography.labelMedium
                              .copyWith(color: AppColors.textMuted),
                        ),
                    ],
                  ),
                ),

                // Opened from the general "?": both walkthroughs as pills,
                // short labels — the full name is in the title above.
                if (widget.items.length > 1)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          for (var i = 0; i < widget.items.length; i++)
                            ChoiceChip(
                              label: Text(widget.items[i].shortTitle),
                              selected: i == _index,
                              onSelected: (_) => _select(i),
                              showCheckmark: false,
                              shape: const StadiumBorder(),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: AppSpacing.xs),
                              backgroundColor: Colors.transparent,
                              selectedColor:
                                  AppColors.secondary.withValues(alpha: 0.15),
                              side: BorderSide(
                                color: i == _index
                                    ? AppColors.secondary
                                    : AppColors.border,
                                width: 1.5,
                              ),
                              labelStyle: AppTypography.labelMedium.copyWith(
                                color: i == _index
                                    ? AppColors.secondary
                                    : AppColors.textSecondary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: AppSpacing.md),
                Expanded(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: _Player(
                      controller: _controller,
                      failed: _failed,
                      poster: item.clip.poster,
                      unavailableText: s.tutorialUnavailable,
                      onTap: _togglePlay,
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: SizedBox(
                    width: double.infinity,
                    height: AppSpacing.buttonHeight,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                      ),
                      child: Text(
                        s.howItWorksGotIt,
                        style: AppTypography.labelLarge.copyWith(
                            color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The clip, fitted into the space the sheet leaves it.
class _Player extends StatelessWidget {
  const _Player({
    required this.controller,
    required this.failed,
    required this.poster,
    required this.unavailableText,
    required this.onTap,
  });

  final VideoPlayerController? controller;
  final bool failed;
  final Uri? poster;
  final String unavailableText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final controller = this.controller;
    final ready = controller != null && controller.value.isInitialized;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: ColoredBox(
        color: Colors.black,
        child: Center(
          child: failed
              ? Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wifi_off_rounded,
                          size: 36, color: Colors.white54),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        unavailableText,
                        style: AppTypography.bodySmall
                            .copyWith(color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : !ready
                  ? Stack(
                      alignment: Alignment.center,
                      children: [
                        if (poster != null)
                          Opacity(
                            opacity: 0.5,
                            child: Image.network(
                              poster.toString(),
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) =>
                                  const SizedBox.shrink(),
                            ),
                          ),
                        const CircularProgressIndicator(
                            color: AppColors.secondary),
                      ],
                    )
                  : LayoutBuilder(
                      builder: (context, box) {
                        // Portrait clips: as large as the frame allows,
                        // without cropping the phone screen they show.
                        final ratio = controller.value.aspectRatio;
                        final width =
                            math.min(box.maxWidth, box.maxHeight * ratio);
                        return SizedBox(
                          width: width,
                          height: width / ratio,
                          child: Stack(
                            alignment: Alignment.bottomCenter,
                            children: [
                              GestureDetector(
                                onTap: onTap,
                                child: VideoPlayer(controller),
                              ),
                              VideoProgressIndicator(
                                controller,
                                allowScrubbing: true,
                                colors: const VideoProgressColors(
                                  playedColor: AppColors.secondary,
                                ),
                              ),
                              ValueListenableBuilder<VideoPlayerValue>(
                                valueListenable: controller,
                                builder: (_, value, __) {
                                  if (value.isPlaying) {
                                    return const SizedBox.shrink();
                                  }
                                  final ended =
                                      value.duration > Duration.zero &&
                                          value.position >= value.duration;
                                  return Center(
                                    child: GestureDetector(
                                      onTap: onTap,
                                      child: Icon(
                                        ended
                                            ? Icons.replay_circle_filled
                                            : Icons.play_circle_fill,
                                        size: 64,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ),
    );
  }
}

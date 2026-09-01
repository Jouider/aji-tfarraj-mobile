import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import 'package:aji_tfarraj/app/copywriting/copy_fr.dart' show GuidedStep;
import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';
import 'package:aji_tfarraj/app/localization/locale_provider.dart';
import 'package:aji_tfarraj/features/guided_tour/data/guided_tour_controller.dart';

/// Whether the tutorial clips start with sound on. The clips are narrated, so
/// sound is the point — but the card always shows a mute control.
const bool _kStartUnmuted = true;

/// Contextual guided tour: dims the real screen and raises a card that walks the
/// user through it, one step at a time (short clip + text + "J'ai compris").
///
/// Mounted once in [AppGate], below the update/lock gates so those keep
/// priority. Renders nothing unless a tour is active.
class GuidedTourOverlay extends ConsumerWidget {
  const GuidedTourOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tour = ref.watch(guidedTourControllerProvider);
    if (tour == null) return const SizedBox.shrink();

    final s = ref.watch(stringsProvider);
    final steps = switch (tour) {
      GuidedTourId.home => s.tourHomeSteps,
      GuidedTourId.reserve => s.tourReserveSteps,
    };

    // Never trap the user behind an empty card if a track has no copy.
    if (steps.isEmpty) return const SizedBox.shrink();

    return _GuidedTourView(
      key: ValueKey(tour),
      steps: steps,
      accent:
          tour == GuidedTourId.home ? AppColors.primary : AppColors.secondary,
    );
  }
}

class _GuidedTourView extends ConsumerStatefulWidget {
  const _GuidedTourView({
    super.key,
    required this.steps,
    required this.accent,
  });

  final List<GuidedStep> steps;
  final Color accent;

  @override
  ConsumerState<_GuidedTourView> createState() => _GuidedTourViewState();
}

class _GuidedTourViewState extends ConsumerState<_GuidedTourView> {
  late final PageController _pageController;
  int _index = 0;

  // Per-step illustration used whenever a clip is absent or fails to load.
  static const List<IconData> _fallbackIcons = [
    Icons.waving_hand_outlined,
    Icons.search_outlined,
    Icons.event_seat_outlined,
    Icons.confirmation_number_outlined,
    Icons.notifications_active_outlined,
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool get _isLast => _index >= widget.steps.length - 1;

  void _next() {
    if (_isLast) {
      _finish();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  /// Both "Passer" and finishing the last step mark the tour as seen — being
  /// shown it once is what counts, so skipping must not bring it back.
  void _finish() => ref.read(guidedTourControllerProvider.notifier).finish();

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final media = MediaQuery.of(context);

    return Positioned.fill(
      child: Material(
        type: MaterialType.transparency,
        child: Stack(
          children: [
            // Scrim over the real screen. Tapping it does nothing on purpose —
            // the user leaves via "Passer" or "J'ai compris", so a stray tap
            // never skips a step by accident.
            const ModalBarrier(dismissible: false, color: Colors.black54),

            // Skip, kept clear of the notch.
            Positioned(
              top: media.padding.top + AppSpacing.sm,
              right: AppSpacing.lg,
              child: TextButton(
                onPressed: _finish,
                style: TextButton.styleFrom(
                  backgroundColor: Colors.black.withValues(alpha: 0.35),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  ),
                ),
                child: Text(s.tourSkip, style: AppTypography.labelMedium),
              ),
            ),

            Align(
              alignment: Alignment.bottomCenter,
              child: _TourCard(
                steps: widget.steps,
                accent: widget.accent,
                index: _index,
                pageController: _pageController,
                fallbackIcons: _fallbackIcons,
                onPageChanged: (i) => setState(() => _index = i),
                onPrimaryAction: _next,
                primaryLabel: _isLast ? s.tourGotIt : s.tourNext,
                counter: s.tourStepCounter(_index + 1, widget.steps.length),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// The raised card
// ─────────────────────────────────────────────

class _TourCard extends StatelessWidget {
  const _TourCard({
    required this.steps,
    required this.accent,
    required this.index,
    required this.pageController,
    required this.fallbackIcons,
    required this.onPageChanged,
    required this.onPrimaryAction,
    required this.primaryLabel,
    required this.counter,
  });

  final List<GuidedStep> steps;
  final Color accent;
  final int index;
  final PageController pageController;
  final List<IconData> fallbackIcons;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onPrimaryAction;
  final String primaryLabel;
  final String counter;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 1, end: 0),
      builder: (context, offset, child) => Transform.translate(
        offset: Offset(0, offset * 120),
        child: Opacity(opacity: 1 - offset, child: child),
      ),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.backgroundWhite,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusLg * 1.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 28,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              top: AppSpacing.md,
              bottom: AppSpacing.md + (bottomInset > 0 ? 0 : AppSpacing.sm),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Grab handle
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Swipeable steps. Height is bounded so the card never grows
                // past roughly half the screen on small devices.
                SizedBox(
                  height: (MediaQuery.of(context).size.height * 0.42)
                      .clamp(280.0, 420.0),
                  child: PageView.builder(
                    controller: pageController,
                    onPageChanged: onPageChanged,
                    itemCount: steps.length,
                    itemBuilder: (_, i) => _StepBody(
                      step: steps[i],
                      accent: accent,
                      fallbackIcon:
                          fallbackIcons[i % fallbackIcons.length],
                      isVisible: i == index,
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.md),
                _Dots(count: steps.length, current: index, accent: accent),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  counter,
                  style: AppTypography.labelSmall
                      .copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(height: AppSpacing.md),

                SizedBox(
                  width: double.infinity,
                  height: AppSpacing.buttonHeight,
                  child: FilledButton(
                    onPressed: onPrimaryAction,
                    style: FilledButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                    ),
                    child:
                        Text(primaryLabel, style: AppTypography.buttonLarge),
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

// ─────────────────────────────────────────────
// One step: media + title + body
// ─────────────────────────────────────────────

class _StepBody extends StatelessWidget {
  const _StepBody({
    required this.step,
    required this.accent,
    required this.fallbackIcon,
    required this.isVisible,
  });

  final GuidedStep step;
  final Color accent;
  final IconData fallbackIcon;
  final bool isVisible;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            child: step.videoUrl != null
                ? _StepVideo(
                    url: step.videoUrl!,
                    accent: accent,
                    fallbackIcon: fallbackIcon,
                    isVisible: isVisible,
                  )
                : _Illustration(icon: fallbackIcon, accent: accent),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          step.title,
          style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          step.body,
          style:
              AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

/// Placeholder shown when a step has no clip yet, or when its clip fails to
/// load. Deliberately branded rather than blank, so the tour is fully usable
/// before any video is produced.
class _Illustration extends StatelessWidget {
  const _Illustration({required this.icon, required this.accent});

  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.14),
            accent.withValues(alpha: 0.04),
          ],
        ),
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.backgroundWhite,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.18),
                blurRadius: 24,
              ),
            ],
          ),
          child: Icon(icon, size: 48, color: accent),
        ),
      ),
    );
  }
}

/// Plays a step's clip, with a mute toggle. Falls back to [_Illustration] on
/// any load error so a bad URL can never show a broken player.
class _StepVideo extends ConsumerStatefulWidget {
  const _StepVideo({
    required this.url,
    required this.accent,
    required this.fallbackIcon,
    required this.isVisible,
  });

  final String url;
  final Color accent;
  final IconData fallbackIcon;
  final bool isVisible;

  @override
  ConsumerState<_StepVideo> createState() => _StepVideoState();
}

class _StepVideoState extends ConsumerState<_StepVideo> {
  VideoPlayerController? _controller;
  bool _failed = false;
  bool _muted = !_kStartUnmuted;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final controller =
        VideoPlayerController.networkUrl(Uri.parse(widget.url));
    try {
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      await controller.setLooping(true);
      await controller.setVolume(_muted ? 0 : 1);
      if (widget.isVisible) await controller.play();
      setState(() => _controller = controller);
    } catch (_) {
      await controller.dispose();
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void didUpdateWidget(covariant _StepVideo old) {
    super.didUpdateWidget(old);
    // Only the visible step plays — swiping away pauses instead of leaving
    // several clips talking over each other.
    final c = _controller;
    if (c == null) return;
    if (widget.isVisible && !c.value.isPlaying) {
      c.play();
    } else if (!widget.isVisible && c.value.isPlaying) {
      c.pause();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _toggleMute() {
    final c = _controller;
    if (c == null) return;
    setState(() => _muted = !_muted);
    c.setVolume(_muted ? 0 : 1);
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final controller = _controller;

    if (_failed) {
      return _Illustration(icon: widget.fallbackIcon, accent: widget.accent);
    }
    if (controller == null) {
      return Container(
        color: AppColors.backgroundGrey,
        child: Center(
          child: CircularProgressIndicator(color: widget.accent),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: controller.value.size.width,
            height: controller.value.size.height,
            child: VideoPlayer(controller),
          ),
        ),
        Positioned(
          right: AppSpacing.sm,
          bottom: AppSpacing.sm,
          child: Semantics(
            button: true,
            label: _muted ? s.tourUnmuteVideo : s.tourMuteVideo,
            child: InkWell(
              onTap: _toggleMute,
              customBorder: const CircleBorder(),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _muted ? Icons.volume_off : Icons.volume_up,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Progress dots
// ─────────────────────────────────────────────

class _Dots extends StatelessWidget {
  const _Dots({
    required this.count,
    required this.current,
    required this.accent,
  });

  final int count;
  final int current;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 22 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? accent : AppColors.border,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

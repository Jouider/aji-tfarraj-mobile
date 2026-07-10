import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:aji_tfarraj/app/copywriting/copy_fr.dart' show HowToStep;
import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';
import 'package:aji_tfarraj/app/localization/locale_provider.dart';
import 'package:aji_tfarraj/features/auth/data/auth_repository.dart';
import 'package:aji_tfarraj/features/how_it_works/domain/how_to_track.dart';

/// "Comment ça marche" — illustrated, swipeable step-by-step guide.
///
/// Two tracks:
///  • [HowToTrack.client]  — how to reserve & attend (everyone).
///  • [HowToTrack.parrain] — how to refer & earn (staff/admin only).
///
/// Hybrid format: the illustrated carousel works offline today; when a tutorial
/// video URL is provided in the copy, a "Regarder la vidéo" button appears and
/// plays it in-app.
class HowItWorksScreen extends ConsumerStatefulWidget {
  final HowToTrack initialTrack;

  const HowItWorksScreen({super.key, this.initialTrack = HowToTrack.client});

  @override
  ConsumerState<HowItWorksScreen> createState() => _HowItWorksScreenState();
}

class _HowItWorksScreenState extends ConsumerState<HowItWorksScreen> {
  late final PageController _pageController = PageController();
  late HowToTrack _track = widget.initialTrack;
  int _currentPage = 0;

  // Per-step icons, mapped by index (falls back cyclically if steps grow).
  static const _clientIcons = [
    Icons.explore_outlined,
    Icons.event_seat_outlined,
    Icons.hourglass_top_rounded,
    Icons.confirmation_number_outlined,
    Icons.qr_code_2_rounded,
  ];
  static const _parrainIcons = [
    Icons.link_rounded,
    Icons.share_outlined,
    Icons.how_to_reg_outlined,
    Icons.insights_outlined,
    Icons.payments_outlined,
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _switchTrack(HowToTrack track) {
    if (_track == track) return;
    setState(() {
      _track = track;
      _currentPage = 0;
    });
    if (_pageController.hasClients) {
      _pageController.jumpToPage(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final user = ref.watch(loginAuthStateProvider).user;
    final allowParrain = user?.isReferrerOrStaff ?? false;

    // Clamp to client track if the parrain track isn't permitted.
    final track = (_track == HowToTrack.parrain && !allowParrain)
        ? HowToTrack.client
        : _track;
    final isParrain = track == HowToTrack.parrain;

    final steps = isParrain
        ? s.howItWorksParrainSteps
        : s.howItWorksClientSteps;
    final headline =
        isParrain ? s.howItWorksParrainHeadline : s.howItWorksClientHeadline;
    final subtitle =
        isParrain ? s.howItWorksParrainSubtitle : s.howItWorksClientSubtitle;
    final videoUrl =
        isParrain ? s.howItWorksParrainVideoUrl : s.howItWorksClientVideoUrl;
    final icons = isParrain ? _parrainIcons : _clientIcons;
    final accent = isParrain ? AppColors.secondary : AppColors.primary;

    final isLast = _currentPage >= steps.length - 1;

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        title: Text(s.howItWorksTitle, style: AppTypography.h3),
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.md),

            // Track selector — only when the parrain track is available.
            if (allowParrain)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: _TrackSelector(
                  track: track,
                  clientLabel: s.howItWorksTrackClient,
                  parrainLabel: s.howItWorksTrackParrain,
                  onChanged: _switchTrack,
                ),
              ),

            // Headline + subtitle
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
              child: Column(
                children: [
                  Text(
                    headline,
                    style: AppTypography.h2.copyWith(fontSize: 22),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle,
                    style: AppTypography.bodyMedium
                        .copyWith(color: AppColors.textMuted, height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Optional video button (appears once a clip URL is set in copy).
            if (videoUrl != null) ...[
              const SizedBox(height: AppSpacing.md),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: _WatchVideoButton(
                  label: s.howItWorksWatchVideo,
                  accent: accent,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => _HowToVideoScreen(
                        url: videoUrl,
                        title: headline,
                      ),
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.md),

            // Swipeable step cards
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: steps.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (_, i) => _StepCard(
                  step: steps[i],
                  number: i + 1,
                  icon: icons[i % icons.length],
                  accent: accent,
                ),
              ),
            ),

            // Progress dots + step counter
            _PageDots(
              count: steps.length,
              current: _currentPage,
              accent: accent,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              s.howItWorksStepCounter(_currentPage + 1, steps.length),
              style: AppTypography.labelSmall
                  .copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: AppSpacing.md),

            // Bottom navigation buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _pageController.previousPage(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut,
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          side: BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Icon(Icons.arrow_back,
                            size: 20, color: AppColors.textSecondary),
                      ),
                    ),
                  if (_currentPage > 0)
                    const SizedBox(width: AppSpacing.md),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        if (isLast) {
                          Navigator.of(context).maybePop();
                        } else {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOut,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(52),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        isLast ? s.howItWorksGotIt : s.howItWorksNext,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Track selector (segmented control)
// ─────────────────────────────────────────────

class _TrackSelector extends StatelessWidget {
  final HowToTrack track;
  final String clientLabel;
  final String parrainLabel;
  final ValueChanged<HowToTrack> onChanged;

  const _TrackSelector({
    required this.track,
    required this.clientLabel,
    required this.parrainLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.backgroundGrey,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _segment(HowToTrack.client, clientLabel, AppColors.primary),
          _segment(HowToTrack.parrain, parrainLabel, AppColors.secondary),
        ],
      ),
    );
  }

  Widget _segment(HowToTrack value, String label, Color accent) {
    final selected = track == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(value),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? accent : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            label,
            style: AppTypography.labelMedium.copyWith(
              color: selected ? Colors.white : AppColors.textSecondary,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Step card
// ─────────────────────────────────────────────

class _StepCard extends StatelessWidget {
  final HowToStep step;
  final int number;
  final IconData icon;
  final Color accent;

  const _StepCard({
    required this.step,
    required this.number,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: AppSpacing.md),
          // Illustration: layered circle + icon + step number badge
          SizedBox(
            width: 160,
            height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                ),
                Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                ),
                Icon(icon, size: 52, color: accent),
                Positioned(
                  top: 12,
                  right: 18,
                  child: Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: AppColors.backgroundWhite, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      '$number',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            step.title,
            style: AppTypography.h3,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            step.body,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Page dots
// ─────────────────────────────────────────────

class _PageDots extends StatelessWidget {
  final int count;
  final int current;
  final Color accent;

  const _PageDots({
    required this.count,
    required this.current,
    required this.accent,
  });

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

// ─────────────────────────────────────────────
// Watch-video button
// ─────────────────────────────────────────────

class _WatchVideoButton extends StatelessWidget {
  final String label;
  final Color accent;
  final VoidCallback onTap;

  const _WatchVideoButton({
    required this.label,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(Icons.play_circle_outline, size: 20, color: accent),
      label: Text(
        label,
        style: AppTypography.labelMedium
            .copyWith(color: accent, fontWeight: FontWeight.w600),
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        side: BorderSide(color: accent.withValues(alpha: 0.5), width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// In-app tutorial video player
// ─────────────────────────────────────────────

class _HowToVideoScreen extends ConsumerStatefulWidget {
  final String url;
  final String title;

  const _HowToVideoScreen({required this.url, required this.title});

  @override
  ConsumerState<_HowToVideoScreen> createState() => _HowToVideoScreenState();
}

class _HowToVideoScreenState extends ConsumerState<_HowToVideoScreen> {
  VideoPlayerController? _controller;
  bool _initFailed = false;

  @override
  void initState() {
    super.initState();
    final controller =
        VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _controller = controller;
    controller.initialize().then((_) {
      if (!mounted) return;
      setState(() {});
      controller.play();
    }).catchError((_) {
      if (!mounted) return;
      setState(() => _initFailed = true);
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final controller = _controller;
    final ready = controller != null && controller.value.isInitialized;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.title,
            style: AppTypography.h4.copyWith(color: Colors.white)),
      ),
      body: Center(
        child: _initFailed
            ? Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Text(
                  s.genericError,
                  style: AppTypography.bodyMedium
                      .copyWith(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              )
            : ready
                ? AspectRatio(
                    aspectRatio: controller.value.aspectRatio,
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        GestureDetector(
                          onTap: () => setState(() {
                            controller.value.isPlaying
                                ? controller.pause()
                                : controller.play();
                          }),
                          child: VideoPlayer(controller),
                        ),
                        VideoProgressIndicator(
                          controller,
                          allowScrubbing: true,
                          colors: const VideoProgressColors(
                            playedColor: AppColors.secondary,
                          ),
                        ),
                        if (!controller.value.isPlaying)
                          const Icon(Icons.play_circle_fill,
                              size: 64, color: Colors.white70),
                      ],
                    ),
                  )
                : const CircularProgressIndicator(
                    color: AppColors.secondary),
      ),
    );
  }
}

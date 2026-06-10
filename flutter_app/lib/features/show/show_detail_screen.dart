import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart' as dio_pkg;
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:aji_tfarraj/app/routes.dart';
import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';
import 'package:aji_tfarraj/app/design_system/states.dart';
import 'package:aji_tfarraj/app/design_system/loaders.dart';
import 'package:aji_tfarraj/app/localization/locale_provider.dart';
import 'package:aji_tfarraj/app/network/api_client.dart';
import 'package:aji_tfarraj/app/analytics/analytics_service.dart';
import 'package:aji_tfarraj/features/auth/data/auth_repository.dart';
import 'package:share_plus/share_plus.dart';
import 'package:aji_tfarraj/features/shows/data/shows_repository.dart';
import 'package:aji_tfarraj/features/shows/domain/show.dart';
import 'package:aji_tfarraj/features/shows/domain/episode.dart';
import 'package:aji_tfarraj/features/referral/data/referral_repository.dart';

/// Show Detail Screen — premium cinematic layout
class ShowDetailScreen extends ConsumerStatefulWidget {
  final String showId;

  const ShowDetailScreen({super.key, required this.showId});

  @override
  ConsumerState<ShowDetailScreen> createState() => _ShowDetailScreenState();
}

class _ShowDetailScreenState extends ConsumerState<ShowDetailScreen> {
  bool _viewEventFired = false;

  @override
  Widget build(BuildContext context) {
    final showAsync = ref.watch(showDetailProvider(int.parse(widget.showId)));

    ref.listen(showDetailProvider(int.parse(widget.showId)), (_, next) {
      if (!_viewEventFired) {
        next.whenData((show) {
          _viewEventFired = true;
          ref.read(analyticsServiceProvider).logViewShow(
                showId: show.id,
                showTitle: show.title,
              );
        });
      }
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      body: showAsync.when(
        loading: () => const _ShowDetailSkeleton(),
        error: (error, _) => _ErrorView(
          message: error.toString(),
          onRetry: () =>
              ref.refresh(showDetailProvider(int.parse(widget.showId))),
          onBack: () => _goBack(context),
        ),
        data: (show) => _ShowDetailContent(show: show, showId: widget.showId),
      ),
    );
  }

  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.home);
    }
  }
}

// ─────────────────────────────────────────────────────
// Main Content
// ─────────────────────────────────────────────────────

class _ShowDetailContent extends ConsumerWidget {
  final Show show;
  final String showId;

  const _ShowDetailContent({required this.show, required this.showId});

  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.home);
    }
  }

  void _showProfileIncompleteDialog(BuildContext context, WidgetRef ref) {
    final s = ref.read(stringsProvider);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.profileIncompleteWarning),
        content: Text(s.profileIncompleteMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.push(Routes.editProfile);
            },
            child: Text(s.completeProfileButton),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAr = ref.watch(isRtlProvider);
    final s = ref.watch(stringsProvider);
    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _HeroSection(
                show: show,
                onBack: () => _goBack(context),
                isAr: isAr,
                dateTbc: s.homeDateTbc,
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
                child: _SeatsCard(show: show),
              ),
            ),
            // Episodes section
            if (show.episodes.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
                  child: _EpisodesSection(show: show, showId: showId),
                ),
              ),
            if (show.localizedDescription(isAr) != null && show.localizedDescription(isAr)!.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
                  child: _DescriptionCard(description: show.localizedDescription(isAr)!),
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
                child: _DetailsCard(show: show),
              ),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
                child: _RulesCard(),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),

        // Sticky bottom CTA
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _StickyReserveCTA(
            show: show,
            onReserve: () {
              final user = ref.read(loginAuthStateProvider).user;
              // Block only if the server explicitly lists missing required
              // fields. An empty missingProfileFields with profileComplete=false
              // indicates a backend computation lag — let the user through.
              final missingRequired = user?.missingProfileFields
                      .where((f) => f != 'avatar' && f != 'avatar_url')
                      .isNotEmpty ??
                  false;
              if (user != null && !user.profileComplete && missingRequired) {
                _showProfileIncompleteDialog(context, ref);
              } else if (show.nextEpisode != null) {
                context.go(Routes.episodeReserve(
                    showId, show.nextEpisode!.id.toString()));
              } else {
                context.go(Routes.showReserve(showId));
              }
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────
// Hero Section
// ─────────────────────────────────────────────────────

class _HeroSection extends StatefulWidget {
  final Show show;
  final VoidCallback onBack;
  final bool isAr;
  final String dateTbc;

  const _HeroSection({
    required this.show,
    required this.onBack,
    required this.isAr,
    required this.dateTbc,
  });

  @override
  State<_HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<_HeroSection> with WidgetsBindingObserver {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isPlaying = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pause when app goes to background
    if (state != AppLifecycleState.resumed && _isPlaying) {
      _videoController?.pause();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Pause when widget goes offstage (tab switch in IndexedStack)
    if (!TickerMode.of(context) && _isPlaying) {
      _videoController?.pause();
    }
  }

  @override
  void deactivate() {
    _videoController?.pause();
    super.deactivate();
  }

  Future<void> _startVideo() async {
    final url = widget.show.videoUrl!;

    setState(() => _isLoading = true);

    try {
      // Download to temp file to avoid iOS byte-range issues with the server
      final tmpDir = await getTemporaryDirectory();
      final fileName = url.split('/').last;
      final filePath = '${tmpDir.path}/$fileName';
      final file = File(filePath);

      if (!file.existsSync()) {
        debugPrint('[Video] Downloading: $url');
        await dio_pkg.Dio().download(url, filePath);
        debugPrint('[Video] Downloaded to: $filePath');
      }

      if (!mounted) return;

      final vpc = VideoPlayerController.file(file);
      await vpc.initialize();

      final chewie = ChewieController(
        videoPlayerController: vpc,
        autoPlay: true,
        aspectRatio: vpc.value.aspectRatio,
        allowFullScreen: true,
        showControls: true,
      );

      if (!mounted) {
        vpc.dispose();
        chewie.dispose();
        return;
      }

      setState(() {
        _videoController = vpc;
        _chewieController = chewie;
        _isPlaying = true;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('[Video] Error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _stopVideo() {
    _chewieController?.dispose();
    _videoController?.dispose();
    setState(() {
      _chewieController = null;
      _videoController = null;
      _isPlaying = false;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final show = widget.show;
    final isAr = widget.isAr;
    final fallbackDateFormat = DateFormat('EEE d MMM • HH:mm', 'fr_FR');
    final dateTbc = widget.dateTbc;

    return SizedBox(
      height: 380,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background — video player or image
          if (_isPlaying && _chewieController != null)
            Chewie(controller: _chewieController!)
          else ...[
            // Background image
            show.imageUrl != null
                ? Image.network(
                    show.imageUrl!,
                    fit: BoxFit.cover,
                    loadingBuilder: (_, child, progress) =>
                        progress == null ? child : Container(color: AppColors.backgroundGrey),
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.backgroundGrey,
                      child: Center(
                        child: Icon(Icons.tv, size: 64, color: AppColors.textLight),
                      ),
                    ),
                  )
                : Container(
                    color: AppColors.backgroundGrey,
                    child: Center(
                      child: Icon(Icons.tv, size: 64, color: AppColors.textLight),
                    ),
                  ),

            // Top gradient
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment(0, 0.35),
                  colors: [Color(0xCC000000), Colors.transparent],
                ),
              ),
            ),

            // FIX: Hero gradient — 50% coverage, 4-stop smooth, theme-aware
            Builder(builder: (context) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              final bottomColor =
                  isDark ? const Color(0xFF0C0C0C) : const Color(0xFFFAFAFA);
              return DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.center,
                    colors: [
                      bottomColor,
                      bottomColor.withValues(alpha: 0.80),
                      bottomColor.withValues(alpha: 0.30),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.33, 0.66, 1.0],
                  ),
                ),
              );
            }),

            // Play button — center (only when video available)
            if (show.videoUrl != null)
              Positioned.fill(
                child: Center(
                  child: GestureDetector(
                    onTap: _isLoading ? null : _startVideo,
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 40,
                            ),
                    ),
                  ),
                ),
              ),
          ],

          // FIX: Back button — frosted glass (white 20% opacity), size 36
          Positioned(
            top: MediaQuery.of(context).padding.top + AppSpacing.sm,
            left: AppSpacing.md,
            child: Material(
              color: Colors.white.withValues(alpha: 0.20),
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () {
                  if (_isPlaying) {
                    _stopVideo();
                  } else {
                    widget.onBack();
                  }
                },
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: Icon(
                    _isPlaying ? Icons.close : Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
          ),

          // FIX: Channel badge — primary 85% opacity, secondaryLight icon, white text
          if (show.channel != null && !_isPlaying)
            Positioned(
              top: MediaQuery.of(context).padding.top + AppSpacing.sm,
              right: AppSpacing.md,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.tv_rounded,
                        size: 13, color: AppColors.secondaryLight),
                    const SizedBox(width: 4),
                    Text(
                      show.localizedChannel(isAr) ?? show.channel!,
                      style: AppTypography.labelSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Info overlay — bottom
          Positioned(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: AppSpacing.xl,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // FIX: Hero title — 22px w700, text shadow, Cairo for AR
                Text(
                  show.localizedTitle(widget.isAr),
                  style: (widget.isAr
                          ? AppTypography.h1Ar
                          : AppTypography.h1)
                      .copyWith(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.40),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.sm),
                // FIX: Date/location — secondary icons, textSecondary text, 13px
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        size: 13, color: AppColors.secondary),
                    const SizedBox(width: 5),
                    Text(
                      show.localizedDate(isAr) ??
                          (show.startsAt != null
                              ? fallbackDateFormat.format(show.startsAt!.toLocal())
                              : dateTbc),
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Icon(Icons.location_on_outlined,
                        size: 13, color: AppColors.secondary),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        show.nextEpisode?.localizedCity(isAr) ?? show.city,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// Seats Card
// ─────────────────────────────────────────────────────

class _SeatsCard extends ConsumerWidget {
  final Show show;

  const _SeatsCard({required this.show});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final progress =
        show.capacity > 0 ? show.reservedSeats / show.capacity : 0.0;
    final isSoldOut = show.isSoldOut;

    // FIX: Seats card — cardDarkElevated, radius 16, shadow, brand colors
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.cardDarkElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A1A1A).withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // FIX: Percentage badge — primary circle (40×40), white text
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSoldOut ? AppColors.error : AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${(progress * 100).round()}%',
                    style: AppTypography.labelSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // FIX: Available seats text — secondary color, w700
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSoldOut
                          ? s.showDetailSoldOut
                          : s.showDetailAvailableSeats(show.availableSeats),
                      style: AppTypography.labelLarge.copyWith(
                        color:
                            isSoldOut ? AppColors.error : AppColors.secondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      s.showDetailReservations(
                          show.reservedSeats, show.capacity),
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // FIX: Seat icon — secondary bg, primaryDark icon, radius 12
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSoldOut ? AppColors.errorLight : AppColors.secondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isSoldOut
                      ? Icons.event_busy_outlined
                      : Icons.event_seat_outlined,
                  color: isSoldOut ? AppColors.error : AppColors.primaryDark,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // FIX: Progress bar — gradient primary→secondary, height 6, radius 8
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: progress.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: isSoldOut
                        ? null
                        : const LinearGradient(
                            colors: [AppColors.primary, AppColors.secondary],
                          ),
                    color: isSoldOut ? AppColors.error : null,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// Description Card (expandable)
// ─────────────────────────────────────────────────────

class _DescriptionCard extends ConsumerStatefulWidget {
  final String description;

  const _DescriptionCard({required this.description});

  @override
  ConsumerState<_DescriptionCard> createState() => _DescriptionCardState();
}

class _DescriptionCardState extends ConsumerState<_DescriptionCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.backgroundGrey,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  size: 16, color: AppColors.secondary),
              const SizedBox(width: AppSpacing.sm),
              Text(
                s.showDetailAbout,
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            widget.description,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
            maxLines: _expanded ? null : 3,
            overflow:
                _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
          ),
          if (widget.description.length > 120) ...[
            const SizedBox(height: AppSpacing.sm),
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Text(
                _expanded ? s.showDetailSeeLess : s.showDetailSeeMore,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// Details Card
// ─────────────────────────────────────────────────────

class _DetailsCard extends ConsumerWidget {
  final Show show;

  const _DetailsCard({required this.show});

  String _locationText(bool isAr) {
    final studio = show.nextEpisode?.localizedStudio(isAr) ?? show.studio;
    final city = show.nextEpisode?.localizedCity(isAr) ?? show.city;
    if (studio != null && studio.isNotEmpty) {
      return '$studio, $city';
    }
    return city;
  }

  Future<void> _openInMaps(bool isAr) async {
    final query = Uri.encodeComponent(_locationText(isAr));
    final url = Uri.parse('https://maps.google.com/?q=$query');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final isAr = ref.watch(isRtlProvider);
    final fallbackDateFormat = DateFormat('EEEE dd MMMM yyyy', 'fr_FR');
    final timeFormat = DateFormat('HH:mm', 'fr_FR');

    // Use backend preformatted date_fr/date_ar; split time from date_fr for time row
    final localizedDateStr = show.localizedDate(isAr);
    final hasDate = localizedDateStr != null || show.startsAt != null;
    final dateValue = localizedDateStr ??
        (show.startsAt != null
            ? fallbackDateFormat.format(show.startsAt!.toLocal())
            : s.homeDateTbc);
    final timeValue = show.startsAt != null
        ? timeFormat.format(show.startsAt!.toLocal())
        : (hasDate ? '—' : s.homeDateTbc);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundGrey,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _DetailRow(
            icon: Icons.calendar_today_outlined,
            label: s.showDetailDateLabel,
            value: dateValue,
            isFirst: true,
          ),
          _RowDivider(),
          _DetailRow(
            icon: Icons.access_time_rounded,
            label: s.showDetailTimeLabel,
            value: timeValue,
          ),
          _RowDivider(),
          _DetailRow(
            icon: Icons.location_on_outlined,
            label: s.showDetailLocationLabel,
            value: _locationText(isAr),
            trailing: GestureDetector(
              onTap: () => _openInMaps(isAr),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.backgroundWhite,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusFull),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.map_outlined,
                        size: 12, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      'Maps',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (show.channel != null) ...[
            _RowDivider(),
            _DetailRow(
              icon: Icons.tv_rounded,
              label: s.showDetailChannelLabel,
              value: show.channel!,
              isLast: show.rewardPoints == null,
            ),
          ],
          if (show.rewardPoints != null) ...[
            _RowDivider(),
            _DetailRow(
              icon: Icons.star_rounded,
              label: s.showDetailLoyaltyPointsLabel,
              value: s.showDetailLoyaltyPointsValue(
                  show.effectiveRewardPoints),
              valueColor: AppColors.secondary,
              isLast: true,
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final Widget? trailing;
  final bool isFirst;
  final bool isLast;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.trailing,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        isFirst ? AppSpacing.lg : AppSpacing.md,
        AppSpacing.lg,
        isLast ? AppSpacing.lg : AppSpacing.md,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.backgroundWhite,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(icon, color: AppColors.secondary, size: 18),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTypography.bodyMedium.copyWith(
                    color: valueColor ?? AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _RowDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 0.5,
      color: AppColors.border,
      indent: AppSpacing.lg,
      endIndent: AppSpacing.lg,
    );
  }
}

// ─────────────────────────────────────────────────────
// Rules Card (collapsible)
// ─────────────────────────────────────────────────────

class _RulesCard extends ConsumerStatefulWidget {
  const _RulesCard();

  @override
  ConsumerState<_RulesCard> createState() => _RulesCardState();
}

class _RulesCardState extends ConsumerState<_RulesCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundGrey,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Tappable header
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.backgroundWhite,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: const Icon(Icons.shield_outlined,
                        color: AppColors.secondary, size: 18),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      s.showDetailRulesTitle,
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textLight, size: 22),
                  ),
                ],
              ),
            ),
          ),

          // Collapsible body
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Divider(height: 1, color: AppColors.border),
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg,
                      AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.rulesIntroduction,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textMuted,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      ...s.rulesItems.asMap().entries.map((entry) {
                        final i = entry.key;
                        final rule = entry.value;
                        return Padding(
                          padding:
                              const EdgeInsets.only(bottom: AppSpacing.md),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: AppColors.secondary
                                      .withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${i + 1}',
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.secondary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      rule.title,
                                      style:
                                          AppTypography.labelMedium.copyWith(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      rule.description,
                                      style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.textMuted,
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// Sticky Reserve CTA
// ─────────────────────────────────────────────────────

class _StickyReserveCTA extends ConsumerStatefulWidget {
  final Show show;
  final VoidCallback onReserve;

  const _StickyReserveCTA({required this.show, required this.onReserve});

  @override
  ConsumerState<_StickyReserveCTA> createState() => _StickyReserveCTAState();
}

class _StickyReserveCTAState extends ConsumerState<_StickyReserveCTA> {
  bool _isSharing = false;

  Future<void> _shareShow() async {
    setState(() => _isSharing = true);
    final s = ref.read(stringsProvider);
    try {
      // 1. Generate (or fetch) the referral link — repo always throws ApiException.
      final repo = ref.read(referralRepositoryProvider);
      final link = await repo.generateLink(showId: widget.show.id);
      if (!mounted) return;
      // 2. Open the share sheet. Dismissing it returns ShareResult.dismissed
      //    (no throw) — a dismiss must NOT surface an error. iPad requires a
      //    popover anchor (sharePositionOrigin); it's harmless on iPhone.
      final box = context.findRenderObject() as RenderBox?;
      final origin = box != null && box.hasSize
          ? box.localToGlobal(Offset.zero) & box.size
          : null;
      await Share.share(
        s.referralShareMessage(
            widget.show.localizedTitle(ref.read(isRtlProvider)), link.referralLink),
        sharePositionOrigin: origin,
      );
    } catch (e) {
      // Show the REAL error class: 401 → session expired, 429 → rate limit,
      // parse / share-sheet failure → generic. Never blanket "no internet".
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiException.from(e).userMessage(s))),
      );
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final show = widget.show;
    final episode = show.nextEpisode;
    final isSoldOut = episode?.isSoldOut ?? show.isSoldOut;

    // FIX: Bottom bar — backgroundLight, 12px h-padding, 8px v-padding
    return Container(
      padding: EdgeInsets.fromLTRB(
        12,
        8,
        12,
        MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Reward points badge
            if (!isSoldOut && (episode?.rewardPoints ?? show.rewardPoints) != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.12),
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(
                      color: AppColors.secondary.withValues(alpha: 0.3)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded,
                        color: AppColors.secondary, size: 18),
                    const SizedBox(height: 2),
                    Text(
                      '+${episode?.effectiveRewardPoints ?? show.effectiveRewardPoints}',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
            ],

            // Main button
            Expanded(
              child: SizedBox(
                height: 52,
                child: isSoldOut
                    ? OutlinedButton.icon(
                        onPressed: null,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                              color: AppColors.border, width: 1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                AppSpacing.radiusMd),
                          ),
                        ),
                        icon: Icon(Icons.event_busy_outlined,
                            size: 18, color: AppColors.textLight),
                        label: Text(
                          s.showDetailSoldOutCta,
                          style: AppTypography.buttonLarge
                              .copyWith(color: AppColors.textLight),
                        ),
                      )
                    // FIX: Main CTA — primary bg, white, radius 14, shadow
                    : Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  AppColors.primary.withValues(alpha: 0.30),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: FilledButton.icon(
                          onPressed: widget.onReserve,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            minimumSize:
                                const Size(double.infinity, 52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(
                            Icons.confirmation_number_outlined,
                            size: 18,
                            color: Colors.white,
                          ),
                          label: Text(
                            s.showDetailReserveNow,
                            style: AppTypography.buttonLarge.copyWith(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
              ),
            ),

            // FIX: Share button — backgroundGrey bg, textSecondary icon, radius 12
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _isSharing ? null : _shareShow,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.backgroundGrey,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _isSharing
                    ? Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.textMuted,
                          ),
                        ),
                      )
                    : Icon(Icons.share_outlined,
                        size: 20, color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// Episodes Section
// ─────────────────────────────────────────────────────

class _EpisodesSection extends ConsumerWidget {
  final Show show;
  final String showId;

  const _EpisodesSection({required this.show, required this.showId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final now = DateTime.now();

    // Split into upcoming and past.
    // Episodes with no startsAt (unscheduled) go in upcoming — shown with "Coming Soon".
    final upcoming = show.episodes
        .where((e) => e.startsAt == null || (e.startsAt!.isAfter(now) && e.isActive))
        .toList()
      ..sort((a, b) {
        // Unscheduled episodes sort to the end of upcoming
        final aDate = a.startsAt ?? DateTime(9999);
        final bDate = b.startsAt ?? DateTime(9999);
        return aDate.compareTo(bDate);
      });
    final past = show.episodes
        .where((e) => e.startsAt != null && (!e.startsAt!.isAfter(now) || !e.isActive))
        .toList()
      ..sort((a, b) => b.startsAt!.compareTo(a.startsAt!));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // FIX: Episodes header — secondary icon, split title/count styling
        Row(
          children: [
            const Icon(Icons.video_library_outlined,
                size: 18, color: AppColors.secondary),
            const SizedBox(width: AppSpacing.sm),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: s.episodeSectionTitle,
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  TextSpan(
                    text: ' (${show.episodes.length})',
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w400,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // Upcoming episodes
        ...upcoming.map((episode) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _EpisodeCard(
                show: show,
                episode: episode,
                showId: showId,
                isPast: false,
              ),
            )),

        // Past episodes
        ...past.map((episode) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _EpisodeCard(
                show: show,
                episode: episode,
                showId: showId,
                isPast: true,
              ),
            )),
      ],
    );
  }
}

/// Compact share button on each upcoming episode card. Generates a referral
/// link scoped to the episode and opens the share sheet with an episode-specific
/// invite message.
class _EpisodeShareButton extends ConsumerStatefulWidget {
  final Show show;
  final Episode episode;

  const _EpisodeShareButton({required this.show, required this.episode});

  @override
  ConsumerState<_EpisodeShareButton> createState() =>
      _EpisodeShareButtonState();
}

class _EpisodeShareButtonState extends ConsumerState<_EpisodeShareButton> {
  bool _sharing = false;

  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    final s = ref.read(stringsProvider);
    final isAr = ref.read(isRtlProvider);
    try {
      final link = await ref.read(referralRepositoryProvider).generateLink(
            showId: widget.show.id,
            episodeId: widget.episode.id,
          );
      if (!mounted) return;
      final dateStr = widget.episode.localizedDate(isAr) ??
          (widget.episode.startsAt != null
              ? DateFormat('EEE d MMM • HH:mm', isAr ? 'ar' : 'fr_FR')
                  .format(widget.episode.startsAt!.toLocal())
              : s.homeDateTbc);
      final box = context.findRenderObject() as RenderBox?;
      final origin = box != null && box.hasSize
          ? box.localToGlobal(Offset.zero) & box.size
          : null;
      await Share.share(
        s.episodeShareMessage(
          widget.show.localizedTitle(isAr),
          widget.episode.label,
          dateStr,
          link.referralLink,
        ),
        sharePositionOrigin: origin,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiException.from(e).userMessage(s))),
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: _sharing ? null : _share,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.secondary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border:
                Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
          ),
          child: _sharing
              ? const Padding(
                  padding: EdgeInsets.all(9),
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.secondary),
                )
              : const Icon(Icons.share_outlined,
                  size: 18, color: AppColors.secondary),
        ),
      ),
    );
  }
}

class _EpisodeCard extends ConsumerWidget {
  final Show show;
  final Episode episode;
  final String showId;
  final bool isPast;

  const _EpisodeCard({
    required this.show,
    required this.episode,
    required this.showId,
    required this.isPast,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final isAr = ref.watch(isRtlProvider);
    final isSoldOut = episode.isSoldOut;
    final episodeDateStr = episode.localizedDate(isAr) ??
        (episode.startsAt != null
            ? DateFormat('EEE d MMM • HH:mm', 'fr_FR').format(episode.startsAt!.toLocal())
            : s.homeDateTbc);

    // FIX: Episode card — cardDarkElevated, radius 16, shadow, padding 14
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isPast
            ? AppColors.cardDarkElevated.withValues(alpha: 0.5)
            : AppColors.cardDarkElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPast
              ? AppColors.border.withValues(alpha: 0.5)
              : AppColors.border,
        ),
        boxShadow: isPast
            ? null
            : [
                BoxShadow(
                  color: const Color(0xFF1A1A1A).withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Row(
        children: [
          // Episode info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  episode.label,
                  style: AppTypography.labelLarge.copyWith(
                    color: isPast ? AppColors.textLight : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    // FIX: Calendar icon — secondary when active
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 12,
                      color: isPast ? AppColors.textLight : AppColors.secondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        episodeDateStr,
                        style: AppTypography.caption.copyWith(
                          color:
                              isPast ? AppColors.textLight : AppColors.textMuted,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    // FIX: Location icon — secondary when active
                    Icon(
                      Icons.location_on_outlined,
                      size: 12,
                      color: isPast ? AppColors.textLight : AppColors.secondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        episode.localizedStudio(isAr) != null
                            ? '${episode.localizedStudio(isAr)}, ${episode.localizedCity(isAr)}'
                            : episode.localizedCity(isAr),
                        style: AppTypography.caption.copyWith(
                          color:
                              isPast ? AppColors.textLight : AppColors.textMuted,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Per-episode share — invite friends to join this upcoming episode
          if (!isPast && !isSoldOut) ...[
            const SizedBox(width: AppSpacing.sm),
            _EpisodeShareButton(show: show, episode: episode),
          ],

          const SizedBox(width: AppSpacing.sm),

          // Status + action
          if (isPast)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.border.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Text(
                s.pastEpisodeLabel,
                style: AppTypography.caption
                    .copyWith(color: AppColors.textLight),
              ),
            )
          else if (isSoldOut)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Text(
                s.episodeSoldOut,
                style: AppTypography.caption
                    .copyWith(color: AppColors.error, fontWeight: FontWeight.w600),
              ),
            )
          else
            Flexible(
              flex: 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // FIX: Seats count — secondary color, w600, 12px
                  Text(
                    s.episodeAvailableSeats(episode.availableSeats),
                    style: AppTypography.caption.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.end,
                  ),
                  const SizedBox(height: 6),
                  // FIX: Episode reserve button — primary bg, white, shadow
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: FilledButton(
                      onPressed: () => context.go(Routes.episodeReserve(
                          showId, episode.id.toString())),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        s.reserveEpisode,
                        style: AppTypography.labelSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// Skeleton Loading
// ─────────────────────────────────────────────────────

class _ShowDetailSkeleton extends StatelessWidget {
  const _ShowDetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonLoader.card(height: 380, width: double.infinity),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLoader.card(height: 80),
                const SizedBox(height: AppSpacing.lg),
                SkeletonLoader.card(height: 200),
                const SizedBox(height: AppSpacing.lg),
                SkeletonLoader.card(height: 60),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// Error View
// ─────────────────────────────────────────────────────

class _ErrorView extends ConsumerWidget {
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  const _ErrorView({
    required this.message,
    required this.onRetry,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    return SafeArea(
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: GestureDetector(
                onTap: onBack,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundGrey,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Icon(Icons.arrow_back_ios_new,
                      color: AppColors.textPrimary, size: 16),
                ),
              ),
            ),
          ),
          Expanded(
            child: ErrorState(
              message: message,
              retryText: s.retry,
              onRetry: onRetry,
            ),
          ),
        ],
      ),
    );
  }
}

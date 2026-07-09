import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:aji_tfarraj/app/routes.dart';
import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';
import 'package:aji_tfarraj/app/design_system/states.dart';
import 'package:aji_tfarraj/app/design_system/loaders.dart';
import 'package:aji_tfarraj/features/shows/data/shows_repository.dart';
import 'package:aji_tfarraj/features/shows/domain/show.dart';
import 'package:aji_tfarraj/app/localization/app_locale.dart';
import 'package:aji_tfarraj/app/localization/locale_provider.dart';
import 'package:aji_tfarraj/app/localization/strings.dart';
import 'package:aji_tfarraj/features/notifications/presentation/providers/notifications_provider.dart';
import 'package:aji_tfarraj/features/referral/data/referral_repository.dart'
    show pendingNavigationProvider;
import 'package:aji_tfarraj/features/support/presentation/screens/support_tickets_screen.dart';

/// Home Screen — Cinematic discovery layout inspired by premium streaming apps
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // If the user arrived here after following a referral deep link while
    // logged out, a pending destination route was stored before auth redirect.
    // Navigate there now that the shell is fully initialized — doing it in the
    // redirect itself causes StatefulShellRoute to reset the branch to /home.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final pending = ref.read(pendingNavigationProvider);
      if (pending != null) {
        ref.read(pendingNavigationProvider.notifier).state = null;
        context.go(pending);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(showsListProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final showsState = ref.watch(showsListProvider);
    final unreadCount = ref.watch(unreadNotificationsCountProvider);
    final s = ref.watch(stringsProvider);
    final isAr = ref.watch(isRtlProvider);
    final locale = ref.watch(localeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final logo = locale == AppLocale.ar
        ? (isDark ? 'assets/images/ajitfarraj_logo/white_ar_logo.png' : 'assets/images/ajitfarraj_logo/black_ar_logo.png')
        : (isDark ? 'assets/images/ajitfarraj_logo/white_fr_logo.png' : 'assets/images/ajitfarraj_logo/black_fr_logo.png');

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(unreadCount, s, logo),
      body: _buildBody(showsState, s, isAr),
    );
  }

  PreferredSizeWidget _buildAppBar(int unreadCount, AppStrings s, String logo) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xE6000000), // 90% black
              Colors.transparent,
            ],
          ),
        ),
      ),
      title: Image.asset(
        logo,
        height: 130,
        fit: BoxFit.contain,
        alignment: Alignment.centerLeft,
      ),
      leading: IconButton(
        icon: const Icon(Icons.headset_mic_outlined, color: Colors.white),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SupportTicketsScreen()),
        ),
      ),
      actions: [
        _NotificationBellButton(unreadCount: unreadCount, s: s),
        const SizedBox(width: AppSpacing.xs),
      ],
    );
  }

  Widget _buildBody(ShowsListState showsState, AppStrings s, bool isAr) {
    if (showsState.isLoading) {
      return const _HomeLoadingSkeleton();
    }

    if (showsState.error != null) {
      return ErrorState(
        message: showsState.error!,
        retryText: s.retry,
        onRetry: () => ref.read(showsListProvider.notifier).refresh(),
      );
    }

    final allShows = showsState.items;

    if (allShows.isEmpty) {
      return EmptyState.noShows(
        onAction: () => ref.read(showsListProvider.notifier).refresh(),
      );
    }

    final now = DateTime.now();
    final upcoming60Days = now.add(const Duration(days: 60));

    // Effective date helper: prefer next episode date, fall back to top-level
    DateTime? effectiveDate(Show show) =>
        show.nextEpisode?.startsAt ?? show.startsAt;

    // Hero show: first upcoming active show (prefer shows with upcoming episodes)
    final Show heroShow = allShows
        .where((show) {
          final date = effectiveDate(show);
          return date != null &&
              date.isAfter(now) &&
              show.isActive &&
              show.hasUpcomingEpisodes;
        })
        .fold<Show?>(null, (prev, show) {
          if (prev == null) return show;
          return effectiveDate(show)!.isBefore(effectiveDate(prev)!)
              ? show
              : prev;
        }) ??
        // Fallback: any active upcoming show (backward compat)
        allShows
            .where((show) {
              final date = effectiveDate(show);
              return date != null && date.isAfter(now) && show.isActive;
            })
            .fold<Show?>(null, (prev, show) {
          if (prev == null) return show;
          return effectiveDate(show)!.isBefore(effectiveDate(prev)!)
              ? show
              : prev;
        }) ??
        // No dated upcoming show at all (e.g. everything is "Date à confirmer").
        // Still surface a hero so the home doesn't open on a cramped section
        // header — prefer the most-reserved active show, else just the first.
        (List<Show>.from(allShows)
              ..sort((a, b) => b.reservedSeats.compareTo(a.reservedSeats)))
            .firstWhere((show) => show.isActive, orElse: () => allShows.first);

    // Upcoming within 60 days, excluding hero
    final prochains = allShows
        .where(
          (show) {
            final date = effectiveDate(show);
            return date != null &&
                date.isAfter(now) &&
                date.isBefore(upcoming60Days) &&
                show.isActive &&
                show.id != heroShow.id;
          },
        )
        .toList()
      ..sort((a, b) =>
          (effectiveDate(a) ?? now).compareTo(effectiveDate(b) ?? now));

    // Beyond 60 days or inactive
    final bientot = allShows
        .where((show) {
          final date = effectiveDate(show);
          return show.id != heroShow.id &&
              (!show.isActive ||
                  date == null ||
                  date.isAfter(upcoming60Days));
        })
        .toList()
      ..sort((a, b) =>
          (effectiveDate(a) ?? now).compareTo(effectiveDate(b) ?? now));

    // Sorted by reserved seats descending (excluding the hero to avoid showing
    // the same show twice when it was chosen as a fallback hero)
    final populaires = allShows
        .where((show) => show.id != heroShow.id)
        .toList()
      ..sort((a, b) => b.reservedSeats.compareTo(a.reservedSeats));

    return RefreshIndicator(
      onRefresh: () => ref.read(showsListProvider.notifier).refresh(),
      color: AppColors.secondary,
      backgroundColor: AppColors.backgroundGrey,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Hero show — always present (falls back to a popular show when nothing
          // has a confirmed date) so the home never opens on a bare header.
          SliverToBoxAdapter(child: _HeroShowCard(show: heroShow, s: s, isAr: isAr)),

          // Upcoming section
          if (prochains.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: s.homeSectionUpcoming,
                seeAllText: s.seeAll,
                onSeeAll: () => context.push(Routes.browse),
              ),
            ),
            SliverToBoxAdapter(
              child: _ShowsHorizontalSection(shows: prochains, s: s, isAr: isAr),
            ),
          ],

          // Coming soon section
          if (bientot.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: s.homeSectionComingSoon,
                seeAllText: s.seeAll,
                onSeeAll: () => context.push(Routes.browse),
              ),
            ),
            SliverToBoxAdapter(
              child: _ShowsHorizontalSection(
                shows: bientot,
                isComingSoon: true,
                s: s,
                isAr: isAr,
              ),
            ),
          ],

          // Popular section
          if (populaires.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: s.homeSectionPopular,
                seeAllText: s.seeAll,
                onSeeAll: () => context.push(Routes.browse),
              ),
            ),
            SliverToBoxAdapter(
              child: _ShowsHorizontalSection(
                shows: populaires.take(10).toList(),
                s: s,
                isAr: isAr,
              ),
            ),
          ],

          // FIX: Bottom padding — 16px before bottom nav
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// Hero Show Card
// ─────────────────────────────────────────────────────

class _HeroShowCard extends StatelessWidget {
  final Show show;
  final AppStrings s;
  final bool isAr;

  const _HeroShowCard({required this.show, required this.s, required this.isAr});

  @override
  Widget build(BuildContext context) {
    final fallbackDateFormat = DateFormat('EEE d MMM • HH:mm', 'fr_FR');
    final dateStr = show.localizedDate(isAr) ??
        (show.startsAt != null
            ? fallbackDateFormat.format(show.startsAt!.toLocal())
            : s.homeDateTbc);

    return GestureDetector(
      onTap: () => context.push(Routes.showDetail(show.id.toString())),
      child: SizedBox(
        height: 420,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background image
            show.imageUrl != null
                ? Image.network(
                    show.imageUrl!,
                    fit: BoxFit.cover,
                    loadingBuilder: (_, child, progress) =>
                        progress == null ? child : Container(color: AppColors.backgroundGrey),
                    errorBuilder: (_, __, ___) => _HeroPlaceholder(),
                  )
                : _HeroPlaceholder(),

            // Gradient overlay — top (for AppBar legibility)
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment(0, 0.3),
                  colors: [Color(0xCC000000), Colors.transparent],
                ),
              ),
            ),

            // FIX: Hero gradient — smooth 55% coverage, theme-aware bottom color
            Builder(
              builder: (context) {
                final isDark = Theme.of(context).brightness == Brightness.dark;
                final bottomColor =
                    isDark ? const Color(0xFF0C0C0C) : const Color(0xFFFAFAFA);
                return DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: const Alignment(0, -0.1),
                      colors: [
                        bottomColor,
                        bottomColor.withValues(alpha: 0.85),
                        bottomColor.withValues(alpha: 0.50),
                        bottomColor.withValues(alpha: 0.15),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.25, 0.50, 0.75, 1.0],
                    ),
                  ),
                );
              },
            ),

            // Content at bottom
            Positioned(
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              bottom: AppSpacing.xl,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // FIX: Channel tag — unified primary semi-transparent style (hero)
                  if (show.channel != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        (show.localizedChannel(isAr) ?? show.channel!).toUpperCase(),
                        style: AppTypography.labelSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),

                  // Title — Cairo for AR (proper shaping), Inter for FR
                  Text(
                    show.localizedTitle(isAr),
                    style: (isAr ? AppTypography.h1Ar : AppTypography.h1)
                        .copyWith(color: Colors.white, height: 1.1),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // FIX: Date/location row — secondary icons, textSecondary text, 12px
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 13,
                        color: AppColors.secondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        dateStr,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Icon(
                        Icons.location_on_outlined,
                        size: 13,
                        color: AppColors.secondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        show.nextEpisode?.localizedCity(isAr) ?? show.city,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // FIX: CTA button — primary bg, white text, shadow, height 52, radius 14
                  // FIX: Seats badge — secondary bg, primaryDark text, radius 12
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.30),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: FilledButton.icon(
                            onPressed: () => context.push(
                              Routes.showDetail(show.id.toString()),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.zero,
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
                              show.isSoldOut ? s.homeSoldOut : s.reserve,
                              style: AppTypography.buttonMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: AppSpacing.md),

                      if (!show.isSoldOut)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.event_seat_outlined,
                                size: 15,
                                color: AppColors.primaryDark,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '${show.availableSeats}',
                                style: AppTypography.labelMedium.copyWith(
                                  color: AppColors.primaryDark,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
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

class _HeroPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.backgroundGrey,
      child: Center(
        child: Icon(Icons.tv, size: 64, color: AppColors.textLight),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// Section Header
// ─────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String seeAllText;
  final VoidCallback onSeeAll;

  const _SectionHeader({
    required this.title,
    required this.seeAllText,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.sm,
        AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: AppTypography.h3.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: onSeeAll,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.secondary,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            label: const Icon(Icons.chevron_right, size: 20),
            icon: Text(
              seeAllText,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.secondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// Horizontal Section
// ─────────────────────────────────────────────────────

class _ShowsHorizontalSection extends StatelessWidget {
  final List<Show> shows;
  final bool isComingSoon;
  final AppStrings s;
  final bool isAr;

  const _ShowsHorizontalSection({
    required this.shows,
    required this.s,
    required this.isAr,
    this.isComingSoon = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 240,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.sm,
        ),
        itemCount: shows.length,
        // FIX: Spacing — 14px gap between horizontal cards
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 14),
            child: _ShowHorizontalCard(
              show: shows[index],
              isComingSoon: isComingSoon,
              s: s,
              isAr: isAr,
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// Horizontal Show Card
// ─────────────────────────────────────────────────────

class _ShowHorizontalCard extends StatelessWidget {
  final Show show;
  final bool isComingSoon;
  final AppStrings s;
  final bool isAr;

  const _ShowHorizontalCard({
    required this.show,
    required this.s,
    required this.isAr,
    this.isComingSoon = false,
  });

  @override
  Widget build(BuildContext context) {
    final fallbackCardDateFormat = DateFormat('d MMM', 'fr_FR');
    final cardDateStr = show.localizedDate(isAr) ??
        (show.startsAt != null
            ? fallbackCardDateFormat.format(show.startsAt!.toLocal())
            : s.homeDateTbc);

    return GestureDetector(
      onTap: () => context.push(Routes.showDetail(show.id.toString())),
      child: SizedBox(
        width: 150,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // FIX: Show cards — card elevation shadow, borderRadius 16
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1A1A1A).withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                height: 170,
                width: 150,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Image
                    show.imageUrl != null
                        ? Image.network(
                            show.imageUrl!,
                            fit: BoxFit.cover,
                            loadingBuilder: (_, child, progress) =>
                                progress == null ? child : Container(color: AppColors.backgroundGrey),
                            errorBuilder: (_, __, ___) => Container(
                              color: AppColors.backgroundGrey,
                              child: Icon(
                                Icons.tv,
                                size: 32,
                                color: AppColors.textLight,
                              ),
                            ),
                          )
                        : Container(
                            color: AppColors.backgroundGrey,
                            child: Icon(
                              Icons.tv,
                              size: 32,
                              color: AppColors.textLight,
                            ),
                          ),

                    // Sold-out overlay
                    if (show.isSoldOut)
                      Container(
                        color: Colors.black54,
                        alignment: Alignment.center,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusSm,
                            ),
                          ),
                          child: Text(
                            s.homeSoldOutBadge,
                            style: AppTypography.labelSmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),

                    // Coming soon overlay
                    if (isComingSoon && !show.isSoldOut)
                      Positioned(
                        bottom: AppSpacing.sm,
                        left: AppSpacing.sm,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusSm,
                            ),
                          ),
                          child: Text(
                            s.homeComingSoonBadge,
                            style: AppTypography.labelSmall.copyWith(
                              color: Colors.black,
                              fontWeight: FontWeight.w700,
                              fontSize: 9,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),

                    // FIX: Channel tag — unified primary semi-transparent style (cards)
                    if (show.channel != null)
                      Positioned(
                        top: AppSpacing.sm,
                        right: AppSpacing.sm,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            (show.localizedChannel(isAr) ?? show.channel!).toUpperCase(),
                            style: AppTypography.caption.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ), // ClipRRect
          ), // Container shadow wrapper

            const SizedBox(height: AppSpacing.sm),

            // Title — Cairo for AR (proper shaping), Inter for FR
            Text(
              show.localizedTitle(isAr),
              style: (isAr ? AppTypography.bodyMediumAr : AppTypography.labelMedium)
                  .copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 2),

            // FIX: Cards date label — textMuted for consistent date styling
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 11,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(
                    isComingSoon && !show.isActive
                        ? s.homeDateTbc
                        : cardDateStr,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textMuted,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Episode count badge
                if (show.totalEpisodes > 1) ...[
                  const SizedBox(width: 4),
                  Text(
                    s.episodeCount(show.upcomingEpisodesCount),
                    style: AppTypography.caption.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// Notification Bell Button
// ─────────────────────────────────────────────────────

class _NotificationBellButton extends StatelessWidget {
  final int unreadCount;
  final AppStrings s;

  const _NotificationBellButton({required this.unreadCount, required this.s});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(
            Icons.notifications_outlined,
            color: Colors.white,
          ),
          if (unreadCount > 0)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.secondary,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                child: Text(
                  unreadCount > 99 ? '99+' : unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      tooltip: s.homeNotificationsTooltip,
      onPressed: () => context.push(Routes.notifications),
    );
  }
}

// ─────────────────────────────────────────────────────
// Loading Skeleton
// ─────────────────────────────────────────────────────

class _HomeLoadingSkeleton extends StatelessWidget {
  const _HomeLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero skeleton
          SkeletonLoader.card(height: 420, width: double.infinity),

          const SizedBox(height: AppSpacing.xl),

          // Section label
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: SkeletonLoader.text(width: 180, height: 20),
          ),

          const SizedBox(height: AppSpacing.md),

          // Horizontal cards skeleton
          SizedBox(
            height: 240,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              itemCount: 5,
              itemBuilder: (_, __) => Padding(
                padding: const EdgeInsets.only(right: AppSpacing.md),
                child: SkeletonLoader.card(width: 150, height: 170),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Second section label
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: SkeletonLoader.text(width: 140, height: 20),
          ),

          const SizedBox(height: AppSpacing.md),

          // Second horizontal cards skeleton
          SizedBox(
            height: 240,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              itemCount: 4,
              itemBuilder: (_, __) => Padding(
                padding: const EdgeInsets.only(right: AppSpacing.md),
                child: SkeletonLoader.card(width: 150, height: 170),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

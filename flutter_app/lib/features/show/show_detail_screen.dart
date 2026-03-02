import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:aji_tfarraj/app/routes.dart';
import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';
import 'package:aji_tfarraj/app/design_system/states.dart';
import 'package:aji_tfarraj/app/localization/locale_provider.dart';
import 'package:aji_tfarraj/app/analytics/analytics_service.dart';
import 'package:aji_tfarraj/features/auth/data/auth_repository.dart';
import 'package:aji_tfarraj/features/shows/data/shows_repository.dart';
import 'package:aji_tfarraj/features/shows/domain/show.dart';

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
    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _HeroSection(show: show, onBack: () => _goBack(context)),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
                child: _SeatsCard(show: show),
              ),
            ),
            if (show.description != null && show.description!.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
                  child: _DescriptionCard(description: show.description!),
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

class _HeroSection extends StatelessWidget {
  final Show show;
  final VoidCallback onBack;

  const _HeroSection({required this.show, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEE d MMM • HH:mm', 'fr_FR');

    return SizedBox(
      height: 380,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          show.imageUrl != null
              ? CachedNetworkImage(
                  imageUrl: show.imageUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) =>
                      Container(color: AppColors.backgroundGrey),
                  errorWidget: (_, __, ___) => Container(
                    color: AppColors.backgroundGrey,
                    child: const Center(
                      child: Icon(Icons.tv, size: 64, color: AppColors.textLight),
                    ),
                  ),
                )
              : Container(
                  color: AppColors.backgroundGrey,
                  child: const Center(
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

          // Bottom gradient
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment(0, 0.15),
                colors: [Color(0xFF000000), Colors.transparent],
              ),
            ),
          ),

          // Back button — top left
          Positioned(
            top: MediaQuery.of(context).padding.top + AppSpacing.sm,
            left: AppSpacing.md,
            child: GestureDetector(
              onTap: onBack,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.15)),
                ),
                child: const Icon(Icons.arrow_back_ios_new,
                    color: Colors.white, size: 16),
              ),
            ),
          ),

          // Channel badge — top right
          if (show.channel != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + AppSpacing.sm,
              right: AppSpacing.md,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.tv_rounded, size: 13, color: Colors.black),
                    const SizedBox(width: 4),
                    Text(
                      show.channel!,
                      style: AppTypography.labelSmall.copyWith(
                        color: Colors.black,
                        fontWeight: FontWeight.w700,
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
                Text(
                  show.title,
                  style: AppTypography.h1.copyWith(
                    color: Colors.white,
                    height: 1.1,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 13, color: AppColors.textMuted),
                    const SizedBox(width: 5),
                    Text(
                      dateFormat.format(show.startsAt.toLocal()),
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.textMuted),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    const Icon(Icons.location_on_outlined,
                        size: 13, color: AppColors.textMuted),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        show.city,
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.textMuted),
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
    final statusColor = isSoldOut ? AppColors.error : AppColors.success;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.backgroundGrey,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSoldOut
                      ? Icons.event_busy_outlined
                      : Icons.event_seat_outlined,
                  color: statusColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSoldOut
                          ? s.showDetailSoldOut
                          : s.showDetailAvailableSeats(show.availableSeats),
                      style: AppTypography.labelLarge.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      s.showDetailReservations(
                          show.reservedSeats, show.capacity),
                      style: AppTypography.caption
                          .copyWith(color: AppColors.textLight),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Text(
                  '${(progress * 100).round()}%',
                  style: AppTypography.labelSmall.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
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

  String get _locationText {
    if (show.studio != null && show.studio!.isNotEmpty) {
      return '${show.studio}, ${show.city}';
    }
    return show.city;
  }

  Future<void> _openInMaps() async {
    final query = Uri.encodeComponent(_locationText);
    final url = Uri.parse('https://maps.google.com/?q=$query');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final dateFormat = DateFormat('EEEE dd MMMM yyyy', 'fr_FR');
    final timeFormat = DateFormat('HH:mm', 'fr_FR');

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
            value: dateFormat.format(show.startsAt.toLocal()),
            isFirst: true,
          ),
          _RowDivider(),
          _DetailRow(
            icon: Icons.access_time_rounded,
            label: s.showDetailTimeLabel,
            value: timeFormat.format(show.startsAt.toLocal()),
          ),
          _RowDivider(),
          _DetailRow(
            icon: Icons.location_on_outlined,
            label: s.showDetailLocationLabel,
            value: _locationText,
            trailing: GestureDetector(
              onTap: _openInMaps,
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
                    const Icon(Icons.map_outlined,
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
    return const Divider(
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
                    child: const Icon(Icons.keyboard_arrow_down_rounded,
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
                const Divider(height: 1, color: AppColors.border),
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

class _StickyReserveCTA extends ConsumerWidget {
  final Show show;
  final VoidCallback onReserve;

  const _StickyReserveCTA({required this.show, required this.onReserve});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final isSoldOut = show.isSoldOut;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        MediaQuery.of(context).padding.bottom + AppSpacing.md,
      ),
      decoration: const BoxDecoration(
        color: AppColors.backgroundWhite,
        border:
            Border(top: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Reward points badge
            if (!isSoldOut && show.rewardPoints != null) ...[
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
                      '+${show.effectiveRewardPoints}',
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
                          side: const BorderSide(
                              color: AppColors.border, width: 1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                AppSpacing.radiusMd),
                          ),
                        ),
                        icon: const Icon(Icons.event_busy_outlined,
                            size: 18, color: AppColors.textLight),
                        label: Text(
                          s.showDetailSoldOutCta,
                          style: AppTypography.buttonLarge
                              .copyWith(color: AppColors.textLight),
                        ),
                      )
                    : FilledButton.icon(
                        onPressed: onReserve,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                AppSpacing.radiusMd),
                          ),
                        ),
                        icon: const Icon(
                            Icons.confirmation_number_outlined,
                            size: 18,
                            color: Colors.black),
                        label: Text(
                          s.showDetailReserveNow,
                          style: AppTypography.buttonLarge.copyWith(
                            color: Colors.black,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 380, color: AppColors.backgroundGrey),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundGrey,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusLg),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundGrey,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusLg),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundGrey,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusLg),
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
                  child: const Icon(Icons.arrow_back_ios_new,
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

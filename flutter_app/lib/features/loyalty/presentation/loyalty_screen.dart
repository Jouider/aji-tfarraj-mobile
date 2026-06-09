import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';
import 'package:aji_tfarraj/app/design_system/states.dart';
import 'package:aji_tfarraj/app/design_system/loaders.dart';
import 'package:aji_tfarraj/app/localization/locale_provider.dart';
import 'package:aji_tfarraj/app/localization/app_locale.dart';
import 'package:aji_tfarraj/features/loyalty/data/loyalty_repository.dart';
import 'package:aji_tfarraj/features/loyalty/domain/points_summary.dart';
import 'package:aji_tfarraj/features/loyalty/presentation/widgets/points_total_card.dart';
import 'package:aji_tfarraj/features/loyalty/presentation/widgets/points_history_list.dart';
import 'package:go_router/go_router.dart';
import 'package:aji_tfarraj/app/routes.dart';
import 'package:aji_tfarraj/features/rewards/data/rewards_repository.dart';
import 'package:aji_tfarraj/features/rewards/presentation/widgets/reward_api_card.dart';
import 'package:aji_tfarraj/features/referral/data/referral_repository.dart';

/// Main loyalty / fidelity screen
class LoyaltyScreen extends ConsumerStatefulWidget {
  const LoyaltyScreen({super.key});

  @override
  ConsumerState<LoyaltyScreen> createState() => _LoyaltyScreenState();
}

class _LoyaltyScreenState extends ConsumerState<LoyaltyScreen> {
  bool _showFullHistory = false;

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    final pointsAsync = ref.watch(myPointsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(strings.loyaltyTitle, style: AppTypography.h3),
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
      ),
      body: pointsAsync.when(
        loading: () => _buildSkeleton(),
        error: (error, _) => ErrorState.generic(
          onRetry: () => ref.invalidate(myPointsProvider),
        ),
        data: (summary) => _buildContent(context, summary, strings),
      ),
    );
  }

  Widget _buildContent(BuildContext context, PointsSummary summary, dynamic strings) {
    final locale = ref.watch(localeProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(myPointsProvider),
      color: AppColors.secondary,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // ── Points total card ──
          PointsTotalCard(
            balance: summary.balance,
            subtitle: strings.pointsSubtitle,
          ),
          const SizedBox(height: AppSpacing.xl),

          // ── History section ──
          _SectionHeader(
            title: strings.history,
            trailing: summary.history.length > 5 && !_showFullHistory
                ? TextButton(
                    onPressed: () => setState(() => _showFullHistory = true),
                    child: Text(
                      strings.seeAll,
                      style: AppTypography.labelMedium
                          .copyWith(color: AppColors.primary),
                    ),
                  )
                : null,
          ),
          const SizedBox(height: AppSpacing.sm),
          if (summary.history.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: EmptyState(
                icon: Icons.history,
                title: strings.noPointsYet,
              ),
            )
          else
            PointsHistoryList(
              entries: summary.history,
              isPreview: !_showFullHistory,
              labelForType: (type) => _labelForType(type, locale),
              seeAllLabel: strings.seeAll,
              onSeeAll: () => setState(() => _showFullHistory = true),
            ),
          const SizedBox(height: AppSpacing.xl),

          // ── Referral section ──
          _ReferralSummaryCard(ref: ref, s: strings),
          const SizedBox(height: AppSpacing.xl),

          // ── Rewards section ──
          _SectionHeader(
            title: strings.rewards,
            trailing: TextButton(
              onPressed: () => context.push(Routes.rewards),
              child: Text(
                strings.seeAllRewards,
                style: AppTypography.labelMedium
                    .copyWith(color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _RewardsPreview(),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  /// Resolve a points entry type to a localized label
  String _labelForType(String type, AppLocale locale) {
    switch (type) {
      case 'attendance':
        return locale == AppLocale.fr ? 'Présence' : 'الحضور';
      case 'referral':
        return locale == AppLocale.fr ? 'Parrainage' : 'إحالة';
      case 'bonus':
        return locale == AppLocale.fr ? 'Bonus' : 'مكافأة';
      default:
        return type;
    }
  }

  /// Skeleton loading state
  Widget _buildSkeleton() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          SkeletonLoader.card(height: 180),
          const SizedBox(height: AppSpacing.xl),
          SkeletonLoader.text(width: 120, height: 20),
          const SizedBox(height: AppSpacing.md),
          ...List.generate(
            3,
            (_) => const Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.md),
              child: SkeletonLoader(width: double.infinity, height: 56),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          SkeletonLoader.text(width: 120, height: 20),
          const SizedBox(height: AppSpacing.md),
          ...List.generate(
            3,
            (_) => const Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.md),
              child: SkeletonLoader(width: double.infinity, height: 72),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows first 3 rewards from the API in preview mode (no collect button)
class _RewardsPreview extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rewardsAsync = ref.watch(rewardsListProvider);

    return rewardsAsync.when(
      loading: () => Column(
        children: List.generate(
          2,
          (_) => const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.md),
            child: SkeletonLoader(width: double.infinity, height: 100),
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (rewards) {
        if (rewards.isEmpty) return const SizedBox.shrink();
        final preview = rewards.take(3).toList();
        return Column(
          children: [
            for (int i = 0; i < preview.length; i++) ...[
              RewardApiCard(reward: preview[i], previewMode: true),
              if (i < preview.length - 1)
                const SizedBox(height: AppSpacing.md),
            ],
          ],
        );
      },
    );
  }
}

/// Referral summary card shown in the Loyalty screen
class _ReferralSummaryCard extends StatelessWidget {
  final WidgetRef ref;
  final dynamic s;

  const _ReferralSummaryCard({required this.ref, required this.s});

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(myReferralStatsProvider);

    return statsAsync.when(
      loading: () => const SkeletonLoader(width: double.infinity, height: 100),
      error: (_, __) => const SizedBox.shrink(),
      data: (stats) => GestureDetector(
        onTap: () => context.push(Routes.referralStats),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.08),
                AppColors.secondary.withValues(alpha: 0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border:
                Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.people_outline,
                    color: AppColors.secondary, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.referralTitle, style: AppTypography.h4),
                    const SizedBox(height: 2),
                    Text(
                      '${stats.totalInvited} ${s.referralTotalInvited} · ${stats.totalPoints} pts',
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small section header with optional trailing widget
class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const _SectionHeader({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTypography.h4),
        if (trailing != null) trailing!,
      ],
    );
  }
}

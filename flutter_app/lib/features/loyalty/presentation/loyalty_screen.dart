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
import 'package:aji_tfarraj/features/loyalty/presentation/widgets/reward_card.dart';

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
        data: (summary) => _buildContent(summary, strings),
      ),
    );
  }

  Widget _buildContent(PointsSummary summary, dynamic strings) {
    final locale = ref.watch(localeProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(myPointsProvider),
      color: AppColors.primary,
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
                      'Voir tout',
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
              seeAllLabel: 'Voir tout',
              onSeeAll: () => setState(() => _showFullHistory = true),
            ),
          const SizedBox(height: AppSpacing.xl),

          // ── Rewards section ──
          _SectionHeader(title: strings.rewards),
          const SizedBox(height: AppSpacing.sm),
          RewardCard(
            title: 'Café offert',
            requiredPoints: 100,
            currentBalance: summary.balance,
            icon: Icons.coffee,
            comingSoonLabel: strings.comingSoon,
          ),
          const SizedBox(height: AppSpacing.md),
          RewardCard(
            title: 'Réduction 20%',
            requiredPoints: 250,
            currentBalance: summary.balance,
            icon: Icons.discount,
            comingSoonLabel: strings.comingSoon,
          ),
          const SizedBox(height: AppSpacing.md),
          RewardCard(
            title: 'Invitation VIP',
            requiredPoints: 500,
            currentBalance: summary.balance,
            icon: Icons.workspace_premium,
            comingSoonLabel: strings.comingSoon,
          ),
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

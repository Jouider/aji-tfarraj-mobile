import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/loaders.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';
import 'package:aji_tfarraj/app/design_system/states.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';
import 'package:aji_tfarraj/app/localization/locale_provider.dart';
import 'package:aji_tfarraj/app/routes.dart';
import 'package:aji_tfarraj/features/rewards/data/rewards_repository.dart';
import 'package:aji_tfarraj/features/rewards/presentation/widgets/reward_api_card.dart';
import 'package:aji_tfarraj/features/tutorials/domain/tutorial.dart';
import 'package:aji_tfarraj/features/tutorials/presentation/tutorial_widgets.dart';
import 'package:aji_tfarraj/features/wheel/data/wheel_repository.dart';
import 'package:aji_tfarraj/features/wheel/presentation/wheel_entry_card.dart';

class RewardsScreen extends ConsumerWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    final rewardsAsync = ref.watch(rewardsListProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(strings.rewardsTitle, style: AppTypography.h3),
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        actions: [
          const TutorialHelpAction(topic: TutorialTopic.rewards),
          TextButton.icon(
            onPressed: () => context.push(Routes.myRewards),
            icon: Icon(Icons.history, size: 18, color: AppColors.textSecondary),
            label: Text(
              strings.myRewardsTitle,
              style: AppTypography.labelSmall
                  .copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
      body: rewardsAsync.when(
        loading: () => _buildSkeleton(),
        error: (_, __) => ErrorState.generic(
          onRetry: () => ref.invalidate(rewardsListProvider),
        ),
        data: (rewards) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(rewardsListProvider);
              ref.invalidate(wheelProvider);
            },
            color: AppColors.accentInk,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                // Pas encore assez de points ? La roue en donne, chaque jour.
                // Elle se cache d'elle-même quand elle est fermée.
                const WheelEntryCard(
                  padding: EdgeInsets.only(bottom: AppSpacing.lg),
                ),
                if (rewards.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xxl),
                    child: EmptyState(
                      icon: Icons.card_giftcard_outlined,
                      title: strings.noRewardsYet,
                    ),
                  )
                else
                  for (final (i, reward) in rewards.indexed) ...[
                    if (i > 0) const SizedBox(height: AppSpacing.md),
                    RewardApiCard(reward: reward),
                  ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSkeleton() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: List.generate(
          3,
          (_) => const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.md),
            child: SkeletonLoader(width: double.infinity, height: 90),
          ),
        ),
      ),
    );
  }
}

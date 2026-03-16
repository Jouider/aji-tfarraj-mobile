import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:aji_tfarraj/app/design_system/badges.dart';
import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/loaders.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';
import 'package:aji_tfarraj/app/design_system/states.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';
import 'package:aji_tfarraj/app/localization/locale_provider.dart';
import 'package:aji_tfarraj/features/rewards/data/rewards_repository.dart';
import 'package:aji_tfarraj/features/rewards/domain/reward.dart';

class MyRewardsScreen extends ConsumerWidget {
  const MyRewardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    final requestsAsync = ref.watch(myRewardsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(strings.myRewardsTitle, style: AppTypography.h3),
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
      ),
      body: requestsAsync.when(
        loading: () => Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: List.generate(
              4,
              (_) => const Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.md),
                child: SkeletonLoader(width: double.infinity, height: 72),
              ),
            ),
          ),
        ),
        error: (_, __) => ErrorState.generic(
          onRetry: () => ref.invalidate(myRewardsProvider),
        ),
        data: (requests) {
          if (requests.isEmpty) {
            return Center(
              child: EmptyState(
                icon: Icons.inbox_outlined,
                title: strings.noMyRewardsYet,
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(myRewardsProvider),
            color: AppColors.secondary,
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: requests.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.sm),
              itemBuilder: (_, i) =>
                  _RewardRequestTile(request: requests[i], strings: strings),
            ),
          );
        },
      ),
    );
  }
}

class _RewardRequestTile extends StatelessWidget {
  final RewardRequest request;
  final dynamic strings;

  const _RewardRequestTile({required this.request, required this.strings});

  AppBadge _buildBadge() {
    switch (request.status) {
      case 'approved':
        return AppBadge.success(strings.rewardApprovedLabel as String);
      case 'rejected':
        return AppBadge.error(strings.rewardRejectedLabel as String);
      default:
        return AppBadge.warning(strings.rewardPendingLabel as String);
    }
  }

  @override
  Widget build(BuildContext context) {
    final date =
        DateFormat('dd MMM yyyy', 'fr').format(request.requestedAt.toLocal());

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.card_giftcard,
              color: AppColors.textMuted, size: AppSpacing.iconMd),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(request.rewardTitle, style: AppTypography.labelMedium),
                const SizedBox(height: 2),
                Text(
                  '${strings.requestedAt} $date',
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
          _buildBadge(),
        ],
      ),
    );
  }
}

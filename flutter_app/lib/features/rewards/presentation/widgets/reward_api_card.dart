import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';
import 'package:aji_tfarraj/app/localization/locale_provider.dart';
import 'package:aji_tfarraj/app/network/api_client.dart';
import 'package:aji_tfarraj/features/loyalty/data/loyalty_repository.dart';
import 'package:aji_tfarraj/features/rewards/data/rewards_repository.dart';
import 'package:aji_tfarraj/features/rewards/domain/reward.dart';

/// Full reward card with image, collect button, and collect action.
/// Set [previewMode] to hide the collect button (used in loyalty screen preview).
class RewardApiCard extends ConsumerStatefulWidget {
  final Reward reward;
  final bool previewMode;

  const RewardApiCard({
    super.key,
    required this.reward,
    this.previewMode = false,
  });

  @override
  ConsumerState<RewardApiCard> createState() => _RewardApiCardState();
}

class _RewardApiCardState extends ConsumerState<RewardApiCard> {
  bool _loading = false;

  Future<void> _collect() async {
    if (_loading) return;
    setState(() => _loading = true);

    try {
      await ref
          .read(rewardsRepositoryProvider)
          .collectReward(widget.reward.id);

      // Refresh rewards list and points balance
      ref.invalidate(rewardsListProvider);
      ref.invalidate(myPointsProvider);
      ref.invalidate(myRewardsProvider);

      if (mounted) {
        final strings = ref.read(stringsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(strings.rewardRequestSent),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reward = widget.reward;
    final strings = ref.watch(stringsProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Image ──
          if (reward.imageUrl != null)
            CachedNetworkImage(
              imageUrl: reward.imageUrl!,
              height: 140,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                height: 140,
                color: AppColors.backgroundGrey,
                child: const Center(
                  child: Icon(Icons.card_giftcard,
                      color: AppColors.textMuted, size: 40),
                ),
              ),
              errorWidget: (_, __, ___) => Container(
                height: 140,
                color: AppColors.backgroundGrey,
                child: const Center(
                  child: Icon(Icons.card_giftcard,
                      color: AppColors.textMuted, size: 40),
                ),
              ),
            )
          else
            Container(
              height: 100,
              width: double.infinity,
              color: AppColors.backgroundGrey,
              child: const Center(
                child: Icon(Icons.card_giftcard,
                    color: AppColors.textMuted, size: 40),
              ),
            ),

          // ── Content ──
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reward.title, style: AppTypography.labelLarge),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  reward.description,
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Points badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: reward.canCollect
                            ? AppColors.secondaryLight.withValues(alpha: 0.3)
                            : AppColors.backgroundGrey,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusFull),
                      ),
                      child: Text(
                        '${reward.pointsRequired} ${strings.pointsRequired}',
                        style: AppTypography.labelSmall.copyWith(
                          color: reward.canCollect
                              ? AppColors.secondaryDark
                              : AppColors.textMuted,
                          fontWeight: AppTypography.semiBold,
                        ),
                      ),
                    ),

                    // Collect button (hidden in preview mode)
                    if (!widget.previewMode)
                      SizedBox(
                        height: 34,
                        child: ElevatedButton(
                          onPressed:
                              reward.canCollect && !_loading ? _collect : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.textPrimary,
                            disabledBackgroundColor: AppColors.disabled,
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusFull),
                            ),
                            elevation: 0,
                          ),
                          child: _loading
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.textPrimary,
                                  ),
                                )
                              : Text(strings.collectReward,
                                  style: AppTypography.labelSmall),
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

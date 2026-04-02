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
    final isAr = ref.watch(isRtlProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: widget.previewMode
          ? _buildHorizontal(reward, strings, isAr)
          : _buildVertical(reward, strings, isAr),
    );
  }

  /// Horizontal layout: image left, text right — used in loyalty screen preview
  Widget _buildHorizontal(Reward reward, dynamic strings, bool isAr) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ── Image (left, square) ──
        SizedBox(
          width: 90,
          height: 90,
          child: reward.imageUrl != null
              ? CachedNetworkImage(
                  imageUrl: reward.imageUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => _imagePlaceholder(),
                  errorWidget: (_, __, ___) => _imagePlaceholder(),
                )
              : _imagePlaceholder(),
        ),

        // ── Text (right) ──
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  reward.localizedTitle(isAr),
                  style: AppTypography.labelMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  reward.localizedDescription(isAr),
                  style: AppTypography.caption
                      .copyWith(color: AppColors.textSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                _buildPointsBadge(reward, strings),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Horizontal layout with collect button — used in rewards screen
  Widget _buildVertical(Reward reward, dynamic strings, bool isAr) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ── Image (left, square) ──
        SizedBox(
          width: 90,
          height: 90,
          child: reward.imageUrl != null
              ? CachedNetworkImage(
                  imageUrl: reward.imageUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => _imagePlaceholder(),
                  errorWidget: (_, __, ___) => _imagePlaceholder(),
                )
              : _imagePlaceholder(),
        ),

        // ── Text + actions (right) ──
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  reward.localizedTitle(isAr),
                  style: AppTypography.labelMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  reward.localizedDescription(isAr),
                  style: AppTypography.caption
                      .copyWith(color: AppColors.textSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildPointsBadge(reward, strings),
                    SizedBox(
                      height: 30,
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
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusFull),
                          ),
                          elevation: 0,
                        ),
                        child: _loading
                            ? SizedBox(
                                width: 12,
                                height: 12,
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
        ),
      ],
    );
  }

  Widget _imagePlaceholder() => Container(
        color: AppColors.backgroundGrey,
        child: Center(
          child:
              Icon(Icons.card_giftcard, color: AppColors.textMuted, size: 32),
        ),
      );

  Widget _buildPointsBadge(Reward reward, dynamic strings) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: reward.canCollect
            ? AppColors.secondaryLight.withValues(alpha: 0.3)
            : AppColors.backgroundGrey,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
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
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';
import 'package:aji_tfarraj/app/design_system/states.dart';
import 'package:aji_tfarraj/app/design_system/loaders.dart';
import 'package:aji_tfarraj/app/localization/locale_provider.dart';
import 'package:aji_tfarraj/app/routes.dart';
import 'package:aji_tfarraj/features/auth/data/auth_repository.dart';
import 'package:aji_tfarraj/features/referral/data/referral_repository.dart';
import 'package:aji_tfarraj/features/referral/domain/referral_stats.dart';

/// Referral stats dashboard — shows totals and links to My Links screen
class ReferralStatsScreen extends ConsumerWidget {
  const ReferralStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(myReferralStatsProvider);
    final s = ref.watch(stringsProvider);
    final user = ref.watch(loginAuthStateProvider).user;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(s.referralStatsTitle, style: AppTypography.h3),
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
      ),
      body: statsAsync.when(
        loading: () => _buildSkeleton(),
        error: (error, _) => ErrorState.generic(
          onRetry: () => ref.invalidate(myReferralStatsProvider),
        ),
        data: (stats) => _buildContent(context, ref, stats, s, user),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref,
      ReferralStats stats, dynamic s, dynamic user) {
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(myReferralStatsProvider),
      color: AppColors.secondary,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // Referral code card
          if (user?.referralCode != null) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withValues(alpha: 0.85),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              ),
              child: Column(
                children: [
                  Text(
                    s.referralMyCode,
                    style: AppTypography.labelMedium
                        .copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        user!.referralCode!,
                        style: AppTypography.h2.copyWith(
                          color: Colors.white,
                          letterSpacing: 4,
                          fontWeight: AppTypography.semiBold,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      IconButton(
                        onPressed: () {
                          Clipboard.setData(
                              ClipboardData(text: user.referralCode!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(s.referralCodeCopied),
                              duration: const Duration(seconds: 2),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy, color: Colors.white70),
                        iconSize: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    s.referralInviteFriendsEarnPoints,
                    style: AppTypography.bodySmall
                        .copyWith(color: Colors.white60),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],

          // Stats grid
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: s.referralTotalInvited,
                  value: stats.totalInvited.toString(),
                  icon: Icons.person_add_outlined,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _StatCard(
                  label: s.referralTotalAttended,
                  value: stats.totalAttended.toString(),
                  icon: Icons.how_to_reg_outlined,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: s.referralPending,
                  value: stats.pending.toString(),
                  icon: Icons.schedule_outlined,
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _StatCard(
                  label: s.referralPointsEarned,
                  value: '${stats.totalPoints}',
                  icon: Icons.star_outlined,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),

          // My Links tile
          ListTile(
            leading: Icon(Icons.link, color: AppColors.textSecondary),
            title:
                Text(s.referralMyLinks, style: AppTypography.bodyMedium),
            trailing: Icon(Icons.chevron_right,
                color: AppColors.textMuted),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              side: BorderSide(color: AppColors.border),
            ),
            tileColor: AppColors.backgroundWhite,
            onTap: () => context.push(Routes.referralLinks),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          SkeletonLoader.card(height: 140),
          const SizedBox(height: AppSpacing.xl),
          const Row(
            children: [
              Expanded(
                  child:
                      SkeletonLoader(width: double.infinity, height: 100)),
              SizedBox(width: AppSpacing.md),
              Expanded(
                  child:
                      SkeletonLoader(width: double.infinity, height: 100)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Row(
            children: [
              Expanded(
                  child:
                      SkeletonLoader(width: double.infinity, height: 100)),
              SizedBox(width: AppSpacing.md),
              Expanded(
                  child:
                      SkeletonLoader(width: double.infinity, height: 100)),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: AppTypography.h2.copyWith(color: color),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style:
                AppTypography.labelSmall.copyWith(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

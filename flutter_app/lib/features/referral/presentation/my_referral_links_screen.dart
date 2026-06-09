import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:aji_tfarraj/app/network/api_client.dart';
import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';
import 'package:aji_tfarraj/app/design_system/states.dart';
import 'package:aji_tfarraj/app/design_system/loaders.dart';
import 'package:aji_tfarraj/app/localization/locale_provider.dart';
import 'package:aji_tfarraj/features/referral/data/referral_repository.dart';
import 'package:aji_tfarraj/features/referral/domain/referral_link.dart';

/// Lists the user's generated magic referral links with stats
class MyReferralLinksScreen extends ConsumerWidget {
  const MyReferralLinksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linksAsync = ref.watch(myReferralLinksProvider);
    final s = ref.watch(stringsProvider);
    final isAr = ref.watch(isRtlProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(s.referralLinksTitle, style: AppTypography.h3),
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
      ),
      body: linksAsync.when(
        loading: () => _buildSkeleton(),
        error: (error, _) => ErrorState.generic(
          onRetry: () => ref.invalidate(myReferralLinksProvider),
        ),
        data: (links) => links.isEmpty
            ? Center(
                child: EmptyState(
                  icon: Icons.link_off,
                  title: s.referralNoLinksYet,
                ),
              )
            : _buildList(context, ref, links, s, isAr),
      ),
    );
  }

  Widget _buildList(BuildContext context, WidgetRef ref,
      List<ReferralLink> links, dynamic s, bool isAr) {
    final dateFormat = DateFormat('dd MMM yyyy', 'fr_FR');

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(myReferralLinksProvider),
      color: AppColors.secondary,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: links.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (_, index) {
          final link = links[index];
          return _LinkCard(
            link: link,
            dateFormat: dateFormat,
            s: s,
            isAr: isAr,
            onShare: () async {
              try {
                final box = context.findRenderObject() as RenderBox?;
                final origin = box != null && box.hasSize
                    ? box.localToGlobal(Offset.zero) & box.size
                    : null;
                await Share.share(
                  s.referralShareMessage(
                      link.show.localizedTitle(isAr), link.referralLink),
                  sharePositionOrigin: origin,
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(ApiException.from(e).userMessage(s))),
                );
              }
            },
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
          (_) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: SkeletonLoader.card(height: 120),
          ),
        ),
      ),
    );
  }
}

class _LinkCard extends StatelessWidget {
  final ReferralLink link;
  final DateFormat dateFormat;
  final dynamic s;
  final bool isAr;
  final VoidCallback onShare;

  const _LinkCard({
    required this.link,
    required this.dateFormat,
    required this.s,
    required this.isAr,
    required this.onShare,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: show title + expired badge
          Row(
            children: [
              Expanded(
                child: Text(
                  link.show.localizedTitle(isAr),
                  style: AppTypography.h4,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (link.isExpired)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.errorLight,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Text(
                    s.referralExpired,
                    style: AppTypography.labelSmall
                        .copyWith(color: AppColors.error),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            link.show.startsAt != null
                ? dateFormat.format(link.show.startsAt!.toLocal())
                : '—',
            style:
                AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.md),

          // Stats row
          Row(
            children: [
              _StatBadge(
                icon: Icons.touch_app_outlined,
                value: link.clickCount,
                label: s.referralClicks,
              ),
              const SizedBox(width: AppSpacing.lg),
              _StatBadge(
                icon: Icons.how_to_reg_outlined,
                value: link.conversionCount,
                label: s.referralConversions,
              ),
              const Spacer(),
              if (!link.isExpired)
                IconButton(
                  onPressed: onShare,
                  icon: const Icon(Icons.share_outlined),
                  color: AppColors.secondary,
                  iconSize: 20,
                  tooltip: s.referralShareLink,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final int value;
  final String label;

  const _StatBadge({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Text(
          '$value',
          style: AppTypography.labelMedium
              .copyWith(fontWeight: AppTypography.semiBold),
        ),
        const SizedBox(width: 2),
        Text(
          label,
          style:
              AppTypography.labelSmall.copyWith(color: AppColors.textMuted),
        ),
      ],
    );
  }
}

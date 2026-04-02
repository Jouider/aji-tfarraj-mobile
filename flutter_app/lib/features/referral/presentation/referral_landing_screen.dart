import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';
import 'package:aji_tfarraj/app/design_system/loaders.dart';
import 'package:aji_tfarraj/app/localization/locale_provider.dart';
import 'package:aji_tfarraj/app/network/api_client.dart';
import 'package:aji_tfarraj/app/routes.dart';
import 'package:aji_tfarraj/features/referral/data/referral_repository.dart';
import 'package:aji_tfarraj/features/referral/domain/resolved_referral.dart';

/// Provider that resolves a referral token
final _resolvedReferralProvider =
    FutureProvider.autoDispose.family<ResolvedReferral, String>((ref, token) {
  final repo = ref.watch(referralRepositoryProvider);
  return repo.resolveLink(token);
});

/// Screen shown when a user opens a referral magic link (/r/{token}).
/// Displays the referrer info + show card, then lets the user reserve.
class ReferralLandingScreen extends ConsumerWidget {
  final String token;

  const ReferralLandingScreen({super.key, required this.token});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resolvedAsync = ref.watch(_resolvedReferralProvider(token));
    final s = ref.watch(stringsProvider);
    final isAr = ref.watch(isRtlProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        title: Text(s.referralTitle, style: AppTypography.h3),
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
      ),
      body: resolvedAsync.when(
        loading: () => _buildSkeleton(),
        error: (error, _) => _buildError(context, ref, error, s),
        data: (resolved) => _buildContent(context, ref, resolved, s, isAr),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref,
      ResolvedReferral resolved, dynamic s, bool isAr) {
    final dateFormat = DateFormat('dd MMM yyyy · HH:mm', 'fr_FR');
    final show = resolved.show;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Referrer invitation banner
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.08),
                        AppColors.secondary.withValues(alpha: 0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    border: Border.all(
                      color: AppColors.secondary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.secondary,
                        backgroundImage: resolved.referrer.avatarUrl != null
                            ? CachedNetworkImageProvider(
                                resolved.referrer.avatarUrl!)
                            : null,
                        child: resolved.referrer.avatarUrl == null
                            ? const Icon(Icons.person,
                                color: Colors.white, size: 24)
                            : null,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          s.referralInvitesYou(resolved.referrer.name),
                          style: AppTypography.h4.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Show image
                if (show.imageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    child: CachedNetworkImage(
                      imageUrl: show.imageUrl!,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        height: 200,
                        color: AppColors.backgroundGrey,
                        child: Center(
                          child: Icon(Icons.tv_outlined,
                              size: 48, color: AppColors.textLight),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.lg),

                // Show title + channel
                if (show.channel != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.15),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Text(
                      show.channel!,
                      style: AppTypography.labelSmall
                          .copyWith(color: AppColors.secondary),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                Text(show.localizedTitle(isAr), style: AppTypography.h2),
                const SizedBox(height: AppSpacing.md),

                // Details row
                _DetailRow(
                  icon: Icons.calendar_today_outlined,
                  text: dateFormat.format(show.startsAt.toLocal()),
                ),
                const SizedBox(height: AppSpacing.sm),
                _DetailRow(
                  icon: Icons.location_on_outlined,
                  text: show.city,
                ),
                const SizedBox(height: AppSpacing.sm),
                _DetailRow(
                  icon: Icons.event_seat_outlined,
                  text: show.isSoldOut
                      ? s.reserveSeatsSoldOutBadge
                      : s.reserveSeatsAvailable(show.availableSeats),
                ),

                if (show.localizedDescription(isAr) != null) ...[
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    show.localizedDescription(isAr)!,
                    style: AppTypography.bodyMedium
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
        ),

        // Sticky CTA
        Container(
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.md,
            bottom: MediaQuery.of(context).padding.bottom + AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: AppColors.backgroundLight,
            border: Border(
                top: BorderSide(color: AppColors.border, width: 0.5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              width: double.infinity,
              height: AppSpacing.buttonHeight,
              child: FilledButton(
                onPressed: show.isSoldOut
                    ? null
                    : () {
                        // Store the referral code for the reservation flow
                        ref
                            .read(pendingReferralCodeProvider.notifier)
                            .state = resolved.referralCode;
                        context
                            .go(Routes.showReserve(show.id.toString()));
                      },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: AppColors.backgroundWhite,
                  disabledBackgroundColor:
                      AppColors.secondary.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                ),
                child: Text(
                  show.isSoldOut
                      ? s.reserveSeatsSoldOutCta
                      : s.referralReserveNow,
                  style: AppTypography.buttonLarge,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildError(
      BuildContext context, WidgetRef ref, Object error, dynamic s) {
    String message = s.referralLinkInvalid;
    if (error is ApiException) {
      if (error.statusCode == 410) {
        final code = error.code;
        message = (code == 'SHOW_UNAVAILABLE')
            ? s.referralShowUnavailable
            : s.referralLinkExpired;
      } else if (error.statusCode == 404) {
        message = s.referralLinkInvalid;
      }
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.link_off, size: 64, color: AppColors.textLight),
            const SizedBox(height: AppSpacing.lg),
            Text(message,
                style: AppTypography.h4, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.xl),
            TextButton(
              onPressed: () => context.go(Routes.home),
              child: Text(s.showDetailBackToHome ?? 'Accueil'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonLoader.card(height: 80),
          const SizedBox(height: AppSpacing.xl),
          SkeletonLoader.card(height: 200),
          const SizedBox(height: AppSpacing.lg),
          SkeletonLoader.text(width: 80, height: 20),
          const SizedBox(height: AppSpacing.sm),
          SkeletonLoader.text(width: double.infinity, height: 28),
          const SizedBox(height: AppSpacing.md),
          SkeletonLoader.text(width: 200, height: 16),
          const SizedBox(height: AppSpacing.sm),
          SkeletonLoader.text(width: 150, height: 16),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _DetailRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style:
                AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';
import 'package:aji_tfarraj/app/design_system/states.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';
import 'package:aji_tfarraj/app/localization/app_locale.dart';
import 'package:aji_tfarraj/app/localization/locale_provider.dart';
import 'package:aji_tfarraj/app/network/api_client.dart';
import 'package:aji_tfarraj/features/casting/data/casting_repository.dart';
import 'package:aji_tfarraj/features/casting/domain/casting_models.dart';
import 'package:aji_tfarraj/features/casting/presentation/casting_home_screen.dart';

/// What I applied to, and where each one stands.
class MyApplicationsScreen extends ConsumerWidget {
  const MyApplicationsScreen({super.key});

  Future<void> _withdraw(
    BuildContext context,
    WidgetRef ref,
    MyApplication application,
  ) async {
    final s = ref.read(stringsProvider);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: Text(s.casting.withdrawConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(s.casting.withdraw),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(castingRepositoryProvider).withdraw(application.id);
      ref.invalidate(myApplicationsProvider);
      if (application.call != null) {
        ref.invalidate(castingFeedProvider(application.call!.type));
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(s.casting.withdrawn)));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e is ApiException ? e.message : s.casting.loadError),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final isAr = ref.watch(localeProvider) == AppLocale.ar;
    final applications = ref.watch(myApplicationsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      appBar: AppBar(
          title: Text(s.casting.myApplications, style: AppTypography.h3)),
      body: applications.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => ErrorState(
          message: s.casting.loadError,
          retryText: s.retry,
          onRetry: () => ref.invalidate(myApplicationsProvider),
        ),
        data: (list) {
          if (list.isEmpty) {
            return EmptyState(
              icon: Icons.assignment_outlined,
              title: s.casting.noApplications,
              description: s.casting.noApplicationsSubtitle,
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(myApplicationsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: list.length,
              itemBuilder: (_, i) {
                final application = list[i];

                return Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundWhite,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              application.call?.localizedTitle(isAr) ?? '—',
                              style: AppTypography.bodyMedium
                                  .copyWith(fontWeight: FontWeight.w600),
                            ),
                            if (application.appliedAt != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                DateFormat('dd/MM/yyyy')
                                    .format(application.appliedAt!),
                                style: AppTypography.caption
                                    .copyWith(color: AppColors.textMuted),
                              ),
                            ],
                            const SizedBox(height: AppSpacing.xs),
                            ApplicationBadge(status: application.status),
                          ],
                        ),
                      ),
                      // Withdrawing is only offered while nobody has acted on
                      // it — taking it back after a shortlisting would erase
                      // someone's decision.
                      if (application.withdrawable)
                        TextButton(
                          onPressed: () =>
                              _withdraw(context, ref, application),
                          child: Text(s.casting.withdraw,
                              style: AppTypography.bodySmall
                                  .copyWith(color: AppColors.error)),
                        ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

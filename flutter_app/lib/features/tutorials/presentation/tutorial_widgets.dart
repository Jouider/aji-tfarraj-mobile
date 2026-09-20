import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';
import 'package:aji_tfarraj/app/localization/locale_provider.dart';
import 'package:aji_tfarraj/app/localization/strings.dart';
import 'package:aji_tfarraj/app/routes.dart';
import 'package:aji_tfarraj/features/auth/data/auth_repository.dart';
import 'package:aji_tfarraj/features/tutorials/data/tutorials_repository.dart';
import 'package:aji_tfarraj/features/tutorials/domain/tutorial.dart';
import 'package:aji_tfarraj/features/tutorials/presentation/tutorial_sheet.dart';

// The ways a clip is offered:
//
//  • TutorialHelpAction   — the "?" in the top bar. Always there.
//  • TutorialOfferBanner  — the first time on a screen, until watched or hidden.
//  • TutorialHowToLink    — under an error, when the member just got stuck.
//
// The banner and the link vanish when the server has no clip: they promise a
// video. The "?" stays and falls back to the illustrated guide.

String tutorialTitle(AppStrings s, TutorialTopic topic) => switch (topic) {
      TutorialTopic.profile => s.tutorialProfileTitle,
      TutorialTopic.reservationReferral => s.tutorialReservationTitle,
      TutorialTopic.cpShare => s.tutorialCpShareTitle,
      TutorialTopic.cpGuests => s.tutorialCpGuestsTitle,
      TutorialTopic.cpEarnings => s.tutorialCpEarningsTitle,
    };

String tutorialShortTitle(AppStrings s, TutorialTopic topic) => switch (topic) {
      TutorialTopic.profile => s.tutorialProfileShort,
      TutorialTopic.reservationReferral => s.tutorialReservationShort,
      TutorialTopic.cpShare => s.tutorialCpShareShort,
      TutorialTopic.cpGuests => s.tutorialCpGuestsShort,
      TutorialTopic.cpEarnings => s.tutorialCpEarningsShort,
    };

String tutorialOffer(AppStrings s, TutorialTopic topic) => switch (topic) {
      TutorialTopic.profile => s.tutorialProfileOffer,
      TutorialTopic.reservationReferral => s.tutorialReservationOffer,
      TutorialTopic.cpShare => s.tutorialCpShareOffer,
      TutorialTopic.cpGuests => s.tutorialCpGuestsOffer,
      TutorialTopic.cpEarnings => s.tutorialCpEarningsOffer,
    };

/// Opens the tutorial sheet.
///
/// Every clip the member is entitled to is offered, as pills; a [topic] (the
/// screen they are on) starts selected, otherwise the first. [only] narrows the
/// list — l'espace chargé public n'offre que ses trois clips. No clip at all —
/// an older server, no network — and the member gets the illustrated
/// "Comment ça marche" instead of nothing.
Future<void> openTutorial(
  BuildContext context,
  WidgetRef ref, [
  TutorialTopic? topic,
  List<TutorialTopic>? only,
]) async {
  final Tutorials tutorials;
  try {
    tutorials = await ref.read(tutorialsProvider.future);
  } catch (_) {
    if (context.mounted) context.push(Routes.howItWorks);
    return;
  }
  if (!context.mounted) return;

  final locale = ref.read(localeProvider);
  final s = ref.read(stringsProvider);
  // Les clips de l'espace chargé public ne concernent que ceux qui y entrent.
  final isChargePublic =
      ref.read(loginAuthStateProvider).user?.canUseChargePublicMode ?? false;
  final offered =
      only ?? TutorialTopic.offeredTo(chargePublic: isChargePublic);

  final all = [
    for (final t in offered)
      if (tutorials.clipFor(t, locale) case final clip?)
        TutorialSheetItem(
          topic: t,
          title: tutorialTitle(s, t),
          shortTitle: tutorialShortTitle(s, t),
          clip: clip,
        ),
  ];

  if (all.isEmpty) {
    context.push(Routes.howItWorks);
    return;
  }

  // Watching retires the first-time banner for that topic.
  if (topic != null) {
    ref.read(tutorialOfferProvider(topic).notifier).dismiss();
  }

  // Every clip is offered as a pill; the screen's own topic starts selected.
  final selected = all.indexWhere((item) => item.topic == topic);
  await showTutorialSheet(
    context,
    items: all,
    initialIndex: selected < 0 ? 0 : selected,
  );
}

/// The "?" in a top bar. Always visible, so help is never hidden.
class TutorialHelpAction extends ConsumerWidget {
  const TutorialHelpAction({super.key, this.topic, this.only, this.color});

  /// Null for the general "?" (home), which offers every clip.
  final TutorialTopic? topic;

  /// Restreint les clips proposés : l'espace chargé public n'offre que les
  /// siens, sans mélanger les tutoriels du mode public.
  final List<TutorialTopic>? only;

  /// The icon colour; defaults to the text colour.
  final Color? color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: Icon(Icons.help_outline, color: color ?? AppColors.textPrimary),
      tooltip: ref.watch(stringsProvider).tutorialWatch,
      onPressed: () => openTutorial(context, ref, topic, only),
    );
  }
}

/// Offered the first time the member reaches a screen that trips people up.
class TutorialOfferBanner extends ConsumerWidget {
  const TutorialOfferBanner({
    super.key,
    required this.topic,
    this.also = const [],
    this.message,
  });

  final TutorialTopic topic;

  /// Les autres clips offerts en même temps : l'espace chargé public en
  /// propose trois d'un coup, et il serait pénible de fermer trois bandeaux.
  final List<TutorialTopic> also;

  /// Remplace le texte du sujet, quand le bandeau en annonce plusieurs.
  final String? message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clip = ref.watch(tutorialClipProvider(topic));
    final stillOffered = ref.watch(tutorialOfferProvider(topic));
    if (clip == null || !stillOffered) return const SizedBox.shrink();

    final s = ref.watch(stringsProvider);
    final message = this.message ?? tutorialOffer(s, topic);
    final duration = formatClipDuration(clip.duration);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Material(
        color: AppColors.secondary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          onTap: () => openTutorial(
              context, ref, topic, also.isEmpty ? null : [topic, ...also]),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.sm, AppSpacing.xs, AppSpacing.sm),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: AppColors.secondary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow_rounded,
                      color: Colors.black, size: 26),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message,
                        style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        duration.isEmpty
                            ? s.tutorialWatch
                            : '${s.tutorialWatch} · $duration',
                        style: AppTypography.labelSmall.copyWith(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, size: 18, color: AppColors.textMuted),
                  tooltip: s.tutorialDismiss,
                  onPressed: () {
                    for (final t in [topic, ...also]) {
                      ref.read(tutorialOfferProvider(t).notifier).dismiss();
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Under an error message: the walkthrough, one tap away.
class TutorialHowToLink extends ConsumerWidget {
  const TutorialHowToLink({super.key, required this.topic});

  final TutorialTopic topic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clip = ref.watch(tutorialClipProvider(topic));
    if (clip == null) return const SizedBox.shrink();

    final s = ref.watch(stringsProvider);
    final duration = formatClipDuration(clip.duration);

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: TextButton.icon(
        onPressed: () => openTutorial(context, ref, topic),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.error,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          minimumSize: const Size(0, 36),
        ),
        icon: const Icon(Icons.play_circle_outline, size: 18),
        label: Text(
          duration.isEmpty ? s.tutorialHowTo : '${s.tutorialHowTo} · $duration',
          style: AppTypography.labelMedium.copyWith(
              color: AppColors.error, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

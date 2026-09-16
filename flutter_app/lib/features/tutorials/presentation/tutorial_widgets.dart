import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';
import 'package:aji_tfarraj/app/localization/locale_provider.dart';
import 'package:aji_tfarraj/app/localization/strings.dart';
import 'package:aji_tfarraj/features/tutorials/data/tutorials_repository.dart';
import 'package:aji_tfarraj/features/tutorials/domain/tutorial.dart';
import 'package:aji_tfarraj/features/tutorials/presentation/tutorial_video_screen.dart';

// The three ways a clip is offered. Each one disappears when the server has no
// clip for its topic: a help button that plays nothing is worse than none.
//
//  • TutorialHelpAction   — the "?" in the app bar, always available.
//  • TutorialOfferBanner  — the first time on the screen, until watched or hidden.
//  • TutorialHowToLink    — under an error, when the member just got stuck.

String tutorialTitle(AppStrings s, TutorialTopic topic) => switch (topic) {
      TutorialTopic.profile => s.tutorialProfileTitle,
      TutorialTopic.reservationReferral => s.tutorialReservationTitle,
    };

/// Plays the clip for [topic]. Watching it also retires its first-time banner.
Future<void> openTutorial(
  BuildContext context,
  WidgetRef ref,
  TutorialTopic topic,
) async {
  final clip = ref.read(tutorialClipProvider(topic));
  if (clip == null) return;

  ref.read(tutorialOfferProvider(topic).notifier).dismiss();

  await Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => TutorialVideoScreen(
        clip: clip,
        title: tutorialTitle(ref.read(stringsProvider), topic),
      ),
    ),
  );
}

/// The "?" in an app bar.
class TutorialHelpAction extends ConsumerWidget {
  const TutorialHelpAction({super.key, required this.topic});

  final TutorialTopic topic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(tutorialClipProvider(topic)) == null) {
      return const SizedBox.shrink();
    }

    return IconButton(
      icon: Icon(Icons.help_outline, color: AppColors.textPrimary),
      tooltip: ref.watch(stringsProvider).tutorialWatch,
      onPressed: () => openTutorial(context, ref, topic),
    );
  }
}

/// Offered the first time the member reaches a screen that trips people up.
class TutorialOfferBanner extends ConsumerWidget {
  const TutorialOfferBanner({super.key, required this.topic});

  final TutorialTopic topic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clip = ref.watch(tutorialClipProvider(topic));
    final stillOffered = ref.watch(tutorialOfferProvider(topic));
    if (clip == null || !stillOffered) return const SizedBox.shrink();

    final s = ref.watch(stringsProvider);
    final message = switch (topic) {
      TutorialTopic.profile => s.tutorialProfileOffer,
      TutorialTopic.reservationReferral => s.tutorialReservationOffer,
    };
    final duration = formatClipDuration(clip.duration);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Material(
        color: AppColors.secondary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          onTap: () => openTutorial(context, ref, topic),
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
                  onPressed: () =>
                      ref.read(tutorialOfferProvider(topic).notifier).dismiss(),
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

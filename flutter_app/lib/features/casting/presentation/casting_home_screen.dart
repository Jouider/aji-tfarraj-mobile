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
import 'package:aji_tfarraj/features/casting/presentation/casting_book_screen.dart';
import 'package:aji_tfarraj/features/casting/presentation/casting_detail_screen.dart';
import 'package:aji_tfarraj/features/casting/presentation/my_applications_screen.dart';

/// The casting section: open calls, and the state of your own book.
///
/// The book banner sits above the list rather than behind a menu, because an
/// incomplete book is the reason the apply button will not work — someone who
/// discovers that only at the end of an application has been wasted.
class CastingHomeScreen extends ConsumerStatefulWidget {
  const CastingHomeScreen({super.key});

  @override
  ConsumerState<CastingHomeScreen> createState() => _CastingHomeScreenState();
}

class _CastingHomeScreenState extends ConsumerState<CastingHomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      appBar: AppBar(
        title: Text(s.casting.title, style: AppTypography.h3),
        actions: [
          IconButton(
            tooltip: s.casting.myApplications,
            icon: const Icon(Icons.assignment_outlined),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const MyApplicationsScreen())),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(text: s.casting.tabCastings),
            Tab(text: s.casting.tabPublications),
          ],
        ),
      ),
      body: Column(
        children: [
          const _BookBanner(),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: const [
                _CallList(type: CastingType.casting),
                _CallList(type: CastingType.publication),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Where the book stands, and the way into it.
class _BookBanner extends ConsumerWidget {
  const _BookBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final book = ref.watch(castingBookProvider);

    // Ineligible accounts get told why, and nothing else: the calls below are
    // not for them either.
    final code = book.hasError && book.error is ApiException
        ? (book.error as ApiException).code
        : null;

    if (code == 'MINOR_NOT_ELIGIBLE' || code == 'BIRTHDAY_REQUIRED') {
      return _Banner(
        icon: code == 'BIRTHDAY_REQUIRED' ? Icons.cake_outlined : Icons.lock_outline,
        text: code == 'BIRTHDAY_REQUIRED'
            ? s.casting.birthdayRequired
            : s.casting.adultsOnly,
        tone: AppColors.error,
        onTap: null,
      );
    }

    final complete = book.valueOrNull?.isComplete ?? false;
    final missing = book.valueOrNull?.missingPoses.length ?? 0;

    return _Banner(
      icon: complete ? Icons.check_circle : Icons.photo_camera_outlined,
      text: complete
          ? s.casting.bookComplete
          : s.casting.bookMissing.replaceFirst('%d', '$missing'),
      tone: complete ? AppColors.success : AppColors.secondary,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const CastingBookScreen()),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.icon,
    required this.text,
    required this.tone,
    required this.onTap,
  });

  final IconData icon;
  final String text;
  final Color tone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: tone.withValues(alpha: 0.1),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          child: Row(
            children: [
              Icon(icon, color: tone, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(text,
                    style: AppTypography.bodyMedium
                        .copyWith(fontWeight: FontWeight.w600)),
              ),
              if (onTap != null)
                Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _CallList extends ConsumerWidget {
  const _CallList({required this.type});

  final CastingType type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final feed = ref.watch(castingFeedProvider(type));

    return feed.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => ErrorState(
        message: s.casting.loadError,
        retryText: s.retry,
        onRetry: () => ref.invalidate(castingFeedProvider(type)),
      ),
      data: (data) {
        if (data.calls.isEmpty) {
          return EmptyState(
            icon: Icons.movie_filter_outlined,
            title: s.casting.noCastings,
            description: s.casting.noCastingsSubtitle,
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(castingFeedProvider(type));
            ref.invalidate(castingBookProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: data.calls.length,
            itemBuilder: (_, i) => CastingCard(call: data.calls[i]),
          ),
        );
      },
    );
  }
}

class CastingCard extends ConsumerWidget {
  const CastingCard({super.key, required this.call});

  final CastingCall call;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final isAr = ref.watch(localeProvider) == AppLocale.ar;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => CastingDetailScreen(call: call),
        )),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (call.imageUrl != null)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(call.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: AppColors.backgroundGrey)),
              ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(call.localizedTitle(isAr),
                      style: AppTypography.bodyMedium
                          .copyWith(fontWeight: FontWeight.w600)),
                  if (call.closesAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${s.casting.closesAt} ${DateFormat('dd/MM/yyyy').format(call.closesAt!)}',
                      style: AppTypography.caption
                          .copyWith(color: AppColors.textMuted),
                    ),
                  ],
                  if (call.hasApplied) ...[
                    const SizedBox(height: AppSpacing.sm),
                    ApplicationBadge(status: call.applicationStatus!),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One place decides how a status looks, so the list, the detail and the
/// applications screen can never disagree about what "shortlisted" means.
class ApplicationBadge extends ConsumerWidget {
  const ApplicationBadge({super.key, required this.status});

  final ApplicationStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(stringsProvider).casting;

    final (label, colour) = switch (status) {
      ApplicationStatus.pending => (c.statusPending, AppColors.textMuted),
      ApplicationStatus.shortlisted => (c.statusShortlisted, AppColors.secondary),
      ApplicationStatus.accepted => (c.statusAccepted, AppColors.success),
      ApplicationStatus.rejected => (c.statusRejected, AppColors.error),
      ApplicationStatus.unknown => (c.statusUnknown, AppColors.textMuted),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colour.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: AppTypography.caption.copyWith(color: colour)),
    );
  }
}

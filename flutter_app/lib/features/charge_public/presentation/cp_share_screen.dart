import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:aji_tfarraj/app/network/api_client.dart';
import 'package:aji_tfarraj/app/copywriting/copy_fr.dart' show ChargePublicCopy;
import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';
import 'package:aji_tfarraj/app/design_system/states.dart';
import 'package:aji_tfarraj/app/design_system/components/loading/skeleton_loader.dart';
import 'package:aji_tfarraj/app/localization/locale_provider.dart';
import 'package:aji_tfarraj/features/referral/data/referral_repository.dart';
import 'package:aji_tfarraj/features/shows/data/shows_repository.dart';
import 'package:aji_tfarraj/features/shows/domain/episode.dart';
import 'package:aji_tfarraj/features/shows/domain/show.dart';

/// A (show, episode) pair to share.
class CpShareEpisode {
  final Show show;
  final Episode episode;
  const CpShareEpisode(this.show, this.episode);
}

/// Upcoming episodes across all active shows, sorted by date — the CP shares
/// these to bring guests. Reuses the public shows list.
final cpShareEpisodesProvider =
    FutureProvider<List<CpShareEpisode>>((ref) async {
  final shows = await ref.watch(showsRepositoryProvider).fetchShows();
  final now = DateTime.now();
  final rows = <CpShareEpisode>[];
  for (final show in shows) {
    for (final ep in show.episodes) {
      if (ep.startsAt == null || ep.startsAt!.isAfter(now)) {
        rows.add(CpShareEpisode(show, ep));
      }
    }
  }
  rows.sort((a, b) {
    final ad = a.episode.startsAt;
    final bd = b.episode.startsAt;
    if (ad == null) return 1;
    if (bd == null) return -1;
    return ad.compareTo(bd);
  });
  return rows;
});

/// "Partager" tab — the CP picks an upcoming episode and shares their
/// personal referral link in one tap.
class CpShareTab extends ConsumerWidget {
  const CpShareTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(cpShareEpisodesProvider);
    final cp = ref.watch(stringsProvider).cp;

    return async.when(
      loading: () => _skeleton(),
      error: (e, _) => ErrorState(
        message: e.toString(),
        retryText: cp.retry,
        onRetry: () => ref.invalidate(cpShareEpisodesProvider),
      ),
      data: (rows) => rows.isEmpty
          ? ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                const SizedBox(height: 80),
                Center(
                  child: EmptyState(
                    icon: Icons.event_busy_outlined,
                    title: cp.noUpcoming,
                  ),
                ),
              ],
            )
          : RefreshIndicator(
              color: AppColors.secondary,
              onRefresh: () async => ref.invalidate(cpShareEpisodesProvider),
              child: ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: rows.length + 1,
                itemBuilder: (context, i) {
                  if (i == 0) return _ShareHeader(cp: cp);
                  return _EpisodeShareCard(row: rows[i - 1]);
                },
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.sm),
              ),
            ),
    );
  }

  Widget _skeleton() => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: List.generate(
            4,
            (_) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: SkeletonLoader.card(height: 92),
            ),
          ),
        ),
      );
}

class _ShareHeader extends StatelessWidget {
  final ChargePublicCopy cp;
  const _ShareHeader({required this.cp});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.campaign_outlined,
              size: 20, color: AppColors.secondaryDark),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              cp.shareHeader,
              style: AppTypography.labelMedium
                  .copyWith(color: AppColors.secondaryDark),
            ),
          ),
        ],
      ),
    );
  }
}

class _EpisodeShareCard extends ConsumerStatefulWidget {
  final CpShareEpisode row;
  const _EpisodeShareCard({required this.row});

  @override
  ConsumerState<_EpisodeShareCard> createState() => _EpisodeShareCardState();
}

class _EpisodeShareCardState extends ConsumerState<_EpisodeShareCard> {
  bool _sharing = false;

  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    final s = ref.read(stringsProvider);
    final isAr = ref.read(isRtlProvider);
    final show = widget.row.show;
    final ep = widget.row.episode;
    // Capture the share sheet origin before the async gap.
    final box = context.findRenderObject() as RenderBox?;
    final origin = box != null && box.hasSize
        ? box.localToGlobal(Offset.zero) & box.size
        : null;
    try {
      final link = await ref.read(referralRepositoryProvider).generateLink(
            showId: show.id,
            episodeId: ep.id,
          );
      await Share.share(
        s.referralShareMessage(show.localizedTitle(isAr), link.referralLink),
        sharePositionOrigin: origin,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiException.from(e).userMessage(s))),
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = ref.watch(isRtlProvider);
    final cp = ref.watch(stringsProvider).cp;
    final show = widget.row.show;
    final ep = widget.row.episode;
    final dateStr = ep.localizedDate(isAr) ??
        (ep.startsAt != null
            ? DateFormat('EEE d MMM • HH:mm', 'fr_FR')
                .format(ep.startsAt!.toLocal())
            : null);
    final soldOut = ep.isSoldOut;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(show.localizedTitle(isAr),
                    style: AppTypography.bodyMedium
                        .copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(ep.label,
                    style: AppTypography.labelSmall
                        .copyWith(color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (dateStr != null) ...[
                      Icon(Icons.event_outlined,
                          size: 13, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(dateStr,
                            style: AppTypography.labelSmall
                                .copyWith(color: AppColors.textMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Icon(
                      soldOut
                          ? Icons.event_busy_outlined
                          : Icons.event_seat_outlined,
                      size: 13,
                      color: soldOut ? AppColors.error : AppColors.success,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      soldOut ? cp.soldOut : cp.seatsCount(ep.availableSeats),
                      style: AppTypography.labelSmall.copyWith(
                          color:
                              soldOut ? AppColors.error : AppColors.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _ShareButton(loading: _sharing, onTap: _share, label: cp.shareBtn),
        ],
      ),
    );
  }
}

class _ShareButton extends StatelessWidget {
  final bool loading;
  final String label;
  final VoidCallback onTap;
  const _ShareButton(
      {required this.loading, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.secondary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loading)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            else
              const Icon(Icons.share_outlined, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

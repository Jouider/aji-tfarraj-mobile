import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';
import 'package:aji_tfarraj/app/design_system/states.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';
import 'package:aji_tfarraj/app/localization/app_locale.dart';
import 'package:aji_tfarraj/app/localization/locale_provider.dart';
import 'package:aji_tfarraj/features/staff/data/return_manifest_export.dart';
import 'package:aji_tfarraj/features/staff/data/staff_repository.dart';
import 'package:aji_tfarraj/features/staff/domain/return_manifest.dart';

/// What the door hands to whoever runs the shuttle: how many people are waiting
/// at each drop-off point, once the recording is over.
///
/// The scanner already records each answer one person at a time; this is the
/// total. It is read at the end of the evening, when the vehicles are being
/// dispatched, so the numbers matter more than the names — hence the headcount
/// first and the passenger list folded away underneath.
///
/// [episodeId] comes from the ticket the scanner just handled. Without it the
/// screen asks which recording, because at the end of the night someone may
/// open this cold.
class ReturnManifestScreen extends ConsumerStatefulWidget {
  const ReturnManifestScreen({super.key, this.episodeId});

  final int? episodeId;

  @override
  ConsumerState<ReturnManifestScreen> createState() =>
      _ReturnManifestScreenState();
}

class _ReturnManifestScreenState extends ConsumerState<ReturnManifestScreen> {
  int? _episodeId;

  @override
  void initState() {
    super.initState();
    _episodeId = widget.episodeId;
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      appBar: AppBar(
        title: Text(s.staffManifestTitle, style: AppTypography.h3),
        actions: [
          if (_episodeId != null)
            IconButton(
              tooltip: s.staffManifestRefresh,
              icon: const Icon(Icons.refresh),
              onPressed: () => ref.invalidate(returnManifestProvider(_episodeId!)),
            ),
        ],
      ),
      body: _episodeId == null
          ? _EpisodePicker(onPick: (id) => setState(() => _episodeId = id))
          : _ManifestBody(episodeId: _episodeId!),
    );
  }
}

// ─── Choosing a recording ────────────────────────────────────────────────────

class _EpisodePicker extends ConsumerWidget {
  const _EpisodePicker({required this.onPick});

  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final episodes = ref.watch(manifestEpisodesProvider);

    return episodes.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => ErrorState(
        message: s.staffManifestLoadError,
        retryText: s.staffManifestRefresh,
        onRetry: () => ref.invalidate(manifestEpisodesProvider),
      ),
      data: (list) {
        // One recording is the normal case: skip the question entirely rather
        // than making the scanner confirm the only possible answer.
        if (list.length == 1) {
          WidgetsBinding.instance
              .addPostFrameCallback((_) => onPick(list.first.id));
          return const Center(child: CircularProgressIndicator());
        }

        if (list.isEmpty) {
          return EmptyState(
            icon: Icons.event_busy_outlined,
            title: s.staffManifestNoEpisodes,
            description: s.staffManifestNoEpisodesSubtitle,
          );
        }

        return ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text(s.staffManifestPickEpisode,
                style: AppTypography.h3.copyWith(color: AppColors.textPrimary)),
            const SizedBox(height: AppSpacing.md),
            for (final episode in list)
              Card(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  side: BorderSide(color: AppColors.border),
                ),
                child: ListTile(
                  title: Text(episode.label, style: AppTypography.bodyMedium),
                  subtitle: Text(
                    [
                      if (episode.startsAt != null)
                        DateFormat('dd/MM · HH:mm').format(episode.startsAt!),
                      if (episode.studio != null && episode.studio!.isNotEmpty)
                        episode.studio!,
                    ].join(' · '),
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.textMuted),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => onPick(episode.id),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ─── The sheet ───────────────────────────────────────────────────────────────

class _ManifestBody extends ConsumerWidget {
  const _ManifestBody({required this.episodeId});

  final int episodeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final manifest = ref.watch(returnManifestProvider(episodeId));

    return manifest.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => ErrorState(
        message: s.staffManifestLoadError,
        retryText: s.staffManifestRefresh,
        onRetry: () => ref.invalidate(returnManifestProvider(episodeId)),
      ),
      data: (data) => _ManifestView(manifest: data, episodeId: episodeId),
    );
  }
}

class _ManifestView extends ConsumerWidget {
  const _ManifestView({required this.manifest, required this.episodeId});

  final ReturnManifest manifest;
  final int episodeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final isAr = ref.watch(localeProvider) == AppLocale.ar;

    // No stop switched on means no vehicle is running. Saying so beats an empty
    // table, which reads like a loading failure.
    if (!manifest.hasShuttle && manifest.points.isEmpty) {
      return EmptyState(
        icon: Icons.no_transfer_outlined,
        title: s.staffManifestNoShuttle,
        description: s.staffManifestNoShuttleSubtitle,
      );
    }

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(returnManifestProvider(episodeId)),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xxl),
        children: [
          _EpisodeHeader(manifest: manifest),
          const SizedBox(height: AppSpacing.lg),
          _Totals(manifest: manifest, s: s),
          if (manifest.hasOrphanedPassengers) ...[
            const SizedBox(height: AppSpacing.md),
            _OrphanWarning(message: s.staffManifestOrphanWarning),
          ],
          const SizedBox(height: AppSpacing.lg),
          if (manifest.points.isEmpty)
            EmptyState(
              icon: Icons.directions_bus_outlined,
              title: s.staffManifestNobody,
              description: s.staffManifestNobodySubtitle,
            )
          else
            for (final point in manifest.points)
              _PointCard(point: point, isAr: isAr, s: s),
          const SizedBox(height: AppSpacing.lg),
          _ShareButton(manifest: manifest),
        ],
      ),
    );
  }
}

class _EpisodeHeader extends StatelessWidget {
  const _EpisodeHeader({required this.manifest});

  final ReturnManifest manifest;

  @override
  Widget build(BuildContext context) {
    final episode = manifest.episode;
    final title = [
      if (manifest.showTitle.isNotEmpty) manifest.showTitle,
      if (episode.title != null && episode.title!.isNotEmpty) episode.title!,
    ].join(' — ');

    final details = [
      if (episode.startsAt != null)
        DateFormat('dd/MM/yyyy · HH:mm').format(episode.startsAt!),
      if (episode.studio != null && episode.studio!.isNotEmpty) episode.studio!,
      if (episode.city != null && episode.city!.isNotEmpty) episode.city!,
    ].join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.isEmpty ? episode.label : title,
            style: AppTypography.h3.copyWith(color: AppColors.textPrimary)),
        if (details.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(details,
              style:
                  AppTypography.bodySmall.copyWith(color: AppColors.textMuted)),
        ],
      ],
    );
  }
}

/// Headcount first: it is what the dispatcher sizes the vehicles from.
class _Totals extends StatelessWidget {
  const _Totals({required this.manifest, required this.s});

  final ReturnManifest manifest;
  final dynamic s;

  @override
  Widget build(BuildContext context) {
    Widget box(String label, int value, Color background, Color foreground) =>
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.md, horizontal: AppSpacing.sm),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$value',
                    style: AppTypography.h2.copyWith(color: foreground)),
                const SizedBox(height: 2),
                Text(label,
                    style: AppTypography.caption
                        .copyWith(color: AppColors.textMuted)),
              ],
            ),
          ),
        );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        box(s.staffManifestWaiting, manifest.riders, AppColors.secondary.withValues(alpha: 0.12),
            AppColors.secondary),
        const SizedBox(width: AppSpacing.sm),
        box(s.staffManifestOwnMeans, manifest.ownMeans, AppColors.backgroundWhite,
            AppColors.textPrimary),
        const SizedBox(width: AppSpacing.sm),
        box(s.staffManifestPeopleIn, manifest.checkedInPeople,
            AppColors.backgroundWhite, AppColors.textPrimary),
      ],
    );
  }
}

class _OrphanWarning extends StatelessWidget {
  const _OrphanWarning({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: AppColors.error, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(message,
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.errorDark)),
          ),
        ],
      ),
    );
  }
}

/// One stop. Collapsed to the headcount; the names open on tap, because the
/// driver needs them only once they are standing at the vehicle.
class _PointCard extends StatefulWidget {
  const _PointCard({required this.point, required this.isAr, required this.s});

  final ManifestPoint point;
  final bool isAr;
  final dynamic s;

  @override
  State<_PointCard> createState() => _PointCardState();
}

class _PointCardState extends State<_PointCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final point = widget.point;
    final s = widget.s;
    final empty = point.isEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: point.served ? AppColors.border : AppColors.error.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            // Nothing to unfold when nobody chose this stop.
            onTap: empty ? null : () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          point.localizedName(widget.isAr),
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight:
                                empty ? FontWeight.w400 : FontWeight.w600,
                            color: empty
                                ? AppColors.textMuted
                                : AppColors.textPrimary,
                          ),
                        ),
                        if (point.landmark != null && point.landmark!.isNotEmpty)
                          Text(point.landmark!,
                              style: AppTypography.caption
                                  .copyWith(color: AppColors.textMuted)),
                        if (!point.served)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(s.staffManifestOffList,
                                style: AppTypography.caption
                                    .copyWith(color: AppColors.error)),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        empty ? s.staffManifestEmptyStop : '${point.people}',
                        style: empty
                            ? AppTypography.bodySmall
                                .copyWith(color: AppColors.textLight)
                            : AppTypography.h2
                                .copyWith(color: AppColors.textPrimary),
                      ),
                      if (!empty)
                        Text(s.staffManifestPeople,
                            style: AppTypography.caption
                                .copyWith(color: AppColors.textMuted)),
                    ],
                  ),
                  if (!empty)
                    Icon(_open ? Icons.expand_less : Icons.expand_more,
                        color: AppColors.textMuted),
                ],
              ),
            ),
          ),
          if (_open)
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0,
                  AppSpacing.md, AppSpacing.md),
              child: Column(
                children: [
                  Divider(height: 1, color: AppColors.border),
                  const SizedBox(height: AppSpacing.sm),
                  for (final passenger in point.passengers)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(Icons.person_outline,
                              size: 16, color: AppColors.textMuted),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(passenger.name,
                                style: AppTypography.bodySmall),
                          ),
                          if (passenger.seats > 1)
                            Text('×${passenger.seats}',
                                style: AppTypography.bodySmall.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.secondary)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Sending it on ───────────────────────────────────────────────────────────

/// Two formats, because they are read by different people at different moments:
/// a PDF for the record and for the driver to tick names off, and a WhatsApp
/// message for the transport lead who just wants the numbers.
class _ShareButton extends ConsumerStatefulWidget {
  const _ShareButton({required this.manifest});

  final ReturnManifest manifest;

  @override
  ConsumerState<_ShareButton> createState() => _ShareButtonState();
}

class _ShareButtonState extends ConsumerState<_ShareButton> {
  bool _busy = false;

  Future<void> _sharePdf() async {
    final s = ref.read(stringsProvider);
    setState(() => _busy = true);
    try {
      final file = await ReturnManifestExport.writePdf(widget.manifest);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf')],
        subject: s.staffManifestTitle,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.staffManifestShareError)),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _shareText() async {
    await Share.share(ReturnManifestExport.buildText(widget.manifest));
  }

  void _openSheet() {
    final s = ref.read(stringsProvider);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceOverlay,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.md),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined,
                  color: AppColors.secondary),
              title: Text(s.staffManifestSharePdf,
                  style: AppTypography.bodyMedium),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _sharePdf();
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat_bubble_outline,
                  color: AppColors.secondary),
              title: Text(s.staffManifestShareText,
                  style: AppTypography.bodyMedium),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _shareText();
              },
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);

    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: _busy ? null : _openSheet,
        icon: _busy
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.onSecondary),
              )
            : const Icon(Icons.ios_share),
        label: Text(s.staffManifestShare),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.secondary,
          // FilledButton defaults its ink to onPrimary (white), which is
          // 2.1:1 on this gold.
          foregroundColor: AppColors.onSecondary,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        ),
      ),
    );
  }
}

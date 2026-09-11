import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:aji_tfarraj/app/copywriting/departure_copy.dart';
import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';
import 'package:aji_tfarraj/app/design_system/states.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';
import 'package:aji_tfarraj/app/localization/locale_provider.dart';
import 'package:aji_tfarraj/app/network/api_client.dart';
import 'package:aji_tfarraj/features/staff/data/staff_repository.dart';
import 'package:aji_tfarraj/features/staff/domain/attendee.dart';
import 'package:aji_tfarraj/features/staff/presentation/return_manifest_screen.dart'
    show StaffEpisodePicker;

/// "Présents": everyone the door let in for one recording — and the one place
/// to note that somebody left before the end.
///
/// People are found by typing part of their name (or a ticket code): by the
/// time someone walks out, nobody is holding their ticket. The reason given
/// decides nothing about the money — every departure forfeits the evening —
/// but an exclusion follows the person to their next visit.
///
/// [episodeId] comes from the ticket just scanned; without it the screen asks
/// which recording.
class AttendeesScreen extends ConsumerStatefulWidget {
  const AttendeesScreen({super.key, this.episodeId});

  final int? episodeId;

  @override
  ConsumerState<AttendeesScreen> createState() => _AttendeesScreenState();
}

class _AttendeesScreenState extends ConsumerState<AttendeesScreen> {
  int? _episodeId;

  @override
  void initState() {
    super.initState();
    _episodeId = widget.episodeId;
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(stringsProvider).departures;

    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      appBar: AppBar(
        title: Text(c.title, style: AppTypography.h3),
        actions: [
          if (_episodeId != null)
            IconButton(
              tooltip: c.refresh,
              icon: const Icon(Icons.refresh),
              onPressed: () => ref.invalidate(attendeesProvider(_episodeId!)),
            ),
        ],
      ),
      body: _episodeId == null
          ? StaffEpisodePicker(onPick: (id) => setState(() => _episodeId = id))
          : _AttendeesBody(episodeId: _episodeId!),
    );
  }
}

// ─── The list ────────────────────────────────────────────────────────────────

class _AttendeesBody extends ConsumerStatefulWidget {
  const _AttendeesBody({required this.episodeId});

  final int episodeId;

  @override
  ConsumerState<_AttendeesBody> createState() => _AttendeesBodyState();
}

class _AttendeesBodyState extends ConsumerState<_AttendeesBody> {
  final _search = TextEditingController();
  String _query = '';

  /// Rows changed from this phone since the list was loaded, laid over it — so
  /// a departure shows at once instead of after a reload.
  final _changed = <Attendee>[];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _open(Attendee attendee) async {
    final updated = await showModalBottomSheet<Attendee>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: AppColors.backgroundWhite,
      builder: (_) => DepartureSheet(attendee: attendee),
    );
    if (updated == null || !mounted) return;

    setState(() {
      _changed.removeWhere((a) => a.sameAs(updated));
      _changed.add(updated);
    });

    final c = ref.read(stringsProvider).departures;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(updated.hasLeft ? c.recorded : c.undone),
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _reload() async {
    ref.invalidate(attendeesProvider(widget.episodeId));
    await ref.read(attendeesProvider(widget.episodeId).future);
    // The server now has everything this phone changed.
    if (mounted) setState(_changed.clear);
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(stringsProvider).departures;
    final list = ref.watch(attendeesProvider(widget.episodeId));

    return list.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => ErrorState(
        message: c.loadError,
        retryText: c.refresh,
        onRetry: () => ref.invalidate(attendeesProvider(widget.episodeId)),
      ),
      data: (loaded) {
        var data = loaded;
        for (final a in _changed) {
          data = data.replacing(a);
        }
        final results = data.search(_query);

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _search,
                    onChanged: (v) => setState(() => _query = v),
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: c.searchHint,
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                _search.clear();
                                setState(() => _query = '');
                              },
                            ),
                      filled: true,
                      fillColor: AppColors.backgroundWhite,
                      border: _outline(AppColors.border),
                      enabledBorder: _outline(AppColors.border),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    [
                      // Isolated, so a Latin title keeps its place in an Arabic line.
                      if (data.showTitle.isNotEmpty) '\u2068${data.showTitle}\u2069',
                      c.counts(data.presentCount, data.leftCount),
                    ].join(' · '),
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _reload,
                child: data.attendees.isEmpty
                    ? ListView(children: [
                        EmptyState(
                          icon: Icons.groups_outlined,
                          title: c.empty,
                          description: c.emptySubtitle,
                        ),
                      ])
                    : results.isEmpty
                        ? ListView(
                            padding: const EdgeInsets.all(AppSpacing.xl),
                            children: [
                              Text(c.noMatch,
                                  textAlign: TextAlign.center,
                                  style: AppTypography.bodyMedium
                                      .copyWith(color: AppColors.textMuted)),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(AppSpacing.lg,
                                AppSpacing.xs, AppSpacing.lg, AppSpacing.xxl),
                            itemCount: results.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: AppSpacing.sm),
                            itemBuilder: (_, i) => _AttendeeTile(
                              attendee: results[i],
                              onTap: () => _open(results[i]),
                            ),
                          ),
              ),
            ),
          ],
        );
      },
    );
  }
}

OutlineInputBorder _outline(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      borderSide: BorderSide(color: color),
    );

String _time(DateTime at) => DateFormat('HH:mm').format(at);

/// Ticket code (or "no account"), who brought them, when they came in.
String _subtitle(DepartureCopy c, Attendee a) => [
      a.ticketCode ?? c.walkIn,
      if (a.chargePublic != null && a.chargePublic!.isNotEmpty)
        c.broughtBy(a.chargePublic!),
      if (a.checkedInAt != null) c.checkedInAt(_time(a.checkedInAt!)),
    ].join(' · ');

class _AttendeeTile extends ConsumerWidget {
  const _AttendeeTile({required this.attendee, required this.onTap});

  final Attendee attendee;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(stringsProvider).departures;
    final departure = attendee.departure;
    final radius = BorderRadius.circular(AppSpacing.radiusMd);

    return Material(
      color: AppColors.backgroundWhite,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: attendee.wasExcludedBefore
                  ? AppColors.error.withValues(alpha: 0.5)
                  : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              _Avatar(attendee: attendee, size: 44),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      attendee.name,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: departure != null
                            ? AppColors.textMuted
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _subtitle(c, attendee),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.textMuted),
                    ),
                    if (departure != null || attendee.wasExcludedBefore) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: [
                          if (departure != null)
                            _Tag(
                              icon: Icons.logout,
                              label:
                                  '${c.leftAt(_time(departure.at))} · ${c.reason(departure.reason.key)}',
                              color: departure.isExclusion
                                  ? AppColors.error
                                  : AppColors.textMuted,
                            ),
                          if (attendee.wasExcludedBefore)
                            _Tag(
                              icon: Icons.report_gmailerrorred_outlined,
                              label: c.excludedBefore(attendee.pastExclusions),
                              color: AppColors.error,
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Recording a departure ───────────────────────────────────────────────────

/// Record why someone left — or, once recorded, see it and undo it.
///
/// Photo and name come first, so the scanner checks it is the right person
/// before taking their evening away.
class DepartureSheet extends ConsumerStatefulWidget {
  const DepartureSheet({super.key, required this.attendee});

  final Attendee attendee;

  @override
  ConsumerState<DepartureSheet> createState() => _DepartureSheetState();
}

class _DepartureSheetState extends ConsumerState<DepartureSheet> {
  DepartureReason? _reason;
  final _note = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  bool get _canConfirm =>
      !_saving &&
      _reason != null &&
      (!_reason!.needsNote || _note.text.trim().isNotEmpty);

  Future<void> _record() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final updated = await ref.read(staffRepositoryProvider).recordDeparture(
            attendee: widget.attendee,
            reason: _reason!,
            note: _note.text,
          );
      if (mounted) Navigator.of(context).pop(updated);
    } catch (e) {
      _fail(e);
    }
  }

  Future<void> _undo() async {
    final c = ref.read(stringsProvider).departures;
    final sure = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(c.undoConfirmTitle),
        content: Text(c.undoConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(c.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(c.undo),
          ),
        ],
      ),
    );
    if (sure != true || !mounted) return;

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final updated =
          await ref.read(staffRepositoryProvider).undoDeparture(widget.attendee);
      if (mounted) Navigator.of(context).pop(updated);
    } catch (e) {
      _fail(e);
    }
  }

  void _fail(Object e) {
    if (!mounted) return;
    setState(() {
      _saving = false;
      _error = e is ApiException
          ? e.message
          : ref.read(stringsProvider).departures.saveError;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(stringsProvider).departures;
    final a = widget.attendee;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _Avatar(attendee: a, size: 56),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a.name, style: AppTypography.h3),
                      Text(_subtitle(c, a),
                          style: AppTypography.bodySmall
                              .copyWith(color: AppColors.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
            if (a.wasExcludedBefore) ...[
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: _Tag(
                  icon: Icons.report_gmailerrorred_outlined,
                  label: c.excludedBefore(a.pastExclusions),
                  color: AppColors.error,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            if (a.departure != null)
              ..._recorded(c, a.departure!)
            else
              ..._form(c, a),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(_error!,
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.errorDark)),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _form(DepartureCopy c, Attendee a) => [
        Text(c.sheetTitle, style: AppTypography.h3),
        const SizedBox(height: AppSpacing.xs),
        Text(c.reasonQuestion,
            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted)),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final r in DepartureReason.choices)
              ChoiceChip(
                label: Text(c.reason(r.key)),
                selected: _reason == r,
                selectedColor: (r == DepartureReason.excluded
                        ? AppColors.error
                        : AppColors.primary)
                    .withValues(alpha: 0.18),
                onSelected:
                    _saving ? null : (_) => setState(() => _reason = r),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _note,
          enabled: !_saving,
          minLines: 2,
          maxLines: 4,
          maxLength: 500,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: c.noteLabel,
            hintText: _reason?.needsNote == true
                ? c.noteRequired
                : c.noteHintOptional,
            border: _outline(AppColors.border),
          ),
        ),
        _Notice(
          text: a.hasAccount ? c.consequence : c.consequenceWalkIn,
          color: AppColors.warning,
        ),
        if (_reason == DepartureReason.excluded && a.hasAccount) ...[
          const SizedBox(height: AppSpacing.xs),
          _Notice(text: c.exclusionNote, color: AppColors.error),
        ],
        const SizedBox(height: AppSpacing.lg),
        FilledButton(
          onPressed: _canConfirm ? _record : null,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.error,
            minimumSize: const Size.fromHeight(52),
          ),
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(c.confirm),
        ),
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: Text(c.cancel),
        ),
      ];

  List<Widget> _recorded(DepartureCopy c, Departure d) => [
        _Notice(
          text: c.doorAlreadyLeft(_time(d.at), c.reason(d.reason.key)),
          color: d.isExclusion ? AppColors.error : AppColors.warning,
        ),
        if (d.note != null && d.note!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(d.note!, style: AppTypography.bodyMedium),
        ],
        if (d.recordedBy != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(c.recordedBy(d.recordedBy!),
              style:
                  AppTypography.bodySmall.copyWith(color: AppColors.textMuted)),
        ],
        const SizedBox(height: AppSpacing.lg),
        OutlinedButton.icon(
          onPressed: _saving ? null : _undo,
          icon: const Icon(Icons.undo),
          label: Text(c.undo),
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
        ),
      ];
}

// ─── Small pieces ────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  const _Avatar({required this.attendee, required this.size});

  final Attendee attendee;
  final double size;

  @override
  Widget build(BuildContext context) {
    final url = attendee.photoUrl;
    final initials = attendee.name
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty && w != '—')
        .take(2)
        .map((w) => w.characters.first.toUpperCase())
        .join();

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: AppColors.border,
      foregroundImage: url != null ? NetworkImage(url) : null,
      onForegroundImageError: url != null ? (_, __) {} : null,
      child: Text(initials,
          style: AppTypography.bodySmall.copyWith(
              color: AppColors.textMuted, fontWeight: FontWeight.w700)),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(label,
                style: AppTypography.bodySmall
                    .copyWith(color: color, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(text,
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }
}

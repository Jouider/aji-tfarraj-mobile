import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';
import 'package:aji_tfarraj/app/localization/app_locale.dart';
import 'package:aji_tfarraj/app/localization/locale_provider.dart';
import 'package:aji_tfarraj/app/network/api_client.dart';
import 'package:aji_tfarraj/features/casting/data/casting_repository.dart';
import 'package:aji_tfarraj/features/casting/domain/casting_models.dart';
import 'package:aji_tfarraj/features/casting/presentation/casting_book_screen.dart';
import 'package:aji_tfarraj/features/casting/presentation/casting_home_screen.dart';

/// One call, and the way to apply to it.
class CastingDetailScreen extends ConsumerStatefulWidget {
  const CastingDetailScreen({super.key, required this.call});

  final CastingCall call;

  @override
  ConsumerState<CastingDetailScreen> createState() =>
      _CastingDetailScreenState();
}

class _CastingDetailScreenState extends ConsumerState<CastingDetailScreen> {
  final _note = TextEditingController();
  bool _sending = false;
  ApplicationStatus? _justApplied;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    final s = ref.read(stringsProvider);
    setState(() => _sending = true);
    try {
      await ref.read(castingRepositoryProvider).apply(
            castingId: widget.call.id,
            note: _note.text.trim(),
          );
      ref.invalidate(castingFeedProvider(widget.call.type));
      ref.invalidate(myApplicationsProvider);
      if (!mounted) return;
      setState(() => _justApplied = ApplicationStatus.pending);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s.casting.applySent)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        // The server says *why* — book incomplete, call closed, wrong profile —
        // and each of those is a different next step for the person.
        content: Text(e is ApiException ? e.message : s.casting.applyError),
        backgroundColor: AppColors.error,
      ));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final isAr = ref.watch(localeProvider) == AppLocale.ar;
    final call = widget.call;

    final book = ref.watch(castingBookProvider);
    final bookReady = book.valueOrNull?.isComplete ?? false;
    final status = _justApplied ?? call.applicationStatus;

    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      appBar: AppBar(title: Text(s.casting.title, style: AppTypography.h3)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
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
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(call.localizedTitle(isAr),
                    style: AppTypography.h2
                        .copyWith(color: AppColors.textPrimary)),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    if (call.city != null && call.city!.isNotEmpty)
                      _Tag(icon: Icons.place_outlined, label: call.city!),
                    if (call.minAge != null || call.maxAge != null)
                      _Tag(
                        icon: Icons.cake_outlined,
                        label: [
                          if (call.minAge != null) '${call.minAge}',
                          if (call.maxAge != null) '${call.maxAge}',
                        ].join(' – ') + ' ans',
                      ),
                    if (call.closesAt != null)
                      _Tag(
                        icon: Icons.event_outlined,
                        label:
                            '${s.casting.closesAt} ${DateFormat('dd/MM/yyyy').format(call.closesAt!)}',
                      ),
                  ],
                ),

                if (status != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  ApplicationBadge(status: status),
                ],

                if (call.localizedDescription(isAr)?.isNotEmpty ?? false) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Text(call.localizedDescription(isAr)!,
                      style: AppTypography.bodyMedium),
                ],

                const SizedBox(height: AppSpacing.xl),

                if (status != null)
                  _Done(label: s.casting.applied)
                else if (!bookReady)
                  // The reason the button is missing, and the way to fix it —
                  // a dead "Postuler" would just invite tapping.
                  _BlockedCard(
                    message: s.casting.applyBlocked,
                    actionLabel: s.casting.bookTitle,
                    onAction: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const CastingBookScreen())),
                  )
                else ...[
                  TextField(
                    controller: _note,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: s.casting.applyNote,
                      hintText: s.casting.applyNoteHint,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    height: AppSpacing.buttonHeight,
                    child: FilledButton(
                      onPressed: _sending ? null : _apply,
                      style: FilledButton.styleFrom(
                          backgroundColor: AppColors.secondary),
                      child: _sending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text(s.casting.apply),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textMuted),
          const SizedBox(width: 5),
          Text(label,
              style: AppTypography.caption
                  .copyWith(color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _Done extends StatelessWidget {
  const _Done({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.successLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.success, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(label,
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.successDark)),
          ),
        ],
      ),
    );
  }
}

class _BlockedCard extends StatelessWidget {
  const _BlockedCard({
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.photo_camera_outlined,
                  color: AppColors.secondary, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(message, style: AppTypography.bodyMedium),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onAction,
              style:
                  FilledButton.styleFrom(backgroundColor: AppColors.secondary),
              child: Text(actionLabel),
            ),
          ),
        ],
      ),
    );
  }
}

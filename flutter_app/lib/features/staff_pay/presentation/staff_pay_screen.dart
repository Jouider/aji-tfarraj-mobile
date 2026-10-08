import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aji_tfarraj/app/copywriting/staff_pay_copy.dart';
import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';
import 'package:aji_tfarraj/app/localization/locale_provider.dart';
import 'package:aji_tfarraj/features/charge_public/data/charge_public_repository.dart';
import 'package:aji_tfarraj/features/charge_public/presentation/wafacash_section.dart';
import 'package:aji_tfarraj/features/staff_pay/data/staff_pay_repository.dart';
import 'package:aji_tfarraj/features/staff_pay/domain/staff_pay.dart';

/// « Ma paie » : ce que le staff a gagné épisode par épisode, et le retrait.
///
/// Le total d'abord, puis le poste et ce qu'il paie, le retrait Wafacash — le
/// même que celui des chargés publics, sur le même solde —, et l'historique
/// mois par mois.
class StaffPayScreen extends ConsumerWidget {
  const StaffPayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(stringsProvider).staffPay;
    final state = ref.watch(staffPayProvider);

    Future<void> refresh() async {
      ref.invalidate(wafacashProvider);
      ref.invalidate(cpDashboardProvider);
      ref.invalidate(staffPayProvider);
      await ref.read(staffPayProvider.future);
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(title: Text(c.title)),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(c.loadError,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium
                        .copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: AppSpacing.md),
                TextButton(
                  onPressed: () => ref.invalidate(staffPayProvider),
                  child: Text(c.retry),
                ),
              ],
            ),
          ),
        ),
        data: (pay) => RefreshIndicator(
          onRefresh: refresh,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              _TotalCard(pay: pay, copy: c),
              const SizedBox(height: AppSpacing.md),
              for (final p in pay.currentPositions) ...[
                _PositionTile(position: p, copy: c),
                const SizedBox(height: AppSpacing.sm),
              ],
              if (pay.pending > 0) ...[
                _PendingNote(text: c.pendingNote(pay.pending)),
                const SizedBox(height: AppSpacing.sm),
              ],
              // Retirer, juste sous le total. Invisible tant que les retraits
              // Wafacash ne sont pas ouverts.
              WafacashSection(
                onChanged: () {
                  ref.invalidate(staffPayProvider);
                  ref.invalidate(cpDashboardProvider);
                },
              ),
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(c.withdrawHint,
                    style: AppTypography.caption
                        .copyWith(color: AppColors.textMuted)),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(c.historyTitle, style: AppTypography.h4),
              const SizedBox(height: AppSpacing.sm),
              if (pay.lines.isEmpty)
                Text(c.empty,
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.textSecondary))
              else
                ..._history(pay, c),
            ],
          ),
        ),
      ),
    );
  }

  /// Les lignes, mois par mois. Le poste n'est rappelé que si la personne
  /// en a eu plusieurs.
  List<Widget> _history(StaffPayOverview pay, StaffPayCopy c) {
    final showPosition = pay.lines.map((l) => l.position).toSet().length > 1;
    final widgets = <Widget>[];
    String? month;

    for (final line in pay.lines) {
      final m = c.month(line.date);
      if (m != month) {
        month = m;
        widgets.add(Padding(
          padding: EdgeInsets.only(
              top: widgets.isEmpty ? 0 : AppSpacing.md, bottom: AppSpacing.xs),
          child: Text(m,
              style: AppTypography.labelMedium
                  .copyWith(color: AppColors.textMuted)),
        ));
      }
      widgets.add(_LineRow(line: line, copy: c, showPosition: showPosition));
    }

    return widgets;
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.pay, required this.copy});

  final StaffPayOverview pay;
  final StaffPayCopy copy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.cardDarkElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(copy.totalEarned,
              style:
                  AppTypography.caption.copyWith(color: AppColors.textMuted)),
          const SizedBox(height: AppSpacing.xs),
          Text(
            copy.money(pay.total),
            style: AppTypography.h1.copyWith(
              color: AppColors.successDark,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(copy.episodes(pay.episodes),
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.md),
          Divider(height: 1, color: AppColors.border),
          const SizedBox(height: AppSpacing.md),
          Text(
            copy.available(copy.money(pay.available)),
            style: AppTypography.labelLarge,
          ),
        ],
      ),
    );
  }
}

class _PositionTile extends StatelessWidget {
  const _PositionTile({required this.position, required this.copy});

  final StaffPosition position;
  final StaffPayCopy copy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.backgroundGrey,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            switch (position.position) {
              'tech' => Icons.qr_code_scanner,
              'warm_up' => Icons.mic_none_rounded,
              _ => Icons.groups_outlined,
            },
            color: AppColors.accentInk,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(copy.position(position.position),
                    style: AppTypography.labelLarge),
                const SizedBox(height: 2),
                Text(copy.rateLine(position.position),
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(copy.since(copy.date(position.startsOn)),
                    style: AppTypography.caption
                        .copyWith(color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingNote extends StatelessWidget {
  const _PendingNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.schedule, size: 18, color: AppColors.warningDark),
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

class _LineRow extends StatelessWidget {
  const _LineRow({
    required this.line,
    required this.copy,
    required this.showPosition,
  });

  final StaffPayLine line;
  final StaffPayCopy copy;
  final bool showPosition;

  @override
  Widget build(BuildContext context) {
    final detail = [
      if (showPosition) copy.position(line.position),
      line.isTech ? copy.entries(line.entries) : copy.size(line.size),
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: Text(copy.date(line.date),
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.textSecondary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                )),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(line.show ?? '—',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyMedium),
                Text(detail,
                    style: AppTypography.caption
                        .copyWith(color: AppColors.textMuted)),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            line.pending ? copy.pendingAmount : copy.money(line.amount),
            style: AppTypography.labelLarge.copyWith(
              color: line.pending ? AppColors.warningDark : null,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

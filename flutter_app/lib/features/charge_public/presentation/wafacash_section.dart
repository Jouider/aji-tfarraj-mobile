import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;

import 'package:aji_tfarraj/app/copywriting/wafacash_copy.dart';
import 'package:aji_tfarraj/app/design_system/buttons.dart';
import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';
import 'package:aji_tfarraj/app/localization/locale_provider.dart';
import 'package:aji_tfarraj/app/network/api_client.dart';
import 'package:aji_tfarraj/features/charge_public/data/charge_public_repository.dart';
import 'package:aji_tfarraj/features/charge_public/domain/wafacash.dart';
import 'package:aji_tfarraj/features/charge_public/presentation/wafacash_identity_screen.dart';

/// Retirer ses gains via Wafacash, dans l'onglet « Gains ».
///
/// Rien ne s'affiche tant que le staff n'a pas ouvert les retraits — ni si le
/// serveur ne connaît pas encore cette fonction : l'onglet doit rester
/// utilisable sans elle.
class WafacashSection extends ConsumerWidget {
  const WafacashSection({super.key, required this.onChanged});

  /// Une demande change le solde affiché plus haut : l'onglet se recharge.
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(wafacashProvider);
    final c = ref.watch(stringsProvider).wafacash;

    return state.maybeWhen(
      data: (o) {
        if (!o.open && o.current == null) return const SizedBox.shrink();

        final current = o.current;
        final closed =
            o.withdrawals.where((w) => !w.status.isOpen).take(5).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.lg),
            if (current != null)
              _StatusCard(withdrawal: current, copy: c, onChanged: onChanged)
            else
              _WithdrawCard(overview: o, copy: c, onChanged: onChanged),
            if (closed.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              Text(c.historyTitle, style: AppTypography.labelLarge),
              const SizedBox(height: AppSpacing.sm),
              for (final w in closed) _HistoryRow(withdrawal: w, copy: c),
            ],
          ],
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

// ─── Demander ────────────────────────────────────────────────────────────────

class _WithdrawCard extends ConsumerWidget {
  const _WithdrawCard({
    required this.overview,
    required this.copy,
    required this.onChanged,
  });

  final WafacashOverview overview;
  final WafacashCopy copy;
  final VoidCallback onChanged;

  Future<void> _start(BuildContext context, WidgetRef ref) async {
    final identity = overview.identity;

    // Pas encore d'identité, ou refusée : l'envoyer d'abord, une fois.
    if (identity == null ||
        identity.status == WafacashIdentityStatus.rejected) {
      final sent = await Navigator.of(context).push<bool>(MaterialPageRoute(
        builder: (_) =>
            WafacashIdentityScreen(initialName: identity?.legalName),
      ));
      if (sent == true) onChanged();
      return;
    }

    if (!identity.isVerified) return;

    final done = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: AppColors.backgroundWhite,
      builder: (_) => _WithdrawSheet(overview: overview),
    );
    if (done == true) onChanged();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identity = overview.identity;
    final pending = identity?.status == WafacashIdentityStatus.pending;
    final rejected = identity?.status == WafacashIdentityStatus.rejected;
    final verified = identity?.isVerified ?? false;

    return _Card(
      children: [
        Row(
          children: [
            const Icon(Icons.payments_outlined, color: AppColors.primaryAction),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(copy.cardTitle, style: AppTypography.h4)),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(copy.cardAvailable(copy.money(overview.balance.available)),
            style: AppTypography.labelLarge
                .copyWith(color: AppColors.successDark)),
        const SizedBox(height: AppSpacing.xs),
        Text(copy.cardHowItWorks,
            style: AppTypography.bodySmall
                .copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: AppSpacing.md),
        if (pending)
          _Notice(icon: Icons.hourglass_top, text: copy.identityPending)
        else ...[
          if (rejected) ...[
            _Notice(
              icon: Icons.error_outline,
              text: copy.identityRejected(identity!.rejectionReason ?? ''),
              color: AppColors.errorDark,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          AppButton(
            text: rejected
                ? copy.resend
                : verified
                    ? copy.cardWithdraw
                    : copy.identityStart,
            icon: verified ? Icons.arrow_downward : Icons.badge_outlined,
            // Vérifié mais sous le minimum : le bouton n'aurait rien à proposer.
            onPressed: (verified && !overview.hasEnough)
                ? null
                : () => _start(context, ref),
          ),
          if (verified && !overview.hasEnough) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(copy.cardBelowMin(copy.money(overview.minAmount)),
                textAlign: TextAlign.center,
                style:
                    AppTypography.caption.copyWith(color: AppColors.textMuted)),
          ],
        ],
      ],
    );
  }
}

/// Le montant à retirer. Les frais de l'agence sont à la charge du chargé
/// public ; on le dit d'une ligne, sans les chiffrer.
class _WithdrawSheet extends ConsumerStatefulWidget {
  const _WithdrawSheet({required this.overview});

  final WafacashOverview overview;

  @override
  ConsumerState<_WithdrawSheet> createState() => _WithdrawSheetState();
}

class _WithdrawSheetState extends ConsumerState<_WithdrawSheet> {
  late final _amount =
      TextEditingController(text: widget.overview.maxRequestable.toString());
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  int get _value => int.tryParse(_amount.text.trim()) ?? 0;

  /// Ce qui empêche de demander ce montant, ou null.
  String? _problem(WafacashCopy c) {
    final o = widget.overview;
    final v = _value;
    if (v < o.minAmount) return c.belowMin(c.money(o.minAmount));
    if (v > o.balance.available) {
      return c.aboveAvailable(c.money(o.balance.available));
    }
    if (v > o.maxAmount) return c.aboveMax(c.money(o.maxAmount));
    if (o.quote(v) == null) return c.beyondGrid;
    return null;
  }

  Future<void> _confirm() async {
    final c = ref.read(stringsProvider).wafacash;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await ref.read(wafacashRepositoryProvider).request(_value);
      ref.invalidate(wafacashProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(c.requested),
        behavior: SnackBarBehavior.floating,
      ));
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = e is ApiException ? e.message : c.genericError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(stringsProvider).wafacash;
    final o = widget.overview;
    final problem = _problem(c);

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
            Text(c.requestTitle, style: AppTypography.h3),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _amount,
              enabled: !_sending,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: AppTypography.h2,
              onChanged: (_) => setState(() => _error = null),
              decoration: InputDecoration(
                labelText: c.amountLabel,
                suffixText: c.money(0).replaceAll('0', '').trim(),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                for (final v
                    in {o.minAmount, 200, 500, o.maxRequestable}
                        .where((v) => v >= o.minAmount && v <= o.maxRequestable)
                        .toList()
                      ..sort())
                  ActionChip(
                    label: Text(v == o.maxRequestable ? c.all : c.money(v)),
                    onPressed: _sending
                        ? null
                        : () => setState(() {
                              _amount.text = v.toString();
                              _error = null;
                            }),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            // Pas de chiffre : les tarifs sont ceux de Wafacash, pas les
            // nôtres. Une ligne suffit à dire qui les paie.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 14, color: AppColors.textMuted),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(c.feesOnYou,
                      style: AppTypography.caption
                          .copyWith(color: AppColors.textMuted)),
                ),
              ],
            ),
            if (problem != null || _error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(_error ?? problem!,
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.errorDark)),
            ],
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              text: c.confirm,
              isLoading: _sending,
              onPressed: problem == null ? _confirm : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Suivre ──────────────────────────────────────────────────────────────────

class _StatusCard extends ConsumerStatefulWidget {
  const _StatusCard({
    required this.withdrawal,
    required this.copy,
    required this.onChanged,
  });

  final WafacashWithdrawal withdrawal;
  final WafacashCopy copy;
  final VoidCallback onChanged;

  @override
  ConsumerState<_StatusCard> createState() => _StatusCardState();
}

class _StatusCardState extends ConsumerState<_StatusCard> {
  bool _busy = false;

  Future<void> _act(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
      ref.invalidate(wafacashProvider);
      widget.onChanged();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e is ApiException ? e.message : widget.copy.genericError),
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel() async {
    final c = widget.copy;
    final sure = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(c.cancelConfirmTitle),
        content: Text(c.cancelConfirmBody),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(c.keep)),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(c.cancel)),
        ],
      ),
    );
    if (sure != true) return;
    await _act(() =>
        ref.read(wafacashRepositoryProvider).cancel(widget.withdrawal.id));
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.withdrawal;
    final c = widget.copy;
    final ready = w.status == WafacashWithdrawalStatus.codeSent;

    final (title, hint) = switch (w.status) {
      WafacashWithdrawalStatus.processing => (
          c.statusProcessing,
          c.statusProcessingHint
        ),
      WafacashWithdrawalStatus.codeSent => (c.statusCodeSent, null),
      _ => (c.statusRequested, c.statusRequestedHint),
    };

    return _Card(
      highlight: ready,
      children: [
        _Steps(status: w.status),
        const SizedBox(height: AppSpacing.md),
        Text(title, style: AppTypography.h4),
        if (hint != null) ...[
          const SizedBox(height: 2),
          Text(hint,
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textSecondary)),
        ],
        const SizedBox(height: AppSpacing.sm),
        // Toujours le montant demandé : c'est ce qu'Aji Tfarraj paie. Ce
        // qu'en garde l'agence, c'est sa règle, pas la nôtre.
        Text(
          c.requestedAmount(c.money(w.grossAmount)),
          style: AppTypography.caption.copyWith(color: AppColors.textMuted),
        ),
        if (ready && w.code != null) ...[
          const SizedBox(height: AppSpacing.md),
          _CodeBox(code: w.code!, copy: c),
          const SizedBox(height: AppSpacing.sm),
          Text(c.codeInstructions(w.legalName),
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            text: c.iCollected,
            icon: Icons.check_circle_outline,
            isLoading: _busy,
            onPressed: () => _act(
                () => ref.read(wafacashRepositoryProvider).markCollected(w.id)),
          ),
        ],
        if (w.canCancel) ...[
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: _busy ? null : _cancel,
            child: Text(c.cancel),
          ),
        ],
      ],
    );
  }
}

/// Trois étapes, pour qu'on sache où on en est sans lire le texte.
class _Steps extends StatelessWidget {
  const _Steps({required this.status});

  final WafacashWithdrawalStatus status;

  @override
  Widget build(BuildContext context) {
    final reached = switch (status) {
      WafacashWithdrawalStatus.requested => 1,
      WafacashWithdrawalStatus.processing => 2,
      _ => 3,
    };

    return Row(
      children: [
        for (var i = 1; i <= 3; i++) ...[
          Expanded(
            child: Container(
              height: 5,
              decoration: BoxDecoration(
                color:
                    i <= reached ? AppColors.primaryAction : AppColors.border,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          if (i < 3) const SizedBox(width: 4),
        ],
      ],
    );
  }
}

/// Le code, gros et copiable : c'est ce qu'on recopie au guichet.
class _CodeBox extends StatelessWidget {
  const _CodeBox({required this.code, required this.copy});

  final String code;
  final WafacashCopy copy;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      onTap: () {
        Clipboard.setData(ClipboardData(text: code));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(copy.codeCopied),
          behavior: SnackBarBehavior.floating,
        ));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.backgroundGrey,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border:
              Border.all(color: AppColors.primaryAction.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(copy.codeLabel,
                      style: AppTypography.caption
                          .copyWith(color: AppColors.textMuted)),
                  // Toujours de gauche à droite : un code ne se lit pas en arabe.
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      code,
                      // Chiffres à chasse fixe et espacés plutôt qu'une
                      // police à part : la typographie reste celle de l'app,
                      // et un 1 ne se confond pas avec un 7 au guichet.
                      style: AppTypography.h2.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.copy_rounded, color: AppColors.primaryAction),
          ],
        ),
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.withdrawal, required this.copy});

  final WafacashWithdrawal withdrawal;
  final WafacashCopy copy;

  @override
  Widget build(BuildContext context) {
    final w = withdrawal;
    final (label, color) = switch (w.status) {
      WafacashWithdrawalStatus.collected => (
          copy.statusCollected,
          AppColors.successDark
        ),
      WafacashWithdrawalStatus.rejected => (
          copy.statusRejected,
          AppColors.errorDark
        ),
      WafacashWithdrawalStatus.expired => (
          copy.statusExpired,
          AppColors.textSecondary
        ),
      _ => (copy.statusCancelled, AppColors.textMuted),
    };
    final at = w.collectedAt ?? w.closedAt ?? w.requestedAt;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Le montant payé par Aji Tfarraj, frais d'agence compris.
                Text(copy.money(w.grossAmount),
                    style: AppTypography.labelMedium),
                if (w.status == WafacashWithdrawalStatus.rejected &&
                    (w.closedReason ?? '').isNotEmpty)
                  Text(w.closedReason!,
                      style: AppTypography.caption
                          .copyWith(color: AppColors.textMuted)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(label,
                  style: AppTypography.caption
                      .copyWith(color: color, fontWeight: FontWeight.w600)),
              if (at != null)
                Text(DateFormat('dd/MM/yyyy').format(at),
                    style: AppTypography.caption
                        .copyWith(color: AppColors.textMuted)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Petites pièces ──────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  const _Card({required this.children, this.highlight = false});

  final List<Widget> children;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlight
              ? AppColors.primaryAction.withValues(alpha: 0.5)
              : AppColors.border,
          width: highlight ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.text, this.color});

  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? AppColors.textSecondary;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: tint),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child:
              Text(text, style: AppTypography.bodySmall.copyWith(color: tint)),
        ),
      ],
    );
  }
}

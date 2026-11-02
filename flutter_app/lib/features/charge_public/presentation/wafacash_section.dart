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
import 'package:aji_tfarraj/features/charge_public/presentation/wafacash_news.dart';

/// Retirer ses gains via Wafacash, dans l'onglet « Gains ».
///
/// Rien ne s'affiche si le serveur ne connaît pas cette fonction, ni quand les
/// retraits sont fermés et qu'il n'y a rien à retirer : l'onglet doit rester
/// utilisable sans elle. Fermés avec de l'argent sur le solde, on le dit :
/// Wafacash est le seul moyen d'être payé.
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
        // Retraits fermés, rien en cours, rien à retirer : rien à montrer —
        // sauf une demande que le staff vient d'annuler, dont la raison doit
        // être lue.
        final hasMoney = o.balance.available > 0 ||
            o.balance.held > 0 ||
            o.balance.deferred > 0;
        if (!o.open &&
            o.current == null &&
            o.lastCancelledByStaff == null &&
            !hasMoney) {
          return const SizedBox.shrink();
        }

        final current = o.current;
        final closed =
            o.withdrawals.where((w) => !w.status.isOpen).take(5).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.lg),
            if (current != null)
              _StatusCard(
                  withdrawal: current,
                  window: o.window,
                  copy: c,
                  onChanged: onChanged)
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
      // Au-dessus de la barre d'onglets flottante, pas dessous.
      useRootNavigator: true,
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
    final cancelled = overview.lastCancelledByStaff;
    final held = overview.balance.held;
    final deferred = overview.balance.deferred;
    final window = overview.window;
    // Fermé par le calendrier : le bouton dit quand il s'ouvrira. L'identité,
    // elle, s'envoie n'importe quel jour, pour être prêt à l'ouverture.
    final waitingForOpening = overview.open && !overview.canRequestNow;
    final nextOpening = window?.nextOpensAt;
    // L'argent en attente suffira à passer le minimum : la phrase sur ce qu'il
    // manque ne ferait que contredire celle sur ce qui arrive.
    final belowMin = verified &&
        !waitingForOpening &&
        !overview.hasEnough &&
        overview.balance.available + held + deferred < overview.minAmount;

    return _Card(
      highlight: cancelled != null,
      children: [
        // Pas un refus : le staff a annulé pour vérifier le solde après un
        // tournage. La raison, puis de quoi recommencer sur le solde corrigé.
        if (cancelled != null) ...[
          _Notice(
            icon: Icons.info_outline,
            text: copy.cancelledByStaff(
                copy.money(cancelled.grossAmount), cancelled.closedReason!),
            color: AppColors.warningDark,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        Row(
          children: [
            const Icon(Icons.payments_outlined, color: AppColors.primaryAction),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(copy.cardTitle, style: AppTypography.h4)),
          ],
        ),
        if (window != null && overview.open) ...[
          const SizedBox(height: AppSpacing.md),
          _WindowNotice(window: window, copy: copy),
        ],
        const SizedBox(height: AppSpacing.md),
        Text(waitingForOpening ? copy.availableAtOpening : copy.availableNow,
            style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
        Text(copy.money(overview.balance.available),
            style: AppTypography.h2.copyWith(color: AppColors.successDark)),
        if (held > 0) ...[
          const SizedBox(height: AppSpacing.sm),
          _Notice(
            icon: Icons.schedule,
            text: copy.heldNote(copy.money(held)),
          ),
        ],
        if (deferred > 0 && nextOpening != null) ...[
          const SizedBox(height: AppSpacing.sm),
          _Notice(
            icon: Icons.event_repeat_outlined,
            text:
                copy.deferredNote(copy.money(deferred), copy.date(nextOpening)),
          ),
        ],
        // Le premier retrait : ce qui l'attend, dans l'ordre.
        if (overview.open && overview.withdrawals.isEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          _FirstTimeSteps(steps: copy.firstTimeSteps, done: verified ? 1 : 0),
        ],
        const SizedBox(height: AppSpacing.md),
        if (!overview.open)
          _Notice(icon: Icons.lock_clock_outlined, text: copy.closedNotice)
        else if (pending)
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
                : !verified
                    ? copy.identityStart
                    : waitingForOpening && nextOpening != null
                        ? copy.windowClosedButton(copy.date(nextOpening))
                        : cancelled != null
                            ? copy.requestAgain
                            : copy.cardWithdraw,
            icon: !verified
                ? Icons.badge_outlined
                : waitingForOpening
                    ? Icons.event_outlined
                    : Icons.arrow_downward,
            // Vérifié mais fermé ce mois-ci, ou sous le minimum : le bouton
            // n'aurait rien à proposer.
            onPressed: (verified && (waitingForOpening || !overview.hasEnough))
                ? null
                : () => _start(context, ref),
          ),
          if (belowMin) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
                copy.cardBelowMin(copy.money(overview.missingForMin),
                    copy.money(overview.minAmount)),
                textAlign: TextAlign.center,
                style:
                    AppTypography.caption.copyWith(color: AppColors.textMuted)),
          ],
        ],
        // Les règles restent à portée, une fois l'annonce fermée.
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            onPressed: () => showWafacashNews(context, overview),
            icon: const Icon(Icons.help_outline, size: 16),
            label: Text(copy.howItWorksLink),
          ),
        ),
      ],
    );
  }
}

/// Quand on peut demander : la règle du mois, et où on en est. Vert quand c'est
/// ouvert, parce que c'est le moment d'agir ; neutre sinon.
class _WindowNotice extends StatelessWidget {
  const _WindowNotice({required this.window, required this.copy});

  final WafacashWindow window;
  final WafacashCopy copy;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final exception = window.exceptionUntil;
    final closes = window.closesAt;
    final opens = window.nextOpensAt;
    final open = window.openNow;

    final detail = exception != null
        ? copy.exceptionOpen(
            '${copy.date(exception)}, ${DateFormat('HH:mm').format(exception)}')
        : closes != null
            ? copy.windowClosesOn(
                copy.date(closes), WafacashWindow.daysUntil(closes, now))
            : opens != null
                ? copy.windowOpensOn(
                    copy.date(opens), WafacashWindow.daysUntil(opens, now))
                : null;

    final ink = open ? AppColors.successDark : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: open ? AppColors.successLight : AppColors.backgroundGrey,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(open ? Icons.event_available : Icons.event_outlined,
              size: 20, color: ink),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(copy.windowRule(window.startDay, window.endDay),
                    style: AppTypography.labelMedium
                        .copyWith(color: open ? ink : AppColors.textPrimary)),
                if (detail != null) ...[
                  const SizedBox(height: 2),
                  Text(detail,
                      style: AppTypography.bodySmall.copyWith(color: ink)),
                ],
                if (!open) ...[
                  const SizedBox(height: 2),
                  Text(copy.windowEmergency,
                      style: AppTypography.caption
                          .copyWith(color: AppColors.textMuted)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Les étapes d'un premier retrait. Une vraie suite : d'où les numéros.
class _FirstTimeSteps extends StatelessWidget {
  const _FirstTimeSteps({required this.steps, required this.done});

  final List<String> steps;
  final int done;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < steps.length; i++)
          Padding(
            padding: EdgeInsets.only(
                bottom: i < steps.length - 1 ? AppSpacing.xs : 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < done
                        ? AppColors.successDark
                        : AppColors.backgroundGrey,
                  ),
                  child: i < done
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : Text('${i + 1}',
                          style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(steps[i],
                      style: AppTypography.bodySmall.copyWith(
                          color: i < done
                              ? AppColors.textMuted
                              : AppColors.textSecondary)),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Le montant à retirer. Les frais de l'agence sont à la charge du chargé
/// public ; on le dit d'une ligne, sans les chiffrer — et on prévient quand ils
/// pèsent lourd sur un petit montant.
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
      final next = o.window?.nextOpensAt;
      return [
        c.aboveAvailable(c.money(o.balance.available)),
        if (o.balance.held > 0) c.heldNote(c.money(o.balance.held)),
        if (o.balance.deferred > 0 && next != null)
          c.deferredNote(c.money(o.balance.deferred), c.date(next)),
      ].join(' ');
    }
    if (v > o.maxAmount) return c.aboveMax(c.money(o.maxAmount));
    if (!o.covers(v)) return c.doesNotCoverFees;
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
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Expanded(
                  child: Text(c.availableNow,
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.textSecondary)),
                ),
                Text(c.money(o.balance.available),
                    style: AppTypography.labelLarge
                        .copyWith(color: AppColors.successDark)),
              ],
            ),
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
            _Notice(icon: Icons.info_outline, text: c.feesOnYou),
            if (problem == null && o.feesWeighHeavy(_value)) ...[
              const SizedBox(height: AppSpacing.xs),
              _Notice(
                icon: Icons.warning_amber_rounded,
                text: c.feesWeighHeavy,
                color: AppColors.warningDark,
              ),
            ],
            if (problem != null || _error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(_error ?? problem!,
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.errorDark)),
            ],
            const SizedBox(height: AppSpacing.md),
            Text(c.afterConfirm,
                style:
                    AppTypography.caption.copyWith(color: AppColors.textMuted)),
            const SizedBox(height: AppSpacing.sm),
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
    required this.window,
    required this.copy,
    required this.onChanged,
  });

  final WafacashWithdrawal withdrawal;
  final WafacashWindow? window;
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
    final window = widget.window;
    final next = window?.nextOpensAt;
    // Hors ouverture, annuler, c'est attendre le mois prochain : à dire avant.
    final waitsForNextMonth = window != null && !window.openNow && next != null;
    final sure = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(c.cancelConfirmTitle),
        content: Text(waitsForNextMonth
            ? c.cancelConfirmBodyClosed(c.date(next))
            : c.cancelConfirmBody),
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

  /// Sans confirmation, un doigt qui glisse fait disparaître le code : le
  /// serveur ne le renvoie plus une fois le retrait marqué.
  Future<void> _collected() async {
    final c = widget.copy;
    final sure = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(c.collectedConfirmTitle),
        content: Text(c.collectedConfirmBody),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(c.notYet)),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(c.collectedConfirmYes)),
        ],
      ),
    );
    if (sure != true) return;
    await _act(() => ref
        .read(wafacashRepositoryProvider)
        .markCollected(widget.withdrawal.id));
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
        _Steps(status: w.status, labels: c.stepLabels),
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
          _CodeBox(code: w.code!, display: w.formattedCode!, copy: c),
          if (w.collectBefore != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _Deadline(withdrawal: w, copy: c),
          ],
          const SizedBox(height: AppSpacing.md),
          Text(c.bringTitle, style: AppTypography.labelMedium),
          const SizedBox(height: AppSpacing.xs),
          _Notice(icon: Icons.badge_outlined, text: c.bringCin(w.legalName)),
          const SizedBox(height: AppSpacing.xs),
          _Notice(icon: Icons.pin_outlined, text: c.bringCode),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            text: c.iCollected,
            icon: Icons.check_circle_outline,
            isLoading: _busy,
            onPressed: _collected,
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

/// Jusqu'à quand le code se retire. Rouge-orangé dans les derniers jours : c'est
/// là qu'un code oublié finit par revenir sur le solde.
class _Deadline extends StatelessWidget {
  const _Deadline({required this.withdrawal, required this.copy});

  final WafacashWithdrawal withdrawal;
  final WafacashCopy copy;

  /// La relance du serveur part 5 jours avant la fin de validité.
  static const _urgentDays = 5;

  @override
  Widget build(BuildContext context) {
    final limit = withdrawal.collectBefore!;
    final days = withdrawal.daysLeft(DateTime.now());
    final urgent = days != null && days <= _urgentDays;
    final date = copy.collectBefore(DateFormat('dd/MM/yyyy').format(limit));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Notice(
          icon: Icons.event_outlined,
          text: urgent && days >= 0 ? '$date. ${copy.daysLeft(days)}.' : date,
          color: urgent ? AppColors.warningDark : AppColors.textSecondary,
        ),
        const SizedBox(height: 2),
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 18 + AppSpacing.sm),
          child: Text(copy.afterDeadline,
              style:
                  AppTypography.caption.copyWith(color: AppColors.textMuted)),
        ),
      ],
    );
  }
}

/// Trois étapes nommées : où en est la demande, sans lire le texte.
class _Steps extends StatelessWidget {
  const _Steps({required this.status, required this.labels});

  final WafacashWithdrawalStatus status;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final reached = switch (status) {
      WafacashWithdrawalStatus.requested => 1,
      WafacashWithdrawalStatus.processing => 2,
      _ => 3,
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 1; i <= labels.length; i++) ...[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 5,
                  decoration: BoxDecoration(
                    color: i <= reached
                        ? AppColors.primaryAction
                        : AppColors.border,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  labels[i - 1],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    color: i <= reached
                        ? AppColors.textPrimary
                        : AppColors.textMuted,
                    fontWeight:
                        i == reached ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          if (i < labels.length) const SizedBox(width: 4),
        ],
      ],
    );
  }
}

/// Le code, gros et copiable : c'est ce qu'on recopie au guichet.
class _CodeBox extends StatelessWidget {
  const _CodeBox({
    required this.code,
    required this.display,
    required this.copy,
  });

  /// Ce qui part dans le presse-papiers : les chiffres seuls.
  final String code;

  /// Ce qui se lit : `123 456 789 012`.
  final String display;
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
                    // Sur un petit écran, le code rétrécit plutôt que de passer
                    // à la ligne : il se lit d'un seul regard.
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        display,
                        maxLines: 1,
                        // Chiffres à chasse fixe et espacés plutôt qu'une
                        // police à part : la typographie reste celle de l'app,
                        // et un 1 ne se confond pas avec un 7 au guichet.
                        style: AppTypography.h2.copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                          letterSpacing: 2,
                        ),
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
                if ((w.status == WafacashWithdrawalStatus.rejected ||
                        w.cancelledByStaff) &&
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

/// Une ligne d'information : l'icône dit de quoi il s'agit, la couleur si ça
/// presse.
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

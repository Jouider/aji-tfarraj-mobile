import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:aji_tfarraj/app/copywriting/expenses_copy.dart';
import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';
import 'package:aji_tfarraj/app/localization/locale_provider.dart';
import 'package:aji_tfarraj/app/routes.dart';
import 'package:aji_tfarraj/features/expenses/data/expenses_repository.dart';
import 'package:aji_tfarraj/features/expenses/domain/expense.dart';
import 'package:aji_tfarraj/features/expenses/presentation/expense_form_screen.dart';
import 'package:aji_tfarraj/features/expenses/presentation/expense_widgets.dart';

/// « Ma caisse » : ce qu'il reste dans la caisse de Hamza, une tuile par
/// type de dépense (un appui ouvre le bon formulaire), ce qu'Ayoub a refusé
/// à corriger, et la liste par état.
class ExpensesScreen extends ConsumerWidget {
  const ExpensesScreen({super.key});

  /// Ouvre le formulaire ; au retour, tout se recharge (solde compris).
  static Future<void> openForm(
      BuildContext context, WidgetRef ref, ExpenseFormArgs args) async {
    final changed = await context.push<bool>(Routes.expenseForm, extra: args);
    if (changed == true) refreshAll(ref);
  }

  static void refreshAll(WidgetRef ref) {
    ref.invalidate(expensesOverviewProvider);
    ref.invalidate(expensesByStatusProvider);
    ref.invalidate(expenseFormOptionsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(stringsProvider).expenses;
    final state = ref.watch(expensesOverviewProvider);

    Future<void> refresh() async {
      refreshAll(ref);
      await ref.read(expensesOverviewProvider.future);
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(title: Text(c.title)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openForm(context, ref, const ExpenseFormArgs()),
        icon: const Icon(Icons.add),
        label: Text(c.newExpense),
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => ExpenseLoadError(
          copy: c,
          onRetry: () => ref.invalidate(expensesOverviewProvider),
        ),
        data: (o) => RefreshIndicator(
          onRefresh: refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 96),
            children: [
              _BalanceCard(box: o.cashBox, copy: c),
              const SizedBox(height: AppSpacing.xl),
              Text(c.chooseCategory, style: AppTypography.h4),
              const SizedBox(height: AppSpacing.sm),
              CategoryGrid(
                copy: c,
                onPick: (category) =>
                    openForm(context, ref, ExpenseFormArgs(category: category)),
              ),
              if (o.refused > 0) ...[
                const SizedBox(height: AppSpacing.xl),
                _RefusedBlock(copy: c),
              ],
              const SizedBox(height: AppSpacing.xl),
              _StatusLists(overview: o, copy: c),
              const SizedBox(height: AppSpacing.xl),
              Text(c.moneyReceived, style: AppTypography.h4),
              const SizedBox(height: AppSpacing.sm),
              if (o.movements.isEmpty)
                Text(c.noMovement,
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.textSecondary))
              else
                for (final m in o.movements) _MovementRow(m: m, copy: c),
            ],
          ),
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.box, required this.copy});

  final CashBox box;
  final ExpensesCopy copy;

  @override
  Widget build(BuildContext context) {
    final negative = box.balance < 0;
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
          Text(copy.balanceLabel,
              style:
                  AppTypography.caption.copyWith(color: AppColors.textMuted)),
          const SizedBox(height: AppSpacing.xs),
          Text(
            copy.money(box.balance),
            style: AppTypography.h1.copyWith(
              color: negative ? AppColors.errorDark : AppColors.successDark,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          if (negative) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(copy.advancedNote(copy.money(-box.balance)),
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.errorDark)),
          ],
          const SizedBox(height: AppSpacing.md),
          Divider(height: 1, color: AppColors.border),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                  child:
                      _Figure(label: copy.given, value: copy.money(box.given))),
              Expanded(
                  child:
                      _Figure(label: copy.spent, value: copy.money(box.spent))),
              if (box.returned > 0)
                Expanded(
                    child: _Figure(
                        label: copy.returned, value: copy.money(box.returned))),
            ],
          ),
          if (box.spentPending > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(copy.pendingSpent(copy.money(box.spentPending)),
                style: AppTypography.caption
                    .copyWith(color: AppColors.warningDark)),
          ],
        ],
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
        Text(value,
            style: AppTypography.labelLarge
                .copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
      ],
    );
  }
}

/// Ce qu'Ayoub a refusé, en haut, avec « Corriger ».
class _RefusedBlock extends ConsumerWidget {
  const _RefusedBlock({required this.copy});

  final ExpensesCopy copy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final refused = ref.watch(expensesByStatusProvider(ExpenseStatus.refused));
    final items = refused.valueOrNull?.items ?? const <Expense>[];
    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline,
                  color: AppColors.errorDark, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(copy.refusedBanner,
                    style: AppTypography.labelLarge
                        .copyWith(color: AppColors.errorDark)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final e in items)
            ExpenseRow(
              expense: e,
              copy: copy,
              trailing: TextButton(
                onPressed: () => ExpensesScreen.openForm(
                    context, ref, ExpenseFormArgs(existing: e)),
                child: Text(copy.fix),
              ),
              onTap: () => ExpensesScreen.openForm(
                  context, ref, ExpenseFormArgs(existing: e)),
            ),
        ],
      ),
    );
  }
}

/// En attente / Validées / Refusées.
class _StatusLists extends ConsumerStatefulWidget {
  const _StatusLists({required this.overview, required this.copy});

  final ExpensesOverview overview;
  final ExpensesCopy copy;

  @override
  ConsumerState<_StatusLists> createState() => _StatusListsState();
}

class _StatusListsState extends ConsumerState<_StatusLists> {
  String _status = ExpenseStatus.pending;

  @override
  Widget build(BuildContext context) {
    final c = widget.copy;
    final o = widget.overview;
    final page = ref.watch(expensesByStatusProvider(_status));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final (s, n) in [
                (ExpenseStatus.pending, o.pending),
                (ExpenseStatus.validated, o.validated),
                (ExpenseStatus.refused, o.refused),
              ])
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
                  child: ChoiceChip(
                    label: Text(c.statusPlural(s, n)),
                    selected: _status == s,
                    onSelected: (_) => setState(() => _status = s),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        page.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => ExpenseLoadError(
            copy: c,
            onRetry: () => ref.invalidate(expensesByStatusProvider(_status)),
          ),
          data: (p) => p.items.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Text(c.emptyList,
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.textSecondary)),
                )
              : Column(
                  children: [
                    for (final e in p.items)
                      ExpenseRow(
                        expense: e,
                        copy: c,
                        onTap: () => ExpensesScreen.openForm(
                            context, ref, ExpenseFormArgs(existing: e)),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _MovementRow extends StatelessWidget {
  const _MovementRow({required this.m, required this.copy});

  final CashMovement m;
  final ExpensesCopy copy;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Icon(m.isDeposit ? Icons.south_west : Icons.north_east,
              size: 18,
              color: m.isDeposit ? AppColors.successDark : AppColors.textMuted),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(copy.day(m.date), style: AppTypography.bodyMedium),
                Text(
                  [
                    if (m.by != null) '${copy.movement(m.isDeposit)} ${m.by}',
                    if (m.note != null) m.note!,
                  ].join(' · '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption
                      .copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '${m.isDeposit ? '+' : '−'}${copy.money(m.amount)}',
            style: AppTypography.labelLarge.copyWith(
              color: m.isDeposit ? AppColors.successDark : null,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

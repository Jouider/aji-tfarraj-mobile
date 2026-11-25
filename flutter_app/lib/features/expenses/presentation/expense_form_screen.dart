import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:aji_tfarraj/app/copywriting/expenses_copy.dart';
import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/components/buttons.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';
import 'package:aji_tfarraj/app/localization/locale_provider.dart';
import 'package:aji_tfarraj/app/network/api_client.dart';
import 'package:aji_tfarraj/features/expenses/data/expenses_repository.dart';
import 'package:aji_tfarraj/features/expenses/domain/expense.dart';
import 'package:aji_tfarraj/features/expenses/presentation/expense_widgets.dart';

/// Ce que l'écran reçoit : une catégorie (nouvelle dépense), ou une dépense
/// à corriger. `episodeId` pré-remplit le programme (« un autre
/// prestataire pour ce programme »).
class ExpenseFormArgs {
  const ExpenseFormArgs({this.category, this.existing, this.episodeId});

  final String? category;
  final Expense? existing;
  final int? episodeId;
}

/// Saisir ou corriger une dépense. Un seul écran, qui ne montre que les
/// champs de la catégorie ; le total se calcule pendant la saisie et reste
/// en bas, au-dessus du bouton.
class ExpenseFormScreen extends ConsumerStatefulWidget {
  const ExpenseFormScreen({super.key, required this.args});

  final ExpenseFormArgs args;

  @override
  ConsumerState<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends ConsumerState<ExpenseFormScreen> {
  ExpenseDraft? _draft;
  final List<String> _newPhotos = [];
  late List<ExpensePhoto> _photos;
  bool _saving = false;
  String? _error;
  bool _showMissing = false;

  // Les champs tapés au clavier.
  final _provider = TextEditingController();
  final _amount = TextEditingController();
  final _mission = TextEditingController();
  final _note = TextEditingController();
  final _sandwichPrice = TextEditingController();
  final _drinks = TextEditingController();
  final _pricePerPerson = TextEditingController();

  Expense? get _existing => widget.args.existing;
  bool get _locked => _existing != null && !_existing!.editable;

  @override
  void initState() {
    super.initState();
    _photos = [...?_existing?.photos];
    final e = _existing;
    final category = e?.category ?? widget.args.category;
    if (category != null) _start(category, e);
  }

  void _start(String category, [Expense? e]) {
    final d = e != null
        ? ExpenseDraft.fromExpense(e)
        : ExpenseDraft(category: category, episodeId: widget.args.episodeId);
    _provider.text = d.provider;
    _amount.text = d.amount == 0 ? '' : '${d.amount}';
    _mission.text = d.mission;
    _note.text = d.note;
    _sandwichPrice.text = d.sandwichPrice == 0 ? '' : '${d.sandwichPrice}';
    _drinks.text = d.drinks == 0 ? '' : '${d.drinks}';
    _pricePerPerson.text = d.pricePerPerson == 0 ? '' : '${d.pricePerPerson}';
    setState(() => _draft = d);
  }

  @override
  void dispose() {
    for (final c in [
      _provider,
      _amount,
      _mission,
      _note,
      _sandwichPrice,
      _drinks,
      _pricePerPerson,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  int _n(TextEditingController c) => int.tryParse(c.text.trim()) ?? 0;

  /// Recopie les champs tapés dans le brouillon.
  void _sync() {
    final d = _draft;
    if (d == null) return;
    d
      ..provider = _provider.text
      ..amount = _n(_amount)
      ..mission = _mission.text
      ..note = _note.text
      ..sandwichPrice = _n(_sandwichPrice)
      ..drinks = _n(_drinks)
      ..pricePerPerson = _n(_pricePerPerson);
  }

  void _update(void Function(ExpenseDraft d) change) {
    setState(() {
      _sync();
      change(_draft!);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(stringsProvider).expenses;
    final d = _draft;

    if (d == null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundWhite,
        appBar: AppBar(title: Text(c.newExpense)),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text(c.chooseCategory, style: AppTypography.h4),
            const SizedBox(height: AppSpacing.sm),
            CategoryGrid(copy: c, onPick: _start),
          ],
        ),
      );
    }

    final options = ref.watch(expenseFormOptionsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        title: Text(c.category(d.category)),
        actions: [
          if (_existing != null && !_locked)
            IconButton(
              tooltip: c.delete,
              icon: const Icon(Icons.delete_outline),
              onPressed: _saving ? null : () => _delete(c),
            ),
        ],
      ),
      body: options.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => ExpenseLoadError(
          copy: c,
          onRetry: () => ref.invalidate(expenseFormOptionsProvider),
        ),
        data: (o) => _form(c, d, o),
      ),
      bottomNavigationBar: options.valueOrNull == null || _locked
          ? null
          : _TotalBar(
              copy: c,
              draft: d,
              dayStaffRate: options.valueOrNull!.dayStaffRate,
              saving: _saving,
              editing: _existing?.isRefused == true,
              onSave: () => _save(c, options.valueOrNull!),
              recompute: _sync,
            ),
    );
  }

  Widget _form(ExpensesCopy c, ExpenseDraft d, ExpenseFormOptions o) {
    final missing = _showMissing ? d.missing() : const <String>[];
    final e = _existing;

    final children = <Widget>[
      if (e != null && e.isRefused)
        _Banner(
          color: AppColors.errorDark,
          icon: Icons.error_outline,
          text: [
            c.refusedBy(e.reviewedBy),
            if (e.reviewNote != null) '« ${e.reviewNote} »'
          ].join(' : '),
        ),
      if (_locked)
        _Banner(
            color: AppColors.successDark,
            icon: Icons.verified_outlined,
            text: c.locked),
      _Label(c.programme),
      _EpisodeField(
        copy: c,
        options: o,
        category: d.category,
        value: d.episodeId,
        error: missing.contains('episode') ? c.missing('episode') : null,
        onChanged: (id) => _update((d) {
          d.episodeId = id;
          final ep = o.episode(id);
          // Le jour du tournage, sauf si Hamza a déjà changé la date.
          if (ep?.date != null && _existing == null) d.spentOn = ep!.date!;
        }),
      ),
      const SizedBox(height: AppSpacing.md),
      _Label(c.date),
      _DateField(
        copy: c,
        value: d.spentOn,
        onChanged: (v) => _update((d) => d.spentOn = v),
      ),
      const SizedBox(height: AppSpacing.lg),
      ..._categoryFields(c, d, o, missing),
      const SizedBox(height: AppSpacing.lg),
      if (d.category != ExpenseCategory.staffDay) ...[
        _Label(c.receipts),
        _Photos(
          copy: c,
          existing: _photos,
          added: _newPhotos,
          max: o.maxPhotos,
          locked: _locked,
          onAdd: _pickPhoto,
          onRemoveAdded: (p) => setState(() => _newPhotos.remove(p)),
          onRemoveExisting: _removePhoto,
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
      _Label(d.category == ExpenseCategory.other ? c.noteRequired : c.note),
      _Input(
        controller: _note,
        hint: d.category == ExpenseCategory.other ? c.noteRequired : c.note,
        maxLines: 3,
        error: missing.contains('note') ? c.missing('note') : null,
      ),
      if (_error != null) ...[
        const SizedBox(height: AppSpacing.md),
        _Banner(
            color: AppColors.errorDark,
            icon: Icons.error_outline,
            text: _error!),
      ],
      const SizedBox(height: AppSpacing.xl),
    ];

    return AbsorbPointer(
      absorbing: _locked || _saving,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: children,
      ),
    );
  }

  List<Widget> _categoryFields(ExpensesCopy c, ExpenseDraft d,
      ExpenseFormOptions o, List<String> missing) {
    String? err(String key) => missing.contains(key) ? c.missing(key) : null;

    switch (d.category) {
      case ExpenseCategory.transport:
        return [
          TwoChoice(
            first: c.withTransport,
            second: c.withoutTransport,
            firstSelected: d.withTransport,
            onChanged: (v) => _update((d) => d.withTransport = v),
          ),
          if (d.withTransport) ...[
            const SizedBox(height: AppSpacing.lg),
            _Label(c.provider),
            _ProviderInput(
              controller: _provider,
              hint: c.providerHint,
              suggestions: o.providersFor(ExpenseCategory.transport),
              error: err('provider'),
              onPicked: () => setState(_sync),
            ),
            const SizedBox(height: AppSpacing.md),
            Counter(
                label: c.minibuses,
                value: d.minibuses,
                onChanged: (v) => _update((d) => d.minibuses = v)),
            Counter(
                label: c.coaches,
                value: d.coaches,
                onChanged: (v) => _update((d) => d.coaches = v)),
            if (err('vehicles') != null) _ErrorText(err('vehicles')!),
            const SizedBox(height: AppSpacing.md),
            _Label(c.transportAmount),
            _Input(
                controller: _amount,
                money: true,
                onChanged: () => setState(_sync)),
          ],
          const SizedBox(height: AppSpacing.md),
          _Note(text: c.transportPaidBy),
        ];

      case ExpenseCategory.fuel:
        return [
          _Label(c.amount),
          _Input(
              controller: _amount,
              money: true,
              error: err('amount'),
              onChanged: () => setState(_sync)),
          const SizedBox(height: AppSpacing.md),
          _Note(text: c.fuelPaidBy),
        ];

      case ExpenseCategory.vehicle:
        return [
          _Label(c.mission),
          _Input(
              controller: _mission, hint: c.missionHint, error: err('mission')),
          const SizedBox(height: AppSpacing.md),
          TwoChoice(
            first: c.withIndemnity,
            second: c.withoutIndemnity,
            firstSelected: d.indemnified,
            onChanged: (v) => _update((d) => d.indemnified = v),
          ),
          if (d.indemnified) ...[
            const SizedBox(height: AppSpacing.md),
            _Label(c.indemnity),
            _Input(
                controller: _amount,
                money: true,
                error: err('amount'),
                onChanged: () => setState(_sync)),
            const SizedBox(height: AppSpacing.md),
            _CashBoxChoice(
                copy: c,
                value: d.fromCashBox,
                onChanged: (v) => _update((d) => d.fromCashBox = v)),
          ],
        ];

      case ExpenseCategory.catering:
        return [
          _Label(c.provider),
          _ProviderInput(
            controller: _provider,
            hint: c.providerHint,
            suggestions: o.providersFor(ExpenseCategory.catering),
            error: err('provider'),
            onPicked: () => setState(_sync),
          ),
          const SizedBox(height: AppSpacing.md),
          Counter(
              label: c.sandwiches,
              value: d.sandwiches,
              step: 5,
              onChanged: (v) => _update((d) => d.sandwiches = v)),
          const SizedBox(height: AppSpacing.sm),
          _Label(c.sandwichPrice),
          _Input(
              controller: _sandwichPrice,
              money: true,
              onChanged: () => setState(_sync)),
          const SizedBox(height: AppSpacing.md),
          _Label(c.drinks),
          _Input(
              controller: _drinks,
              money: true,
              onChanged: () => setState(_sync)),
          if (err('catering') != null) _ErrorText(err('catering')!),
        ];

      case ExpenseCategory.audience:
        return [
          _Label(c.paidPublic),
          Counter(
              label: c.paidPeople,
              value: d.paidPeople,
              step: 5,
              onChanged: (v) => _update((d) => d.paidPeople = v)),
          if (d.paidPeople > 0) ...[
            _Label(c.pricePerPerson),
            _Input(
                controller: _pricePerPerson,
                money: true,
                error: err('price'),
                onChanged: () => setState(_sync)),
          ],
          const SizedBox(height: AppSpacing.lg),
          _Label(c.freePublic),
          Counter(
              label: c.freePeople,
              value: d.freePeople,
              step: 5,
              onChanged: (v) => _update((d) => d.freePeople = v)),
          if (err('people') != null) _ErrorText(err('people')!),
        ];

      case ExpenseCategory.staffDay:
        final ep = o.episode(d.episodeId);
        return [
          _Label(c.staffPerson),
          _StaffField(
            copy: c,
            staff: o.staff,
            value: d.staffUserId,
            error: err('staff'),
            onChanged: (id) => _update((d) => d.staffUserId = id),
          ),
          if (ep?.dayStaffName != null && _existing == null) ...[
            const SizedBox(height: AppSpacing.sm),
            _ErrorText(c.dayStaffTaken(ep!.dayStaffName!)),
          ],
          const SizedBox(height: AppSpacing.md),
          _Note(text: c.dayStaffNote(c.money(o.dayStaffRate))),
        ];

      default: // taxi, indrive, other
        return [
          _Label(c.amount),
          _Input(
              controller: _amount,
              money: true,
              error: err('amount'),
              onChanged: () => setState(_sync)),
          const SizedBox(height: AppSpacing.md),
          _CashBoxChoice(
              copy: c,
              value: d.fromCashBox,
              onChanged: (v) => _update((d) => d.fromCashBox = v)),
        ];
    }
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final file = await ImagePicker().pickImage(
      source: source,
      // Un reçu doit rester lisible, sans peser douze mégapixels.
      maxWidth: 2000,
      imageQuality: 82,
    );
    if (file == null || !mounted) return;
    setState(() => _newPhotos.add(file.path));
  }

  Future<void> _removePhoto(ExpensePhoto p) async {
    final e = _existing;
    if (e == null) return;
    try {
      final updated =
          await ref.read(expensesRepositoryProvider).deletePhoto(e.id, p.id);
      if (!mounted) return;
      setState(() => _photos = updated.photos);
    } on ApiException catch (err) {
      if (mounted) setState(() => _error = err.message);
    }
  }

  Future<void> _save(ExpensesCopy c, ExpenseFormOptions o) async {
    _sync();
    final d = _draft!;
    if (d.missing().isNotEmpty) {
      setState(() {
        _showMissing = true;
        _error = c.missing(d.missing().first);
      });
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final repo = ref.read(expensesRepositoryProvider);
    try {
      final e = _existing;
      if (e == null) {
        await repo.create(d, _newPhotos);
      } else {
        await repo.update(e.id, d, _newPhotos);
      }
      if (!mounted) return;

      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(SnackBar(
          content:
              Text(_existing?.isRefused == true ? c.resubmitted : c.saved)));

      // Transport : plusieurs prestataires pour le même programme.
      if (e == null &&
          d.category == ExpenseCategory.transport &&
          d.withTransport) {
        final again = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(c.addAnotherProvider),
            content: Text(c.addAnotherProviderBody),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: Text(c.no)),
              FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: Text(c.yes)),
            ],
          ),
        );
        if (!mounted) return;
        if (again == true) {
          _newPhotos.clear();
          _start(ExpenseCategory.transport);
          setState(() {
            _draft!.episodeId = d.episodeId;
            _draft!.spentOn = d.spentOn;
            _saving = false;
            _showMissing = false;
          });
          return;
        }
      }

      Navigator.of(context).pop(true);
    } on ApiException catch (err) {
      if (!mounted) return;
      final first = err.errors?.values
          .expand((v) => v is List ? v : [v])
          .map((v) => '$v')
          .firstOrNull;
      setState(() {
        _saving = false;
        _error = first ?? err.message;
      });
    }
  }

  Future<void> _delete(ExpensesCopy c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(c.deleteConfirm),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(c.cancel)),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(c.delete)),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _saving = true);
    try {
      await ref.read(expensesRepositoryProvider).delete(_existing!.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(c.deleted)));
      Navigator.of(context).pop(true);
    } on ApiException catch (err) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = err.message;
        });
      }
    }
  }
}

// ─── Les morceaux ────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
        child: Text(text,
            style: AppTypography.labelMedium
                .copyWith(color: AppColors.textSecondary)),
      );
}

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xs),
        child: Text(text,
            style: AppTypography.caption.copyWith(color: AppColors.errorDark)),
      );
}

class _Note extends StatelessWidget {
  const _Note({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.backgroundGrey,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, size: 18, color: AppColors.textMuted),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
                child: Text(text,
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.textSecondary))),
          ],
        ),
      );
}

class _Banner extends StatelessWidget {
  const _Banner({required this.color, required this.icon, required this.text});

  final Color color;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
                child: Text(text,
                    style: AppTypography.bodySmall.copyWith(color: color))),
          ],
        ),
      );
}

class _Input extends StatelessWidget {
  const _Input({
    required this.controller,
    this.hint,
    this.money = false,
    this.maxLines = 1,
    this.error,
    this.onChanged,
  });

  final TextEditingController controller;
  final String? hint;
  final bool money;
  final int maxLines;
  final String? error;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: money
          ? TextInputType.number
          : (maxLines > 1 ? TextInputType.multiline : TextInputType.text),
      inputFormatters:
          money ? [FilteringTextInputFormatter.digitsOnly] : const [],
      textInputAction:
          maxLines > 1 ? TextInputAction.newline : TextInputAction.done,
      onChanged: (_) => onChanged?.call(),
      style: money
          ? AppTypography.h4
              .copyWith(fontFeatures: const [FontFeature.tabularFigures()])
          : AppTypography.bodyMedium,
      decoration: InputDecoration(
        hintText: hint ?? (money ? '0' : null),
        suffixText: money ? 'DH' : null,
        errorText: error,
        filled: true,
        fillColor: AppColors.backgroundGrey,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

/// Le nom du prestataire, et ceux déjà saisis en un appui.
class _ProviderInput extends StatelessWidget {
  const _ProviderInput({
    required this.controller,
    required this.hint,
    required this.suggestions,
    required this.onPicked,
    this.error,
  });

  final TextEditingController controller;
  final String hint;
  final List<String> suggestions;
  final VoidCallback onPicked;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Input(
            controller: controller,
            hint: hint,
            error: error,
            onChanged: onPicked),
        if (suggestions.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              for (final s in suggestions.take(8))
                ActionChip(
                  label: Text(s),
                  onPressed: () {
                    controller.text = s;
                    onPicked();
                  },
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _CashBoxChoice extends StatelessWidget {
  const _CashBoxChoice(
      {required this.copy, required this.value, required this.onChanged});

  final ExpensesCopy copy;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Label(copy.fromCashBox),
          TwoChoice(
            first: copy.fromCashBoxYes,
            second: copy.fromCashBoxNo,
            firstSelected: value,
            onChanged: onChanged,
          ),
        ],
      );
}

/// Un champ qui s'ouvre sur une liste : programme, personne du staff.
class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.title,
    this.subtitle,
    required this.onTap,
    this.placeholder = false,
    this.error,
    this.icon = Icons.event_outlined,
  });

  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool placeholder;
  final String? error;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: AppColors.backgroundGrey,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Icon(icon, color: AppColors.accentInk),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              style: AppTypography.bodyMedium.copyWith(
                                  color: placeholder
                                      ? AppColors.textMuted
                                      : null)),
                          if (subtitle != null)
                            Text(subtitle!,
                                style: AppTypography.caption
                                    .copyWith(color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                    Icon(Icons.expand_more, color: AppColors.textMuted),
                  ],
                ),
              ),
            ),
          ),
          if (error != null) _ErrorText(error!),
        ],
      );
}

class _EpisodeField extends StatelessWidget {
  const _EpisodeField({
    required this.copy,
    required this.options,
    required this.category,
    required this.value,
    required this.onChanged,
    this.error,
  });

  final ExpensesCopy copy;
  final ExpenseFormOptions options;
  final String category;
  final int? value;
  final ValueChanged<int?> onChanged;
  final String? error;

  String _label(ExpenseEpisodeChoice e) => [e.show, e.title]
      .whereType<String>()
      .where((s) => s.isNotEmpty)
      .toSet()
      .join(' · ');

  String? _when(ExpenseEpisodeChoice e) => e.date == null
      ? null
      : [copy.day(e.date!), if (e.time != null) e.time!].join(' · ');

  @override
  Widget build(BuildContext context) {
    final selected = options.episode(value);
    // Le staff du jour : seulement là où le staff n'est pas payé.
    final choices = category == ExpenseCategory.staffDay
        ? options.episodes.where((e) => !e.paysStaff).toList()
        : options.episodes;
    final optional = !ExpenseCategory.needsEpisode(category);

    if (category == ExpenseCategory.staffDay && choices.isEmpty) {
      return _Note(text: copy.dayStaffNoEpisode);
    }

    return _PickerTile(
      title: selected != null
          ? _label(selected)
          : (value == null && optional && error == null
              ? copy.noProgramme
              : copy.chooseProgramme),
      subtitle: selected != null ? _when(selected) : null,
      placeholder: selected == null,
      error: error,
      onTap: () async {
        final picked = await showModalBottomSheet<_Pick>(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          builder: (ctx) => _SearchSheet<ExpenseEpisodeChoice>(
            hint: copy.searchProgramme,
            items: choices,
            label: _label,
            subtitle: _when,
            leading: optional ? copy.noProgramme : null,
            selected: (e) => e.id == value,
          ),
        );
        if (picked == null) return;
        onChanged(picked.id);
      },
    );
  }
}

class _StaffField extends StatelessWidget {
  const _StaffField({
    required this.copy,
    required this.staff,
    required this.value,
    required this.onChanged,
    this.error,
  });

  final ExpensesCopy copy;
  final List<StaffChoice> staff;
  final int? value;
  final ValueChanged<int?> onChanged;
  final String? error;

  @override
  Widget build(BuildContext context) {
    StaffChoice? selected;
    for (final s in staff) {
      if (s.id == value) selected = s;
    }
    return _PickerTile(
      icon: Icons.person_outline,
      title: selected?.name ?? copy.chooseStaff,
      subtitle: selected?.phone,
      placeholder: selected == null,
      error: error,
      onTap: () async {
        final picked = await showModalBottomSheet<_Pick>(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          builder: (ctx) => _SearchSheet<StaffChoice>(
            hint: copy.chooseStaff,
            items: staff,
            label: (s) => s.name,
            subtitle: (s) => s.phone,
            selected: (s) => s.id == value,
          ),
        );
        if (picked?.id != null) onChanged(picked!.id);
      },
    );
  }
}

/// Le choix fait dans une liste. `id` null : « Hors programme ».
class _Pick {
  const _Pick(this.id);

  final int? id;
}

class _SearchSheet<T> extends StatefulWidget {
  const _SearchSheet({
    required this.hint,
    required this.items,
    required this.label,
    required this.subtitle,
    required this.selected,
    this.leading,
  });

  final String hint;
  final List<T> items;
  final String Function(T) label;
  final String? Function(T) subtitle;
  final bool Function(T) selected;

  /// Une première ligne sans élément (« Hors programme »).
  final String? leading;

  @override
  State<_SearchSheet<T>> createState() => _SearchSheetState<T>();
}

class _SearchSheetState<T> extends State<_SearchSheet<T>> {
  String _q = '';

  int _id(T item) => switch (item) {
        ExpenseEpisodeChoice e => e.id,
        StaffChoice s => s.id,
        _ => 0,
      };

  @override
  Widget build(BuildContext context) {
    final q = _q.trim().toLowerCase();
    final items = q.isEmpty
        ? widget.items
        : widget.items
            .where((i) => '${widget.label(i)} ${widget.subtitle(i) ?? ''}'
                .toLowerCase()
                .contains(q))
            .toList();

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: TextField(
                autofocus: false,
                onChanged: (v) => setState(() => _q = v),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: widget.hint,
                  filled: true,
                  fillColor: AppColors.backgroundGrey,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: ListView(
                children: [
                  if (widget.leading != null && q.isEmpty)
                    ListTile(
                      leading: const Icon(Icons.public_off_outlined),
                      title: Text(widget.leading!),
                      onTap: () => Navigator.of(context).pop(const _Pick(null)),
                    ),
                  for (final i in items)
                    ListTile(
                      selected: widget.selected(i),
                      title: Text(widget.label(i)),
                      subtitle: widget.subtitle(i) == null
                          ? null
                          : Text(widget.subtitle(i)!),
                      trailing:
                          widget.selected(i) ? const Icon(Icons.check) : null,
                      onTap: () => Navigator.of(context).pop(_Pick(_id(i))),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField(
      {required this.copy, required this.value, required this.onChanged});

  final ExpensesCopy copy;
  final DateTime value;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) => _PickerTile(
        icon: Icons.calendar_today_outlined,
        title: copy.day(value),
        onTap: () async {
          final now = DateTime.now();
          final picked = await showDatePicker(
            context: context,
            initialDate: value,
            firstDate: DateTime(2026, 1, 1),
            lastDate: now.add(const Duration(days: 60)),
          );
          if (picked != null) onChanged(picked);
        },
      );
}

class _Photos extends StatelessWidget {
  const _Photos({
    required this.copy,
    required this.existing,
    required this.added,
    required this.max,
    required this.locked,
    required this.onAdd,
    required this.onRemoveAdded,
    required this.onRemoveExisting,
  });

  final ExpensesCopy copy;
  final List<ExpensePhoto> existing;
  final List<String> added;
  final int max;
  final bool locked;
  final ValueChanged<ImageSource> onAdd;
  final ValueChanged<String> onRemoveAdded;
  final ValueChanged<ExpensePhoto> onRemoveExisting;

  @override
  Widget build(BuildContext context) {
    final full = existing.length + added.length >= max;
    Widget removable(Widget child, VoidCallback onRemove) => Stack(
          clipBehavior: Clip.none,
          children: [
            child,
            if (!locked)
              PositionedDirectional(
                top: -8,
                end: -8,
                child: IconButton.filledTonal(
                  visualDensity: VisualDensity.compact,
                  iconSize: 16,
                  onPressed: onRemove,
                  icon: const Icon(Icons.close),
                ),
              ),
          ],
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (existing.isNotEmpty || added.isNotEmpty) ...[
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              for (final p in existing)
                removable(
                    RemotePhotoThumb(photo: p), () => onRemoveExisting(p)),
              for (final p in added)
                removable(
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    child: Image.file(File(p),
                        width: 84, height: 84, fit: BoxFit.cover),
                  ),
                  () => onRemoveAdded(p),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (!locked && !full) ...[
          Row(
            children: [
              Expanded(
                child: _PhotoButton(
                  label: copy.camera,
                  icon: Icons.photo_camera_outlined,
                  onPressed: () => onAdd(ImageSource.camera),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _PhotoButton(
                  label: copy.gallery,
                  icon: Icons.photo_library_outlined,
                  onPressed: () => onAdd(ImageSource.gallery),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(copy.receiptsHint(max),
              style:
                  AppTypography.caption.copyWith(color: AppColors.textMuted)),
        ],
      ],
    );
  }
}

/// « Photo » / « Galerie » : le libellé se raccourcit plutôt que déborder.
class _PhotoButton extends StatelessWidget {
  const _PhotoButton(
      {required this.label, required this.icon, required this.onPressed});

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSpacing.buttonHeight),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
        ),
        label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      );
}

/// Le total, en bas, et le bouton. Le total se recalcule à chaque frappe.
class _TotalBar extends StatelessWidget {
  const _TotalBar({
    required this.copy,
    required this.draft,
    required this.dayStaffRate,
    required this.saving,
    required this.editing,
    required this.onSave,
    required this.recompute,
  });

  final ExpensesCopy copy;
  final ExpenseDraft draft;
  final int dayStaffRate;
  final bool saving;
  final bool editing;
  final VoidCallback onSave;
  final VoidCallback recompute;

  @override
  Widget build(BuildContext context) {
    recompute();
    final total = draft.total(dayStaffRate: dayStaffRate);
    final where = draft.category == ExpenseCategory.staffDay
        ? copy.totalToBalance
        : draft.takesFromCashBox
            ? copy.totalFromCashBox
            : copy.totalNotFromCashBox;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.backgroundWhite,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(copy.total,
                          style: AppTypography.caption
                              .copyWith(color: AppColors.textMuted)),
                      Text(where,
                          style: AppTypography.caption.copyWith(
                              color: draft.takesFromCashBox
                                  ? AppColors.warningDark
                                  : AppColors.textMuted)),
                    ],
                  ),
                ),
                Text(copy.money(total),
                    style: AppTypography.h2.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()])),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton.primary(
              label: editing ? copy.saveChanges : copy.save,
              isLoading: saving,
              onPressed: saving ? null : onSave,
            ),
          ],
        ),
      ),
    );
  }
}

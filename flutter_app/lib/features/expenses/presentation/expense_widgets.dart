import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aji_tfarraj/app/copywriting/expenses_copy.dart';
import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';
import 'package:aji_tfarraj/features/expenses/data/expenses_repository.dart';
import 'package:aji_tfarraj/features/expenses/domain/expense.dart';

IconData categoryIcon(String c) => switch (c) {
      ExpenseCategory.transport => Icons.directions_bus_outlined,
      ExpenseCategory.fuel => Icons.local_gas_station_outlined,
      ExpenseCategory.vehicle => Icons.directions_car_outlined,
      ExpenseCategory.catering => Icons.lunch_dining_outlined,
      ExpenseCategory.audience => Icons.groups_outlined,
      ExpenseCategory.staffDay => Icons.badge_outlined,
      ExpenseCategory.taxi => Icons.local_taxi_outlined,
      ExpenseCategory.indrive => Icons.hail_outlined,
      _ => Icons.receipt_long_outlined,
    };

Color categoryColor(String c) => switch (c) {
      ExpenseCategory.transport => const Color(0xFF2563EB),
      ExpenseCategory.fuel => const Color(0xFFDC2626),
      ExpenseCategory.vehicle => const Color(0xFF7C3AED),
      ExpenseCategory.catering => const Color(0xFF16A34A),
      ExpenseCategory.audience => AppColors.primaryAction,
      ExpenseCategory.staffDay => const Color(0xFF0891B2),
      ExpenseCategory.taxi => AppColors.secondaryDark,
      ExpenseCategory.indrive => const Color(0xFF65A30D),
      _ => const Color(0xFF6B7280),
    };

/// Une tuile par type de dépense : un appui, et le bon formulaire s'ouvre.
class CategoryGrid extends StatelessWidget {
  const CategoryGrid({super.key, required this.copy, required this.onPick});

  final ExpensesCopy copy;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      const gap = AppSpacing.sm;
      final columns = box.maxWidth >= 520 ? 4 : 3;
      final width = (box.maxWidth - gap * (columns - 1)) / columns;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final c in ExpenseCategory.all)
            SizedBox(
              width: width,
              child: _CategoryTile(
                label: copy.category(c),
                icon: categoryIcon(c),
                color: categoryColor(c),
                onTap: () => onPick(c),
              ),
            ),
        ],
      );
    });
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.backgroundGrey,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 96),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs, vertical: AppSpacing.md),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status, required this.copy});

  final String status;
  final ExpensesCopy copy;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      ExpenseStatus.validated => (
          AppColors.success.withValues(alpha: 0.16),
          AppColors.successDark
        ),
      ExpenseStatus.refused => (
          AppColors.error.withValues(alpha: 0.16),
          AppColors.errorDark
        ),
      _ => (AppColors.warning.withValues(alpha: 0.18), AppColors.warningDark),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(copy.status(status),
          style: AppTypography.caption
              .copyWith(color: fg, fontWeight: FontWeight.w600)),
    );
  }
}

/// Une dépense dans une liste : catégorie, programme, montant, état.
class ExpenseRow extends StatelessWidget {
  const ExpenseRow({
    super.key,
    required this.expense,
    required this.copy,
    this.onTap,
    this.trailing,
  });

  final Expense expense;
  final ExpensesCopy copy;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final e = expense;
    final where = e.episode == null
        ? null
        : [e.episode!.show, e.episode!.title]
            .whereType<String>()
            .toSet()
            .join(' · ');
    final detail = [
      copy.day(e.spentOn),
      if (where != null && where.isNotEmpty) where,
      if (e.provider != null) e.provider!,
    ].join(' · ');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(categoryIcon(e.category),
                color: categoryColor(e.category), size: 22),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(copy.category(e.category),
                      style: AppTypography.bodyMedium),
                  Text(detail,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption
                          .copyWith(color: AppColors.textMuted)),
                  if (e.isRefused && (e.reviewNote ?? '').isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text('« ${e.reviewNote} »',
                          style: AppTypography.caption
                              .copyWith(color: AppColors.errorDark)),
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(copy.money(e.amount),
                    style: AppTypography.labelLarge.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()])),
                const SizedBox(height: 2),
                StatusBadge(status: e.status, copy: copy),
                if (trailing != null) trailing!,
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ExpenseLoadError extends StatelessWidget {
  const ExpenseLoadError(
      {super.key, required this.copy, required this.onRetry});

  final ExpensesCopy copy;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(copy.loadError,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.md),
            TextButton(onPressed: onRetry, child: Text(copy.retry)),
          ],
        ),
      ),
    );
  }
}

/// Un nombre : − et + en gros boutons, et un appui sur le chiffre pour le
/// taper. Pas de clavier à ouvrir pour « 2 minibus ».
class Counter extends StatelessWidget {
  const Counter({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.step = 1,
    this.suffix,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  final int step;
  final String? suffix;

  Future<void> _type(BuildContext context) async {
    final ctrl = TextEditingController(text: value == 0 ? '' : '$value');
    final typed = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(label),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(suffixText: suffix),
          onSubmitted: (v) => Navigator.of(ctx).pop(int.tryParse(v) ?? 0),
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(ctx).pop(int.tryParse(ctrl.text) ?? 0),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (typed != null) onChanged(typed);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTypography.bodyMedium)),
          _RoundButton(
            icon: Icons.remove,
            onTap: value <= 0
                ? null
                : () => onChanged((value - step).clamp(0, 1 << 30)),
          ),
          InkWell(
            onTap: () => _type(context),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 64),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
                child: Text(
                  suffix == null ? '$value' : '$value $suffix',
                  textAlign: TextAlign.center,
                  style: AppTypography.h4.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()]),
                ),
              ),
            ),
          ),
          _RoundButton(icon: Icons.add, onTap: () => onChanged(value + step)),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: onTap == null
          ? AppColors.backgroundGrey
          : AppColors.primary.withValues(alpha: 0.12),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon,
              color: onTap == null
                  ? AppColors.textMuted
                  : AppColors.primaryAction),
        ),
      ),
    );
  }
}

/// Deux gros boutons : « Avec transport » / « Sans transport »…
class TwoChoice extends StatelessWidget {
  const TwoChoice({
    super.key,
    required this.first,
    required this.second,
    required this.firstSelected,
    required this.onChanged,
  });

  final String first;
  final String second;
  final bool firstSelected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget option(String label, bool selected, bool value) => Expanded(
          child: Material(
            color: selected ? AppColors.chipSelected : AppColors.backgroundGrey,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              onTap: () => onChanged(value),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.md, horizontal: AppSpacing.sm),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (selected)
                      const Padding(
                        padding: EdgeInsetsDirectional.only(end: 4),
                        child: Icon(Icons.check,
                            size: 18, color: AppColors.chipSelectedInk),
                      ),
                    Flexible(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: AppTypography.labelLarge.copyWith(
                          color: selected ? AppColors.chipSelectedInk : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

    return Row(
      children: [
        option(first, firstSelected, true),
        const SizedBox(width: AppSpacing.sm),
        option(second, !firstSelected, false),
      ],
    );
  }
}

final _photoBytesProvider =
    FutureProvider.autoDispose.family<Uint8List, String>((ref, url) {
  return ref.watch(expensesRepositoryProvider).photoBytes(url);
});

/// Un reçu déjà envoyé : chargé par l'API, jeton compris.
class RemotePhotoThumb extends ConsumerWidget {
  const RemotePhotoThumb({super.key, required this.photo, this.size = 84});

  final ExpensePhoto photo;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (photo.isPdf) {
      return _ThumbBox(
          size: size,
          child: const Icon(Icons.picture_as_pdf_outlined,
              color: AppColors.errorDark));
    }
    final bytes = ref.watch(_photoBytesProvider(photo.url));
    return _ThumbBox(
      size: size,
      child: bytes.when(
        data: (b) =>
            Image.memory(b, fit: BoxFit.cover, width: size, height: size),
        loading: () => const Center(
            child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2))),
        error: (_, __) =>
            Icon(Icons.broken_image_outlined, color: AppColors.textMuted),
      ),
    );
  }
}

class _ThumbBox extends StatelessWidget {
  const _ThumbBox({required this.size, required this.child});

  final double size;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        width: size,
        height: size,
        color: AppColors.backgroundGrey,
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}

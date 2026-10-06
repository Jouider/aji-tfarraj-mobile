import 'package:flutter/material.dart';

import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';
import 'package:aji_tfarraj/features/return_points/domain/return_point_option.dart';
import 'package:aji_tfarraj/features/return_points/presentation/return_point_search.dart';

/// « Où la navette te dépose ? », posé partout de la même façon.
///
/// Une ligne par arrêt, plus « je rentre par mes propres moyens » : le refus
/// est une réponse comme une autre, et sans cette ligne on ne distingue pas
/// celui qui a dit non de celui à qui on n'a rien demandé.
///
/// Ne s'affiche jamais avec une liste vide : pas d'arrêt veut dire pas de
/// navette, et proposer une navette qui ne passe pas est pire que se taire.
class ReturnPointChoice extends StatefulWidget {
  const ReturnPointChoice({
    super.key,
    required this.points,
    required this.selectedId,
    required this.answered,
    required this.onChoose,
    required this.isArabic,
    required this.noneLabel,
    required this.searchHint,
    required this.noMatchLabel,
    this.enabled = true,
    this.autofocusSearch = false,
    this.scrollable = false,
  });

  final List<ReturnPointOption> points;

  /// L'arrêt choisi, ou null pour « par mes propres moyens ».
  ///
  /// À ne lire que si [answered] : sinon `null` ne veut rien dire d'autre que
  /// « la question n'a pas encore reçu de réponse ».
  final int? selectedId;

  /// Quelqu'un a-t-il répondu ?
  ///
  /// Sans cette distinction, `null` servait à la fois pour « pas encore
  /// répondu » et pour « je rentre par mes propres moyens » : la deuxième
  /// ligne apparaissait cochée d'emblée, le membre croyait la question
  /// réglée, et le staff ne pouvait pas distinguer un refus d'un silence.
  final bool answered;

  final String searchHint;
  final String noMatchLabel;
  final bool autofocusSearch;

  final ValueChanged<int?> onChoose;
  final bool isArabic;

  /// Le libellé du refus : il n'est pas formulé pareil selon qu'on parle à la
  /// personne ou d'elle.
  final String noneLabel;

  final bool enabled;

  /// Dans une feuille : la recherche reste en haut et seuls les arrêts
  /// défilent. Sinon la recherche partait avec la liste au premier geste, et
  /// il fallait remonter pour corriger ce qu'on tapait.
  ///
  /// Hors feuille, la liste suit le défilement de l'écran qui la contient.
  final bool scrollable;

  @override
  State<ReturnPointChoice> createState() => _ReturnPointChoiceState();
}

class _ReturnPointChoiceState extends State<ReturnPointChoice> {
  final TextEditingController _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _search.addListener(_onQueryChanged);
  }

  @override
  void dispose() {
    _search.removeListener(_onQueryChanged);
    _search.dispose();
    super.dispose();
  }

  void _onQueryChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    if (widget.points.isEmpty) return const SizedBox.shrink();

    final searchable = widget.points.length >= ReturnPointSearchField.showFrom;
    final query = _search.text;
    final shown = searchable
        ? widget.points.where((p) => p.matches(query)).toList()
        : widget.points;
    final filtering = searchable && query.trim().isNotEmpty;

    final options = <Widget>[
      for (final point in shown)
        _Option(
          label: point.localizedName(widget.isArabic),
          sublabel: point.landmark,
          selected: widget.answered && widget.selectedId == point.id,
          enabled: widget.enabled,
          onTap: () => widget.onChoose(point.id),
        ),
      if (shown.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: Text(
            widget.noMatchLabel,
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
          ),
        ),
      // « Par mes propres moyens » échappe au filtre : c'est une réponse,
      // pas un arrêt, et elle doit rester atteignable même quand la
      // recherche ne renvoie rien.
      if (!filtering || shown.isEmpty)
        _Option(
          label: widget.noneLabel,
          selected: widget.answered && widget.selectedId == null,
          enabled: widget.enabled,
          onTap: () => widget.onChoose(null),
        ),
    ];

    final search = [
      if (searchable) ...[
        ReturnPointSearchField(
          controller: _search,
          hint: widget.searchHint,
          autofocus: widget.autofocusSearch,
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    ];

    if (widget.scrollable) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...search,
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: options,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [...search, ...options],
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
    this.sublabel,
  });

  final String label;
  final String? sublabel;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final border = selected ? AppColors.primary : AppColors.border;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: selected
            ? AppColors.primary.withValues(alpha: 0.06)
            : AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.md),
            decoration: BoxDecoration(
              border: Border.all(color: border, width: selected ? 1.6 : 1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  size: 20,
                  color: selected ? AppColors.primary : AppColors.textMuted,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(label, style: AppTypography.bodyMedium),
                      if (sublabel != null && sublabel!.isNotEmpty)
                        Text(
                          sublabel!,
                          style: AppTypography.caption
                              .copyWith(color: AppColors.textMuted),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

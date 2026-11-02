import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aji_tfarraj/app/design_system/buttons.dart';
import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';
import 'package:aji_tfarraj/app/localization/locale_provider.dart';
import 'package:aji_tfarraj/features/charge_public/data/charge_public_repository.dart';
import 'package:aji_tfarraj/features/charge_public/domain/wafacash.dart';
import 'package:aji_tfarraj/features/notifications/data/notification_repository.dart'
    show sharedPreferencesProvider;

/// L'annonce aux chargés publics : ils ne sont plus payés qu'en retirant via
/// Wafacash, certains jours du mois seulement, et les règles du retrait ont
/// changé. Un bandeau, une fois ; le détail reste accessible depuis « Comment ça
/// marche ? » sur la carte.

/// Lu une fois sur ce téléphone. Changer la clé relance l'annonce pour tous.
class WafacashNewsSeen extends Notifier<bool> {
  static const _key = 'wafacash_news_v1_seen';

  @override
  bool build() => ref.read(sharedPreferencesProvider).getBool(_key) ?? false;

  void markSeen() {
    state = true;
    ref.read(sharedPreferencesProvider).setBool(_key, true);
  }
}

final wafacashNewsSeenProvider =
    NotifierProvider<WafacashNewsSeen, bool>(WafacashNewsSeen.new);

/// Le bandeau, en haut de l'accueil et des gains, tant que l'annonce n'a pas
/// été lue. Rien tant que l'interrupteur général est coupé : il annoncerait une
/// carte que l'onglet n'affiche pas. Hors ouverture du mois, si : c'est même là
/// qu'il sert le plus.
class WafacashNewsBanner extends ConsumerWidget {
  const WafacashNewsBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(wafacashNewsSeenProvider)) return const SizedBox.shrink();

    final overview = ref.watch(wafacashProvider).valueOrNull;
    if (overview == null || !overview.open) return const SizedBox.shrink();

    final c = ref.watch(stringsProvider).wafacash;
    final radius = BorderRadius.circular(AppSpacing.radiusMd);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Material(
        color: AppColors.primary.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: AppColors.primary.withValues(alpha: 0.35)),
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: () => showWafacashNews(context, overview),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpacing.md, AppSpacing.md, 4, AppSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.campaign_outlined, color: AppColors.accentInk),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.newsBannerTitle, style: AppTypography.labelLarge),
                      const SizedBox(height: 2),
                      Text(
                          c.newsBannerBody(overview.window?.startDay,
                              overview.window?.endDay),
                          style: AppTypography.bodySmall
                              .copyWith(color: AppColors.textSecondary)),
                      const SizedBox(height: AppSpacing.xs),
                      Text(c.newsBannerAction,
                          style: AppTypography.labelMedium
                              .copyWith(color: AppColors.accentInk)),
                    ],
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: c.newsDone,
                  icon: Icon(Icons.close, size: 18, color: AppColors.textMuted),
                  onPressed: () =>
                      ref.read(wafacashNewsSeenProvider.notifier).markSeen(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Le détail des règles. L'ouvrir suffit à marquer l'annonce comme lue.
Future<void> showWafacashNews(BuildContext context, WafacashOverview overview) {
  return showModalBottomSheet<void>(
    // Au-dessus de la barre d'onglets flottante, pas dessous.
    useRootNavigator: true,
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: AppColors.backgroundWhite,
    builder: (_) => _WafacashNewsSheet(overview: overview),
  );
}

class _WafacashNewsSheet extends ConsumerStatefulWidget {
  const _WafacashNewsSheet({required this.overview});

  final WafacashOverview overview;

  @override
  ConsumerState<_WafacashNewsSheet> createState() => _WafacashNewsSheetState();
}

class _WafacashNewsSheetState extends ConsumerState<_WafacashNewsSheet> {
  /// Dans l'ordre de [WafacashCopy.newsItems]. Sans fenêtre, le point sur les
  /// jours du mois n'existe pas : son icône non plus.
  static const _icons = [
    Icons.payments_outlined,
    Icons.calendar_month_outlined,
    Icons.schedule,
    Icons.storefront_outlined,
    Icons.pin_outlined,
    Icons.rule,
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(wafacashNewsSeenProvider.notifier).markSeen();
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(stringsProvider).wafacash;
    final o = widget.overview;
    final items =
        c.newsItems(c.money(o.minAmount), o.window?.startDay, o.window?.endDay);
    final icons =
        o.window != null ? _icons : [..._icons.take(1), ..._icons.skip(2)];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(c.newsTitle, style: AppTypography.h3),
          const SizedBox(height: AppSpacing.lg),
          for (var i = 0; i < items.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icons[i], size: 22, color: AppColors.accentInk),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(items[i].title, style: AppTypography.labelLarge),
                      const SizedBox(height: 2),
                      Text(items[i].body,
                          style: AppTypography.bodySmall
                              .copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            text: c.newsDone,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

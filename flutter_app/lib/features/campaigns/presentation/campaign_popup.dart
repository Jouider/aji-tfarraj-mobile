import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';
import 'package:aji_tfarraj/app/localization/locale_provider.dart';
import 'package:aji_tfarraj/app/router.dart';
import 'package:aji_tfarraj/features/campaigns/data/campaigns_controller.dart';
import 'package:aji_tfarraj/features/campaigns/domain/campaign.dart';
import 'package:aji_tfarraj/features/campaigns/presentation/campaign_actions.dart';

/// La fenêtre d'une campagne, posée par AppGate au-dessus de l'accueil :
/// image 4:5, un vrai bouton, ✕, et « Ne plus afficher » si le serveur le
/// permet. Jamais par-dessus la mise à jour forcée, le verrou ou la
/// connexion : AppGate ne la pose que sur l'accueil, quand rien d'autre n'y
/// est.
class CampaignPopupOverlay extends ConsumerStatefulWidget {
  const CampaignPopupOverlay({super.key, required this.campaign});

  final Campaign campaign;

  @override
  ConsumerState<CampaignPopupOverlay> createState() =>
      _CampaignPopupOverlayState();
}

class _CampaignPopupOverlayState extends ConsumerState<CampaignPopupOverlay> {
  @override
  void initState() {
    super.initState();
    // Visible : l'impression part (c'est elle que le serveur compte pour
    // « une fois par jour, trois fois au plus »).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(campaignsProvider.notifier).popupShown(widget.campaign);
      }
    });
  }

  void _tap() {
    final c = widget.campaign;
    ref.read(campaignsProvider.notifier).tapped(c);
    runCampaignAction(ref.read(routerProvider), c.action);
  }

  void _close({bool never = false}) => ref
      .read(campaignsProvider.notifier)
      .closePopup(widget.campaign, never: never);

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider).campaigns;
    final arabic = ref.watch(isRtlProvider);
    final c = widget.campaign;
    final title = c.title.pick(arabic: arabic);
    final body = c.body.pick(arabic: arabic);
    final cta = c.cta.pick(arabic: arabic) ?? s.defaultCta;

    return Positioned.fill(
      child: Material(
        color: Colors.black.withValues(alpha: 0.62),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, box) {
              // L'image 4:5 et le bouton tiennent dans l'écran, sans
              // défiler, même sur un petit iPhone : la largeur se règle sur
              // la hauteur disponible (texte et bouton : ~190 px).
              final fitWidth =
                  (box.maxHeight - 2 * AppSpacing.xl - 190) * 4 / 5;
              final width = fitWidth.clamp(220.0, 400.0);
              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: width),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.backgroundWhite,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Stack(
                            children: [
                              GestureDetector(
                                onTap: _tap,
                                child: AspectRatio(
                                  aspectRatio: 4 / 5,
                                  child: CampaignImage(
                                      url: c.imageUrl, label: title),
                                ),
                              ),
                              PositionedDirectional(
                                top: AppSpacing.sm,
                                end: AppSpacing.sm,
                                child:
                                    _CloseButton(label: s.close, onTap: _close),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(AppSpacing.lg,
                                AppSpacing.md, AppSpacing.lg, AppSpacing.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (title != null)
                                  Text(title,
                                      textAlign: TextAlign.center,
                                      style: AppTypography.h4),
                                if (body != null) ...[
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(body,
                                      textAlign: TextAlign.center,
                                      style: AppTypography.bodySmall.copyWith(
                                          color: AppColors.textSecondary)),
                                ],
                                if (title != null || body != null)
                                  const SizedBox(height: AppSpacing.md),
                                FilledButton(
                                  onPressed: _tap,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.primaryAction,
                                    foregroundColor: AppColors.onPrimary,
                                    minimumSize: const Size.fromHeight(
                                        AppSpacing.buttonHeight),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          AppSpacing.radiusLg),
                                    ),
                                  ),
                                  child: Text(cta,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.labelLarge.copyWith(
                                          color: AppColors.onPrimary)),
                                ),
                                if (c.canHideForever)
                                  TextButton(
                                    onPressed: () => _close(never: true),
                                    child: Text(s.neverShowAgain,
                                        style: AppTypography.caption.copyWith(
                                            color: AppColors.textMuted,
                                            decoration:
                                                TextDecoration.underline)),
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
            },
          ),
        ),
      ),
    );
  }
}

/// L'image d'une campagne : en cache, sans déformation (elle remplit son
/// cadre au bon format).
class CampaignImage extends StatelessWidget {
  const CampaignImage({super.key, required this.url, this.label});

  final String url;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: label,
      child: CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(color: AppColors.backgroundGrey),
        errorWidget: (_, __, ___) => Container(
          color: AppColors.backgroundGrey,
          alignment: Alignment.center,
          child: Icon(Icons.image_outlined, color: AppColors.textMuted),
        ),
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton(
      {required this.label, required this.onTap, this.size = 36});

  final String label;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.black.withValues(alpha: 0.45),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(Icons.close, size: size * 0.55, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

/// Le petit ✕ d'une bannière : même bouton, plus petit.
class CampaignCloseButton extends StatelessWidget {
  const CampaignCloseButton(
      {super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) =>
      _CloseButton(label: label, onTap: onTap, size: 28);
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/shadows.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';
import 'package:aji_tfarraj/app/localization/locale_provider.dart';
import 'package:aji_tfarraj/features/social/domain/social_link.dart';
import 'package:aji_tfarraj/features/tutorials/data/tutorials_repository.dart'
    show appConfigJsonProvider;

/// Nos comptes officiels, relus avec le reste d'`app-config`.
final socialLinksProvider = FutureProvider<List<SocialLink>>(
  (ref) async =>
      SocialLink.fromAppConfig(await ref.watch(appConfigJsonProvider.future)),
);

/// « Suis Aji Tfarraj » : une carte, un bouton rond par réseau.
///
/// Les liens viennent du tableau de bord ; tant qu'aucun n'y est tapé, ou si
/// le serveur ne répond pas, la carte n'existe pas, pas même sa marge.
class FollowUsCard extends ConsumerWidget {
  const FollowUsCard({super.key, this.padding = EdgeInsets.zero});

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final links = ref.watch(socialLinksProvider).valueOrNull ?? const [];
    if (links.isEmpty) return const SizedBox.shrink();

    final c = ref.watch(stringsProvider).followUs;

    return Padding(
      padding: padding,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.cardDarkElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              c.title,
              style: AppTypography.labelLarge
                  .copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 2),
            Text(
              c.subtitle,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMuted,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: [
                for (final link in links)
                  _NetworkButton(
                    link: link,
                    semanticLabel: c.followOn(link.label),
                    onTap: () => _open(context, link, c.cannotOpen),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Dans l'app du réseau quand elle est installée — c'est là qu'on s'abonne
  /// d'un geste —, sinon dans le navigateur.
  Future<void> _open(
      BuildContext context, SocialLink link, String failure) async {
    final messenger = ScaffoldMessenger.of(context);
    var opened = false;
    try {
      opened = await launchUrl(link.url, mode: LaunchMode.externalApplication);
    } catch (_) {}
    if (!opened) {
      messenger.showSnackBar(SnackBar(content: Text(failure)));
    }
  }
}

class _NetworkButton extends StatelessWidget {
  const _NetworkButton({
    required this.link,
    required this.semanticLabel,
    required this.onTap,
  });

  final SocialLink link;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 64,
          child: Column(
            children: [
              NetworkGlyph(network: link.network, size: 48),
              const SizedBox(height: 6),
              Text(
                link.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption
                    .copyWith(color: AppColors.textSecondary, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// La marque du réseau, sur sa couleur : reconnue avant d'être lue.
/// Material a TikTok, Snapchat et Facebook ; le badge d'Instagram
/// et le bouton de YouTube sont dessinés, WhatsApp est une bulle sur son vert.
class NetworkGlyph extends StatelessWidget {
  const NetworkGlyph({super.key, required this.network, this.size = 48});

  final String network;
  final double size;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size * 0.3);
    final icon = size * 0.55;

    BoxDecoration flat(Color color) =>
        BoxDecoration(color: color, borderRadius: radius);

    final (BoxDecoration decoration, Widget glyph) = switch (network) {
      'instagram' => (
          BoxDecoration(
            borderRadius: radius,
            gradient: const LinearGradient(
              begin: Alignment.bottomLeft,
              end: Alignment.topRight,
              colors: [
                Color(0xFFFEDA75),
                Color(0xFFFA7E1E),
                Color(0xFFD62976),
                Color(0xFF962FBF),
                Color(0xFF4F5BD5),
              ],
            ),
          ),
          Icon(Icons.camera_alt_outlined, size: icon, color: Colors.white),
        ),
      'tiktok' => (
          flat(const Color(0xFF111111)),
          Icon(Icons.tiktok, size: icon, color: Colors.white),
        ),
      'facebook' => (
          flat(const Color(0xFF1877F2)),
          Icon(Icons.facebook, size: icon, color: Colors.white),
        ),
      'youtube' => (
          flat(const Color(0xFFFF0000)),
          Icon(Icons.play_arrow_rounded, size: icon, color: Colors.white),
        ),
      'snapchat' => (
          flat(const Color(0xFFFFFC00)),
          Icon(Icons.snapchat, size: icon, color: Colors.black),
        ),
      'whatsapp' => (
          flat(const Color(0xFF25D366)),
          Icon(Icons.chat_rounded, size: icon, color: Colors.white),
        ),
      _ => (
          flat(AppColors.primary),
          Icon(Icons.link, size: icon, color: AppColors.onPrimary),
        ),
    };

    return Container(
      width: size,
      height: size,
      decoration: decoration,
      alignment: Alignment.center,
      child: glyph,
    );
  }
}

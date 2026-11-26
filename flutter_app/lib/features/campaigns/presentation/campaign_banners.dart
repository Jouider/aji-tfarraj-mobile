import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';
import 'package:aji_tfarraj/app/localization/locale_provider.dart';
import 'package:aji_tfarraj/app/router.dart';
import 'package:aji_tfarraj/features/campaigns/data/campaigns_controller.dart';
import 'package:aji_tfarraj/features/campaigns/domain/campaign.dart';
import 'package:aji_tfarraj/features/campaigns/presentation/campaign_actions.dart';
import 'package:aji_tfarraj/features/campaigns/presentation/campaign_popup.dart';

/// Les bannières de l'accueil : image 16:9, un carrousel s'il y en a
/// plusieurs, un petit ✕ qui la cache jusqu'à demain. Sans bannière, rien :
/// aucune place prise.
class CampaignBanners extends ConsumerStatefulWidget {
  const CampaignBanners({super.key, this.padding = EdgeInsets.zero});

  final EdgeInsetsGeometry padding;

  @override
  ConsumerState<CampaignBanners> createState() => _CampaignBannersState();
}

class _CampaignBannersState extends ConsumerState<CampaignBanners> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _seen(List<Campaign> banners, int index) {
    if (index < 0 || index >= banners.length) return;
    final c = banners[index];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(campaignsProvider.notifier).bannerShown(c);
    });
  }

  void _tap(Campaign c) {
    ref.read(campaignsProvider.notifier).tapped(c);
    runCampaignAction(ref.read(routerProvider), c.action);
  }

  @override
  Widget build(BuildContext context) {
    final banners = ref.watch(campaignsProvider.select((s) => s.banners));
    if (banners.isEmpty) return const SizedBox.shrink();

    final s = ref.watch(stringsProvider).campaigns;
    final arabic = ref.watch(isRtlProvider);
    final page = _page.clamp(0, banners.length - 1);
    _seen(banners, page);

    return Padding(
      padding: widget.padding,
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: PageView.builder(
              controller: _controller,
              itemCount: banners.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (context, i) {
                final c = banners[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        GestureDetector(
                          onTap: () => _tap(c),
                          child: CampaignImage(
                              url: c.imageUrl,
                              label: c.title.pick(arabic: arabic)),
                        ),
                        PositionedDirectional(
                          top: AppSpacing.sm,
                          end: AppSpacing.sm,
                          child: CampaignCloseButton(
                            label: s.close,
                            onTap: () => ref
                                .read(campaignsProvider.notifier)
                                .dismissBanner(c),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (banners.length > 1) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < banners.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == page ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == page
                          ? AppColors.accentInk
                          : AppColors.textMuted.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

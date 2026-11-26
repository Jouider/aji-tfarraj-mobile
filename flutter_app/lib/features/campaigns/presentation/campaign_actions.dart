import 'package:go_router/go_router.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:aji_tfarraj/app/routes.dart';
import 'package:aji_tfarraj/features/campaigns/domain/campaign.dart';
import 'package:aji_tfarraj/features/review/data/review_prompter.dart';

/// Où mène un écran nommé par le serveur (`action.screen`). `tab` : un onglet
/// de la barre du bas, on y va ; sinon on empile l'écran. Un nom inconnu
/// ramène à l'accueil. `store` n'a pas de route : voir [runCampaignAction].
({String route, bool tab}) campaignScreenRoute(String? screen) =>
    switch (screen) {
      'shows' => (route: Routes.browse, tab: true),
      'my_reservations' => (route: Routes.myReservations, tab: true),
      'profile' => (route: Routes.profile, tab: true),
      // La photo se change dans « Modifier le profil ».
      'profile_photo' => (route: Routes.editProfile, tab: false),
      'rewards' => (route: Routes.rewards, tab: false),
      'referral' => (route: Routes.referralStats, tab: false),
      'lucky_wheel' => (route: Routes.wheel, tab: false),
      'casting_profile' => (route: Routes.casting, tab: false),
      _ => (route: Routes.home, tab: true),
    };

/// Une page web : le navigateur du téléphone (Safari / Chrome), à défaut
/// Safari View Controller / Chrome Custom Tabs. Jamais une WebView : on y
/// envoie mal une vidéo de 300 Mo pour un casting.
Future<bool> openCampaignUrl(String url) async {
  final uri = Uri.tryParse(url.trim());
  if (uri == null || !(uri.scheme == 'https' || uri.scheme == 'http')) {
    return false;
  }
  try {
    if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return true;
  } catch (_) {}
  try {
    return await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
  } catch (_) {
    return false;
  }
}

/// Fait ce que dit l'action. `none` ou un type inconnu : rien (la fenêtre,
/// elle, est déjà fermée). `openUrl` et `openStore` se remplacent en test.
Future<void> runCampaignAction(
  GoRouter router,
  CampaignAction action, {
  Future<bool> Function(String url) openUrl = openCampaignUrl,
  Future<void> Function()? openStore,
}) async {
  switch (action.type) {
    case 'url':
      if (action.url != null) await openUrl(action.url!);
    case 'show':
      if (action.showId != null) {
        router.push(Routes.showDetail('${action.showId}'));
      }
    case 'episode':
      final show = action.showId;
      final episode = action.episodeId;
      if (show != null && episode != null) {
        // La fiche de l'émission, puis l'épisode choisi par-dessus : le
        // retour ramène à la fiche.
        router.push(Routes.showDetail('$show'));
        router.push(Routes.episodeReserve('$show', '$episode'));
      } else if (show != null) {
        router.push(Routes.showDetail('$show'));
      }
    case 'screen':
      if (action.screen == 'store') {
        await (openStore ??
            () => InAppReview.instance
                .openStoreListing(appStoreId: ReviewPrompter.appStoreId))();
        return;
      }
      final target = campaignScreenRoute(action.screen);
      target.tab ? router.go(target.route) : router.push(target.route);
    default:
      // `none`, ou un type qu'une version future de l'app connaîtra.
      break;
  }
}

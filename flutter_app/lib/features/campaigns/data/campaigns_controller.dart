import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aji_tfarraj/features/campaigns/data/campaigns_repository.dart';
import 'package:aji_tfarraj/features/campaigns/domain/campaign.dart';
import 'package:aji_tfarraj/features/notifications/data/notification_repository.dart'
    show sharedPreferencesProvider;

/// Ce que l'app montre en ce moment.
class CampaignsState {
  const CampaignsState({
    this.feed = CampaignFeed.empty,
    this.fetchedAt,
    this.activePopup,
    this.popupDone = false,
    this.hiddenBanners = const {},
  });

  final CampaignFeed feed;
  final DateTime? fetchedAt;

  /// La fenêtre à montrer, jusqu'à ce qu'on la ferme ou la touche.
  final Campaign? activePopup;

  /// Une fenêtre a déjà été montrée depuis le lancement : plus d'autre.
  final bool popupDone;

  /// Bannières fermées aujourd'hui (✕) : elles reviennent demain.
  final Set<int> hiddenBanners;

  List<Campaign> get banners =>
      feed.banners.where((b) => !hiddenBanners.contains(b.id)).toList();

  CampaignsState copyWith({
    CampaignFeed? feed,
    DateTime? fetchedAt,
    Campaign? activePopup,
    bool clearPopup = false,
    bool? popupDone,
    Set<int>? hiddenBanners,
  }) =>
      CampaignsState(
        feed: feed ?? this.feed,
        fetchedAt: fetchedAt ?? this.fetchedAt,
        activePopup: clearPopup ? null : (activePopup ?? this.activePopup),
        popupDone: popupDone ?? this.popupDone,
        hiddenBanners: hiddenBanners ?? this.hiddenBanners,
      );
}

/// Les campagnes : chargées au lancement (en arrivant sur l'accueil), puis en
/// revenant au premier plan après 30 minutes. Une seule fenêtre par
/// lancement. Chaque affichage, toucher ou fermeture est envoyé au serveur,
/// qui s'en sert pour décider de la suite (par défaut, la fenêtre une fois
/// par jour, trois fois au plus).
class CampaignsController extends Notifier<CampaignsState> {
  /// Au-delà, un retour au premier plan recharge les campagnes.
  static const staleAfter = Duration(minutes: 30);

  DateTime Function() clock = DateTime.now;
  final Set<int> _seenBanners = {};
  Future<void>? _loading;

  CampaignsRepository get _repo => ref.read(campaignsRepositoryProvider);
  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  CampaignsState build() => const CampaignsState();

  bool get loaded => state.fetchedAt != null;

  /// Charge, sans jamais lever : en cas d'erreur, on garde ce qu'on avait.
  Future<void> refresh() =>
      _loading ??= _refresh().whenComplete(() => _loading = null);

  Future<void> _refresh() async {
    try {
      final feed = await _repo.fetch();
      _seenBanners.clear();
      state = state.copyWith(
        feed: feed,
        fetchedAt: clock(),
        // Une fenêtre par lancement : une fois montrée, on n'en prend plus.
        activePopup: state.popupDone ? null : feed.popup,
        clearPopup: state.popupDone || feed.popup == null,
        hiddenBanners: _hiddenToday(feed.banners),
      );
    } catch (_) {
      state = state.copyWith(fetchedAt: clock());
    }
  }

  /// Au retour au premier plan : seulement si les campagnes ont plus de 30 min.
  Future<void> refreshIfStale() async {
    final at = state.fetchedAt;
    if (at == null || clock().difference(at) >= staleAfter) {
      await refresh();
    }
  }

  /// La fenêtre est à l'écran : une impression, une seule.
  void popupShown(Campaign c) {
    if (state.popupDone) return;
    state = state.copyWith(popupDone: true);
    _repo.event(c, 'impression');
  }

  /// ✕ (`dismiss`) ou « Ne plus afficher » (`never`).
  void closePopup(Campaign c, {bool never = false}) {
    state = state.copyWith(clearPopup: true, popupDone: true);
    _repo.event(c, never ? 'never' : 'dismiss');
  }

  /// Le toucher : `click` avant l'action. La fenêtre se ferme.
  void tapped(Campaign c) {
    _repo.event(c, 'click');
    if (c.placement == Campaign.popup) {
      state = state.copyWith(clearPopup: true, popupDone: true);
    }
  }

  /// Une bannière visible : une impression par chargement.
  void bannerShown(Campaign c) {
    if (_seenBanners.add(c.id)) _repo.event(c, 'impression');
  }

  /// ✕ sur une bannière : cachée jusqu'à demain.
  void dismissBanner(Campaign c) {
    _prefs.setString(_bannerKey(c.id), _today());
    state = state.copyWith(hiddenBanners: {...state.hiddenBanners, c.id});
    _repo.event(c, 'dismiss');
  }

  Set<int> _hiddenToday(List<Campaign> banners) => {
        for (final b in banners)
          if (_prefs.getString(_bannerKey(b.id)) == _today()) b.id,
      };

  String _bannerKey(int id) => 'campaign_banner_hidden_$id';

  String _today() {
    final d = clock();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}

final campaignsProvider = NotifierProvider<CampaignsController, CampaignsState>(
    CampaignsController.new);

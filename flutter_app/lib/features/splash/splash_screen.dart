import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'package:aji_tfarraj/app/routes.dart';
import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/localization/locale_provider.dart';
import 'package:aji_tfarraj/features/notifications/data/notification_repository.dart'
    show sharedPreferencesProvider;

/// L'animation de lancement : trois secondes de logo, puis l'app.
///
/// L'écran natif est du même noir que le premier plan de la vidéo, si bien
/// qu'on ne voit pas où l'un s'arrête et où l'autre commence. La vidéo est
/// muette, et jouée « avec les autres » : elle ne coupe pas la musique de
/// quelqu'un qui ouvre l'app en écoutant autre chose.
///
/// Elle ne retient jamais personne : si elle ne démarre pas vite (vieux
/// téléphone, décodeur occupé), ou si elle bloque, on passe à la suite.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  static const _asset = 'assets/splash/splash.mp4';

  /// Le temps qu'on laisse à la vidéo pour démarrer.
  static const _startTimeout = Duration(milliseconds: 1500);

  /// Au-delà, on part quoi qu'il arrive.
  static const _hardLimit = Duration(seconds: 6);

  /// Le dernier plan — le logo complet — reste un instant à l'écran.
  static const _hold = Duration(milliseconds: 350);

  static const _fadeOut = Duration(milliseconds: 250);

  final _video = VideoPlayerController.asset(
    _asset,
    videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
  );

  final List<Timer> _timers = [];
  bool _ready = false;
  bool _ending = false;
  bool _fading = false;
  bool _left = false;

  @override
  void initState() {
    super.initState();
    _timers
      ..add(Timer(_startTimeout, () {
        if (!_ready) _leave();
      }))
      ..add(Timer(_hardLimit, _leave));
    _start();
  }

  Future<void> _start() async {
    try {
      await _video.initialize();
      await _video.setVolume(0);
      if (!mounted || _left) return;
      _video.addListener(_onTick);
      setState(() => _ready = true);
      await _video.play();
    } catch (_) {
      // Pas de lecteur, fichier illisible : l'app n'attend pas une animation.
      _leave();
    }
  }

  void _onTick() {
    final v = _video.value;
    if (_ending || !v.isInitialized || v.duration == Duration.zero) return;
    if (v.hasError) return _leave();
    // Une marge : certains lecteurs s'arrêtent quelques millisecondes avant
    // la durée annoncée, et la fin ne serait jamais « atteinte ».
    if (v.position >= v.duration - const Duration(milliseconds: 100)) {
      _ending = true;
      _timers.add(Timer(_hold, () {
        if (!mounted) return;
        setState(() => _fading = true);
        _timers.add(Timer(_fadeOut, _leave));
      }));
    }
  }

  void _leave() {
    if (_left || !mounted) return;
    _left = true;
    final prefs = ref.read(sharedPreferencesProvider);
    // Already chose a language before — skip to auth; first launch — show
    // the language picker.
    context.go(hasChosenLocale(prefs) ? Routes.authLanding : Routes.language);
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    _video.removeListener(_onTick);
    _video.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Icônes de la barre d'état en blanc : on est sur du noir.
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.splashBackground,
        body: Center(
          child: _ready
              ? AnimatedOpacity(
                  // Le fondu ne commence qu'une fois le dernier plan tenu.
                  opacity: _fading ? 0 : 1,
                  duration: _fadeOut,
                  // Contenue, pas rognée : sur un écran plus étroit que la
                  // vidéo, le noir l'entoure sans couture.
                  child: AspectRatio(
                    aspectRatio: _video.value.aspectRatio,
                    child: VideoPlayer(_video),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ),
    );
  }
}

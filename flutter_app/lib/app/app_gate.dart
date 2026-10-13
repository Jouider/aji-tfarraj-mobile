import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aji_tfarraj/app/router.dart';
import 'package:aji_tfarraj/app/routes.dart';
import 'package:aji_tfarraj/features/app_lock/data/app_lock_controller.dart';
import 'package:aji_tfarraj/features/app_lock/presentation/lock_screen.dart';
import 'package:aji_tfarraj/features/app_update/data/app_update_service.dart';
import 'package:aji_tfarraj/features/app_update/presentation/update_widgets.dart';

/// Wraps the whole app (via MaterialApp.builder) and overlays, in priority:
///   1. forced-update blocker (below min_version),
///   2. biometric lock screen (when enabled + locked) — but never over the
///      launch video: the lock takes over on its last frame, see
///      [LockScreen] and SplashScreen,
///   3. a dismissible "update available" sheet (optional update).
/// Also drives the biometric lock's foreground/background lifecycle.
class AppGate extends ConsumerStatefulWidget {
  final Widget child;
  const AppGate({super.key, required this.child});

  @override
  ConsumerState<AppGate> createState() => _AppGateState();
}

class _AppGateState extends ConsumerState<AppGate> with WidgetsBindingObserver {
  bool _updateDismissed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Start the update check and initialize the lock state.
      ref.read(updateStatusProvider);
      ref.read(appLockProvider);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final lock = ref.read(appLockProvider.notifier);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      lock.onPaused();
    } else if (state == AppLifecycleState.resumed) {
      lock.onResumed();
    }
  }

  /// Le lancement joue encore : rien de privé à l'écran, le verrou attend la
  /// fin de la vidéo pour prendre le relais sur son dernier plan.
  bool _onSplash(GoRouterDelegate delegate) {
    final matches = delegate.currentConfiguration;
    return matches.isEmpty || matches.uri.path == Routes.splash;
  }

  @override
  Widget build(BuildContext context) {
    final lock = ref.watch(appLockProvider);
    final update =
        ref.watch(updateStatusProvider).valueOrNull ?? UpdateStatus.none;
    final delegate = ref.watch(routerProvider).routerDelegate;

    return ListenableBuilder(
      listenable: delegate,
      builder: (context, _) =>
          _overlays(lock, update, onSplash: _onSplash(delegate)),
    );
  }

  Widget _overlays(AppLockState lock, UpdateStatus update,
      {required bool onSplash}) {
    final locked = lock.isLocked && !onSplash;
    final forced = update.requirement == UpdateRequirement.forced;
    // Verrouillée, la proposition de mise à jour attend le déverrouillage —
    // même pendant le lancement, pour ne pas apparaître puis disparaître.
    final showOptional = !forced &&
        !lock.isLocked &&
        !_updateDismissed &&
        update.requirement == UpdateRequirement.optional;

    return Stack(
      children: [
        widget.child,
        if (showOptional)
          UpdateAvailableOverlay(
            storeUrl: update.storeUrl,
            onLater: () => setState(() => _updateDismissed = true),
          ),
        if (locked) const Positioned.fill(child: LockScreen()),
        if (forced)
          Positioned.fill(child: ForceUpdateScreen(storeUrl: update.storeUrl)),
      ],
    );
  }
}

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aji_tfarraj/app/copywriting/wheel_copy.dart';
import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';
import 'package:aji_tfarraj/app/localization/locale_provider.dart';
import 'package:aji_tfarraj/app/network/api_client.dart';
import 'package:aji_tfarraj/app/routes.dart';
import 'package:aji_tfarraj/features/ads/data/ads_service.dart';
import 'package:aji_tfarraj/features/auth/data/auth_repository.dart';
import 'package:aji_tfarraj/features/loyalty/data/loyalty_repository.dart';
import 'package:aji_tfarraj/features/rewards/data/rewards_repository.dart';
import 'package:aji_tfarraj/features/wheel/data/wheel_repository.dart';
import 'package:aji_tfarraj/features/wheel/domain/wheel.dart';
import 'package:aji_tfarraj/features/wheel/presentation/lucky_wheel_view.dart';
import 'package:aji_tfarraj/features/wheel/presentation/wheel_painters.dart';
import 'package:aji_tfarraj/features/wheel/presentation/wheel_sheets.dart';

/// La roue de la chance : trois essais par jour pour gagner des points.
///
/// Quand le serveur le demande, seuls les premiers essais sont gratuits : les
/// suivants se débloquent un par un en regardant une vidéo. C'est le rappel
/// signé de Google au serveur qui débloque l'essai ; l'écran ne fait que
/// relire la roue jusqu'à le voir arriver.
///
/// Le résultat vient du serveur. Au toucher, la roue s'élance tout de suite
/// pendant que la requête part ; dès la réponse, elle ralentit et s'arrête
/// sur la case désignée. Le ralenti part exactement de la vitesse de croisière,
/// si bien qu'on ne voit jamais la roue « changer d'avis ».
///
/// Une scène sombre, comme un plateau télé : c'est le moment spectacle de
/// l'app, et l'or des ampoules n'existe que sur du noir.
class WheelScreen extends ConsumerStatefulWidget {
  const WheelScreen({super.key});

  @override
  ConsumerState<WheelScreen> createState() => _WheelScreenState();
}

enum _Phase { idle, spinUp, cruise, slowDown }

/// La vidéo qui débloque un essai : rien, la vidéo, puis l'attente du serveur.
enum _Video { none, playing, unlocking }

class _WheelScreenState extends ConsumerState<WheelScreen>
    with TickerProviderStateMixin {
  /// Deux tours par seconde en croisière.
  static const _cruiseSpeed = 4 * math.pi;
  static const _spinUp = Duration(milliseconds: 600);

  /// Un minimum de suspense, même quand le serveur répond tout de suite.
  static const _minCruise = Duration(milliseconds: 500);

  /// La durée visée pour le ralenti.
  static const _slowDownSeconds = 4.2;

  late final Ticker _ticker = createTicker(_onTick);
  late final AnimationController _lights = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  );

  final _rotation = ValueNotifier<double>(0);
  final _flap = ValueNotifier<double>(0);
  final _random = math.Random();

  _Phase _phase = _Phase.idle;
  Duration _phaseStart = Duration.zero;
  Duration _last = Duration.zero;
  double _speed = 0;

  double _from = 0;
  double _distance = 0;
  double _seconds = 1;

  SpinResult? _pending;
  Object? _failure;
  int _slices = 0;
  int _lastSlice = -1;
  Duration _lastHaptic = Duration.zero;

  Timer? _clock;
  bool _reloadedAfterMidnight = false;

  /// La roue s'ouvre arrêtée sur le gros lot : c'est lui qu'on a envie de
  /// viser. Une fois, au premier affichage.
  bool _placed = false;

  _Video _video = _Video.none;

  bool get _spinning => _phase != _Phase.idle;

  @override
  void initState() {
    super.initState();
    // L'horloge du « nouveaux essais dans… ».
    _clock = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _lights.stop();
    } else if (!_lights.isAnimating) {
      _lights.repeat();
    }
  }

  @override
  void dispose() {
    _clock?.cancel();
    _ticker.dispose();
    _lights.dispose();
    _rotation.dispose();
    _flap.dispose();
    super.dispose();
  }

  // ─── Le tour ────────────────────────────────────────────────────────

  Future<void> _spin(WheelStatus status) async {
    if (_spinning || status.spinsLeftAt(DateTime.now()) == 0) return;

    HapticFeedback.mediumImpact();
    setState(() {
      _phase = _Phase.spinUp;
      _phaseStart = Duration.zero;
      _last = Duration.zero;
      _speed = 0;
      _pending = null;
      _failure = null;
      _slices = status.slices.length;
    });
    _ticker.start();

    try {
      _pending = await ref.read(wheelProvider.notifier).spin();
    } catch (e) {
      _failure = e;
    }
  }

  void _onTick(Duration elapsed) {
    final dt = (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    final t = elapsed - _phaseStart;
    var angle = _rotation.value;

    switch (_phase) {
      case _Phase.idle:
        return;
      case _Phase.spinUp:
        final u = (t.inMicroseconds / _spinUp.inMicroseconds).clamp(0.0, 1.0);
        _speed = _cruiseSpeed * u * u;
        angle += _speed * dt;
        if (u >= 1) {
          _phase = _Phase.cruise;
          _phaseStart = elapsed;
        }
      case _Phase.cruise:
        angle += _cruiseSpeed * dt;
        if (t >= _minCruise && (_pending != null || _failure != null)) {
          _startSlowDown(angle, elapsed);
        }
      case _Phase.slowDown:
        final u = (t.inMicroseconds / 1e6 / _seconds).clamp(0.0, 1.0);
        // easeOutCubic : sa vitesse de départ (3·D/T) est celle de croisière.
        angle = _from + _distance * (1 - math.pow(1 - u, 3));
        if (u >= 1) {
          _rotation.value = angle % (2 * math.pi);
          _land();
          return;
        }
    }

    _rotation.value = angle;
    _tickPointer(angle, elapsed, dt);
  }

  void _startSlowDown(double angle, Duration elapsed) {
    const full = 2 * math.pi;
    final result = _pending;
    final reduced = MediaQuery.disableAnimationsOf(context);

    if (result != null && _slices > 0) {
      // Pas pile au milieu de la case : une vraie roue s'arrête où elle peut.
      final offset = 0.5 + (_random.nextDouble() - 0.5) * 0.6;
      final target =
          WheelGeometry.rotationFor(result.slice, _slices, offset: offset);
      final delta = (target - angle % full) % full;
      const wanted = _cruiseSpeed * _slowDownSeconds / 3;
      final turns =
          reduced ? 0 : ((wanted - delta) / full).round().clamp(1, 10);
      _distance = delta + turns * full;
    } else {
      // Pas de résultat : la roue finit sa course, sans rien désigner.
      _distance = full * 0.75;
    }

    _from = angle;
    _seconds = math.max(0.3, 3 * _distance / _cruiseSpeed);
    _phase = _Phase.slowDown;
    _phaseStart = elapsed;
  }

  /// La languette claque à chaque case, avec un petit retour haptique.
  void _tickPointer(double angle, Duration elapsed, double dt) {
    if (_slices > 0) {
      final slice = WheelGeometry.sliceUnderPointer(angle, _slices);
      if (slice != _lastSlice) {
        _lastSlice = slice;
        _flap.value = 1;
        if (elapsed - _lastHaptic > const Duration(milliseconds: 45)) {
          HapticFeedback.selectionClick();
          _lastHaptic = elapsed;
        }
        return;
      }
    }
    if (_flap.value > 0.01) {
      _flap.value *= math.exp(-dt * 14);
    } else if (_flap.value != 0) {
      _flap.value = 0;
    }
  }

  Future<void> _land() async {
    _ticker.stop();
    _flap.value = 0;
    final result = _pending;
    final failure = _failure;
    setState(() => _phase = _Phase.idle);

    final s = ref.read(stringsProvider);
    final c = s.wheel;

    if (result == null) {
      final code = failure is ApiException ? failure.code : null;
      if (code == 'NO_SPINS_LEFT' ||
          code == 'CLOSED' ||
          code == 'AD_REQUIRED') {
        ref.invalidate(wheelProvider);
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(switch (code) {
          'NO_SPINS_LEFT' => c.noSpinsLeft,
          'AD_REQUIRED' => c.adRequired,
          'CLOSED' => c.closed,
          _ => c.error,
        }),
      ));
      return;
    }

    if (result.outcome == WheelOutcome.retry) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.heavyImpact();
    }

    ref.read(wheelProvider.notifier).settle(result);
    if (result.points > 0) ref.invalidate(myPointsProvider);
    if (result.outcome == WheelOutcome.reward) {
      ref.invalidate(myRewardsProvider);
    }

    final action = await showWheelResult(
      context,
      result: result,
      copy: c,
      arabic: ref.read(isRtlProvider),
    );
    if (!mounted) return;

    switch (action) {
      case WheelResultAction.myRewards:
        context.push(Routes.myRewards);
      case WheelResultAction.again:
        final status = ref.read(wheelProvider).valueOrNull;
        if (status != null) _spin(status);
      case WheelResultAction.watchVideo:
        _watchVideo();
      case WheelResultAction.close:
      case null:
        break;
    }
  }

  // ─── La vidéo ───────────────────────────────────────────────────────

  Future<void> _watchVideo() async {
    final userId = ref.read(loginAuthStateProvider).user?.id;
    if (userId == null || _spinning || _video != _Video.none) return;

    final c = ref.read(stringsProvider).wheel;
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _video = _Video.playing);
    try {
      final earned = await ref
          .read(adsServiceProvider)
          .showRewardedForWheel(userId: userId);
      if (!mounted) return;
      if (!earned) {
        messenger.showSnackBar(SnackBar(content: Text(c.videoNotFinished)));
        return;
      }

      setState(() => _video = _Video.unlocking);
      final wheel = ref.read(wheelProvider.notifier);
      final unlocked = await wheel.waitForUnlockedSpin(
        upTo: const Duration(seconds: 20),
      );
      if (!mounted) return;
      if (unlocked) {
        HapticFeedback.mediumImpact();
      } else {
        // Google a parfois plus d'une minute de retard. La vidéo est vue :
        // on rend la main, et la roue continue de relire en silence — le
        // bouton « Tourner » apparaît tout seul quand l'essai arrive.
        messenger.showSnackBar(SnackBar(content: Text(c.unlockSlow)));
        unawaited(wheel.waitForUnlockedSpin(
          every: const Duration(seconds: 5),
          upTo: const Duration(minutes: 3),
        ));
      }
    } finally {
      if (mounted) setState(() => _video = _Video.none);
    }
  }

  // ─── L'écran ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final c = s.wheel;
    final arabic = ref.watch(isRtlProvider);
    final async = ref.watch(wheelProvider);
    final status = async.valueOrNull;

    // Passé minuit à Casablanca, les essais reviennent : relire le serveur
    // une fois, pour le reste (le gros lot du jour).
    if (status != null &&
        status.resetsAt != null &&
        !DateTime.now().isBefore(status.resetsAt!) &&
        !_reloadedAfterMidnight &&
        !_spinning) {
      _reloadedAfterMidnight = true;
      WidgetsBinding.instance
          .addPostFrameCallback((_) => ref.invalidate(wheelProvider));
    }

    return PopScope(
      // Pendant un tour, le résultat est déjà tiré : on attend de le voir.
      canPop: !_spinning,
      child: Scaffold(
        backgroundColor: AppColors.premiumSurface,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
          systemOverlayStyle: SystemUiOverlayStyle.light,
          // Au bord d'attaque, comme les autres écrans : centré entre un
          // retour et « Règles », il paraissait décalé.
          centerTitle: false,
          title: Text(c.title,
              style: AppTypography.h3.copyWith(color: Colors.white)),
        ),
        body: DecoratedBox(
          // Le projecteur : une lueur dorée derrière la roue.
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.15),
              radius: 0.9,
              colors: [
                WheelPalette.gold.withValues(alpha: 0.22),
                AppColors.premiumSurface,
              ],
            ),
          ),
          child: SafeArea(
            child: async.when(
              skipLoadingOnReload: true,
              loading: () => const Center(
                child: CircularProgressIndicator(color: WheelPalette.gold),
              ),
              error: (_, __) => _Message(
                icon: Icons.wifi_off_rounded,
                text: c.error,
                action: s.retry,
                onAction: () => ref.invalidate(wheelProvider),
              ),
              data: (status) => status.playable
                  ? _buildWheel(status, c, arabic)
                  : _Message(
                      icon: Icons.lock_clock_rounded,
                      text: c.closed,
                      action: c.close,
                      onAction: () => context.pop(),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWheel(WheelStatus status, WheelCopy c, bool arabic) {
    final now = DateTime.now();
    final left = status.spinsLeftAt(now);
    final videoLeft = status.adSpinsLeftAt(now);
    final jackpot = status.jackpot;

    if (!_placed) {
      _placed = true;
      final showcase = status.slices
          .indexWhere((slice) => slice.type == WheelOutcome.reward);
      _rotation.value = WheelGeometry.rotationFor(
          showcase < 0 ? 0 : showcase, status.slices.length);
    }

    return LayoutBuilder(
      builder: (context, box) {
        final size = math.min(
          math.min(box.maxWidth - 2 * AppSpacing.xl, 360.0),
          box.maxHeight * 0.52,
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.sm),
              _BalancePill(label: c.balance(status.pointsBalance)),
              const SizedBox(height: AppSpacing.lg),
              Text(
                c.headline,
                textAlign: TextAlign.center,
                style: AppTypography.h2.copyWith(color: Colors.white),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                status.adSpinsEnabled
                    ? c.subtitleWithVideo(status.freeSpins)
                    : c.subtitle(status.dailySpins),
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.inkOnPhotoMuted),
              ),
              const SizedBox(height: AppSpacing.xl),
              Semantics(
                label: c.title,
                child: LuckyWheelView(
                  size: size,
                  slices: status.slices,
                  pointsUnit: c.pointsUnit,
                  rotation: _rotation,
                  flap: _flap,
                  lights: _lights,
                  chasing: _spinning,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              _SpinsLeft(
                left: left,
                locked: videoLeft,
                total: status.dailySpins,
                label: left == 0 && videoLeft > 0
                    ? c.videoSpinsLeft(videoLeft)
                    : c.spinsLeft(left),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (left > 0 || _spinning)
                _SpinButton(
                  label: _spinning ? c.spinning : c.spin,
                  busy: _spinning,
                  onPressed: () => _spin(status),
                )
              else if (videoLeft > 0 || _video != _Video.none)
                _SpinButton(
                  icon: Icons.play_circle_fill_rounded,
                  label: switch (_video) {
                    _Video.none => c.watchVideo,
                    _Video.playing => c.videoLoading,
                    _Video.unlocking => c.unlocking,
                  },
                  busy: _video != _Video.none,
                  onPressed: _watchVideo,
                )
              else
                _ComeBack(
                  title: c.comeBackTomorrow,
                  subtitle: status.resetsAt == null
                      ? null
                      : c.nextSpinsIn(status.resetsAt!.difference(now)),
                ),
              if (jackpot != null) ...[
                const SizedBox(height: AppSpacing.lg),
                _JackpotTeaser(
                  text: jackpot.availableToday
                      ? c.jackpotOfTheDay(jackpot.titleFor(arabic: arabic))
                      : c.jackpotGoneToday,
                  live: jackpot.availableToday,
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        );
      },
    );
  }
}

class _BalancePill extends StatelessWidget {
  const _BalancePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.xs + 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: AppColors.premiumBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.stars_rounded, size: 18, color: WheelPalette.gold),
          const SizedBox(width: AppSpacing.xs + 2),
          Text(
            label,
            style: AppTypography.labelMedium.copyWith(
              color: Colors.white,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// Les essais du jour, en pastilles : on les voit partir.
class _SpinsLeft extends StatelessWidget {
  const _SpinsLeft({
    required this.left,
    required this.locked,
    required this.total,
    required this.label,
  });

  final int left;

  /// Les essais qui suivent, à débloquer avec une vidéo : cerclés d'or,
  /// encore vides.
  final int locked;
  final int total;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < total; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < left
                      ? WheelPalette.gold
                      : Colors.white.withValues(alpha: 0.12),
                  border: Border.all(
                    color: i < left
                        ? WheelPalette.goldLight
                        : i < left + locked
                            ? WheelPalette.gold
                            : Colors.white.withValues(alpha: 0.2),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          label,
          style: AppTypography.labelMedium
              .copyWith(color: AppColors.inkOnPhotoMuted),
        ),
      ],
    );
  }
}

class _SpinButton extends StatelessWidget {
  const _SpinButton({
    this.icon = Icons.casino_rounded,
    required this.label,
    required this.busy,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: busy ? 0.6 : 1,
      duration: const Duration(milliseconds: 200),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: AppColors.actionGradient,
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              onTap: busy ? null : onPressed,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: 22),
                  const SizedBox(width: AppSpacing.sm),
                  // « Regarder une vidéo pour un nouvel essai » est long :
                  // il rétrécit un peu plutôt que de se couper.
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label,
                        maxLines: 1,
                        style: AppTypography.buttonLarge
                            .copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ComeBack extends StatelessWidget {
  const _ComeBack({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        border: Border.all(color: AppColors.premiumBorder),
      ),
      child: Column(
        children: [
          Text(title,
              style: AppTypography.labelLarge.copyWith(color: Colors.white)),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: AppTypography.caption.copyWith(color: WheelPalette.gold),
            ),
          ],
        ],
      ),
    );
  }
}

class _JackpotTeaser extends StatelessWidget {
  const _JackpotTeaser({required this.text, required this.live});

  final String text;
  final bool live;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.card_giftcard_rounded,
          size: 18,
          color: live ? WheelPalette.gold : AppColors.inkOnPhotoMuted,
        ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: AppTypography.caption.copyWith(
              color: live ? WheelPalette.gold : AppColors.inkOnPhotoMuted,
            ),
          ),
        ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.text,
    required this.action,
    required this.onAction,
  });

  final IconData icon;
  final String text;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: WheelPalette.gold),
            const SizedBox(height: AppSpacing.lg),
            Text(
              text,
              textAlign: TextAlign.center,
              style: AppTypography.bodyLarge.copyWith(color: Colors.white),
            ),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton(
              onPressed: onAction,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: AppColors.premiumBorder),
              ),
              child: Text(action),
            ),
          ],
        ),
      ),
    );
  }
}

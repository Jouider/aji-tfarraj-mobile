import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/shadows.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';
import 'package:aji_tfarraj/app/localization/locale_provider.dart';
import 'package:aji_tfarraj/app/routes.dart';
import 'package:aji_tfarraj/features/wheel/data/wheel_repository.dart';
import 'package:aji_tfarraj/features/wheel/domain/wheel.dart';
import 'package:aji_tfarraj/features/wheel/presentation/wheel_painters.dart';

/// La roue de la chance, sur l'accueil : une demi-roue qui dépasse du bord
/// de l'écran, en bas, au-dessus de la barre d'onglets — à droite, à gauche
/// en arabe. Elle tourne doucement, ses ampoules courent tant qu'il reste
/// des essais, et une pastille dit combien. Un toucher ouvre la roue.
///
/// Elle remplace la carte de l'accueil, qui empilait avec la bannière des
/// campagnes : l'accueil reste aux émissions. Pendant qu'on fait défiler,
/// elle rentre presque toute dans le bord pour ne cacher aucune carte, et
/// ressort quand la page s'arrête. Elle n'existe que si la roue est ouverte.
/// (Fidélité et Récompenses gardent la carte complète.)
class WheelPeek extends ConsumerStatefulWidget {
  const WheelPeek({super.key, this.scrollController});

  /// La page qu'elle surveille, pour rentrer pendant le défilement.
  final ScrollController? scrollController;

  /// Le diamètre de la roue entière ; on en voit à peu près la moitié.
  static const size = 80.0;

  @override
  ConsumerState<WheelPeek> createState() => _WheelPeekState();
}

class _WheelPeekState extends ConsumerState<WheelPeek>
    with TickerProviderStateMixin {
  late final AnimationController _turn =
      AnimationController(vsync: this, duration: const Duration(seconds: 14));
  late final AnimationController _lights =
      AnimationController(vsync: this, duration: const Duration(seconds: 1));

  bool _shown = false;
  bool _tucked = false;
  bool _pressed = false;
  Timer? _settle;
  Timer? _enter;

  @override
  void initState() {
    super.initState();
    widget.scrollController?.addListener(_onScroll);
    // Elle arrive un peu après l'accueil : un mouvement qu'on remarque.
    _enter = Timer(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _shown = true);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _turn.stop();
      _lights.stop();
    } else {
      if (!_turn.isAnimating) _turn.repeat();
      if (!_lights.isAnimating) _lights.repeat();
    }
  }

  void _onScroll() {
    if (!_tucked) setState(() => _tucked = true);
    _settle?.cancel();
    _settle = Timer(const Duration(milliseconds: 650), () {
      if (mounted) setState(() => _tucked = false);
    });
  }

  @override
  void dispose() {
    widget.scrollController?.removeListener(_onScroll);
    _settle?.cancel();
    _enter?.cancel();
    _turn.dispose();
    _lights.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wheel = ref.watch(wheelProvider).valueOrNull;
    if (wheel == null || !wheel.playable) return const SizedBox.shrink();

    final c = ref.watch(stringsProvider).wheel;
    final now = DateTime.now();
    final left = wheel.spinsLeftAt(now);
    final lively = left > 0 || wheel.videoUnlocksSpinAt(now);
    final rtl = Directionality.of(context) == TextDirection.rtl;

    // La part de la roue cachée dans le bord : toute avant l'arrivée,
    // presque toute pendant le défilement, un peu moins de la moitié sinon.
    final hidden = !_shown ? 1.0 : (_tucked ? 0.76 : 0.46);

    return PositionedDirectional(
      end: 0,
      bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.xs,
      child: AnimatedSlide(
        offset: Offset((rtl ? -1 : 1) * hidden, 0),
        duration: Duration(milliseconds: _shown && !_tucked ? 520 : 260),
        curve: _shown && !_tucked ? Curves.easeOutBack : Curves.easeOut,
        child: Semantics(
          button: true,
          label: '${c.entryTitle}, '
              '${left > 0 ? c.entrySpinsLeft(left) : c.entryComeBack}',
          child: GestureDetector(
            onTapDown: (_) => setState(() => _pressed = true),
            onTapCancel: () => setState(() => _pressed = false),
            onTapUp: (_) => setState(() => _pressed = false),
            onTap: () => context.push(Routes.wheel),
            child: AnimatedScale(
              scale: _pressed ? 0.92 : 1,
              duration: const Duration(milliseconds: 120),
              child: _PeekWheel(
                turn: _turn,
                lights: _lights,
                slices: wheel.slices,
                left: left,
                lively: lively,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PeekWheel extends StatelessWidget {
  const _PeekWheel({
    required this.turn,
    required this.lights,
    required this.slices,
    required this.left,
    required this.lively,
  });

  final AnimationController turn;
  final AnimationController lights;
  final List<WheelSlice> slices;
  final int left;
  final bool lively;

  @override
  Widget build(BuildContext context) {
    const size = WheelPeek.size;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Un halo doré, et une ombre pour la détacher des affiches.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: WheelPalette.gold
                        .withValues(alpha: lively ? 0.55 : 0.25),
                    blurRadius: 22,
                    spreadRadius: 1,
                  ),
                  // L'ombre neutre du thème : elle se lit en clair comme en sombre.
                  ...AppShadows.card,
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: WheelRimPainter(
                lights: lights,
                chasing: lively,
                bulbs: 12,
                thickness: 0.11,
              ),
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(size * 0.11),
              child: RotationTransition(
                turns: turn,
                child: CustomPaint(
                  painter: WheelFacePainter(
                    slices: slices,
                    pointsUnit: '',
                    showLabels: false,
                  ),
                ),
              ),
            ),
          ),
          Center(
            child: Container(
              width: size * 0.24,
              height: size * 0.24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.premiumSurface,
                border: Border.all(color: WheelPalette.gold, width: 2),
              ),
            ),
          ),
          // Les essais du jour, du côté visible de la roue.
          if (left > 0)
            PositionedDirectional(
              top: -2,
              start: 6,
              child: Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryAction,
                  border: Border.all(color: AppColors.premiumSurface, width: 2),
                ),
                child: Text(
                  '$left',
                  style: AppTypography.labelSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

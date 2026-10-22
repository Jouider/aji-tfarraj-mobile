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

/// La porte de la roue, sur l'accueil et dans Fidélité.
///
/// Une petite roue qui tourne doucement sur le noir des cartes premium, et le
/// nombre d'essais du jour en pastille : on la remarque sans qu'elle prenne
/// la place des émissions. Elle n'existe que si la roue est ouverte — fermée
/// ou injoignable, rien ne s'affiche, pas même la marge.
class WheelEntryCard extends ConsumerStatefulWidget {
  const WheelEntryCard({super.key, this.padding = EdgeInsets.zero});

  final EdgeInsetsGeometry padding;

  @override
  ConsumerState<WheelEntryCard> createState() => _WheelEntryCardState();
}

class _WheelEntryCardState extends ConsumerState<WheelEntryCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _turn = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _turn.stop();
    } else if (!_turn.isAnimating) {
      _turn.repeat();
    }
  }

  @override
  void dispose() {
    _turn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wheel = ref.watch(wheelProvider).valueOrNull;
    if (wheel == null || !wheel.playable) return const SizedBox.shrink();

    final c = ref.watch(stringsProvider).wheel;
    final now = DateTime.now();
    final left = wheel.spinsLeftAt(now);
    final video = wheel.videoUnlocksSpinAt(now);
    final radius = BorderRadius.circular(20);

    return Padding(
      padding: widget.padding,
      child: Semantics(
        button: true,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: radius,
            onTap: () => context.push(Routes.wheel),
            child: Ink(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: AlignmentDirectional.topStart,
                  end: AlignmentDirectional.bottomEnd,
                  colors: [
                    AppColors.premiumSurfaceRaised,
                    AppColors.premiumSurface,
                  ],
                ),
                borderRadius: radius,
                border: Border.all(color: AppColors.premiumBorder),
                boxShadow: AppShadows.card,
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md + 2),
                child: Row(
                  children: [
                    _MiniWheel(
                        turn: _turn, wheelSlices: wheel.slices, left: left),
                    const SizedBox(width: AppSpacing.md + 2),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            c.entryTitle,
                            style: AppTypography.labelLarge
                                .copyWith(color: Colors.white),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            left > 0
                                ? c.entrySpinsLeft(left)
                                : video
                                    ? c.entryVideoSpin
                                    : c.entryComeBack,
                            style: AppTypography.caption.copyWith(
                              color: left > 0 || video
                                  ? WheelPalette.gold
                                  : AppColors.inkOnPhotoMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    if (left > 0 || video)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: WheelPalette.gold,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusFull),
                        ),
                        child: Text(
                          c.entryPlay,
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.premiumSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    else
                      const Icon(Icons.chevron_right_rounded,
                          color: AppColors.inkOnPhotoMuted),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniWheel extends StatelessWidget {
  const _MiniWheel({
    required this.turn,
    required this.wheelSlices,
    required this.left,
  });

  final AnimationController turn;
  final List<WheelSlice> wheelSlices;
  final int left;

  static const _size = 60.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _size,
      height: _size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: WheelRimPainter(
                lights: const AlwaysStoppedAnimation(0),
                chasing: false,
                bulbs: 8,
                thickness: 0.11,
              ),
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(_size * 0.11),
              child: RotationTransition(
                turns: turn,
                child: CustomPaint(
                  painter: WheelFacePainter(
                    slices: wheelSlices,
                    pointsUnit: '',
                    showLabels: false,
                  ),
                ),
              ),
            ),
          ),
          Center(
            child: Container(
              width: _size * 0.24,
              height: _size * 0.24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.premiumSurface,
                border: Border.all(color: WheelPalette.gold, width: 1.5),
              ),
            ),
          ),
          if (left > 0)
            PositionedDirectional(
              top: -4,
              end: -4,
              child: Container(
                width: 22,
                height: 22,
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

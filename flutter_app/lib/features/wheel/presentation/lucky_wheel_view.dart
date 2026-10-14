import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/primitives/app_logo.dart';
import 'package:aji_tfarraj/features/wheel/domain/wheel.dart';
import 'package:aji_tfarraj/features/wheel/presentation/wheel_painters.dart';

/// La roue assemblée : la couronne et ses ampoules, le disque qui tourne, le
/// moyeu au logo, et le pointeur qui bat à chaque case.
///
/// Le disque est peint une seule fois dans son propre calque ; pendant un
/// tour, seule sa rotation change. Les ampoules ont leur calque à elles.
class LuckyWheelView extends StatelessWidget {
  const LuckyWheelView({
    super.key,
    required this.size,
    required this.slices,
    required this.pointsUnit,
    required this.rotation,
    required this.lights,
    this.flap,
    this.chasing = false,
  });

  final double size;
  final List<WheelSlice> slices;
  final String pointsUnit;

  /// La rotation du disque, en radians, dans le sens des aiguilles.
  final ValueListenable<double> rotation;
  final Animation<double> lights;

  /// 1 quand le pointeur vient de passer une case, puis retombe à 0.
  final ValueListenable<double>? flap;
  final bool chasing;

  static const _rim = 0.085;

  @override
  Widget build(BuildContext context) {
    final inset = size * _rim;
    final pointerW = size * 0.11;

    return SizedBox(
      width: size,
      height: size + pointerW * 0.35,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: pointerW * 0.35,
            left: 0,
            width: size,
            height: size,
            child: Stack(
              fit: StackFit.expand,
              children: [
                RepaintBoundary(
                  child: CustomPaint(
                    painter: WheelRimPainter(
                      lights: lights,
                      chasing: chasing,
                      thickness: _rim,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(inset),
                  child: ValueListenableBuilder<double>(
                    valueListenable: rotation,
                    builder: (context, angle, child) =>
                        Transform.rotate(angle: angle, child: child),
                    child: RepaintBoundary(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CustomPaint(
                            painter: WheelFacePainter(
                              slices: slices,
                              pointsUnit: pointsUnit,
                            ),
                          ),
                          _SliceIcons(
                              slices: slices, diameter: size - 2 * inset),
                        ],
                      ),
                    ),
                  ),
                ),
                Center(child: _Hub(size: size * 0.24)),
              ],
            ),
          ),
          // Le pointeur, à cheval sur la couronne.
          Positioned(
            top: 0,
            left: (size - pointerW) / 2,
            width: pointerW,
            height: pointerW * 1.35,
            child: _Pointer(flap: flap),
          ),
        ],
      ),
    );
  }
}

class _Hub extends StatelessWidget {
  const _Hub({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [AppColors.premiumSurfaceRaised, AppColors.premiumSurface],
        ),
        border: Border.all(color: WheelPalette.gold, width: size * 0.06),
        // Un halo d'or : le moyeu accroche la lumière comme la couronne.
        boxShadow: [
          BoxShadow(
            color: WheelPalette.gold.withValues(alpha: 0.35),
            blurRadius: size * 0.18,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: AppLogo(variant: AppLogoVariant.mark, width: size * 0.56),
    );
  }
}

/// Les icônes des cases sans chiffre, à la place qu'aurait leur libellé et
/// tournées comme lui.
class _SliceIcons extends StatelessWidget {
  const _SliceIcons({required this.slices, required this.diameter});

  final List<WheelSlice> slices;
  final double diameter;

  @override
  Widget build(BuildContext context) {
    final r = diameter / 2;
    final sweep = WheelGeometry.sweep(slices.length);

    return Stack(
      children: [
        for (var i = 0; i < slices.length; i++)
          if (slices[i].type != WheelOutcome.points)
            _icon(i, r, sweep, slices[i].type),
      ],
    );
  }

  Widget _icon(int i, double r, double sweep, WheelOutcome type) {
    final mid = -math.pi / 2 + (i + 0.5) * sweep;
    final reward = type == WheelOutcome.reward;
    final box = r * 0.2;
    final at =
        Offset(r + math.cos(mid) * r * 0.70, r + math.sin(mid) * r * 0.70);

    return Positioned(
      left: at.dx - box / 2,
      top: at.dy - box / 2,
      width: box,
      height: box,
      child: Transform.rotate(
        angle: mid + math.pi / 2,
        child: Icon(
          reward ? Icons.card_giftcard_rounded : Icons.refresh_rounded,
          size: r * (reward ? 0.17 : 0.15),
          color: reward ? AppColors.premiumSurface : WheelPalette.inkOnRetry,
        ),
      ),
    );
  }
}

/// Le pointeur bascule un instant à chaque case qu'il franchit, comme la
/// languette d'une vraie roue.
class _Pointer extends StatelessWidget {
  const _Pointer({this.flap});

  final ValueListenable<double>? flap;

  @override
  Widget build(BuildContext context) {
    const pointer = CustomPaint(painter: WheelPointerPainter());
    final f = flap;
    if (f == null) return pointer;
    return ValueListenableBuilder<double>(
      valueListenable: f,
      builder: (context, v, child) => Transform.rotate(
        alignment: Alignment.topCenter,
        // La roue tourne dans le sens des aiguilles : la languette part
        // dans l'autre.
        angle: -v * math.pi / 14,
        child: child,
      ),
      child: pointer,
    );
  }
}

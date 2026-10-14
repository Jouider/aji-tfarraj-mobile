import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';
import 'package:aji_tfarraj/features/wheel/domain/wheel.dart';

/// Les couleurs de la roue : celles de la charte, posées sur le noir chaud des
/// cartes premium. Une roue de plateau télé, pas une roue de casino.
abstract final class WheelPalette {
  /// Cases à points, en alternance : l'orange (encre blanche) et l'or (encre
  /// noire). Chacune garde l'encre qui y tient.
  static const pointsA = AppColors.primaryAction;
  static const pointsB = AppColors.secondary;
  static const inkOnA = Colors.white;
  static const inkOnB = AppColors.premiumSurface;

  /// « Réessaie » : le noir de la scène, qui laisse briller les autres.
  static const retry = AppColors.premiumSurfaceRaised;
  static const inkOnRetry = Color(0xD9FFFFFF);

  static const goldDeep = AppColors.secondaryDark;
  static const gold = AppColors.secondary;
  static const goldLight = Color(0xFFFFE3A3);
}

/// Les angles de la roue.
///
/// La case 0 commence en haut, sous le pointeur, et les suivantes défilent
/// dans le sens des aiguilles d'une montre. La roue tourne dans ce même sens.
abstract final class WheelGeometry {
  static double sweep(int count) => 2 * math.pi / count;

  /// La case sous le pointeur quand la roue a tourné de [rotation].
  static int sliceUnderPointer(double rotation, int count) {
    final a = (-rotation) % (2 * math.pi);
    return (a / sweep(count)).floor() % count;
  }

  /// La rotation (modulo un tour) qui place le point [offset] de la case
  /// [index] sous le pointeur ; 0,5 en est le milieu.
  static double rotationFor(int index, int count, {double offset = 0.5}) =>
      (-(index + offset) * sweep(count)) % (2 * math.pi);
}

/// Le disque des cases. Il ne change pas pendant que la roue tourne : il est
/// peint une fois, et c'est la couche qui pivote.
///
/// Il écrit les chiffres ; les icônes (« Réessaie », le gros lot) sont des
/// widgets posés par-dessus, dans la même couche.
class WheelFacePainter extends CustomPainter {
  WheelFacePainter({
    required this.slices,
    required this.pointsUnit,
    this.showLabels = true,
  });

  final List<WheelSlice> slices;
  final String pointsUnit;
  final bool showLabels;

  @override
  void paint(Canvas canvas, Size size) {
    if (slices.isEmpty) return;
    final r = size.shortestSide / 2;
    final c = size.center(Offset.zero);
    final rect = Rect.fromCircle(center: c, radius: r);
    final sweep = WheelGeometry.sweep(slices.length);

    var pointsSeen = 0;
    for (var i = 0; i < slices.length; i++) {
      final s = slices[i];
      final start = -math.pi / 2 + i * sweep;
      final Color ink;
      final Paint fill = Paint()..isAntiAlias = true;

      switch (s.type) {
        case WheelOutcome.points:
          final a = pointsSeen.isEven;
          pointsSeen++;
          final base = a ? WheelPalette.pointsA : WheelPalette.pointsB;
          fill.shader = RadialGradient(
            colors: [Color.lerp(base, Colors.black, 0.18)!, base],
            stops: const [0.25, 1],
          ).createShader(rect);
          ink = a ? WheelPalette.inkOnA : WheelPalette.inkOnB;
        case WheelOutcome.retry:
          fill.shader = const RadialGradient(
            colors: [AppColors.premiumSurface, WheelPalette.retry],
            stops: [0.25, 1],
          ).createShader(rect);
          ink = WheelPalette.inkOnRetry;
        case WheelOutcome.reward:
          fill.shader = const RadialGradient(
            colors: [WheelPalette.gold, WheelPalette.goldLight],
            stops: [0.2, 1],
          ).createShader(rect);
          ink = AppColors.premiumSurface;
      }

      canvas.drawArc(rect, start, sweep, true, fill);

      if (showLabels) {
        _label(canvas, c, r, start + sweep / 2, s, ink);
      }
    }

    // Les filets entre les cases : un trait d'or fin, comme sur un plateau.
    final divider = Paint()
      ..color = WheelPalette.goldLight.withValues(alpha: 0.55)
      ..strokeWidth = math.max(1, r * 0.012);
    for (var i = 0; i < slices.length; i++) {
      final a = -math.pi / 2 + i * sweep;
      canvas.drawLine(
        c + Offset(math.cos(a), math.sin(a)) * r * 0.2,
        c + Offset(math.cos(a), math.sin(a)) * r,
        divider,
      );
    }

    // Un voile au centre : la roue a du relief, le moyeu s'y pose.
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [Colors.black.withValues(alpha: 0.35), Colors.transparent],
          stops: const [0.18, 0.5],
        ).createShader(rect),
    );
  }

  void _label(
      Canvas canvas, Offset c, double r, double mid, WheelSlice s, Color ink) {
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(mid + math.pi / 2);

    switch (s.type) {
      case WheelOutcome.points:
        final value = _text('${s.points}', r * 0.17, FontWeight.w800, ink);
        final unit = _text(pointsUnit, r * 0.075, FontWeight.w600,
            ink.withValues(alpha: 0.85));
        final y = -r * 0.70;
        value.paint(canvas, Offset(-value.width / 2, y - value.height / 2));
        unit.paint(
            canvas, Offset(-unit.width / 2, y + value.height / 2 - r * 0.02));
      case WheelOutcome.retry:
      case WheelOutcome.reward:
        // Des icônes : posées en widgets par LuckyWheelView, au-dessus.
        break;
    }
    canvas.restore();
  }

  /// Les chiffres dans la police des titres : ceux d'une affiche, pas d'un
  /// formulaire. Un `TextPainter` n'hérite d'aucun style ; sans celui-ci, il
  /// prendrait la police par défaut du moteur.
  TextPainter _text(String t, double size, FontWeight w, Color color) =>
      TextPainter(
        text: TextSpan(
          text: t,
          style: AppTypography.h1.copyWith(
            fontSize: size,
            fontWeight: w,
            color: color,
            height: 1,
            letterSpacing: 0,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

  @override
  bool shouldRepaint(WheelFacePainter old) =>
      old.slices != slices ||
      old.pointsUnit != pointsUnit ||
      old.showLabels != showLabels;
}

/// La couronne dorée et ses ampoules. Elle ne tourne pas : seules les
/// ampoules s'animent — elles clignotent au repos et courent pendant un tour.
class WheelRimPainter extends CustomPainter {
  WheelRimPainter({
    required this.lights,
    required this.chasing,
    this.bulbs = 16,
    this.thickness = 0.085,
  }) : super(repaint: lights);

  /// 0 → 1 chaque seconde.
  final Animation<double> lights;
  final bool chasing;
  final int bulbs;

  /// L'épaisseur de la couronne, en fraction du diamètre.
  final double thickness;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.shortestSide / 2;
    final c = size.center(Offset.zero);
    final w = size.shortestSide * thickness;
    final ringR = r - w / 2;

    // L'ombre portée sous la roue.
    canvas.drawCircle(
      c + Offset(0, r * 0.04),
      r,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.55)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.08),
    );

    // La couronne : un or qui accroche la lumière à deux endroits.
    canvas.drawCircle(
      c,
      ringR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w
        ..shader = const SweepGradient(
          colors: [
            WheelPalette.goldDeep,
            WheelPalette.goldLight,
            WheelPalette.gold,
            WheelPalette.goldDeep,
            WheelPalette.gold,
            WheelPalette.goldLight,
            WheelPalette.goldDeep,
          ],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    // Ses deux arêtes.
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1, r * 0.008)
      ..color = AppColors.premiumSurface.withValues(alpha: 0.6);
    canvas.drawCircle(c, r - edge.strokeWidth / 2, edge);
    canvas.drawCircle(c, r - w, edge);

    // Les ampoules.
    final step = (lights.value * (chasing ? 12 : 2)).floor();
    final bulbR = w * 0.24;
    for (var i = 0; i < bulbs; i++) {
      final a = -math.pi / 2 + i * 2 * math.pi / bulbs + math.pi / bulbs;
      final p = c + Offset(math.cos(a), math.sin(a)) * ringR;
      final on = chasing ? (i + step) % 4 == 0 : (i + step).isEven;
      if (on) {
        canvas.drawCircle(
          p,
          bulbR * 2.2,
          Paint()
            ..color = WheelPalette.goldLight.withValues(alpha: 0.55)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, bulbR),
        );
      }
      canvas.drawCircle(
        p,
        bulbR,
        Paint()
          ..color =
              on ? Colors.white : WheelPalette.goldDeep.withValues(alpha: 0.9),
      );
    }
  }

  @override
  bool shouldRepaint(WheelRimPainter old) =>
      old.chasing != chasing ||
      old.bulbs != bulbs ||
      old.thickness != thickness;
}

/// Le pointeur, en haut : une goutte blanche cerclée d'or, pointe en bas.
class WheelPointerPainter extends CustomPainter {
  const WheelPointerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w / 2, h)
      ..cubicTo(w * 0.18, h * 0.62, 0, h * 0.42, 0, w / 2)
      ..arcToPoint(Offset(w, w / 2), radius: Radius.circular(w / 2))
      ..cubicTo(w, h * 0.42, w * 0.82, h * 0.62, w / 2, h)
      ..close();

    canvas.drawShadow(path, Colors.black, 4, false);
    canvas.drawPath(path, Paint()..color = Colors.white);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.09
        ..color = WheelPalette.gold,
    );
    canvas.drawCircle(Offset(w / 2, w / 2), w * 0.17,
        Paint()..color = AppColors.primaryAction);
  }

  @override
  bool shouldRepaint(WheelPointerPainter old) => false;
}

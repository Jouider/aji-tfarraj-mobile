import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:aji_tfarraj/app/copywriting/wheel_copy.dart';
import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';
import 'package:aji_tfarraj/features/wheel/domain/wheel.dart';
import 'package:aji_tfarraj/features/wheel/presentation/wheel_painters.dart';

/// Ce que la personne choisit après un tour.
enum WheelResultAction { close, again, watchVideo, myRewards }

/// Le résultat, une fois la roue arrêtée.
Future<WheelResultAction?> showWheelResult(
  BuildContext context, {
  required SpinResult result,
  required WheelCopy copy,
  required bool arabic,
}) {
  return showDialog<WheelResultAction>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (dialogContext) =>
        WheelResultDialog(result: result, copy: copy, arabic: arabic),
  );
}

@visibleForTesting
class WheelResultDialog extends StatelessWidget {
  const WheelResultDialog({
    super.key,
    required this.result,
    required this.copy,
    required this.arabic,
  });

  final SpinResult result;
  final WheelCopy copy;
  final bool arabic;

  @override
  Widget build(BuildContext context) {
    final c = copy;
    final won = result.outcome != WheelOutcome.retry;
    final reward = result.reward;

    final (String title, String body) = switch (result.outcome) {
      WheelOutcome.points => (
          c.winTitle(result.points),
          c.winBody(result.pointsBalance)
        ),
      WheelOutcome.retry => (
          c.retryTitle,
          result.videoUnlocksSpin
              ? c.retryBodyVideo
              : c.retryBody(result.spinsLeft)
        ),
      WheelOutcome.reward => (c.jackpotTitle, c.jackpotBody),
    };

    void close(WheelResultAction a) => Navigator.pop(context, a);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl, AppSpacing.xxl, AppSpacing.xl, AppSpacing.lg),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.premiumSurfaceRaised,
                  AppColors.premiumSurface
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.premiumBorder),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ResultBadge(result: result, unit: c.pointsUnit),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTypography.h2.copyWith(color: Colors.white),
                ),
                if (reward != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    reward.titleFor(arabic: arabic),
                    textAlign: TextAlign.center,
                    style: AppTypography.h3.copyWith(color: WheelPalette.gold),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium
                      .copyWith(color: AppColors.inkOnPhotoMuted),
                ),
                const SizedBox(height: AppSpacing.xl),
                if (result.outcome == WheelOutcome.reward) ...[
                  _GradientButton(
                    label: c.myRewards,
                    onPressed: () => close(WheelResultAction.myRewards),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _QuietButton(
                    label: c.close,
                    onPressed: () => close(WheelResultAction.close),
                  ),
                ] else if (result.spinsLeft > 0 ||
                    result.videoUnlocksSpin) ...[
                  _GradientButton(
                    label: result.spinsLeft > 0 ? c.again : c.watchVideoShort,
                    onPressed: () => close(result.spinsLeft > 0
                        ? WheelResultAction.again
                        : WheelResultAction.watchVideo),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _QuietButton(
                    label: c.close,
                    onPressed: () => close(WheelResultAction.close),
                  ),
                ] else
                  _GradientButton(
                    label: c.close,
                    onPressed: () => close(WheelResultAction.close),
                  ),
              ],
            ),
          ),
          if (won)
            const Positioned.fill(
              child: IgnorePointer(child: ConfettiBurst()),
            ),
        ],
      ),
    );
  }
}

class _ResultBadge extends StatelessWidget {
  const _ResultBadge({required this.result, required this.unit});

  final SpinResult result;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final imageUrl = result.reward?.imageUrl;
    if (result.outcome == WheelOutcome.reward &&
        imageUrl != null &&
        imageUrl.isNotEmpty) {
      return Container(
        width: 112,
        height: 112,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: WheelPalette.gold, width: 2),
        ),
        clipBehavior: Clip.antiAlias,
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => const _GiftIcon(),
        ),
      );
    }

    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: result.outcome == WheelOutcome.retry
            ? null
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [WheelPalette.goldLight, WheelPalette.gold],
              ),
        color: result.outcome == WheelOutcome.retry
            ? Colors.white.withValues(alpha: 0.08)
            : null,
        border: Border.all(
          color: result.outcome == WheelOutcome.retry
              ? Colors.white.withValues(alpha: 0.2)
              : WheelPalette.goldDeep,
          width: 2,
        ),
      ),
      alignment: Alignment.center,
      child: switch (result.outcome) {
        WheelOutcome.points => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '+${result.points}',
                style: AppTypography.h1.copyWith(
                  color: AppColors.premiumSurface,
                  height: 1,
                ),
              ),
              Text(
                unit,
                style: AppTypography.labelSmall
                    .copyWith(color: AppColors.premiumSurface),
              ),
            ],
          ),
        WheelOutcome.retry =>
          const Icon(Icons.refresh_rounded, size: 44, color: Colors.white),
        WheelOutcome.reward => const _GiftIcon(),
      },
    );
  }
}

class _GiftIcon extends StatelessWidget {
  const _GiftIcon();

  @override
  Widget build(BuildContext context) => const Center(
        child: Icon(Icons.card_giftcard_rounded,
            size: 48, color: AppColors.premiumSurface),
      );
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.actionGradient,
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            onTap: onPressed,
            child: Center(
              child: Text(
                label,
                style: AppTypography.labelLarge.copyWith(color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuietButton extends StatelessWidget {
  const _QuietButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(foregroundColor: AppColors.inkOnPhotoMuted),
      child: Text(label),
    );
  }
}

/// Une pluie de confettis, une seule fois, quand on gagne.
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({super.key});

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _t = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );
  late final List<_Bit> _bits;

  @override
  void initState() {
    super.initState();
    final rnd = math.Random();
    const colors = [
      AppColors.primary,
      AppColors.secondary,
      WheelPalette.goldLight,
      Colors.white,
      AppColors.primaryAction,
    ];
    _bits = List.generate(
      42,
      (i) => _Bit(
        x: 0.35 + rnd.nextDouble() * 0.3,
        vx: (rnd.nextDouble() * 2 - 1) * 0.7,
        vy: -(0.5 + rnd.nextDouble() * 0.8),
        spin: (rnd.nextDouble() * 2 - 1) * 10,
        size: 5 + rnd.nextDouble() * 5,
        color: colors[i % colors.length],
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _t.value = 1;
    } else if (!_t.isAnimating && _t.value == 0) {
      _t.forward();
    }
  }

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _ConfettiPainter(_t, _bits));
}

class _Bit {
  const _Bit({
    required this.x,
    required this.vx,
    required this.vy,
    required this.spin,
    required this.size,
    required this.color,
  });

  final double x, vx, vy, spin, size;
  final Color color;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.t, this.bits) : super(repaint: t);

  final Animation<double> t;
  final List<_Bit> bits;

  @override
  void paint(Canvas canvas, Size size) {
    if (t.value == 0 || t.value == 1) return;
    final s = t.value * 1.8;
    final fade = t.value > 0.7 ? (1 - t.value) / 0.3 : 1.0;
    for (final b in bits) {
      final x = (b.x + b.vx * s) * size.width;
      final y = size.height * 0.12 + (b.vy * s + 0.9 * s * s) * size.height;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(b.spin * s);
      canvas.drawRect(
        Rect.fromCenter(
            center: Offset.zero, width: b.size, height: b.size * 0.55),
        Paint()..color = b.color.withValues(alpha: fade),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => false;
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';
import 'package:aji_tfarraj/app/localization/locale_provider.dart';

/// ConfirmationHero — layered circle icon + title + status badge.
/// FIX: Layered secondary circles, pulse animation on outer ring,
///      warningLight badge with border, secondary warningText colors.
class ConfirmationHero extends ConsumerStatefulWidget {
  const ConfirmationHero({super.key});

  @override
  ConsumerState<ConfirmationHero> createState() => _ConfirmationHeroState();
}

class _ConfirmationHeroState extends ConsumerState<ConfirmationHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    // FIX: Pulse animation — 0.97→1.03, repeat reverse, 1500ms
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    // FIX: warningText — secondaryDark (light) / secondaryLight (dark)
    final warningText = AppColors.getStatusForegroundColor('contacting');

    return Column(
      children: [
        // FIX: Layered circle illustration
        SizedBox(
          width: 120,
          height: 120,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer circle — secondary 10% opacity + pulse scale
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, __) => Transform.scale(
                  scale: _pulseAnim.value,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              // Middle circle — secondary 20% opacity
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.20),
                  shape: BoxShape.circle,
                ),
              ),
              // Center circle — secondary 100% + hourglass icon
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: AppColors.secondary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.hourglass_top_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ],
          ),
        ),

        // FIX: Title — textPrimary w800 24px, margin top 20
        const SizedBox(height: 20),
        Text(
          s.reservationResultTitle,
          style: AppTypography.h2.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 24,
          ),
          textAlign: TextAlign.center,
        ),

        // FIX: Status badge — warningLight bg, secondary 35% border, radius 20
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.warningLight,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: AppColors.secondary.withValues(alpha: 0.35)),
            boxShadow: [
              BoxShadow(
                color: AppColors.secondary.withValues(alpha: 0.12),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // FIX: Clock icon (not emoji) in warningText, size 16
              Icon(Icons.hourglass_empty_outlined,
                  color: warningText, size: 16),
              const SizedBox(width: 6),
              Text(
                s.reservationResultStatusBadge,
                style: TextStyle(
                  color: warningText,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

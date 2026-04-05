// FEATURE: Support Tickets - Confirmation Screen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';
import 'package:aji_tfarraj/app/localization/locale_provider.dart';
import 'package:aji_tfarraj/app/localization/strings.dart';
import 'package:aji_tfarraj/features/support/domain/support_ticket.dart';
import 'package:aji_tfarraj/features/support/presentation/screens/support_tickets_screen.dart';

/// Full-immersive confirmation — same sequential fade+slide pattern
/// as ReservationResultScreen.
class TicketConfirmationScreen extends ConsumerStatefulWidget {
  final SupportTicket ticket;

  const TicketConfirmationScreen({super.key, required this.ticket});

  @override
  ConsumerState<TicketConfirmationScreen> createState() =>
      _TicketConfirmationScreenState();
}

class _TicketConfirmationScreenState
    extends ConsumerState<TicketConfirmationScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  late final Animation<double> _heroOpacity;
  late final Animation<Offset> _heroSlide;
  late final Animation<double> _cardOpacity;
  late final Animation<Offset> _cardSlide;
  late final Animation<double> _stepsOpacity;
  late final Animation<Offset> _stepsSlide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _heroOpacity = _interval(0.00, 0.44);
    _heroSlide = _slideInterval(0.00, 0.44);
    _cardOpacity = _interval(0.39, 0.78);
    _cardSlide = _slideInterval(0.39, 0.78);
    _stepsOpacity = _interval(0.56, 1.00);
    _stepsSlide = _slideInterval(0.56, 1.00);
  }

  Animation<double> _interval(double begin, double end) => CurvedAnimation(
        parent: _ctrl,
        curve: Interval(begin, end, curve: Curves.easeOut),
      );

  Animation<Offset> _slideInterval(double begin, double end) =>
      Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(
        CurvedAnimation(
            parent: _ctrl,
            curve: Interval(begin, end, curve: Curves.easeOut)),
      );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final locale =
        ref.watch(localeProvider).languageCode == 'ar' ? 'ar' : 'fr_FR';

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            children: [
              const SizedBox(height: 40),

              _Animated(
                opacity: _heroOpacity,
                slide: _heroSlide,
                child: _ConfirmationHero(s: s),
              ),

              const SizedBox(height: 28),

              _Animated(
                opacity: _cardOpacity,
                slide: _cardSlide,
                child: _SummaryCard(ticket: widget.ticket, s: s, locale: locale),
              ),

              const SizedBox(height: 28),

              _Animated(
                opacity: _stepsOpacity,
                slide: _stepsSlide,
                child: _NextSteps(s: s),
              ),

              const SizedBox(height: 32),

              _Animated(
                opacity: _stepsOpacity,
                slide: _stepsSlide,
                child: _ActionButtons(
                  s: s,
                  onViewTickets: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                          builder: (_) => const SupportTicketsScreen()),
                      (route) => route.isFirst,
                    );
                  },
                  onHome: () =>
                      Navigator.of(context).popUntil((r) => r.isFirst),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Animated wrapper
// ─────────────────────────────────────────────

class _Animated extends StatelessWidget {
  final Animation<double> opacity;
  final Animation<Offset> slide;
  final Widget child;

  const _Animated(
      {required this.opacity, required this.slide, required this.child});

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: opacity,
        child: SlideTransition(position: slide, child: child),
      );
}

// ─────────────────────────────────────────────
// Confirmation Hero — layered primary circles + pulse
// ─────────────────────────────────────────────

class _ConfirmationHero extends StatefulWidget {
  final AppStrings s;

  const _ConfirmationHero({required this.s});

  @override
  State<_ConfirmationHero> createState() => _ConfirmationHeroState();
}

class _ConfirmationHeroState extends State<_ConfirmationHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
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
    final warningText = AppColors.getStatusForegroundColor('contacting');
    return Column(
      children: [
        SizedBox(
          width: 120,
          height: 120,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, __) => Transform.scale(
                  scale: _pulseAnim.value,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.20),
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.headset_mic,
                    color: Colors.white, size: 32),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          widget.s.supportConfirmationTitle,
          style: AppTypography.h2.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 24,
          ),
          textAlign: TextAlign.center,
        ),
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
              Icon(Icons.hourglass_empty_outlined,
                  color: warningText, size: 16),
              const SizedBox(width: 6),
              Text(
                widget.s.supportConfirmationBadge,
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

// ─────────────────────────────────────────────
// Summary Card
// ─────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final SupportTicket ticket;
  final AppStrings s;
  final String locale;

  const _SummaryCard(
      {required this.ticket, required this.s, required this.locale});

  @override
  Widget build(BuildContext context) {
    final dateStr =
        DateFormat('dd MMM yyyy', locale).format(ticket.createdAt.toLocal());

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.cardDarkElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SummaryRow(
            label: s.supportSummarySubject,
            value: ticket.subject,
            valueStyle: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          Divider(height: 1, color: AppColors.border),
          _SummaryRow(
            label: s.supportSummaryTicket,
            value: '#${ticket.id}',
            valueStyle: const TextStyle(
              color: AppColors.secondary,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          Divider(height: 1, color: AppColors.border),
          _SummaryRow(
            label: s.supportSummarySubmitted,
            value: dateStr,
            valueStyle: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? valueStyle;

  const _SummaryRow(
      {required this.label, required this.value, this.valueStyle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.textMuted,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: valueStyle ??
                  AppTypography.bodyMedium.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Next Steps Section
// ─────────────────────────────────────────────

class _NextSteps extends StatelessWidget {
  final AppStrings s;

  const _NextSteps({required this.s});

  @override
  Widget build(BuildContext context) {
    final steps = [s.supportStep1, s.supportStep2, s.supportStep3];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 3,
              height: 20,
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.info_outline,
                color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              s.supportStepsTitle,
              style: AppTypography.h4.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        ..._buildSteps(steps),
      ],
    );
  }

  List<Widget> _buildSteps(List<String> steps) {
    final widgets = <Widget>[];
    for (int i = 0; i < steps.length; i++) {
      widgets.add(_StepRow(number: i + 1, text: steps[i]));
      if (i < steps.length - 1) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 29.5),
            child:
                Container(width: 1, height: 20, color: AppColors.border),
          ),
        );
      }
    }
    return widgets;
  }
}

class _StepRow extends StatelessWidget {
  final int number;
  final String text;

  const _StepRow({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                '$number',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                text,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Action Buttons
// ─────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  final AppStrings s;
  final VoidCallback onViewTickets;
  final VoidCallback onHome;

  const _ActionButtons(
      {required this.s, required this.onViewTickets, required this.onHome});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.30),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: FilledButton.icon(
            onPressed: onViewTickets,
            icon: const Icon(Icons.headset_mic_outlined,
                size: 18, color: Colors.white),
            label: Text(
              s.supportBtnViewTickets,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              padding: EdgeInsets.zero,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: OutlinedButton.icon(
            onPressed: onHome,
            icon: Icon(Icons.home_outlined,
                size: 18, color: AppColors.primary),
            label: Text(
              s.supportBtnBackHome,
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ],
    );
  }
}

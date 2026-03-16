import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';
import 'package:aji_tfarraj/app/localization/locale_provider.dart';
import 'package:aji_tfarraj/features/auth/data/auth_repository.dart';
import 'package:aji_tfarraj/features/staff/data/staff_repository.dart';
import 'package:aji_tfarraj/features/staff/domain/staff_check_in_result.dart';

class StaffCheckInScreen extends ConsumerStatefulWidget {
  const StaffCheckInScreen({super.key});

  @override
  ConsumerState<StaffCheckInScreen> createState() => _StaffCheckInScreenState();
}

class _StaffCheckInScreenState extends ConsumerState<StaffCheckInScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _manualCodeController = TextEditingController();
  final _manualCodeFocus = FocusNode();
  final _scannerController = MobileScannerController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      // Reset state when switching tabs so errors/results don't persist
      if (!_tabController.indexIsChanging) {
        ref.read(staffCheckInProvider.notifier).reset();
        _manualCodeController.clear();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _manualCodeController.dispose();
    _manualCodeFocus.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final user = ref.watch(loginAuthStateProvider).user;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.staffCheckInTitle, style: AppTypography.h3),
        bottom: user != null && user.isStaffOrAdmin
            ? TabBar(
                controller: _tabController,
                tabs: [
                  Tab(icon: const Icon(Icons.qr_code_scanner), text: s.staffTabScanQr),
                  Tab(icon: const Icon(Icons.keyboard), text: s.staffTabManualCode),
                ],
              )
            : null,
      ),
      body: user == null || !user.isStaffOrAdmin
          ? _ForbiddenView(message: s.staffAccessDenied, subtitle: s.staffAccessDeniedSubtitle)
          : TabBarView(
              controller: _tabController,
              children: [
                _QrScanTab(
                  scannerController: _scannerController,
                  tabController: _tabController,
                ),
                _ManualCodeTab(
                  codeController: _manualCodeController,
                  focusNode: _manualCodeFocus,
                ),
              ],
            ),
    );
  }
}

// ─── Forbidden view ──────────────────────────────────────────────────────────

class _ForbiddenView extends StatelessWidget {
  final String message;
  final String subtitle;

  const _ForbiddenView({required this.message, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 64, color: AppColors.error),
            const SizedBox(height: AppSpacing.lg),
            Text(message,
                style: AppTypography.h3.copyWith(color: AppColors.error),
                textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.sm),
            Text(subtitle,
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.textMuted),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ─── QR scan tab ─────────────────────────────────────────────────────────────

class _QrScanTab extends ConsumerStatefulWidget {
  final MobileScannerController scannerController;
  final TabController tabController;

  const _QrScanTab({
    required this.scannerController,
    required this.tabController,
  });

  @override
  ConsumerState<_QrScanTab> createState() => _QrScanTabState();
}

class _QrScanTabState extends ConsumerState<_QrScanTab> {
  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final checkInState = ref.watch(staffCheckInProvider);

    // Show result/error overlay when not idle
    if (checkInState.status == StaffCheckInStatus.success) {
      return _CheckInResultCard(
        result: checkInState.result!,
        onScanAnother: () => ref.read(staffCheckInProvider.notifier).reset(),
      );
    }

    if (checkInState.status == StaffCheckInStatus.error) {
      return _ErrorCard(
        message: checkInState.errorMessage ?? s.staffNetworkError,
        alreadyCheckedInAt: checkInState.alreadyCheckedInAt,
        onRetry: () => ref.read(staffCheckInProvider.notifier).reset(),
      );
    }

    return Stack(
      children: [
        // Camera preview
        MobileScanner(
          controller: widget.scannerController,
          onDetect: (capture) {
            if (checkInState.status != StaffCheckInStatus.idle) return;
            final barcode = capture.barcodes.firstOrNull;
            final value = barcode?.rawValue;
            if (value == null || value.isEmpty) return;
            ref.read(staffCheckInProvider.notifier).checkIn(qrToken: value);
          },
        ),

        // Viewfinder overlay
        CustomPaint(
          painter: _ViewfinderPainter(),
          child: const SizedBox.expand(),
        ),

        // Loading overlay
        if (checkInState.status == StaffCheckInStatus.loading)
          Container(
            color: Colors.black54,
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),

        // Instruction text at bottom
        Positioned(
          bottom: AppSpacing.xxl,
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Text(
              s.staffScanInstruction,
              style: AppTypography.bodyMedium.copyWith(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}

/// Simple viewfinder square drawn over the camera preview
class _ViewfinderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final dimPaint = Paint()..color = Colors.black.withValues(alpha: 0.5);
    final squareSize = size.width * 0.65;
    final left = (size.width - squareSize) / 2;
    final top = (size.height - squareSize) / 2 - 40;
    final rect = Rect.fromLTWH(left, top, squareSize, squareSize);

    // Dim the area outside the square
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(12)))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, dimPaint);

    // Corner brackets
    final bracketPaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const len = 24.0;
    final r = rect;
    // Top-left
    canvas.drawLine(Offset(r.left, r.top + len), Offset(r.left, r.top), bracketPaint);
    canvas.drawLine(Offset(r.left, r.top), Offset(r.left + len, r.top), bracketPaint);
    // Top-right
    canvas.drawLine(Offset(r.right - len, r.top), Offset(r.right, r.top), bracketPaint);
    canvas.drawLine(Offset(r.right, r.top), Offset(r.right, r.top + len), bracketPaint);
    // Bottom-left
    canvas.drawLine(Offset(r.left, r.bottom - len), Offset(r.left, r.bottom), bracketPaint);
    canvas.drawLine(Offset(r.left, r.bottom), Offset(r.left + len, r.bottom), bracketPaint);
    // Bottom-right
    canvas.drawLine(Offset(r.right - len, r.bottom), Offset(r.right, r.bottom), bracketPaint);
    canvas.drawLine(Offset(r.right, r.bottom), Offset(r.right, r.bottom - len), bracketPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Manual code tab ─────────────────────────────────────────────────────────

class _ManualCodeTab extends ConsumerWidget {
  final TextEditingController codeController;
  final FocusNode focusNode;

  const _ManualCodeTab({required this.codeController, required this.focusNode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final checkInState = ref.watch(staffCheckInProvider);
    final notifier = ref.read(staffCheckInProvider.notifier);

    if (checkInState.status == StaffCheckInStatus.success) {
      return _CheckInResultCard(
        result: checkInState.result!,
        onScanAnother: () {
          notifier.reset();
          codeController.clear();
        },
      );
    }

    if (checkInState.status == StaffCheckInStatus.error) {
      return _ErrorCard(
        message: checkInState.errorMessage ?? s.staffNetworkError,
        alreadyCheckedInAt: checkInState.alreadyCheckedInAt,
        onRetry: () {
          notifier.reset();
          codeController.clear();
        },
      );
    }

    final isLoading = checkInState.status == StaffCheckInStatus.loading;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.xl),
          const Icon(Icons.confirmation_number_outlined,
              size: 64, color: AppColors.textMuted),
          const SizedBox(height: AppSpacing.xl),
          TextField(
            controller: codeController,
            focusNode: focusNode,
            enabled: !isLoading,
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.done,
            style: AppTypography.bodyLarge,
            decoration: InputDecoration(
              hintText: s.staffManualPlaceholder,
              hintStyle: AppTypography.bodyLarge
                  .copyWith(color: AppColors.textMuted),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              prefixIcon: const Icon(Icons.tag),
            ),
            onSubmitted: (_) => _submit(ref, s),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: AppSpacing.buttonHeight,
            child: ElevatedButton(
              onPressed: isLoading ? null : () => _submit(ref, s),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(s.staffValidateButton,
                      style: AppTypography.labelLarge
                          .copyWith(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  void _submit(WidgetRef ref, dynamic s) {
    final code = codeController.text.trim();
    if (code.isEmpty) return;
    ref.read(staffCheckInProvider.notifier).checkIn(ticketCode: code);
  }
}

// ─── Success result card ──────────────────────────────────────────────────────

class _CheckInResultCard extends ConsumerWidget {
  final StaffCheckInResult result;
  final VoidCallback onScanAnother;

  const _CheckInResultCard({
    required this.result,
    required this.onScanAnother,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    // Haptic feedback on mount
    HapticFeedback.lightImpact();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.xl),

          // Success icon
          Container(
            width: 80,
            height: 80,
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
            decoration: const BoxDecoration(
              color: AppColors.successLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded,
                size: 48, color: AppColors.success),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Title
          Text(
            s.staffSuccessTitle,
            style: AppTypography.h2.copyWith(color: AppColors.success),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xxl),

          // Details card
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.successLight.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ResultRow(
                  icon: Icons.confirmation_number_outlined,
                  label: s.staffTicketCodeLabel,
                  value: result.ticketCode,
                  valueBold: true,
                ),
                const Divider(color: AppColors.border, height: AppSpacing.xl),
                _ResultRow(
                  icon: Icons.access_time_rounded,
                  label: s.staffCheckedInAt,
                  value: dateFormat.format(result.checkedInAt),
                ),
                const Divider(color: AppColors.border, height: AppSpacing.xl),
                _ResultRow(
                  icon: Icons.person_outline,
                  label: s.staffAttendeeName,
                  value: result.userName,
                  subtitle: result.userEmail,
                ),
                const Divider(color: AppColors.border, height: AppSpacing.xl),
                _ResultRow(
                  icon: Icons.tv_outlined,
                  label: s.staffShowLabel,
                  value: result.showTitle,
                  subtitle:
                      '${result.showCity} · ${dateFormat.format(result.showStartsAt)}',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          // Actions
          SizedBox(
            height: AppSpacing.buttonHeight,
            child: ElevatedButton.icon(
              onPressed: onScanAnother,
              icon: const Icon(Icons.qr_code_scanner, size: 20),
              label: Text(s.staffScanAnother),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: AppSpacing.buttonHeight,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
              child: Text(s.staffBack),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Error card ───────────────────────────────────────────────────────────────

class _ErrorCard extends ConsumerWidget {
  final String message;
  final DateTime? alreadyCheckedInAt;
  final VoidCallback onRetry;

  const _ErrorCard({
    required this.message,
    required this.onRetry,
    this.alreadyCheckedInAt,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.xl),

          // Error icon
          Container(
            width: 80,
            height: 80,
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
            decoration: const BoxDecoration(
              color: AppColors.errorLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.close_rounded,
                size: 48, color: AppColors.error),
          ),
          const SizedBox(height: AppSpacing.lg),

          Text(
            message,
            style: AppTypography.h3.copyWith(color: AppColors.error),
            textAlign: TextAlign.center,
          ),

          if (alreadyCheckedInAt != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${s.staffCheckedInAt}: ${dateFormat.format(alreadyCheckedInAt!)}',
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],

          const SizedBox(height: AppSpacing.xxl),

          SizedBox(
            height: AppSpacing.buttonHeight,
            child: ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
              child: Text(s.staffRetry),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: AppSpacing.buttonHeight,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
              child: Text(s.staffBack),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Result row helper ────────────────────────────────────────────────────────

class _ResultRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? subtitle;
  final bool valueBold;

  const _ResultRow({
    required this.icon,
    required this.label,
    required this.value,
    this.subtitle,
    this.valueBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: AppSpacing.iconMd, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: AppTypography.labelSmall
                      .copyWith(color: AppColors.textMuted)),
              const SizedBox(height: 2),
              Text(
                value,
                style: valueBold
                    ? AppTypography.bodyMedium
                        .copyWith(fontWeight: AppTypography.semiBold)
                    : AppTypography.bodyMedium,
              ),
              if (subtitle != null)
                Text(subtitle!,
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.textMuted)),
            ],
          ),
        ),
      ],
    );
  }
}

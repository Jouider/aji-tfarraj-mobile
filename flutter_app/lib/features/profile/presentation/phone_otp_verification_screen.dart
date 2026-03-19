import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';
import 'package:aji_tfarraj/app/localization/locale_provider.dart';
import 'package:aji_tfarraj/features/profile/presentation/phone_otp_controller.dart';


class PhoneOtpVerificationScreen extends ConsumerStatefulWidget {
  const PhoneOtpVerificationScreen({
    super.key,
    required this.countryCode,
    required this.phoneNumber,
  });

  final String countryCode;
  final String phoneNumber;

  @override
  ConsumerState<PhoneOtpVerificationScreen> createState() =>
      _PhoneOtpVerificationScreenState();
}

class _PhoneOtpVerificationScreenState
    extends ConsumerState<PhoneOtpVerificationScreen> {
  final _codeController = TextEditingController();
  final _focusNode = FocusNode();

  (String, String) get _providerKey =>
      (widget.countryCode, widget.phoneNumber);

  @override
  void dispose() {
    _codeController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final code = _codeController.text.trim();
    if (code.length < 6) return;
    final ok = await ref
        .read(phoneOtpControllerProvider(_providerKey).notifier)
        .verifyOtp(code);
    if (ok && mounted) {
      final s = ref.read(stringsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.otpVerifiedSuccess),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop(true);
    }
  }

  Future<void> _resend() async {
    await ref
        .read(phoneOtpControllerProvider(_providerKey).notifier)
        .requestOtp();
    if (mounted) {
      final state =
          ref.read(phoneOtpControllerProvider(_providerKey));
      if (state.errorMessage == null) {
        final s = ref.read(stringsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.otpSentSuccess),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final state = ref.watch(phoneOtpControllerProvider(_providerKey));
    final maskedPhone = '${widget.countryCode} ${widget.phoneNumber}';

    return Scaffold(
      appBar: AppBar(
        title: Text(s.otpScreenTitle, style: AppTypography.h3),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: AppSpacing.xxl),

            // ── Icon ──
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.phone_android_outlined,
                size: AppSpacing.iconXxl,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // ── Title ──
            Text(
              s.otpScreenTitle,
              style: AppTypography.h2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),

            // ── Subtitle ──
            Text(
              s.otpScreenSubtitle(maskedPhone),
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxl),

            // ── OTP input ──
            TextFormField(
              controller: _codeController,
              focusNode: _focusNode,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: 6,
              textAlign: TextAlign.center,
              style: AppTypography.h2.copyWith(letterSpacing: 8),
              enabled: !state.isVerifying,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: s.otpCodeHint,
                counterText: '',
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusMd),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusMd),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusMd),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // ── Error banner ──
            if (state.errorMessage != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppColors.error, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        state.errorMessage!,
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            const SizedBox(height: AppSpacing.lg),

            // ── Verify button ──
            SizedBox(
              width: double.infinity,
              height: AppSpacing.buttonHeight,
              child: ElevatedButton(
                onPressed: (state.isVerifying ||
                        _codeController.text.length < 6)
                    ? null
                    : _verify,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      AppColors.primary.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                ),
                child: state.isVerifying
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(s.otpVerifyButton,
                        style: AppTypography.labelLarge),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── Resend section ──
            if (state.resendSecondsLeft > 0)
              Text(
                s.otpResendCountdown(state.resendSecondsLeft),
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textMuted),
              )
            else
              state.isRequesting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.primary),
                    )
                  : TextButton(
                      onPressed: _resend,
                      child: Text(
                        s.otpResendButton,
                        style: AppTypography.labelMedium
                            .copyWith(color: AppColors.primary),
                      ),
                    ),
          ],
        ),
      ),
    );
  }
}

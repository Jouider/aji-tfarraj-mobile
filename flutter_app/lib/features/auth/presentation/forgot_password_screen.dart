import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:aji_tfarraj/app/routes.dart';
import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';
import 'package:aji_tfarraj/app/localization/locale_provider.dart';
import 'package:aji_tfarraj/app/localization/strings.dart';
import 'package:aji_tfarraj/features/auth/data/auth_repository.dart';

/// Forgot Password Screen — requests a reset link via POST /api/auth/forgot-password.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.forgotPasswordTitle, style: AppTypography.h3),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go(Routes.login),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: _emailSent ? _buildSuccess(s) : _buildForm(s),
        ),
      ),
    );
  }

  // ── Success state ──────────────────────────────────────────────────────────

  Widget _buildSuccess(AppStrings s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.xxxl),
        const Center(
          child: Icon(
            Icons.mark_email_read_outlined,
            size: 72,
            color: AppColors.success,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          s.forgotPasswordSuccess,
          textAlign: TextAlign.center,
          style: AppTypography.h3,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          s.forgotPasswordSuccessMessage,
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium
              .copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: AppSpacing.xxxl),
        SizedBox(
          height: AppSpacing.buttonHeight,
          child: FilledButton(
            onPressed: () => context.canPop()
                ? context.pop()
                : context.go(Routes.login),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: AppColors.backgroundWhite,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
            ),
            child: Text(s.backToLogin,
                style: AppTypography.labelLarge
                    .copyWith(fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  // ── Form state ─────────────────────────────────────────────────────────────

  Widget _buildForm(AppStrings s) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.lg),
          Text(
            s.forgotPasswordSubtitle,
            style: AppTypography.bodyMedium
                .copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.xxl),

          // ── Error banner ──
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
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
                      _errorMessage!,
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],

          // ── Email field ──
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            enabled: !_isLoading,
            decoration: InputDecoration(
              labelText: s.emailLabel,
              hintText: s.emailHint,
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return s.emailRequired;
              if (!v.contains('@')) return s.emailInvalid;
              return null;
            },
            onFieldSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: AppSpacing.xl),

          // ── Submit button ──
          SizedBox(
            height: AppSpacing.buttonHeight,
            child: FilledButton(
              onPressed: _isLoading ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: AppColors.backgroundWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.backgroundWhite,
                      ),
                    )
                  : Text(
                      s.forgotPasswordButton,
                      style: AppTypography.labelLarge
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Back to login ──
          Center(
            child: TextButton(
              onPressed: _isLoading
                  ? null
                  : () => context.canPop()
                      ? context.pop()
                      : context.go(Routes.login),
              style:
                  TextButton.styleFrom(foregroundColor: AppColors.secondary),
              child: Text(s.backToLogin,
                  style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final dio = ref.read(authDioProvider);
      await dio.post(
        '/api/auth/forgot-password',
        data: {'email': _emailController.text.trim()},
      );
      if (mounted) setState(() => _emailSent = true);
    } on DioException catch (e) {
      final data = e.response?.data;
      String msg = 'Une erreur est survenue. Veuillez réessayer.';
      if (data is Map) msg = data['message'] as String? ?? msg;
      if (mounted) setState(() => _errorMessage = msg);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

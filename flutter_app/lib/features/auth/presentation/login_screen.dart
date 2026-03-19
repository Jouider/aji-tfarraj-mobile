import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:aji_tfarraj/app/routes.dart';
import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';
import 'package:aji_tfarraj/app/localization/app_locale.dart';
import 'package:aji_tfarraj/app/localization/locale_provider.dart';
import 'package:aji_tfarraj/features/auth/data/auth_repository.dart';

/// Login Screen
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _loadingProvider;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(loginAuthStateProvider);
    final s = ref.watch(stringsProvider);
    final locale = ref.watch(localeProvider);
    final logo = locale == AppLocale.ar
        ? 'assets/images/ajitfarraj_logo/white_ar_logo.png'
        : 'assets/images/ajitfarraj_logo/white_fr_logo.png';

    final isAnyLoading = authState.isLoading || _loadingProvider != null;

    ref.listen<AuthState>(loginAuthStateProvider, (_, next) {
      if (next.isAuthenticated) context.go(Routes.home);
    });

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.xxxl),

                // Logo
                Center(child: Image.asset(logo, width: 160)),
                const SizedBox(height: AppSpacing.lg),

                Text(
                  s.loginSubtitle,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxl),

                // Error banner
                if (authState.errorMessage != null) ...[
                  _ErrorBanner(message: authState.errorMessage!),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // ── Google ──
                _SocialButton(
                  label: s.continueWithGoogle,
                  icon: const _GoogleIcon(),
                  isLoading: _loadingProvider == 'google',
                  isDisabled: isAnyLoading,
                  onPressed: _handleGoogle,
                ),
                const SizedBox(height: AppSpacing.sm),

                // ── Apple (iOS only) ──
                if (Platform.isIOS) ...[
                  _SocialButton(
                    label: s.continueWithApple,
                    icon: const Icon(Icons.apple, size: 20, color: Colors.white),
                    isLoading: _loadingProvider == 'apple',
                    isDisabled: isAnyLoading,
                    onPressed: _handleApple,
                    dark: true,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],

                // ── Divider ──
                const SizedBox(height: AppSpacing.md),
                _OrDivider(label: s.orDivider),
                const SizedBox(height: AppSpacing.md),

                // Email field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  enabled: !isAnyLoading,
                  decoration: InputDecoration(
                    labelText: s.emailLabel,
                    hintText: s.emailHint,
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return s.emailRequired;
                    if (!v.contains('@')) return s.emailInvalid;
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),

                // Password field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  enabled: !isAnyLoading,
                  decoration: InputDecoration(
                    labelText: s.passwordLabel,
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AppColors.textMuted,
                        size: AppSpacing.iconMd,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return s.passwordRequired;
                    return null;
                  },
                  onFieldSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: AppSpacing.sm),

                // Forgot password
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton(
                    onPressed: isAnyLoading
                        ? null
                        : () => context.push(Routes.forgotPassword),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.secondary,
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      s.forgotPassword,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.secondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Login button
                SizedBox(
                  height: AppSpacing.buttonHeight,
                  child: FilledButton(
                    onPressed: isAnyLoading ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: AppColors.backgroundWhite,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                    ),
                    child: authState.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            s.login,
                            style: AppTypography.labelLarge.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Register link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      s.noAccount,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                    TextButton(
                      onPressed: isAnyLoading
                          ? null
                          : () => context.go(Routes.authLanding),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.secondary,
                        padding: const EdgeInsets.only(left: AppSpacing.xs),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        s.registerLink,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    ref.read(loginAuthStateProvider.notifier).clearError();
    try {
      await ref.read(loginAuthStateProvider.notifier).login(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
    } catch (_) {}
  }

  Future<void> _handleGoogle() async {
    setState(() => _loadingProvider = 'google');
    ref.read(loginAuthStateProvider.notifier).clearError();
    try {
      await ref.read(loginAuthStateProvider.notifier).loginWithGoogle();
    } on DioException catch (_) {
      // Error message already set in authState.errorMessage by the notifier
    } catch (_) {
      // Silently ignore (e.g. user cancelled the popup)
    } finally {
      if (mounted) setState(() => _loadingProvider = null);
    }
  }

  Future<void> _handleApple() async {
    setState(() => _loadingProvider = 'apple');
    ref.read(loginAuthStateProvider.notifier).clearError();
    try {
      await ref.read(loginAuthStateProvider.notifier).loginWithApple();
    } on DioException catch (_) {
      // Error message already set in authState.errorMessage by the notifier
    } catch (_) {
      // Silently ignore (e.g. user cancelled)
    } finally {
      if (mounted) setState(() => _loadingProvider = null);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Social Auth Button
// ─────────────────────────────────────────────────────────────────────────────

class _SocialButton extends StatelessWidget {
  final String label;
  final Widget icon;
  final bool isLoading;
  final bool isDisabled;
  final VoidCallback onPressed;
  final bool dark;

  const _SocialButton({
    required this.label,
    required this.icon,
    required this.isLoading,
    required this.isDisabled,
    required this.onPressed,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = dark ? Colors.black : Colors.white;
    final fgColor = dark ? Colors.white : Colors.black87;
    final borderColor = dark ? Colors.black : AppColors.border;

    return SizedBox(
      height: AppSpacing.buttonHeight,
      child: OutlinedButton(
        onPressed: (isDisabled || isLoading) ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: isDisabled ? null : bgColor,
          foregroundColor: fgColor,
          side: BorderSide(color: borderColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: dark ? Colors.white : Colors.black87,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  icon,
                  const SizedBox(width: AppSpacing.sm),
                  Text(label,
                      style: AppTypography.labelLarge
                          .copyWith(color: fgColor, fontWeight: FontWeight.w500)),
                ],
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Google "G" Icon
// ─────────────────────────────────────────────────────────────────────────────

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 20,
      height: 20,
      child: Text(
        'G',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF4285F4), // Google blue
          height: 1.25,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// "ou" Divider
// ─────────────────────────────────────────────────────────────────────────────

class _OrDivider extends StatelessWidget {
  final String label;
  const _OrDivider({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            label,
            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.border)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error Banner
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: AppSpacing.iconMd),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySmall.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

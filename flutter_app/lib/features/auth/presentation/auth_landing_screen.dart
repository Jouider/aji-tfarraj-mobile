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
import 'package:aji_tfarraj/app/auth/token_storage.dart';
import 'package:aji_tfarraj/features/auth/data/auth_repository.dart';

/// Auth Landing Screen — entry point for unauthenticated users.
/// Offers Google, Apple (iOS only), and email auth options.
class AuthLandingScreen extends ConsumerStatefulWidget {
  const AuthLandingScreen({super.key});

  @override
  ConsumerState<AuthLandingScreen> createState() => _AuthLandingScreenState();
}

class _AuthLandingScreenState extends ConsumerState<AuthLandingScreen> {
  // Which social provider button is currently loading ('google' | 'apple')
  String? _loadingProvider;

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final locale = ref.watch(localeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final logo = locale == AppLocale.ar
        ? (isDark ? 'assets/images/ajitfarraj_logo/white_ar_logo.png' : 'assets/images/ajitfarraj_logo/black_ar_logo.png')
        : (isDark ? 'assets/images/ajitfarraj_logo/white_fr_logo.png' : 'assets/images/ajitfarraj_logo/black_fr_logo.png');

    // Navigate to home once authenticated
    ref.listen<AuthState>(loginAuthStateProvider, (_, next) {
      if (next.isAuthenticated) {
        // Clear session-expired flag on successful login
        ref.read(sessionExpiredProvider.notifier).state = false;
        context.go(Routes.home);
      }
    });

    final authState = ref.watch(loginAuthStateProvider);
    final sessionExpired = ref.watch(sessionExpiredProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.xxxl),

              // ── Logo ──
              Center(
                child: Image.asset(logo, width: 160),
              ),
              const SizedBox(height: AppSpacing.lg),

              // ── Title & subtitle ──
              Text(
                s.authLandingTitle,
                textAlign: TextAlign.center,
                style: AppTypography.h2,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                s.authLandingSubtitle,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: AppSpacing.xxxl),

              // ── Session expired banner ──
              if (sessionExpired) ...[
                _ErrorBanner(message: s.unauthorized),
                const SizedBox(height: AppSpacing.lg),
              ],

              // ── Error banner ──
              if (authState.errorMessage != null) ...[
                _ErrorBanner(message: authState.errorMessage!),
                const SizedBox(height: AppSpacing.lg),
              ],

              // ── Google ──
              _SocialButton(
                label: s.continueWithGoogle,
                icon: const _GoogleIcon(),
                isLoading: _loadingProvider == 'google',
                isDisabled: _loadingProvider != null,
                onPressed: _handleGoogle,
              ),
              const SizedBox(height: AppSpacing.sm),

              // ── Apple (iOS only) ──
              if (Platform.isIOS) ...[
                _SocialButton(
                  label: s.continueWithApple,
                  icon: const Icon(Icons.apple, size: 20, color: Colors.white),
                  isLoading: _loadingProvider == 'apple',
                  isDisabled: _loadingProvider != null,
                  onPressed: _handleApple,
                  dark: true,
                ),
                const SizedBox(height: AppSpacing.sm),
              ],

              // ── Divider ──
              const SizedBox(height: AppSpacing.md),
              _OrDivider(label: s.orDivider),
              const SizedBox(height: AppSpacing.md),

              // ── Email login ──
              SizedBox(
                height: AppSpacing.buttonHeight,
                child: FilledButton(
                  onPressed: _loadingProvider != null
                      ? null
                      : () => context.push(Routes.login),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: AppColors.backgroundWhite, // #0C0C0C — dark text on gold, intentional

                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                  child: Text(s.continueWithEmail,
                      style: AppTypography.labelLarge
                          .copyWith(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // ── Create account ──
              SizedBox(
                height: AppSpacing.buttonHeight,
                child: OutlinedButton(
                  onPressed: _loadingProvider != null
                      ? null
                      : () => context.push(Routes.register),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                  child: Text(s.createAccount,
                      style: AppTypography.labelLarge),
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),

              // ── Terms notice ──
              Text(
                s.termsNotice,
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleGoogle() async {
    setState(() => _loadingProvider = 'google');
    ref.read(loginAuthStateProvider.notifier).clearError();
    try {
      await ref.read(loginAuthStateProvider.notifier).loginWithGoogle();
    } on DioException catch (_) {
      // Error message already set in authState.errorMessage by the notifier
    } catch (e) {
      debugPrint('[Google] error: $e');
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
        Expanded(child: Divider(color: AppColors.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            label,
            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
          ),
        ),
        Expanded(child: Divider(color: AppColors.border)),
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
          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style:
                  AppTypography.bodySmall.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

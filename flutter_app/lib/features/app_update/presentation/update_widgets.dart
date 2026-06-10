import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';
import 'package:aji_tfarraj/app/localization/locale_provider.dart';

Future<void> _openStore(String? url) async {
  if (url == null || url.isEmpty) return;
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

/// Full-screen, non-dismissible blocker shown when the installed build is below
/// the backend `min_version`.
class ForceUpdateScreen extends ConsumerWidget {
  final String? storeUrl;
  const ForceUpdateScreen({super.key, this.storeUrl});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.backgroundWhite,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _UpdateIcon(color: AppColors.primary, size: 88, icon: 44),
                  const SizedBox(height: AppSpacing.xl),
                  Text(s.updateForcedTitle,
                      textAlign: TextAlign.center, style: AppTypography.h2),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    s.updateForcedMessage,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium
                        .copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  _UpdateButton(label: s.updateNow, onTap: () => _openStore(storeUrl)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Dismissible "update available" overlay (scrim + bottom card). Rendered inside
/// the app gate's Stack, so it needs no Navigator ancestor.
class UpdateAvailableOverlay extends ConsumerWidget {
  final String? storeUrl;
  final VoidCallback onLater;
  const UpdateAvailableOverlay({
    super.key,
    required this.storeUrl,
    required this.onLater,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    return Stack(
      children: [
        // Scrim — tap to dismiss
        Positioned.fill(
          child: GestureDetector(
            onTap: onLater,
            child: Container(color: Colors.black.withValues(alpha: 0.45)),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Material(
            color: AppColors.surfaceOverlay,
            shape: const RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg,
                    AppSpacing.xl, AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _UpdateIcon(
                        color: AppColors.secondary, size: 64, icon: 32),
                    const SizedBox(height: AppSpacing.lg),
                    Text(s.updateTitle,
                        textAlign: TextAlign.center, style: AppTypography.h3),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      s.updateMessage,
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium
                          .copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _UpdateButton(
                      label: s.updateNow,
                      onTap: () {
                        onLater();
                        _openStore(storeUrl);
                      },
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    TextButton(
                      onPressed: onLater,
                      child: Text(s.updateLater,
                          style: AppTypography.labelMedium
                              .copyWith(color: AppColors.textMuted)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _UpdateIcon extends StatelessWidget {
  final Color color;
  final double size;
  final double icon;
  const _UpdateIcon(
      {required this.color, required this.size, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.system_update_rounded, size: icon, color: color),
    );
  }
}

class _UpdateButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _UpdateButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(label,
            style: AppTypography.buttonLarge.copyWith(fontSize: 15)),
      ),
    );
  }
}

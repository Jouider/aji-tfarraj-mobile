import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:aji_tfarraj/app/routes.dart';
import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';
import 'package:aji_tfarraj/app/localization/app_locale.dart';
import 'package:aji_tfarraj/app/localization/locale_provider.dart';
import 'package:aji_tfarraj/app/localization/strings.dart';
import 'package:aji_tfarraj/app/theme/theme_mode_provider.dart';
import 'package:aji_tfarraj/features/auth/data/auth_repository.dart';
import 'package:aji_tfarraj/features/auth/domain/user.dart';
import 'package:aji_tfarraj/features/notifications/presentation/providers/notifications_provider.dart';
import 'package:aji_tfarraj/features/loyalty/data/loyalty_repository.dart';
import 'package:aji_tfarraj/features/support/presentation/screens/support_tickets_screen.dart';

// ─────────────────────────────────────────────
// Profile Screen
// ─────────────────────────────────────────────

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isLoggingOut = false;
  bool _isDeletingAccount = false;

  Future<bool> _showLogoutDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surfaceOverlay,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: Text('Se déconnecter ?', style: AppTypography.h3),
            content: Text(
              'Vous serez redirigé vers l\'écran de connexion.',
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
            ),
            actionsAlignment: MainAxisAlignment.end,
            actionsPadding:
                const EdgeInsets.fromLTRB(16, 0, 16, 16),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.backgroundGrey,
                  foregroundColor: AppColors.textPrimary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                ),
                child: Text('Annuler', style: AppTypography.labelMedium),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                ),
                child: Text(
                  'Confirmer',
                  style: AppTypography.labelMedium
                      .copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _handleLogout() async {
    final confirmed = await _showLogoutDialog();
    if (!confirmed || !mounted) return;
    setState(() => _isLoggingOut = true);
    try {
      await ref.read(loginAuthStateProvider.notifier).logout();
    } finally {
      if (mounted) setState(() => _isLoggingOut = false);
    }
  }

  Future<void> _handleDeleteAccount() async {
    // Step 1: initial warning dialog
    final proceed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surfaceOverlay,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                const Icon(Icons.warning_rounded,
                    color: AppColors.error, size: 22),
                const SizedBox(width: 8),
                Text('Supprimer le compte ?', style: AppTypography.h3),
              ],
            ),
            content: Text(
              'Toutes vos données seront définitivement supprimées : '
              'réservations, points de fidélité, historique. '
              'Cette action est irréversible.',
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
            ),
            actionsAlignment: MainAxisAlignment.end,
            actionsPadding:
                const EdgeInsets.fromLTRB(16, 0, 16, 16),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.backgroundGrey,
                  foregroundColor: AppColors.textPrimary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                ),
                child: Text('Annuler', style: AppTypography.labelMedium),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                ),
                child: Text(
                  'Continuer',
                  style: AppTypography.labelMedium
                      .copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (!proceed || !mounted) return;

    // Step 2: final confirmation dialog
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surfaceOverlay,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: Text('Confirmer la suppression',
                style: AppTypography.h3
                    .copyWith(color: AppColors.error)),
            content: Text(
              'Voulez-vous vraiment supprimer définitivement votre compte ?',
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
            ),
            actionsAlignment: MainAxisAlignment.end,
            actionsPadding:
                const EdgeInsets.fromLTRB(16, 0, 16, 16),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.backgroundGrey,
                  foregroundColor: AppColors.textPrimary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                ),
                child: Text('Annuler', style: AppTypography.labelMedium),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                ),
                child: Text(
                  'Supprimer définitivement',
                  style: AppTypography.labelMedium
                      .copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed || !mounted) return;

    setState(() => _isDeletingAccount = true);
    try {
      await ref.read(loginAuthStateProvider.notifier).deleteAccount();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la suppression. Réessayez.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDeletingAccount = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(loginAuthStateProvider);
    final user = authState.user;
    final unreadCount = ref.watch(unreadNotificationsCountProvider);
    final pointsAsync = ref.watch(myPointsProvider);
    final s = ref.watch(stringsProvider);
    final currentLocale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);

    final themeLabel = switch (themeMode) {
      ThemeMode.system => s.themeSystem,
      ThemeMode.light => s.themeLight,
      ThemeMode.dark => s.themeDark,
    };
    final themeIcon = switch (themeMode) {
      ThemeMode.system => Icons.brightness_auto,
      ThemeMode.light => Icons.light_mode,
      ThemeMode.dark => Icons.dark_mode,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(s.profileTitle, style: AppTypography.h3),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.xl),
        children: [
          // Incomplete profile warning
          if (user != null &&
              !user.profileComplete &&
              user.missingProfileFields
                  .any((f) => f != 'avatar' && f != 'avatar_url')) ...[
            _IncompleteProfileBanner(
              onTap: () => context.push(Routes.editProfile),
              s: s,
            ),
            const SizedBox(height: AppSpacing.xl),
          ],

          // Header: avatar + name + email
          _ProfileHeader(
            user: user,
            s: s,
            onEditTap: () => context.push(Routes.editProfile),
          ),
          const SizedBox(height: AppSpacing.xxl),

          // ── Préférences ──────────────────────────────
          _SettingsGroup(
            label: s.profileGroupPreferences,
            children: [
              _SettingsRow(
                icon: Icons.language,
                iconColor: AppColors.primary,
                title: s.profileLanguageLabel,
                subtitle: currentLocale == AppLocale.fr
                    ? s.profileLanguageValueFr
                    : s.profileLanguageValueAr,
                trailing: Icon(Icons.swap_horiz,
                    size: 18, color: AppColors.textMuted),
                showChevron: false,
                onTap: () =>
                    ref.read(localeProvider.notifier).toggleLocale(),
              ),
              _SettingsRow(
                icon: themeIcon,
                iconColor: AppColors.secondary,
                title: s.profileThemeLabel,
                subtitle: themeLabel,
                trailing: Icon(Icons.swap_horiz,
                    size: 18, color: AppColors.textMuted),
                showChevron: false,
                onTap: () =>
                    ref.read(themeModeProvider.notifier).toggleTheme(),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Compte ───────────────────────────────────
          _SettingsGroup(
            label: s.profileGroupAccount,
            children: [
              _SettingsRow(
                icon: Icons.star_outline,
                iconColor: AppColors.secondary,
                title: s.profileLoyaltyLabel,
                trailing: pointsAsync.when(
                  data: (summary) => _LoyaltyBadge(points: summary.balance),
                  loading: () => const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.secondary),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                onTap: () => context.push(Routes.loyalty),
              ),
              _SettingsRow(
                icon: Icons.people_outline,
                iconColor: AppColors.primary,
                title: s.referralProfileTileLabel,
                trailing: user?.referralCode != null
                    ? _ReferralCodeChip(
                        code: user!.referralCode!,
                        copiedLabel: s.referralCodeCopied,
                      )
                    : null,
                onTap: () => context.push(Routes.referralStats),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Paramètres ───────────────────────────────
          _SettingsGroup(
            label: s.profileGroupSettings,
            children: [
              _SettingsRow(
                icon: Icons.notifications_outlined,
                iconColor: AppColors.primary,
                title: s.profileNotificationsLabel,
                subtitle: unreadCount > 0
                    ? s.profileUnreadCount(unreadCount)
                    : null,
                trailing: unreadCount > 0
                    ? _UnreadBadge(count: unreadCount)
                    : null,
                onTap: () => context.push(Routes.notifications),
              ),
              if (user != null && user.isStaffOrAdmin)
                _SettingsRow(
                  icon: Icons.qr_code_scanner,
                  iconColor: AppColors.secondary,
                  title: s.staffCheckInLabel,
                  onTap: () => context.push(Routes.staffCheckIn),
                ),
              // FIX: Added support entry point
              _SettingsRow(
                icon: Icons.headset_mic_outlined,
                iconColor: AppColors.primary,
                title: s.supportProfileTitle,
                subtitle: s.supportProfileSubtitle,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const SupportTicketsScreen()),
                ),
              ),
              _SettingsRow(
                icon: Icons.gavel_outlined,
                iconColor: AppColors.textMuted,
                title: s.conditionsProfileTileLabel,
                onTap: () => context.push(Routes.rules),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),

          // Logout button
          _LogoutButton(
            isLoading: _isLoggingOut,
            onTap: _handleLogout,
            label: s.profileLogoutLabel,
          ),
          const SizedBox(height: AppSpacing.md),

          // Delete account button (required by Apple App Store guideline 5.1.1)
          _DeleteAccountButton(
            isLoading: _isDeletingAccount,
            onTap: _handleDeleteAccount,
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Incomplete Profile Banner
// ─────────────────────────────────────────────

class _IncompleteProfileBanner extends StatelessWidget {
  final VoidCallback onTap;
  final AppStrings s;

  const _IncompleteProfileBanner({required this.onTap, required this.s});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
            color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: AppColors.warning, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              s.profileIncompleteWarning,
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.warning),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              s.completeProfileButton,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.warning,
                fontWeight: AppTypography.semiBold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Profile Header — avatar ring + name + email
// ─────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final User? user;
  final AppStrings s;
  final VoidCallback onEditTap;

  const _ProfileHeader({
    required this.user,
    required this.s,
    required this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Avatar with gradient ring
        GestureDetector(
          onTap: onEditTap,
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              // Gradient ring (96px = 80 image + 3px ring + 2px gap × 2 sides)
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  // Gap: 2px on each side → 96 - (3+2)*2 = 86px
                  child: Container(
                    width: 86,
                    height: 86,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.backgroundWhite,
                    ),
                    child: ClipOval(
                      child: user?.avatarUrl != null
                          ? Image.network(
                              user!.avatarUrl!,
                              width: 86,
                              height: 86,
                              fit: BoxFit.cover,
                              // Bound decoded bitmap so a large avatar can't OOM.
                              cacheWidth: 258,
                              cacheHeight: 258,
                              loadingBuilder: (_, child, progress) =>
                                  progress == null ? child : _AvatarPlaceholder(),
                              errorBuilder: (_, __, ___) =>
                                  _AvatarPlaceholder(),
                            )
                          : _AvatarPlaceholder(),
                    ),
                  ),
                ),
              ),
              // Edit badge
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppColors.backgroundWhite, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondary.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.edit, size: 13, color: Colors.white),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        // Name
        Text(
          user?.displayName ?? s.unknownUser,
          style: AppTypography.h3.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        // Email
        if (user?.email != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            user!.email,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textMuted,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

class _AvatarPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.backgroundGrey,
      child: Icon(Icons.person, size: 40, color: AppColors.textMuted),
    );
  }
}

// ─────────────────────────────────────────────
// Settings Group — card with label + rows
// ─────────────────────────────────────────────

class _SettingsGroup extends StatelessWidget {
  final String label;
  final List<Widget> children;

  const _SettingsGroup({required this.label, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            label.toUpperCase(),
            style: AppTypography.caption.copyWith(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardDarkElevated,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: List.generate(
              children.length * 2 - 1,
              (i) => i.isOdd
                  ? Divider(
                      height: 1,
                      thickness: 1,
                      color: AppColors.border,
                      indent: 56,
                    )
                  : children[i ~/ 2],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Settings Row — single tappable item
// ─────────────────────────────────────────────

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool showChevron;
  final VoidCallback? onTap;

  const _SettingsRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.showChevron = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        child: Row(
          children: [
            // Icon container 36×36
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: AppSpacing.md),
            // Title + subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyMedium.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: AppSpacing.sm),
              trailing!,
            ],
            if (showChevron) ...[
              const SizedBox(width: AppSpacing.xs),
              Icon(Icons.chevron_right,
                  size: 18, color: AppColors.textMuted),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Loyalty Badge
// ─────────────────────────────────────────────

class _LoyaltyBadge extends StatelessWidget {
  final int points;

  const _LoyaltyBadge({required this.points});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppColors.secondary.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, size: 13, color: AppColors.secondaryDark),
          const SizedBox(width: 4),
          Text(
            '$points pts',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.secondaryDark,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Referral Code Chip
// ─────────────────────────────────────────────

class _ReferralCodeChip extends StatelessWidget {
  final String code;
  final String copiedLabel;

  const _ReferralCodeChip({
    required this.code,
    required this.copiedLabel,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: code));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(copiedLabel),
            duration: const Duration(seconds: 2),
            backgroundColor: AppColors.primary,
          ),
        );
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            code,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.secondary,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.copy, size: 14, color: AppColors.secondary),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Unread Notifications Badge
// ─────────────────────────────────────────────

class _UnreadBadge extends StatelessWidget {
  final int count;

  const _UnreadBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        count > 9 ? '9+' : count.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Delete Account Button
// ─────────────────────────────────────────────

class _DeleteAccountButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onTap;

  const _DeleteAccountButton({
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: TextButton.icon(
        onPressed: isLoading ? null : onTap,
        icon: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.error),
              )
            : const Icon(Icons.delete_forever_outlined,
                size: 18, color: AppColors.error),
        label: Text(
          'Supprimer mon compte',
          style: AppTypography.labelMedium.copyWith(
            color: AppColors.error,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.error,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Logout Button
// ─────────────────────────────────────────────

class _LogoutButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onTap;
  final String label;

  const _LogoutButton({
    required this.isLoading,
    required this.onTap,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: isLoading ? null : onTap,
        icon: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.errorDark),
              )
            : const Icon(Icons.logout, size: 18),
        label: Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: AppColors.errorDark,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.errorLight,
          foregroundColor: AppColors.errorDark,
          side: const BorderSide(color: AppColors.error, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
          shadowColor: AppColors.error.withValues(alpha: 0.15),
        ),
      ),
    );
  }
}

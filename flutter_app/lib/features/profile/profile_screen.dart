import 'package:cached_network_image/cached_network_image.dart';
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
import 'package:aji_tfarraj/features/notifications/presentation/providers/notifications_provider.dart';
import 'package:aji_tfarraj/features/loyalty/data/loyalty_repository.dart';

/// Profile Screen
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isLoggingOut = false;

  Future<void> _handleLogout() async {
    setState(() => _isLoggingOut = true);
    try {
      await ref.read(loginAuthStateProvider.notifier).logout();
    } finally {
      if (mounted) setState(() => _isLoggingOut = false);
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

    return Scaffold(
      appBar: AppBar(
        title: Text(s.profileTitle, style: AppTypography.h3),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push(Routes.editProfile),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // Incomplete profile warning banner — only show when the server
          // explicitly reports missing required fields (excluding avatar).
          if (user != null &&
              !user.profileComplete &&
              user.missingProfileFields
                  .any((f) => f != 'avatar' && f != 'avatar_url')) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: const Color(0xFFFFD54F)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: Color(0xFFF57F17), size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      s.profileIncompleteWarning,
                      style: AppTypography.bodySmall
                          .copyWith(color: const Color(0xFFF57F17)),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  TextButton(
                    onPressed: () => context.push(Routes.editProfile),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      s.completeProfileButton,
                      style: AppTypography.labelSmall.copyWith(
                        color: const Color(0xFFF57F17),
                        fontWeight: AppTypography.semiBold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],

          // User avatar and info
          Center(
            child: CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.backgroundGrey,
              child: user?.avatarUrl != null
                  ? ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: user!.avatarUrl!,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => const Icon(Icons.person,
                            size: 50, color: AppColors.textMuted),
                        errorWidget: (_, __, ___) => const Icon(Icons.person,
                            size: 50, color: AppColors.textMuted),
                      ),
                    )
                  : const Icon(Icons.person,
                      size: 50, color: AppColors.textMuted),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: Text(
              user?.displayName ?? s.unknownUser,
              style: AppTypography.h3,
            ),
          ),
          if (user?.email != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Center(
              child: Text(
                user!.email,
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.textMuted),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xxl),

          // Language tile — shows current language, toggles on tap
          ListTile(
            leading: const Icon(Icons.language, color: AppColors.textSecondary),
            title: Text(s.profileLanguageLabel, style: AppTypography.bodyMedium),
            subtitle: Text(
              currentLocale == AppLocale.fr
                  ? s.profileLanguageValueFr
                  : s.profileLanguageValueAr,
              style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
            ),
            trailing: const Icon(Icons.swap_horiz, color: AppColors.textMuted),
            onTap: () =>
                ref.read(localeProvider.notifier).toggleLocale(),
          ),
          const Divider(color: AppColors.border),

          // Loyalty tile
          ListTile(
            leading:
                const Icon(Icons.star_outline, color: AppColors.textSecondary),
            title: Text(s.profileLoyaltyLabel,
                style: AppTypography.bodyMedium),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                pointsAsync.when(
                  data: (summary) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryLight.withValues(alpha: 0.3),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusFull),
                    ),
                    child: Text(
                      '${summary.balance} pts',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.secondaryDark,
                        fontWeight: AppTypography.medium,
                      ),
                    ),
                  ),
                  loading: () => const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.secondary),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(width: AppSpacing.xs),
                const Icon(Icons.chevron_right, color: AppColors.textMuted),
              ],
            ),
            onTap: () => context.push(Routes.loyalty),
          ),
          const Divider(color: AppColors.border),

          // Notifications tile
          ListTile(
            leading: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_outlined,
                    color: AppColors.textSecondary),
                if (unreadCount > 0)
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                          minWidth: 16, minHeight: 16),
                      child: Text(
                        unreadCount > 9 ? '9+' : unreadCount.toString(),
                        style: const TextStyle(
                          color: AppColors.backgroundWhite,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            title: Text(s.profileNotificationsLabel,
                style: AppTypography.bodyMedium),
            subtitle: unreadCount > 0
                ? Text(
                    s.profileUnreadCount(unreadCount),
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.textMuted),
                  )
                : null,
            trailing:
                const Icon(Icons.chevron_right, color: AppColors.textMuted),
            onTap: () => context.push(Routes.notifications),
          ),
          const Divider(color: AppColors.border),

          // Help tile
          ListTile(
            leading: const Icon(Icons.help_outline,
                color: AppColors.textSecondary),
            title: Text(s.profileHelpLabel, style: AppTypography.bodyMedium),
            trailing:
                const Icon(Icons.chevron_right, color: AppColors.textMuted),
            onTap: () {},
          ),
          const Divider(color: AppColors.border),

          // About tile
          ListTile(
            leading: const Icon(Icons.info_outline,
                color: AppColors.textSecondary),
            title: Text(s.profileAboutLabel, style: AppTypography.bodyMedium),
            trailing:
                const Icon(Icons.chevron_right, color: AppColors.textMuted),
            onTap: () {},
          ),
          const Divider(color: AppColors.border),
          const SizedBox(height: AppSpacing.xl),

          // Logout button
          SizedBox(
            width: double.infinity,
            height: AppSpacing.buttonHeight,
            child: OutlinedButton.icon(
              onPressed: _isLoggingOut ? null : _handleLogout,
              icon: _isLoggingOut
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.error),
                    )
                  : const Icon(Icons.logout, size: 18),
              label: Text(s.profileLogoutLabel),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

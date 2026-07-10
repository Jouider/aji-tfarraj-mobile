import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:aji_tfarraj/app/routes.dart';
import 'package:aji_tfarraj/app/copywriting/copy_fr.dart' show ChargePublicCopy;
import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';
import 'package:aji_tfarraj/app/design_system/states.dart';
import 'package:aji_tfarraj/app/design_system/components/loading/skeleton_loader.dart';
import 'package:aji_tfarraj/app/localization/locale_provider.dart';
import 'package:aji_tfarraj/features/auth/data/auth_repository.dart';
import 'package:aji_tfarraj/features/badges/domain/badge.dart';
import 'package:aji_tfarraj/features/badges/presentation/level_badge_card.dart';
import 'package:aji_tfarraj/features/charge_public/data/charge_public_repository.dart';
import 'package:aji_tfarraj/features/charge_public/domain/cp_dashboard.dart';
import 'package:aji_tfarraj/features/charge_public/presentation/cp_mode_provider.dart';
import 'package:aji_tfarraj/features/charge_public/presentation/cp_share_screen.dart';

/// "Mode Chargé Public" — a dedicated space with its own bottom nav
/// (Accueil / Partager / Invités / Gains). Entered from Profile; leave via the
/// header. Fully localized FR + AR (RTL handled by the app's Directionality).
class ChargePublicShell extends ConsumerStatefulWidget {
  const ChargePublicShell({super.key});

  @override
  ConsumerState<ChargePublicShell> createState() => _ChargePublicShellState();
}

class _ChargePublicShellState extends ConsumerState<ChargePublicShell> {
  int _index = 0;

  void _exitToPublicMode() {
    ref.read(cpModeProvider.notifier).setEnabled(false);
    context.go(Routes.home);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(loginAuthStateProvider).user;
    final dashAsync = ref.watch(cpDashboardProvider);
    final cp = ref.watch(stringsProvider).cp;

    final titles = [cp.tabHome, cp.tabShare, cp.tabGuests, cp.tabEarnings];

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: AppSpacing.lg,
        title: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(Icons.workspace_premium_outlined,
                  size: 18, color: AppColors.secondaryDark),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(titles[_index],
                    style: AppTypography.h4.copyWith(
                        fontWeight: FontWeight.w700, fontSize: 17)),
                Text(cp.spaceSubtitle,
                    style: AppTypography.labelSmall
                        .copyWith(color: AppColors.textMuted, fontSize: 11)),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: GestureDetector(
              onTap: _exitToPublicMode,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.swap_horiz,
                        size: 16, color: AppColors.primary),
                    const SizedBox(width: 5),
                    Text(cp.modePublic,
                        style: AppTypography.labelSmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: _index == 1
          // Partager tab has its own data source — independent of the dashboard.
          ? const CpShareTab()
          : dashAsync.when(
              loading: () => const _CpSkeleton(),
              error: (e, _) => ErrorState(
                message: e.toString(),
                retryText: cp.retry,
                onRetry: () => ref.invalidate(cpDashboardProvider),
              ),
              data: (dash) => RefreshIndicator(
                color: AppColors.secondary,
                onRefresh: () async => ref.invalidate(cpDashboardProvider),
                child: switch (_index) {
                  0 => _AccueilTab(
                      dash: dash,
                      cp: cp,
                      userName: _firstName(user, cp),
                      cpBadge: user?.badges?.chargePublic,
                      onSeeGuests: () => setState(() => _index = 2)),
                  2 => _InvitesTab(dash: dash, cp: cp),
                  _ => _GainsTab(dash: dash, cp: cp),
                },
              ),
            ),
      bottomNavigationBar: _CpNavBar(
        currentIndex: _index,
        cp: cp,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }

  static String _firstName(dynamic user, ChargePublicCopy cp) {
    final first = user?.firstName as String?;
    if (first != null && first.trim().isNotEmpty) return first.trim();
    final display = user?.displayName as String?;
    if (display != null && display.trim().isNotEmpty) {
      return display.trim().split(' ').first;
    }
    return cp.roleFallbackName;
  }
}

/// Resolve a reservation status to a localized label.
String _statusLabel(ChargePublicCopy cp, bool attended, String? resStatus) {
  if (attended) return cp.statusPresent;
  switch (resStatus) {
    case 'approved':
      return cp.statusApproved;
    case 'contacting':
      return cp.statusContacting;
    case 'checked_in':
      return cp.statusPresent;
    case 'rejected':
      return cp.statusRejected;
    case 'cancelled':
      return cp.statusCancelled;
    case 'expired':
      return cp.statusExpired;
    default:
      return cp.statusPending;
  }
}

// ─────────────────────────────────────────────
// Custom bottom nav — pill indicator, matches public shell
// ─────────────────────────────────────────────

class _CpNavBar extends StatelessWidget {
  final int currentIndex;
  final ChargePublicCopy cp;
  final ValueChanged<int> onTap;

  const _CpNavBar({
    required this.currentIndex,
    required this.cp,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      (icon: Icons.home_outlined, active: Icons.home, label: cp.navHome),
      (icon: Icons.share_outlined, active: Icons.share, label: cp.navShare),
      (icon: Icons.people_outline, active: Icons.people, label: cp.navGuests),
      (
        icon: Icons.account_balance_wallet_outlined,
        active: Icons.account_balance_wallet,
        label: cp.navEarnings
      ),
    ];
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(items.length, (i) {
              final item = items[i];
              final isActive = currentIndex == i;
              final color =
                  isActive ? AppColors.secondary : AppColors.textMuted;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.secondary.withValues(alpha: 0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(isActive ? item.active : item.icon,
                            size: 22, color: color),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: isActive ? 10.0 : 9.5,
                          fontWeight:
                              isActive ? FontWeight.w600 : FontWeight.w400,
                          color: color,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Accueil
// ─────────────────────────────────────────────

class _AccueilTab extends StatelessWidget {
  final CpDashboard dash;
  final ChargePublicCopy cp;
  final String userName;
  final LevelBadge? cpBadge;
  final VoidCallback onSeeGuests;

  const _AccueilTab({
    required this.dash,
    required this.cp,
    required this.userName,
    required this.cpBadge,
    required this.onSeeGuests,
  });

  @override
  Widget build(BuildContext context) {
    final s = dash.stats;
    final hour = DateTime.now().hour;
    final greeting =
        (hour >= 5 && hour < 18) ? cp.greetingMorning : cp.greetingEvening;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        // Personalised greeting
        Text(
          '$greeting,',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
        ),
        Text(
          '$userName 👋',
          style: AppTypography.h2.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (cpBadge != null) ...[
          LevelBadgeCard(badge: cpBadge!, isCp: true),
          const SizedBox(height: AppSpacing.lg),
        ],
        _BalanceCard(stats: s, cp: cp),
        const SizedBox(height: AppSpacing.lg),
        _KpiGrid(stats: s, cp: cp),
        if (dash.byShow.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          _SectionHeader(title: cp.earningsByShow),
          const SizedBox(height: AppSpacing.sm),
          ...dash.byShow.take(3).map((r) => _ShowRow(row: r, cp: cp)),
        ],
        if (dash.guests.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          _SectionHeader(
              title: cp.recentGuests,
              actionLabel: cp.seeAll,
              onAction: onSeeGuests),
          const SizedBox(height: AppSpacing.sm),
          ...dash.guests.take(3).map((g) => _GuestTile(guest: g, cp: cp)),
        ] else if (dash.referredUsers.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          _SectionHeader(
              title: cp.myReferred,
              actionLabel: cp.seeAll,
              onAction: onSeeGuests),
          const SizedBox(height: AppSpacing.sm),
          ...dash.referredUsers.take(3).map((u) => _ReferredRow(user: u, cp: cp)),
        ],
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final CpStats stats;
  final ChargePublicCopy cp;
  const _BalanceCard({required this.stats, required this.cp});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.successLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(cp.balanceTitle,
                    style: AppTypography.labelMedium
                        .copyWith(color: AppColors.successDark)),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.account_balance_wallet_outlined,
                    size: 19, color: AppColors.successDark),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(cp.money(stats.unpaidBalance),
              style: AppTypography.h1.copyWith(
                  color: AppColors.successDark, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          // Paid progress
          if (stats.earnings > 0) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (stats.paid / stats.earnings).clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: AppColors.success.withValues(alpha: 0.18),
                valueColor:
                    const AlwaysStoppedAnimation(AppColors.successDark),
              ),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              _MiniStat(
                  icon: Icons.savings_outlined,
                  label: cp.earnedShort(stats.earnings)),
              const SizedBox(width: AppSpacing.lg),
              _MiniStat(
                  icon: Icons.check_circle_outline,
                  label: cp.paidShort(stats.paid)),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MiniStat({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(label,
            style: AppTypography.labelSmall
                .copyWith(color: AppColors.textSecondary)),
      ],
    );
  }
}

class _KpiGrid extends StatelessWidget {
  final CpStats stats;
  final ChargePublicCopy cp;
  const _KpiGrid({required this.stats, required this.cp});

  @override
  Widget build(BuildContext context) {
    // CPs don't earn points — 3 KPIs: brought / attended / pending.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _KpiTile(
              icon: Icons.groups_outlined,
              value: '${stats.brought}',
              label: cp.kpiBrought,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _KpiTile(
              icon: Icons.check_circle_outline,
              value: '${stats.attended}',
              label: cp.kpiAttended,
              color: AppColors.success,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _KpiTile(
              icon: Icons.hourglass_empty_rounded,
              value: '${stats.notAttended}',
              label: cp.kpiPending,
              color: AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _KpiTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 15, color: color),
              ),
              const SizedBox(width: 8),
              Text(value,
                  style: AppTypography.h2
                      .copyWith(color: color, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Invités
// ─────────────────────────────────────────────

class _InvitesTab extends StatefulWidget {
  final CpDashboard dash;
  final ChargePublicCopy cp;
  const _InvitesTab({required this.dash, required this.cp});

  @override
  State<_InvitesTab> createState() => _InvitesTabState();
}

class _InvitesTabState extends State<_InvitesTab> {
  /// all | present | approved | pending | cancelled
  String _filter = 'all';

  /// Does a guest match a filter key?
  bool _match(String f, CpGuest g) {
    switch (f) {
      case 'present':
        return g.attended;
      case 'approved':
        return !g.attended && g.resStatus == 'approved';
      case 'pending':
        return !g.attended &&
            (g.resStatus == null ||
                g.resStatus == 'pending_review' ||
                g.resStatus == 'contacting');
      case 'cancelled':
        return !g.attended &&
            (g.resStatus == 'cancelled' ||
                g.resStatus == 'rejected' ||
                g.resStatus == 'expired');
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dash = widget.dash;
    final cp = widget.cp;

    // Fallback source has no per-guest list yet.
    if (dash.guests.isEmpty) {
      if (dash.referredUsers.isEmpty) {
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            const SizedBox(height: 80),
            Center(
              child: EmptyState(
                icon: Icons.people_outline,
                title: cp.noGuests,
              ),
            ),
          ],
        );
      }
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _PartialBanner(cp: cp),
          const SizedBox(height: AppSpacing.md),
          ...dash.referredUsers.map((u) => _ReferredRow(user: u, cp: cp)),
        ],
      );
    }

    int count(String f) => dash.guests.where((g) => _match(f, g)).length;

    // Build the filter set: "Tous" + "Présents" always; the granular states
    // (Approuvés / En attente / Annulés) only when they have guests.
    final chips = <(String key, String label)>[
      ('all', cp.filterAll(count('all'))),
      ('present', cp.filterAttended(count('present'))),
    ];
    if (count('approved') > 0) {
      chips.add(('approved', cp.filterApproved(count('approved'))));
    }
    if (count('pending') > 0) {
      chips.add(('pending', cp.filterPending(count('pending'))));
    }
    if (count('cancelled') > 0) {
      chips.add(('cancelled', cp.filterCancelled(count('cancelled'))));
    }

    final guests = dash.guests.where((g) => _match(_filter, g)).toList();

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final c in chips) ...[
                _FilterChip(
                  label: c.$2,
                  selected: _filter == c.$1,
                  onTap: () => setState(() => _filter = c.$1),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ...guests.map((g) => _GuestTile(guest: g, cp: cp)),
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }
}

class _GuestTile extends StatelessWidget {
  final CpGuest guest;
  final ChargePublicCopy cp;
  const _GuestTile({required this.guest, required this.cp});

  Future<void> _whatsapp(String phone) async {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('https://wa.me/$digits');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final initials = guest.name.trim().isNotEmpty
        ? guest.name.trim()[0].toUpperCase()
        : '?';
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.secondary.withValues(alpha: 0.15),
            backgroundImage:
                guest.avatarUrl != null ? NetworkImage(guest.avatarUrl!) : null,
            child: guest.avatarUrl == null
                ? Text(initials,
                    style: AppTypography.labelMedium
                        .copyWith(color: AppColors.secondaryDark))
                : null,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(guest.name,
                    style: AppTypography.bodyMedium
                        .copyWith(fontWeight: FontWeight.w500)),
                Text('${guest.show}${guest.date != null ? ' · ${guest.date}' : ''}',
                    style: AppTypography.labelSmall
                        .copyWith(color: AppColors.textMuted)),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _StatusChip(
                  label: _statusLabel(cp, guest.attended, guest.resStatus),
                  statusKey: guest.attended
                      ? 'checked_in'
                      : (guest.resStatus ?? 'pending_review')),
              const SizedBox(height: 4),
              if (guest.attended && guest.amount != null)
                Text(cp.gain(guest.amount!),
                    style: AppTypography.labelSmall.copyWith(
                        color: AppColors.successDark,
                        fontWeight: FontWeight.w600))
              else if (guest.phone != null)
                GestureDetector(
                  onTap: () => _whatsapp(guest.phone!),
                  child: const Icon(Icons.chat_outlined,
                      size: 18, color: AppColors.success),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;

  /// Reservation status key (checked_in / approved / contacting /
  /// pending_review / rejected / cancelled / expired) — drives the color.
  final String statusKey;

  const _StatusChip({required this.label, required this.statusKey});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.getStatusBackgroundColor(statusKey),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.getStatusForegroundColor(statusKey),
          fontSize: 11,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Gains
// ─────────────────────────────────────────────

class _GainsTab extends StatelessWidget {
  final CpDashboard dash;
  final ChargePublicCopy cp;
  const _GainsTab({required this.dash, required this.cp});

  @override
  Widget build(BuildContext context) {
    final s = dash.stats;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        _BalanceCard(stats: s, cp: cp),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
                child: _GainStat(
                    value: cp.money(s.earnings),
                    label: cp.totalEarned,
                    color: AppColors.successDark)),
            const SizedBox(width: AppSpacing.md),
            Expanded(
                child: _GainStat(
                    value: cp.money(s.paid),
                    label: cp.alreadyPaid,
                    color: AppColors.textSecondary)),
          ],
        ),
        if (dash.byShow.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          _SectionHeader(title: cp.earningsByShow),
          const SizedBox(height: AppSpacing.sm),
          ...dash.byShow.map((r) => _ShowRow(row: r, cp: cp)),
        ],
        if (dash.payments.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          _SectionHeader(title: cp.paymentHistory),
          const SizedBox(height: AppSpacing.sm),
          ...dash.payments.map((p) => _PaymentRow(payment: p, cp: cp)),
        ],
        if (dash.isPartial) ...[
          const SizedBox(height: AppSpacing.xl),
          _PartialBanner(cp: cp),
        ],
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }
}

class _GainStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _GainStat(
      {required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: AppTypography.h3.copyWith(color: color)),
          Text(label,
              style: AppTypography.labelSmall
                  .copyWith(color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  final CpPayment payment;
  final ChargePublicCopy cp;
  const _PaymentRow({required this.payment, required this.cp});

  @override
  Widget build(BuildContext context) {
    final date = payment.paidAt;
    final dateStr = date != null
        ? '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}'
        : '';
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.payments_outlined,
              size: 20, color: AppColors.success),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    payment.note?.isNotEmpty == true
                        ? payment.note!
                        : cp.payment,
                    style: AppTypography.bodyMedium),
                if (dateStr.isNotEmpty)
                  Text(dateStr,
                      style: AppTypography.labelSmall
                          .copyWith(color: AppColors.textMuted)),
              ],
            ),
          ),
          Text(cp.money(payment.amount),
              style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.successDark, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Shared bits
// ─────────────────────────────────────────────

class _ShowRow extends StatelessWidget {
  final CpShowRow row;
  final ChargePublicCopy cp;
  const _ShowRow({required this.row, required this.cp});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(row.showTitle,
                    style: AppTypography.bodyMedium
                        .copyWith(fontWeight: FontWeight.w500)),
                Text(cp.invitedAttended(row.invited, row.attended),
                    style: AppTypography.labelSmall
                        .copyWith(color: AppColors.textMuted)),
              ],
            ),
          ),
          Text(cp.money(row.earnings),
              style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.successDark, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ReferredRow extends StatelessWidget {
  final CpReferredUser user;
  final ChargePublicCopy cp;
  const _ReferredRow({required this.user, required this.cp});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name,
                    style: AppTypography.bodyMedium
                        .copyWith(fontWeight: FontWeight.w500)),
                Text(cp.visitsCount(user.visits),
                    style: AppTypography.labelSmall
                        .copyWith(color: AppColors.textMuted)),
              ],
            ),
          ),
          Text(cp.money(user.totalEarned),
              style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.successDark, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  const _SectionHeader({required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: AppTypography.h4.copyWith(fontWeight: FontWeight.w600)),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            child: Text(actionLabel!,
                style: AppTypography.labelSmall
                    .copyWith(color: AppColors.primary)),
          ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.secondary : AppColors.backgroundWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? AppColors.secondary : AppColors.border),
        ),
        child: Text(label,
            style: AppTypography.labelSmall.copyWith(
                color: selected ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.w500)),
      ),
    );
  }
}

class _PartialBanner extends StatelessWidget {
  final ChargePublicCopy cp;
  const _PartialBanner({required this.cp});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 18, color: AppColors.warning),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              cp.detailSoon,
              style: AppTypography.labelSmall
                  .copyWith(color: AppColors.warning),
            ),
          ),
        ],
      ),
    );
  }
}

class _CpSkeleton extends StatelessWidget {
  const _CpSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          SkeletonLoader.card(height: 120),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(child: SkeletonLoader.card(height: 70)),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: SkeletonLoader.card(height: 70)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SkeletonLoader.card(height: 70),
        ],
      ),
    );
  }
}

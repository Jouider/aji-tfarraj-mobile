// FEATURE: Support — the client's conversations with the Aji Tfarraj team.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:aji_tfarraj/app/copywriting/support_chat_copy.dart';
import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';
import 'package:aji_tfarraj/app/localization/locale_provider.dart';
import 'package:aji_tfarraj/features/support/data/support_service.dart';
import 'package:aji_tfarraj/features/support/domain/support_ticket.dart';
import 'package:aji_tfarraj/features/support/presentation/screens/create_ticket_screen.dart';
import 'package:aji_tfarraj/features/support/presentation/screens/support_chat_screen.dart';

class SupportTicketsScreen extends ConsumerStatefulWidget {
  const SupportTicketsScreen({super.key});

  @override
  ConsumerState<SupportTicketsScreen> createState() =>
      _SupportTicketsScreenState();
}

class _SupportTicketsScreenState extends ConsumerState<SupportTicketsScreen> {
  late Future<List<SupportTicket>> _tickets;

  @override
  void initState() {
    super.initState();
    _tickets = _load();
  }

  Future<List<SupportTicket>> _load() =>
      ref.read(supportServiceProvider).getTickets();

  Future<void> _refresh() async {
    final next = _load();
    setState(() => _tickets = next);
    await next.catchError((_) => <SupportTicket>[]);
  }

  /// Back from a conversation or a new one: its last message and unread count
  /// have changed.
  Future<void> _open(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    if (!mounted) return;
    ref.invalidate(supportUnreadProvider);
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final copy = ref.watch(stringsProvider).supportChat;
    final locale =
        ref.watch(localeProvider).languageCode == 'ar' ? 'ar' : 'fr_FR';

    // A reply arrived while the list was open.
    ref.listen(supportPushTickProvider, (_, __) => _refresh());

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new,
              size: 20, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          copy.listTitle,
          style: AppTypography.h4.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: AppColors.border),
        ),
      ),
      body: FutureBuilder<List<SupportTicket>>(
        future: _tickets,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (snapshot.hasError) {
            return _Message(
              icon: Icons.error_outline,
              title: copy.loadError,
              action: copy.retry,
              onAction: _refresh,
            );
          }
          final tickets = snapshot.data ?? const [];
          if (tickets.isEmpty) {
            return _Message(
              icon: Icons.forum_outlined,
              title: copy.emptyTitle,
              body: copy.emptyBody,
              action: copy.emptyButton,
              onAction: () => _open(const CreateTicketScreen()),
            );
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _refresh,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              // Room at the bottom for the button and the home indicator.
              padding: EdgeInsets.fromLTRB(
                0,
                AppSpacing.sm,
                0,
                AppSpacing.xxxl +
                    AppSpacing.xl +
                    MediaQuery.paddingOf(context).bottom,
              ),
              itemCount: tickets.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                indent: AppSpacing.lg + 44 + AppSpacing.md,
                color: AppColors.border,
              ),
              itemBuilder: (context, i) => _ConversationTile(
                ticket: tickets[i],
                copy: copy,
                locale: locale,
                onTap: () => _open(SupportChatScreen(
                  ticketId: tickets[i].id,
                  subject: tickets[i].subject,
                )),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FutureBuilder<List<SupportTicket>>(
        future: _tickets,
        builder: (context, snapshot) {
          // The empty state has its own button: no second one under it.
          if (!(snapshot.data?.isNotEmpty ?? false)) {
            return const SizedBox.shrink();
          }
          return FloatingActionButton.extended(
            onPressed: () => _open(const CreateTicketScreen()),
            backgroundColor: AppColors.primaryAction,
            foregroundColor: AppColors.onPrimary,
            elevation: 2,
            icon: const Icon(Icons.edit_outlined),
            label: Text(copy.newConversation),
          );
        },
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.ticket,
    required this.copy,
    required this.locale,
    required this.onTap,
  });

  final SupportTicket ticket;
  final SupportChatCopy copy;
  final String locale;
  final VoidCallback onTap;

  String _when(DateTime at) {
    final local = at.toLocal();
    final now = DateTime.now();
    final sameDay = local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
    return sameDay
        ? DateFormat.Hm(locale).format(local)
        : DateFormat('d MMM', locale).format(local);
  }

  @override
  Widget build(BuildContext context) {
    final unread = ticket.unreadCount > 0;
    final preview = ticket.lastMessage == null
        ? null
        : (ticket.lastMessageFromStaff ? '' : copy.you) + ticket.lastMessage!;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.support_agent,
                  size: 22, color: AppColors.primary),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          ticket.subject,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight:
                                unread ? FontWeight.w700 : FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        _when(ticket.lastActivityAt),
                        style: AppTypography.caption.copyWith(
                          color:
                              unread ? AppColors.primary : AppColors.textMuted,
                          fontWeight: unread ? FontWeight.w600 : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          preview ?? _status(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySmall.copyWith(
                            color: unread
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                            height: 1.35,
                          ),
                        ),
                      ),
                      if (unread) ...[
                        const SizedBox(width: AppSpacing.sm),
                        _UnreadBadge(count: ticket.unreadCount),
                      ],
                    ],
                  ),
                  if (ticket.isClosed) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      copy.statusClosed,
                      style: AppTypography.caption
                          .copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _status() => switch (ticket.status) {
        'in_progress' => copy.statusInProgress,
        'closed' => copy.statusClosed,
        _ => copy.statusOpen,
      };
}

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: AppTypography.caption.copyWith(
          color: AppColors.onPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Empty and error states: an icon, a line or two, one button.
class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.action,
    required this.onAction,
    this.body,
  });

  final IconData icon;
  final String title;
  final String? body;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AppColors.textMuted),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            if (body != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                body!,
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: onAction,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryAction,
                foregroundColor: AppColors.onPrimary,
                minimumSize: const Size(0, AppSpacing.buttonHeight),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
              ),
              child: Text(action,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

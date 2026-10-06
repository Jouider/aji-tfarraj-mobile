// FEATURE: Support — one conversation with the Aji Tfarraj team.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:aji_tfarraj/app/copywriting/support_chat_copy.dart';
import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';
import 'package:aji_tfarraj/app/localization/locale_provider.dart';
import 'package:aji_tfarraj/app/routes.dart';
import 'package:aji_tfarraj/features/support/data/support_service.dart';
import 'package:aji_tfarraj/features/support/domain/support_ticket.dart';

/// The conversation.
///
/// No socket: while the screen is open and the app in front, it asks for new
/// messages every [_pollEvery]; a support push asks at once. Closed or in the
/// background, it asks nothing — the server bill does not grow with the
/// number of people who once opened support.
class SupportChatScreen extends ConsumerStatefulWidget {
  const SupportChatScreen({super.key, required this.ticketId, this.subject});

  final int ticketId;

  /// Known when coming from the list; from a notification, the first answer
  /// brings it.
  final String? subject;

  @override
  ConsumerState<SupportChatScreen> createState() => _SupportChatScreenState();
}

/// A message the client wrote, until the server has it.
class _Pending {
  _Pending(this.body) : at = DateTime.now();

  final String body;
  final DateTime at;
  bool failed = false;
}

class _SupportChatScreenState extends ConsumerState<SupportChatScreen>
    with WidgetsBindingObserver {
  static const _pollEvery = Duration(seconds: 8);
  static const _maxLength = 2000;

  final _input = TextEditingController();
  final List<SupportMessage> _messages = [];
  final List<_Pending> _pending = [];

  String? _subject;
  String _status = 'open';
  bool _loading = true;
  bool _loadFailed = false;
  bool _polling = false;
  Timer? _timer;
  late final StateController<int?> _openTicket;

  int get _lastId => _messages.isEmpty ? 0 : _messages.last.id;

  @override
  void initState() {
    super.initState();
    _subject = widget.subject;
    WidgetsBinding.instance.addObserver(this);
    _input.addListener(() => setState(() {}));

    // While this conversation is on screen, its push needs no banner.
    _openTicket = ref.read(openSupportTicketProvider.notifier);
    Future.microtask(() => _openTicket.state = widget.ticketId);

    _poll(initial: true);
    _timer = Timer.periodic(_pollEvery, (_) => _poll());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _input.dispose();
    final open = _openTicket;
    final id = widget.ticketId;
    Future.microtask(() {
      // The whole app may be going away with this screen.
      try {
        if (open.state == id) open.state = null;
      } catch (_) {}
    });
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _poll();
      _timer ??= Timer.periodic(_pollEvery, (_) => _poll());
    } else if (state == AppLifecycleState.paused) {
      _timer?.cancel();
      _timer = null;
    }
  }

  Future<void> _poll({bool initial = false}) async {
    if (_polling) return;
    _polling = true;
    try {
      final update = await ref
          .read(supportServiceProvider)
          .getMessages(widget.ticketId, after: _lastId);
      if (!mounted) return;
      setState(() {
        _status = update.status;
        _subject ??= update.subject;
        final known = _messages.map((m) => m.id).toSet();
        _messages.addAll(update.messages.where((m) => !known.contains(m.id)));
        _loading = false;
        _loadFailed = false;
      });
      if (update.messages.any((m) => m.fromStaff)) {
        ref.invalidate(supportUnreadProvider);
      }
    } catch (_) {
      // A missed poll is retried by the next one; only the first load, with
      // nothing to show, deserves an error screen.
      if (mounted && initial) {
        setState(() {
          _loading = false;
          _loadFailed = true;
        });
      }
    } finally {
      _polling = false;
    }
  }

  Future<void> _send([_Pending? retry]) async {
    final copy = ref.read(stringsProvider).supportChat;
    final body = retry?.body ?? _input.text.trim();
    if (body.isEmpty) return;
    if (body.length > _maxLength) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(copy.tooLong)));
      return;
    }

    final pending = retry ?? _Pending(body);
    setState(() {
      pending.failed = false;
      if (retry == null) {
        _pending.add(pending);
        _input.clear();
      }
    });

    try {
      final sent = await ref
          .read(supportServiceProvider)
          .sendMessage(widget.ticketId, body);
      if (!mounted) return;
      setState(() {
        _pending.remove(pending);
        _status = sent.status;
        if (!_messages.any((m) => m.id == sent.message.id)) {
          _messages.add(sent.message);
          _messages.sort((a, b) => a.id.compareTo(b.id));
        }
      });
    } catch (_) {
      if (mounted) setState(() => pending.failed = true);
    }
  }

  void _back() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      // Opened from a notification: nothing underneath.
      context.go(Routes.support);
    }
  }

  @override
  Widget build(BuildContext context) {
    final copy = ref.watch(stringsProvider).supportChat;
    final locale =
        ref.watch(localeProvider).languageCode == 'ar' ? 'ar' : 'fr_FR';

    ref.listen(supportPushTickProvider, (_, __) => _poll());

    return PopScope(
      canPop: Navigator.of(context).canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go(Routes.support);
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundWhite,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new,
                size: 20, color: AppColors.textPrimary),
            onPressed: _back,
          ),
          titleSpacing: 0,
          title: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.support_agent,
                    size: 20, color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _subject ?? copy.listTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      copy.team,
                      style: AppTypography.caption
                          .copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(0.5),
            child: Container(height: 0.5, color: AppColors.border),
          ),
        ),
        body: Column(
          children: [
            Expanded(child: _thread(copy, locale)),
            if (_status == 'closed') _Notice(text: copy.closedNotice),
            _Composer(
              controller: _input,
              hint: copy.inputHint,
              maxLength: _maxLength,
              onSend: _input.text.trim().isEmpty ? null : () => _send(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _thread(SupportChatCopy copy, String locale) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_loadFailed) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: AppSpacing.lg),
              Text(copy.loadError,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium
                      .copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() => _loading = true);
                  _poll(initial: true);
                },
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(copy.retry),
              ),
            ],
          ),
        ),
      );
    }

    // Newest at the bottom, built from the bottom up: the list opens on the
    // last message and stays there as messages arrive.
    final items = <Widget>[];
    final waiting = !_messages.any((m) => m.fromStaff) && _status != 'closed';

    for (final p in _pending.reversed) {
      items.add(_Bubble(
        body: p.body,
        mine: true,
        time: DateFormat.Hm(locale).format(p.at),
        pending: !p.failed,
        failed: p.failed,
        failedLabel: '${copy.sendFailed} · ${copy.retrySend}',
        onRetry: p.failed ? () => _send(p) : null,
      ));
    }
    if (waiting && _messages.isNotEmpty) {
      items.add(_Notice(text: copy.waitingNotice, inline: true));
    }
    for (var i = _messages.length - 1; i >= 0; i--) {
      final m = _messages[i];
      final previous = i > 0 ? _messages[i - 1] : null;
      // The team's name above the first of a run of replies.
      final startsRun = previous == null || previous.fromStaff != m.fromStaff;
      items.add(_Bubble(
        body: m.body,
        mine: !m.fromStaff,
        author: m.fromStaff && startsRun ? copy.team : null,
        time: DateFormat.Hm(locale).format(m.createdAt.toLocal()),
      ));
      if (previous == null || !_sameDay(previous.createdAt, m.createdAt)) {
        items.add(_DayChip(label: _day(m.createdAt, copy, locale)));
      }
    }

    return ListView(
      reverse: true,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.md),
      children: items,
    );
  }

  bool _sameDay(DateTime a, DateTime b) {
    final x = a.toLocal(), y = b.toLocal();
    return x.year == y.year && x.month == y.month && x.day == y.day;
  }

  String _day(DateTime at, SupportChatCopy copy, String locale) {
    final now = DateTime.now();
    if (_sameDay(at, now)) return copy.today;
    if (_sameDay(at, now.subtract(const Duration(days: 1)))) {
      return copy.yesterday;
    }
    return DateFormat('EEEE d MMMM', locale).format(at.toLocal());
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.body,
    required this.mine,
    required this.time,
    this.author,
    this.pending = false,
    this.failed = false,
    this.failedLabel,
    this.onRetry,
  });

  final String body;

  /// Written by the client: on the end side, in the brand colour.
  final bool mine;
  final String time;
  final String? author;
  final bool pending;
  final bool failed;
  final String? failedLabel;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    const radius = Radius.circular(18);
    const tail = Radius.circular(4);
    final maxWidth = MediaQuery.sizeOf(context).width * 0.78;

    return Padding(
      padding: EdgeInsets.only(top: author != null ? AppSpacing.md : 3),
      child: Column(
        crossAxisAlignment:
            mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (author != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(
                  start: AppSpacing.sm, bottom: AppSpacing.xs),
              child: Text(
                author!,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          GestureDetector(
            onTap: onRetry,
            child: Opacity(
              opacity: pending ? 0.6 : 1,
              child: Container(
                constraints: BoxConstraints(maxWidth: maxWidth),
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md + 2, vertical: AppSpacing.sm + 2),
                decoration: BoxDecoration(
                  color: mine
                      ? AppColors.primaryAction
                      : AppColors.backgroundWhite,
                  border: mine ? null : Border.all(color: AppColors.border),
                  borderRadius: BorderRadiusDirectional.only(
                    topStart: radius,
                    topEnd: radius,
                    bottomStart: mine ? radius : tail,
                    bottomEnd: mine ? tail : radius,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SelectableText(
                      body,
                      style: AppTypography.bodyMedium.copyWith(
                        color:
                            mine ? AppColors.onPrimary : AppColors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          time,
                          style: AppTypography.caption.copyWith(
                            fontSize: 11,
                            color: mine
                                ? AppColors.onPrimary.withValues(alpha: 0.75)
                                : AppColors.textMuted,
                          ),
                        ),
                        if (pending) ...[
                          const SizedBox(width: 4),
                          Icon(Icons.schedule,
                              size: 12,
                              color:
                                  AppColors.onPrimary.withValues(alpha: 0.75)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (failed && failedLabel != null)
            GestureDetector(
              onTap: onRetry,
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 14, color: AppColors.error),
                    const SizedBox(width: 4),
                    Text(
                      failedLabel!,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.xs),
          decoration: BoxDecoration(
            color: AppColors.backgroundWhite,
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            label,
            style: AppTypography.caption.copyWith(color: AppColors.textMuted),
          ),
        ),
      ),
    );
  }
}

/// A line from the app, not from anyone: closed conversation, or waiting
/// for the first reply.
class _Notice extends StatelessWidget {
  const _Notice({required this.text, this.inline = false});

  final String text;
  final bool inline;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: inline
          ? const EdgeInsets.symmetric(vertical: AppSpacing.md)
          : EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.sm + 2),
      decoration: BoxDecoration(
        color: inline ? null : AppColors.backgroundWhite,
        border:
            inline ? null : Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppTypography.caption
            .copyWith(color: AppColors.textMuted, height: 1.4),
      ),
    );
  }
}

/// The input bar: grows with the text up to five lines, sits above the
/// keyboard, and above the home indicator when the keyboard is down.
class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.hint,
    required this.maxLength,
    required this.onSend,
  });

  final TextEditingController controller;
  final String hint;
  final int maxLength;
  final VoidCallback? onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.sm, AppSpacing.sm, AppSpacing.sm),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 5,
                maxLength: maxLength,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.textPrimary, height: 1.35),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: AppTypography.bodyMedium
                      .copyWith(color: AppColors.textMuted),
                  counterText: '',
                  isDense: true,
                  filled: true,
                  fillColor: AppColors.backgroundLight,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg, vertical: AppSpacing.md - 2),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            SizedBox(
              width: 44,
              height: 44,
              child: IconButton.filled(
                onPressed: onSend,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primaryAction,
                  foregroundColor: AppColors.onPrimary,
                  disabledBackgroundColor: AppColors.border,
                  disabledForegroundColor: AppColors.textMuted,
                ),
                // Mirrored in Arabic: the arrow points where the text goes.
                icon: const Icon(Icons.send_rounded, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

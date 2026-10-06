import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aji_tfarraj/app/push/push_router.dart';
import 'package:aji_tfarraj/features/notifications/data/notification_repository.dart'
    show sharedPreferencesProvider;
import 'package:aji_tfarraj/features/support/data/support_service.dart';
import 'package:aji_tfarraj/features/support/domain/support_ticket.dart';
import 'package:aji_tfarraj/features/support/presentation/screens/support_chat_screen.dart';

/// The support chat: what the server sends is read right, and the
/// conversation shows, sends and survives a failed send.
void main() {
  group('ce que le serveur envoie', () {
    test('une conversation avec son dernier message et ses non-lus', () {
      final t = SupportTicket.fromJson({
        'id': 7,
        'subject': 'Billet',
        'status': 'in_progress',
        'created_at': '2026-10-06T10:00:00+01:00',
        'updated_at': '2026-10-06T11:00:00+01:00',
        'last_message_at': '2026-10-06T12:30:00+01:00',
        'last_message': {'body': 'Dans l\'onglet Billets.', 'from_staff': true},
        'unread_count': 2,
      });

      expect(t.lastMessage, 'Dans l\'onglet Billets.');
      expect(t.lastMessageFromStaff, isTrue);
      expect(t.unreadCount, 2);
      expect(t.lastActivityAt, DateTime.parse('2026-10-06T12:30:00+01:00'));
    });

    test('une réponse sans les champs du chat ne casse rien', () {
      final t = SupportTicket.fromJson({
        'id': 3,
        'subject': 'Ancien',
        'status': 'open',
        'created_at': '2026-09-01T10:00:00Z',
        'updated_at': '2026-09-02T10:00:00Z',
      });

      expect(t.lastMessage, isNull);
      expect(t.unreadCount, 0);
      expect(t.lastActivityAt, DateTime.parse('2026-09-02T10:00:00Z'));
    });

    test('la notification « réponse du support » ouvre la conversation', () {
      expect(
        PushRouter.getRouteFromData(
            {'type': 'support_reply', 'deep_link': '/support/12'}),
        '/support/12',
      );
    });
  });

  group('la conversation', () {
    late _FakeSupport support;

    setUpAll(() => initializeDateFormatting('fr_FR'));

    setUp(() => support = _FakeSupport());

    Future<void> open(WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          supportServiceProvider.overrideWithValue(support),
        ],
        child: const MaterialApp(
          home: SupportChatScreen(ticketId: 7, subject: 'Billet'),
        ),
      ));
      await tester.pumpAndSettle();
    }

    /// The screen polls on a timer: take it down before the test ends.
    Future<void> close(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    }

    testWidgets('elle montre le fil, et le nom de l\'équipe sur ses réponses',
        (tester) async {
      support.messages = [
        _msg(1, 'Je ne trouve pas mon billet', staff: false),
        _msg(2, 'Il est dans l\'onglet Billets.', staff: true),
      ];
      await open(tester);

      expect(find.text('Je ne trouve pas mon billet'), findsOneWidget);
      expect(find.text('Il est dans l\'onglet Billets.'), findsOneWidget);
      // In the app bar, and above the team's reply.
      expect(find.text('Équipe Aji Tfarraj'), findsNWidgets(2));
      await close(tester);
    });

    testWidgets('sans réponse encore, elle dit que le message est arrivé',
        (tester) async {
      support.messages = [_msg(1, 'Bonjour', staff: false)];
      await open(tester);

      expect(find.textContaining('Message bien reçu'), findsOneWidget);
      await close(tester);
    });

    testWidgets('un message envoyé rejoint le fil', (tester) async {
      support.messages = [_msg(1, 'Bonjour', staff: false)];
      await open(tester);

      await tester.enterText(find.byType(TextField), 'Vous êtes là ?');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      expect(support.sent, ['Vous êtes là ?']);
      expect(find.text('Vous êtes là ?'), findsOneWidget);
      expect(find.text('Non envoyé · Réessayer'), findsNothing);
      await close(tester);
    });

    testWidgets('un envoi raté se réessaie d\'un geste', (tester) async {
      support.messages = [_msg(1, 'Bonjour', staff: false)];
      support.failNextSend = true;
      await open(tester);

      await tester.enterText(find.byType(TextField), 'Allô ?');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Non envoyé · Réessayer'), findsOneWidget);

      await tester.tap(find.text('Non envoyé · Réessayer'));
      await tester.pumpAndSettle();

      expect(support.sent, ['Allô ?']);
      expect(find.text('Non envoyé · Réessayer'), findsNothing);
      await close(tester);
    });

    testWidgets('fermée, elle dit qu\'un message la rouvre', (tester) async {
      support.status = 'closed';
      support.messages = [
        _msg(1, 'Bonjour', staff: false),
        _msg(2, 'C\'est réglé.', staff: true),
      ];
      await open(tester);

      expect(find.textContaining('Conversation fermée'), findsOneWidget);
      await close(tester);
    });
  });
}

SupportMessage _msg(int id, String body, {required bool staff}) =>
    SupportMessage(
      id: id,
      body: body,
      fromStaff: staff,
      createdAt: DateTime.now(),
    );

class _FakeSupport implements SupportService {
  List<SupportMessage> messages = [];
  String status = 'open';
  bool failNextSend = false;
  final List<String> sent = [];

  @override
  Future<SupportThreadUpdate> getMessages(int ticketId, {int after = 0}) async =>
      SupportThreadUpdate(
        subject: 'Billet',
        status: status,
        messages: messages.where((m) => m.id > after).toList(),
      );

  @override
  Future<({String status, SupportMessage message})> sendMessage(
      int ticketId, String body) async {
    if (failNextSend) {
      failNextSend = false;
      throw Exception('réseau');
    }
    sent.add(body);
    final m = _msg(messages.length + 1, body, staff: false);
    messages.add(m);
    return (status: status, message: m);
  }

  @override
  Future<int> unreadCount() async => 0;

  @override
  Future<List<SupportTicket>> getTickets() async => [];

  @override
  Future<SupportTicket> createTicket(
          {required String subject, required String message}) =>
      throw UnimplementedError();
}

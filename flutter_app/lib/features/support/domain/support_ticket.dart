// FEATURE: Support — conversations with the Aji Tfarraj team.

/// A conversation, as the list shows it.
class SupportTicket {
  final int id;
  final String subject;
  final String status; // 'open' | 'in_progress' | 'closed'
  final DateTime createdAt;
  final DateTime lastActivityAt;

  /// The latest message, cut short by the server. Null only for a
  /// conversation created by an app version older than the chat.
  final String? lastMessage;
  final bool lastMessageFromStaff;

  /// Replies from the team the client has not opened yet.
  final int unreadCount;

  const SupportTicket({
    required this.id,
    required this.subject,
    required this.status,
    required this.createdAt,
    required this.lastActivityAt,
    this.lastMessage,
    this.lastMessageFromStaff = false,
    this.unreadCount = 0,
  });

  bool get isClosed => status == 'closed';

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    final createdAt = DateTime.parse(json['created_at'] as String);
    final last = json['last_message'] as Map<String, dynamic>?;
    final activity = json['last_message_at'] ?? json['updated_at'];

    return SupportTicket(
      id: json['id'] as int,
      subject: json['subject'] as String,
      status: json['status'] as String,
      createdAt: createdAt,
      lastActivityAt:
          activity != null ? DateTime.parse(activity as String) : createdAt,
      lastMessage: last?['body'] as String?,
      lastMessageFromStaff: last?['from_staff'] as bool? ?? false,
      unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
    );
  }
}

/// One message of a conversation, from the client or from the team.
class SupportMessage {
  final int id;
  final String body;
  final bool fromStaff;
  final DateTime createdAt;

  const SupportMessage({
    required this.id,
    required this.body,
    required this.fromStaff,
    required this.createdAt,
  });

  factory SupportMessage.fromJson(Map<String, dynamic> json) => SupportMessage(
        id: json['id'] as int,
        body: json['body'] as String,
        fromStaff: json['from_staff'] as bool? ?? false,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

/// What the conversation screen gets back each time it asks: the status, and
/// the messages it did not have yet.
class SupportThreadUpdate {
  final String? subject;
  final String status;
  final List<SupportMessage> messages;

  const SupportThreadUpdate({
    this.subject,
    required this.status,
    required this.messages,
  });

  factory SupportThreadUpdate.fromJson(Map<String, dynamic> json) =>
      SupportThreadUpdate(
        subject: json['subject'] as String?,
        status: json['status'] as String,
        messages: (json['messages'] as List<dynamic>)
            .map((m) => SupportMessage.fromJson(m as Map<String, dynamic>))
            .toList(),
      );
}

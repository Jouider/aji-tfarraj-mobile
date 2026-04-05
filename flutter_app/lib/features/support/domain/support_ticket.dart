// FEATURE: Support Tickets - Data Models

/// Lightweight ticket used in list responses.
class SupportTicket {
  final int id;
  final String subject;
  final String status; // 'open' | 'in_progress' | 'closed'
  final DateTime createdAt;
  final DateTime updatedAt;

  const SupportTicket({
    required this.id,
    required this.subject,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    final createdAt = DateTime.parse(json['created_at'] as String);
    return SupportTicket(
      id: json['id'] as int,
      subject: json['subject'] as String,
      status: json['status'] as String,
      createdAt: createdAt,
      // updated_at is absent in the POST 201 response — fall back to createdAt
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : createdAt,
    );
  }
}

/// Full ticket with message — used in detail responses.
class SupportTicketDetail extends SupportTicket {
  final String message;

  const SupportTicketDetail({
    required super.id,
    required super.subject,
    required super.status,
    required super.createdAt,
    required super.updatedAt,
    required this.message,
  });

  factory SupportTicketDetail.fromJson(Map<String, dynamic> json) =>
      SupportTicketDetail(
        id: json['id'] as int,
        subject: json['subject'] as String,
        status: json['status'] as String,
        message: json['message'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );
}

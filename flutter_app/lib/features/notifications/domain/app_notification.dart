// filepath: /Users/mouadsmac/aji-tfarraj-mobile/flutter_app/lib/features/notifications/domain/app_notification.dart

/// Notification types supported by the app
enum NotificationType {
  reservation,
  ticket,
  system,
  unknown;

  static NotificationType fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'reservation':
        return NotificationType.reservation;
      case 'ticket':
        return NotificationType.ticket;
      case 'system':
        return NotificationType.system;
      default:
        return NotificationType.unknown;
    }
  }

  String toJson() => name;
}

/// App Notification model
/// Represents a push notification received by the app
class AppNotification {
  /// Unique identifier for the notification
  final String id;

  /// Notification title
  final String title;

  /// Notification body/message
  final String body;

  /// Type of notification (reservation, ticket, system, unknown)
  final NotificationType type;

  /// Optional reservation ID for reservation-related notifications
  final String? reservationId;

  /// Optional ticket code for ticket-related notifications
  final String? ticketCode;

  /// Optional deep link for custom navigation
  final String? deepLink;

  /// When the notification was received
  final DateTime receivedAt;

  /// Whether the notification has been read
  final bool isRead;

  /// Raw data from the push notification payload
  final Map<String, dynamic> rawData;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.reservationId,
    this.ticketCode,
    this.deepLink,
    required this.receivedAt,
    this.isRead = false,
    this.rawData = const {},
  });

  /// Create AppNotification from Firebase RemoteMessage data
  /// Supports various payload formats from backend
  factory AppNotification.fromRemoteMessage(Map<String, dynamic> data, {
    String? notificationTitle,
    String? notificationBody,
  }) {
    // Generate unique ID based on timestamp and data hash
    final id = data['id']?.toString() ?? 
        '${DateTime.now().millisecondsSinceEpoch}_${data.hashCode}';

    // Extract title and body - prefer data payload, fallback to notification.
    // Title/body are expected to already be localized by the backend based on
    // the device's registered locale (see DeviceRepository.registerDevice).
    // If both payload and notification fields are missing, we leave the title
    // empty and let the UI render a locale-aware fallback via AppStrings.
    final title = data['title']?.toString() ??
        notificationTitle ??
        '';

    final body = data['body']?.toString() ??
        notificationBody ??
        '';

    // Determine notification type
    final typeString = data['type']?.toString();
    final type = NotificationType.fromString(typeString);

    // Extract optional fields - support both snake_case and camelCase
    final reservationId = data['reservation_id']?.toString() ?? 
        data['reservationId']?.toString();
    
    final ticketCode = data['ticket_code']?.toString() ?? 
        data['ticketCode']?.toString();
    
    final deepLink = data['deep_link']?.toString() ?? 
        data['deepLink']?.toString();

    return AppNotification(
      id: id,
      title: title,
      body: body,
      type: type,
      reservationId: reservationId,
      ticketCode: ticketCode,
      deepLink: deepLink,
      receivedAt: DateTime.now(),
      isRead: false,
      rawData: Map<String, dynamic>.from(data),
    );
  }

  /// Create AppNotification from JSON (local storage)
  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      type: NotificationType.fromString(json['type'] as String?),
      reservationId: json['reservationId'] as String?,
      ticketCode: json['ticketCode'] as String?,
      deepLink: json['deepLink'] as String?,
      receivedAt: DateTime.parse(json['receivedAt'] as String),
      isRead: json['isRead'] as bool? ?? false,
      rawData: json['rawData'] != null
          ? Map<String, dynamic>.from(json['rawData'] as Map)
          : const {},
    );
  }

  /// Convert to JSON for local storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type.toJson(),
      'reservationId': reservationId,
      'ticketCode': ticketCode,
      'deepLink': deepLink,
      'receivedAt': receivedAt.toIso8601String(),
      'isRead': isRead,
      'rawData': rawData,
    };
  }

  /// Create a copy with updated fields
  AppNotification copyWith({
    String? id,
    String? title,
    String? body,
    NotificationType? type,
    String? reservationId,
    String? ticketCode,
    String? deepLink,
    DateTime? receivedAt,
    bool? isRead,
    Map<String, dynamic>? rawData,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      reservationId: reservationId ?? this.reservationId,
      ticketCode: ticketCode ?? this.ticketCode,
      deepLink: deepLink ?? this.deepLink,
      receivedAt: receivedAt ?? this.receivedAt,
      isRead: isRead ?? this.isRead,
      rawData: rawData ?? this.rawData,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppNotification &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'AppNotification(id: $id, title: $title, type: $type)';
}

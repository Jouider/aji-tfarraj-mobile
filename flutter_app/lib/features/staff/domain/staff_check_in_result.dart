/// Domain model for a successful staff check-in response
class StaffCheckInResult {
  final String ticketCode;
  final DateTime checkedInAt;
  final int userId;
  final String userName;
  final String userEmail;
  final int showId;
  final String showTitle;
  final String showCity;
  final DateTime showStartsAt;

  const StaffCheckInResult({
    required this.ticketCode,
    required this.checkedInAt,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.showId,
    required this.showTitle,
    required this.showCity,
    required this.showStartsAt,
  });

  factory StaffCheckInResult.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? {};
    final show = json['show'] as Map<String, dynamic>? ?? {};

    return StaffCheckInResult(
      ticketCode: json['ticket_code'] as String? ?? '',
      checkedInAt: DateTime.parse(json['checked_in_at'] as String).toLocal(),
      userId: user['id'] as int? ?? 0,
      userName: user['name'] as String? ?? '',
      userEmail: user['email'] as String? ?? '',
      showId: show['id'] as int? ?? 0,
      showTitle: show['title'] as String? ?? '',
      showCity: show['city'] as String? ?? '',
      showStartsAt: DateTime.parse(show['starts_at'] as String).toLocal(),
    );
  }
}

// A drop-off point offered at the door. Shared by the two places that put the
// question — scanning a booked ticket, and registering a walk-in — so the two
// can never drift apart on a control that decides who gets a ride home.

/// A drop-off point the shuttle serves for this recording.
class ReturnPointOption {
  final int id;
  final String name;
  final String? nameAr;
  final String? landmark;

  const ReturnPointOption({
    required this.id,
    required this.name,
    this.nameAr,
    this.landmark,
  });

  /// Localised label — falls back to French when no Arabic name is set.
  String localizedName(bool isAr) =>
      (isAr && nameAr != null && nameAr!.isNotEmpty) ? nameAr! : name;

  factory ReturnPointOption.fromJson(Map<String, dynamic> json) =>
      ReturnPointOption(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        nameAr: json['name_ar'] as String?,
        landmark: json['landmark'] as String?,
      );
}

import 'package:aji_tfarraj/features/casting/domain/casting_pose.dart';

/// One shot already in the book.
class CastingPhoto {
  final CastingPose pose;
  final String url;

  const CastingPhoto({required this.pose, required this.url});

  static CastingPhoto? fromJson(Map<String, dynamic> json) {
    final pose = CastingPose.fromKey(json['pose'] as String?);
    final url = json['url'] as String?;
    // A pose this build does not know about is dropped rather than guessed at:
    // showing it in the wrong slot would be worse than not showing it.
    if (pose == null || url == null) return null;
    return CastingPhoto(pose: pose, url: url);
  }
}

/// The member's own book: measurements plus the photo set.
class CastingBook {
  final int? id;
  final int? heightCm;
  final int? weightKg;
  final String? clothingSize;
  final int? shoeSize;

  final List<CastingPhoto> photos;

  /// Required poses still missing. Comes from the server so the app never has
  /// to re-derive the rule.
  final List<CastingPose> missingPoses;

  /// Whether this book can be put forward.
  final bool isComplete;

  const CastingBook({
    this.id,
    this.heightCm,
    this.weightKg,
    this.clothingSize,
    this.shoeSize,
    this.photos = const [],
    this.missingPoses = const [],
    this.isComplete = false,
  });

  /// The shot in a given slot, if it has been taken.
  CastingPhoto? photoFor(CastingPose pose) {
    for (final photo in photos) {
      if (photo.pose == pose) return photo;
    }
    return null;
  }

  bool get hasMeasurements =>
      heightCm != null || weightKg != null || clothingSize != null || shoeSize != null;

  factory CastingBook.fromJson(Map<String, dynamic> json) {
    final profile = json['profile'] as Map<String, dynamic>?;

    return CastingBook(
      id: profile?['id'] as int?,
      heightCm: profile?['height_cm'] as int?,
      weightKg: profile?['weight_kg'] as int?,
      clothingSize: profile?['clothing_size'] as String?,
      shoeSize: profile?['shoe_size'] as int?,
      photos: (json['photos'] as List<dynamic>? ?? const [])
          .map((e) => CastingPhoto.fromJson(e as Map<String, dynamic>))
          .whereType<CastingPhoto>()
          .toList(),
      missingPoses: (json['missing_poses'] as List<dynamic>? ?? const [])
          .map((e) => CastingPose.fromKey(e as String?))
          .whereType<CastingPose>()
          .toList(),
      isComplete: json['is_complete'] as bool? ?? false,
    );
  }
}

/// What kind of thing is being announced.
enum CastingType {
  casting('casting'),
  publication('publication');

  const CastingType(this.key);

  final String key;

  static CastingType fromKey(String? key) =>
      key == 'publication' ? CastingType.publication : CastingType.casting;
}

/// Where an application stands.
enum ApplicationStatus {
  pending('pending'),
  shortlisted('shortlisted'),
  accepted('accepted'),
  rejected('rejected'),

  /// A status a newer server introduced. Shown neutrally rather than guessed.
  unknown('unknown');

  const ApplicationStatus(this.key);

  final String key;

  static ApplicationStatus? fromKey(String? key) {
    if (key == null) return null;
    for (final status in ApplicationStatus.values) {
      if (status.key == key) return status;
    }
    return ApplicationStatus.unknown;
  }
}

/// A call a member can apply to.
class CastingCall {
  final int id;
  final CastingType type;
  final String title;
  final String? titleAr;
  final String? description;
  final String? descriptionAr;
  /// The cover — first in the sequence an admin arranged.
  final String? imageUrl;

  /// Every picture, cover first. Empty for a call with no visual.
  final List<String> imageUrls;

  final String? city;
  final String? gender;
  final int? minAge;
  final int? maxAge;
  final DateTime? closesAt;

  /// Null when this member has not applied.
  final ApplicationStatus? applicationStatus;

  const CastingCall({
    required this.id,
    required this.type,
    required this.title,
    this.titleAr,
    this.description,
    this.descriptionAr,
    this.imageUrl,
    this.imageUrls = const [],
    this.city,
    this.gender,
    this.minAge,
    this.maxAge,
    this.closesAt,
    this.applicationStatus,
  });

  String localizedTitle(bool isAr) =>
      (isAr && titleAr != null && titleAr!.isNotEmpty) ? titleAr! : title;

  String? localizedDescription(bool isAr) =>
      (isAr && descriptionAr != null && descriptionAr!.isNotEmpty)
          ? descriptionAr
          : description;

  bool get hasApplied => applicationStatus != null;

  factory CastingCall.fromJson(Map<String, dynamic> json) => CastingCall(
        id: json['id'] as int,
        type: CastingType.fromKey(json['type'] as String?),
        title: json['title'] as String? ?? '',
        titleAr: json['title_ar'] as String?,
        description: json['description'] as String?,
        descriptionAr: json['description_ar'] as String?,
        imageUrl: json['image_url'] as String?,
        imageUrls: (json['image_urls'] as List<dynamic>? ?? const [])
            .whereType<String>()
            .toList(),
        city: json['city'] as String?,
        gender: json['gender'] as String?,
        minAge: json['min_age'] as int?,
        maxAge: json['max_age'] as int?,
        closesAt: json['closes_at'] is String
            ? DateTime.parse(json['closes_at'] as String).toLocal()
            : null,
        applicationStatus:
            ApplicationStatus.fromKey(json['application_status'] as String?),
      );
}

/// The list of calls, plus why the apply button may be unavailable — carried
/// together so the list screen can explain itself without a second request.
class CastingFeed {
  final List<CastingCall> calls;
  final bool canApply;
  final bool isEligible;

  const CastingFeed({
    this.calls = const [],
    this.canApply = false,
    this.isEligible = false,
  });

  factory CastingFeed.fromJson(Map<String, dynamic> json) => CastingFeed(
        calls: (json['castings'] as List<dynamic>? ?? const [])
            .map((e) => CastingCall.fromJson(e as Map<String, dynamic>))
            .toList(),
        canApply: json['can_apply'] as bool? ?? false,
        isEligible: json['is_eligible'] as bool? ?? false,
      );
}

/// One of my applications.
class MyApplication {
  final int id;
  final ApplicationStatus status;
  final DateTime? appliedAt;
  final bool withdrawable;
  final CastingCall? call;

  const MyApplication({
    required this.id,
    required this.status,
    this.appliedAt,
    this.withdrawable = false,
    this.call,
  });

  factory MyApplication.fromJson(Map<String, dynamic> json) => MyApplication(
        id: json['id'] as int,
        status: ApplicationStatus.fromKey(json['status'] as String?) ??
            ApplicationStatus.unknown,
        appliedAt: json['applied_at'] is String
            ? DateTime.parse(json['applied_at'] as String).toLocal()
            : null,
        withdrawable: json['withdrawable'] as bool? ?? false,
        call: json['casting'] is Map<String, dynamic>
            ? CastingCall.fromJson(json['casting'] as Map<String, dynamic>)
            : null,
      );
}

import 'package:flutter_test/flutter_test.dart';
import 'package:aji_tfarraj/features/casting/domain/casting_models.dart';
import 'package:aji_tfarraj/features/casting/domain/casting_pose.dart';

/// The book decides whether someone can be put forward at all, and the poses
/// decide whether forty books can be compared. A parsing slip here either hides
/// a shot the person took or files it in the wrong slot.
void main() {
  group('the prescribed poses', () {
    /// The keys travel to the server as-is, so renaming one silently breaks
    /// every upload.
    test('their keys match the server contract', () {
      expect(
        CastingPose.values.map((p) => p.key).toList(),
        ['full_front', 'full_profile', 'portrait', 'full_back', 'portrait_smile'],
      );
    });

    test('three are required, two are not', () {
      expect(CastingPose.required, hasLength(3));
      expect(CastingPose.fullFront.isRequired, isTrue);
      expect(CastingPose.fullProfile.isRequired, isTrue);
      expect(CastingPose.portrait.isRequired, isTrue);
      expect(CastingPose.fullBack.isRequired, isFalse);
      expect(CastingPose.portraitSmile.isRequired, isFalse);
    });

    /// The camera guide is drawn from this: a portrait framed as a full length
    /// tells the person to step back out of their own shot.
    test('full-length poses are told apart from portraits', () {
      expect(CastingPose.fullFront.isFullLength, isTrue);
      expect(CastingPose.fullProfile.isFullLength, isTrue);
      expect(CastingPose.fullBack.isFullLength, isTrue);
      expect(CastingPose.portrait.isFullLength, isFalse);
      expect(CastingPose.portraitSmile.isFullLength, isFalse);
    });

    test('an unknown key resolves to nothing rather than to a wrong pose', () {
      expect(CastingPose.fromKey('full_front'), CastingPose.fullFront);
      expect(CastingPose.fromKey('lying_down'), isNull);
      expect(CastingPose.fromKey(null), isNull);
    });
  });

  group('reading the book', () {
    Map<String, dynamic> payload({
      List<Map<String, dynamic>>? photos,
      List<String>? missing,
      bool complete = false,
      Map<String, dynamic>? profile,
    }) =>
        {
          'profile': profile ??
              {
                'id': 7,
                'height_cm': 178,
                'weight_kg': 70,
                'clothing_size': 'M',
                'shoe_size': 42,
              },
          'photos': photos ??
              [
                {'pose': 'full_front', 'url': 'https://x/1.jpg', 'required': true},
              ],
          'missing_poses': missing ?? ['full_profile', 'portrait'],
          'is_complete': complete,
        };

    test('parses the measurements and the shots', () {
      final book = CastingBook.fromJson(payload());

      expect(book.heightCm, 178);
      expect(book.clothingSize, 'M');
      expect(book.shoeSize, 42);
      expect(book.hasMeasurements, isTrue);
      expect(book.photoFor(CastingPose.fullFront)?.url, 'https://x/1.jpg');
      expect(book.photoFor(CastingPose.portrait), isNull);
    });

    /// Completeness is the server's call, not the app's: re-deriving it here
    /// would let the two disagree about who is allowed to apply.
    test('completeness comes from the server', () {
      expect(CastingBook.fromJson(payload()).isComplete, isFalse);
      expect(
        CastingBook.fromJson(payload(missing: [], complete: true)).isComplete,
        isTrue,
      );
    });

    test('missing poses are read back as poses, not strings', () {
      final book = CastingBook.fromJson(payload());

      expect(book.missingPoses,
          [CastingPose.fullProfile, CastingPose.portrait]);
    });

    /// A pose a newer server introduced is dropped rather than guessed at:
    /// showing it in the wrong slot would be worse than not showing it.
    test('a pose this build does not know is dropped', () {
      final book = CastingBook.fromJson(payload(photos: [
        {'pose': 'full_front', 'url': 'https://x/1.jpg'},
        {'pose': 'hands_close_up', 'url': 'https://x/2.jpg'},
      ]));

      expect(book.photos, hasLength(1));
      expect(book.photos.single.pose, CastingPose.fullFront);
    });

    test('a photo with no url is dropped', () {
      final book = CastingBook.fromJson(payload(photos: [
        {'pose': 'portrait'},
      ]));

      expect(book.photos, isEmpty);
    });

    /// Someone who has not started yet still gets a usable screen.
    test('an empty book parses', () {
      final book = CastingBook.fromJson({
        'profile': null,
        'photos': [],
        'missing_poses': ['full_front', 'full_profile', 'portrait'],
        'is_complete': false,
      });

      expect(book.id, isNull);
      expect(book.hasMeasurements, isFalse);
      expect(book.photos, isEmpty);
      expect(book.missingPoses, hasLength(3));
    });
  });

  group('calls', () {
    Map<String, dynamic> call({
      String type = 'casting',
      String? titleAr,
      String? status,
    }) =>
        {
          'id': 3,
          'type': type,
          'title': 'Figuration série ramadan',
          'title_ar': titleAr,
          'description': 'On cherche des figurants.',
          'image_url': 'https://x/a.jpg',
          'image_urls': ['https://x/a.jpg', 'https://x/b.jpg'],
          'city': 'Casablanca',
          'min_age': 18,
          'max_age': 35,
          'closes_at': '2026-10-01T00:00:00',
          'application_status': status,
        };

    test('parses a call', () {
      final c = CastingCall.fromJson(call());

      expect(c.type, CastingType.casting);
      expect(c.city, 'Casablanca');
      expect(c.minAge, 18);
      expect(c.closesAt, isNotNull);
      expect(c.hasApplied, isFalse);
    });

    test('a publication is told apart from a casting', () {
      expect(CastingCall.fromJson(call(type: 'publication')).type,
          CastingType.publication);
      // An unknown type falls back to casting rather than breaking the list.
      expect(CastingCall.fromJson(call(type: 'something_new')).type,
          CastingType.casting);
    });

    test('the Arabic title falls back to French when absent', () {
      expect(CastingCall.fromJson(call(titleAr: 'كاستينغ')).localizedTitle(true),
          'كاستينغ');
      expect(CastingCall.fromJson(call()).localizedTitle(true),
          'Figuration série ramadan');
    });

    /// The cover is what the list shows; the whole series is what the detail
    /// screen swipes through.
    test('carries the cover and the whole series', () {
      final c = CastingCall.fromJson(call());

      expect(c.imageUrl, 'https://x/a.jpg');
      expect(c.imageUrls, ['https://x/a.jpg', 'https://x/b.jpg']);
      expect(c.imageUrls.first, c.imageUrl,
          reason: 'the cover is the first picture');
    });

    /// An older server, or a call with no visual, must not crash the gallery.
    test('a call with no pictures parses to an empty series', () {
      final c = CastingCall.fromJson({'id': 1, 'title': 'Sans visuel'});

      expect(c.imageUrl, isNull);
      expect(c.imageUrls, isEmpty);
    });

    test('an application status is carried through', () {
      final c = CastingCall.fromJson(call(status: 'shortlisted'));

      expect(c.hasApplied, isTrue);
      expect(c.applicationStatus, ApplicationStatus.shortlisted);
    });

    /// A status a newer server introduced must not read as "not applied" —
    /// that would offer the apply button to someone who already did.
    test('an unknown status still counts as applied', () {
      final c = CastingCall.fromJson(call(status: 'on_hold'));

      expect(c.applicationStatus, ApplicationStatus.unknown);
      expect(c.hasApplied, isTrue);
    });
  });

  group('the feed', () {
    test('carries why applying may be unavailable', () {
      final feed = CastingFeed.fromJson({
        'castings': [],
        'can_apply': false,
        'is_eligible': true,
      });

      expect(feed.calls, isEmpty);
      expect(feed.canApply, isFalse);
      expect(feed.isEligible, isTrue);
    });

    /// Defaults must be the cautious ones: an older payload must not make the
    /// app think an ineligible account can apply.
    test('a payload missing the flags does not assume permission', () {
      final feed = CastingFeed.fromJson({'castings': []});

      expect(feed.canApply, isFalse);
      expect(feed.isEligible, isFalse);
    });
  });

  group('my applications', () {
    test('parses one, with whether it can still be withdrawn', () {
      final a = MyApplication.fromJson({
        'id': 12,
        'status': 'pending',
        'applied_at': '2026-09-10T12:00:00',
        'withdrawable': true,
        'casting': {'id': 3, 'type': 'casting', 'title': 'Figuration'},
      });

      expect(a.id, 12);
      expect(a.status, ApplicationStatus.pending);
      expect(a.withdrawable, isTrue);
      expect(a.call?.title, 'Figuration');
    });

    /// Withdrawal is the server's call. Defaulting to true would offer a button
    /// that erases a decision someone already made.
    test('withdrawable defaults to false when the server is silent', () {
      final a = MyApplication.fromJson({'id': 1, 'status': 'accepted'});

      expect(a.withdrawable, isFalse);
      expect(a.call, isNull);
    });
  });

  /// What a member reads on opening a call. Before this, the description never
  /// reached the app at all: the list carried none, and the detail screen was
  /// built from the list.
  group('opening a call', () {
    Map<String, dynamic> detail({
      List<String>? rules,
      List<String>? rulesAr,
      String? eventAt = '2026-09-20T13:00:00.000000Z',
      String? location = 'Studio 2M, Aïn Sebaâ',
      String? compensation = '500 DH / jour',
    }) =>
        {
          'id': 3,
          'type': 'casting',
          'title': 'Figuration',
          'description': 'Figuration pour une série.',
          'rules': rules ?? ['Être à l\'heure', 'Pièce d\'identité'],
          'rules_ar': rulesAr ?? <String>[],
          'event_at': eventAt,
          'location': location,
          'compensation': compensation,
        };

    test('parses the description, the rules and the practical details', () {
      final c = CastingCall.fromJson(detail());

      expect(c.description, 'Figuration pour une série.');
      expect(c.rules, ['Être à l\'heure', 'Pièce d\'identité']);
      expect(c.eventAt, isNotNull);
      expect(c.location, 'Studio 2M, Aïn Sebaâ');
      expect(c.compensation, '500 DH / jour');
      expect(c.hasPracticalInfo, isTrue);
    });

    /// Arabic readers must not lose rules that only exist in French.
    test('Arabic rules fall back to French when there are none', () {
      final c = CastingCall.fromJson(detail());

      expect(c.localizedRules(true), c.rules);
      expect(
        CastingCall.fromJson(detail(rulesAr: ['كن في الوقت']))
            .localizedRules(true),
        ['كن في الوقت'],
      );
    });

    test('a call with no practical details has no card to show', () {
      final c = CastingCall.fromJson(
          detail(eventAt: null, location: null, compensation: null));

      expect(c.hasPracticalInfo, isFalse);
    });

    /// An empty string from the admin is not information.
    test('blank location and pay do not count as details', () {
      final c = CastingCall.fromJson(
          detail(eventAt: null, location: '', compensation: ''));

      expect(c.hasPracticalInfo, isFalse);
    });

    /// A list payload carries none of this; parsing it must not invent any.
    test('a list card parses with no rules and no details', () {
      final c = CastingCall.fromJson(
          {'id': 1, 'type': 'casting', 'title': 'Carte de liste'});

      expect(c.rules, isEmpty);
      expect(c.rulesAr, isEmpty);
      expect(c.eventAt, isNull);
      expect(c.hasPracticalInfo, isFalse);
    });
  });

  /// The studio star. Only the final state is ever sent to the app; being
  /// shortlisted is staff's business, so the model has no field for it.
  group('the studio star', () {
    Map<String, dynamic> book({Map<String, dynamic>? studio}) => {
          'profile': {'id': 7},
          'photos': [],
          'missing_poses': [],
          'is_complete': true,
          if (studio != null) 'studio': studio,
        };

    test('a book photographed at the studio carries its star and date', () {
      final b = CastingBook.fromJson(
          book(studio: {'verified': true, 'shot_on': '2026-09-10'}));

      expect(b.studioVerified, isTrue);
      expect(b.studioShotOn, DateTime(2026, 9, 10));
    });

    test('a book not photographed has no star', () {
      final b = CastingBook.fromJson(
          book(studio: {'verified': false, 'shot_on': null}));

      expect(b.studioVerified, isFalse);
      expect(b.studioShotOn, isNull);
    });

    /// An older server sends no studio block; that must read as "no star",
    /// never as a star.
    test('no studio block reads as no star', () {
      final b = CastingBook.fromJson(book());

      expect(b.studioVerified, isFalse);
      expect(b.studioShotOn, isNull);
    });
  });
}

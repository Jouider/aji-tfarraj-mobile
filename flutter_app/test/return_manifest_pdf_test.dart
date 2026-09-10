import 'package:flutter_test/flutter_test.dart';
import 'package:aji_tfarraj/features/staff/data/return_manifest_export.dart';
import 'package:aji_tfarraj/features/staff/domain/return_manifest.dart';

/// The PDF is built from a bundled font asset. If that asset ever stops being
/// shipped, nothing fails at compile time — the export just throws in the
/// scanner's hands at the end of a recording, which is the worst moment to
/// find out.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ReturnManifest sample() => ReturnManifest.fromJson({
        'episode': {
          'id': 10,
          'title': 'الحلقة 12',
          'starts_at': '2026-09-09T19:00:00',
          'studio': 'Studio 2M Ain Sebaa',
          'city': 'Casablanca',
        },
        'show': {'id': 1, 'title': 'ساعة صراحة'},
        'generated_at': '2026-09-09T23:10:00',
        'has_shuttle': true,
        'totals': {
          'checked_in_people': 42,
          'checked_in_tickets': 30,
          'riders': 26,
          'own_means': 16,
        },
        'points': [
          {
            'id': 1,
            'name': 'Ain Sebaa',
            'name_ar': 'عين السبع',
            'landmark': 'devant la gare',
            'served': true,
            'people': 14,
            'tickets': 9,
            'passengers': [
              // A booking is one seat now; an older multi-seat row must still
              // render rather than silently under-report the driver's load.
              {'name': 'Ahmed Bennani', 'seats': 3},
              // A name in Arabic script must not blow the builder up: the
              // built-in PDF fonts have no Arabic glyphs, which is exactly why
              // Cairo is bundled.
              {'name': 'سلمى الإدريسي', 'seats': 1},
            ],
          },
          {
            'id': 3,
            'name': 'Zenata',
            'served': true,
            'people': 0,
            'tickets': 0,
            'passengers': [],
          },
          {
            'id': 4,
            'name': 'Sidi Moumen',
            'served': false,
            'people': 2,
            'tickets': 1,
            'passengers': [
              {'name': 'Karim Tazi', 'seats': 2},
            ],
          },
        ],
      });

  test('builds a real PDF, Arabic names and all', () async {
    final bytes = await ReturnManifestExport.pdfBytes(sample());

    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    expect(bytes.length, greaterThan(5000), reason: 'fonts must be embedded');
  });

  test('builds even when nobody is waiting', () async {
    final empty = ReturnManifest.fromJson({
      'episode': {'id': 1},
      'has_shuttle': true,
      'points': [],
    });

    final bytes = await ReturnManifestExport.pdfBytes(empty);

    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });

  /// The file lands in a share sheet and then in someone's downloads, so the
  /// name has to say which recording it belongs to.
  test('the file name carries the recording date', () {
    expect(
      ReturnManifestExport.fileName(sample()),
      'retour-navette_2026-09-09_1900.pdf',
    );
  });
}

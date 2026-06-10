import 'package:flutter_test/flutter_test.dart';
import 'package:aji_tfarraj/features/app_update/data/app_update_service.dart';

void main() {
  group('isVersionOlder', () {
    test('older patch / minor / major', () {
      expect(isVersionOlder('1.0.7', '1.0.8'), isTrue);
      expect(isVersionOlder('1.0.7', '1.1.0'), isTrue);
      expect(isVersionOlder('1.0.7', '2.0.0'), isTrue);
    });

    test('equal is not older', () {
      expect(isVersionOlder('1.0.7', '1.0.7'), isFalse);
    });

    test('newer is not older', () {
      expect(isVersionOlder('1.2.0', '1.1.9'), isFalse);
      expect(isVersionOlder('1.0.10', '1.0.9'), isFalse);
    });

    test('numeric (not lexical) comparison: 1.0.10 > 1.0.9', () {
      expect(isVersionOlder('1.0.9', '1.0.10'), isTrue);
    });

    test('ignores build metadata and suffixes', () {
      expect(isVersionOlder('1.0.7+28', '1.0.8+1'), isTrue);
      expect(isVersionOlder('1.0.7-beta', '1.0.7'), isFalse);
    });

    test('handles missing segments as zero', () {
      expect(isVersionOlder('1.0', '1.0.1'), isTrue);
      expect(isVersionOlder('1', '1.0.0'), isFalse);
    });
  });
}

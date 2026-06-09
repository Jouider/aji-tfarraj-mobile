import 'dart:io';
import 'package:integration_test/integration_test_driver_extended.dart';

/// Driver entry point — runs on the host machine (not the device).
/// Receives screenshot bytes from the test and saves them to screenshots/.
Future<void> main() => integrationDriver(
      onScreenshot: (
        String screenshotName,
        List<int> screenshotBytes, [
        Map<String, Object?>? args,
      ]) async {
        final dir = Directory('screenshots');
        if (!dir.existsSync()) {
          dir.createSync(recursive: true);
        }
        final file = File('screenshots/$screenshotName.png');
        file.writeAsBytesSync(screenshotBytes);
        // ignore: avoid_print
        print('[screenshot] ✅ screenshots/$screenshotName.png');
        return true;
      },
    );

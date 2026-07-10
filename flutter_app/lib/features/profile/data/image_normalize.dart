import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Bakes EXIF orientation into the pixels and resizes a captured photo,
/// returning the path to a normalized upright JPEG.
///
/// The `camera` plugin saves front-camera photos with an EXIF orientation flag
/// that ML Kit's `InputImage.fromFilePath` doesn't apply — so faces look
/// sideways and detection fails. Baking the orientation fixes detection and
/// also stops the uploaded avatar from displaying rotated. Falls back to the
/// original path on any failure.
Future<String> normalizeCapturedImage(
  String path, {
  int maxSide = 1024,
  int quality = 85,
}) async {
  try {
    final bytes = await File(path).readAsBytes();
    var decoded = img.decodeImage(bytes);
    if (decoded == null) return path;

    // Apply EXIF orientation so the pixels are upright.
    decoded = img.bakeOrientation(decoded);

    // Cap the longest side to keep the upload small.
    if (decoded.width > maxSide || decoded.height > maxSide) {
      decoded = decoded.width >= decoded.height
          ? img.copyResize(decoded, width: maxSide)
          : img.copyResize(decoded, height: maxSide);
    }

    final out = File('${path}_norm.jpg');
    await out.writeAsBytes(img.encodeJpg(decoded, quality: quality));
    return out.path;
  } catch (e) {
    debugPrint('[ImageNormalize] error: $e');
    return path;
  }
}

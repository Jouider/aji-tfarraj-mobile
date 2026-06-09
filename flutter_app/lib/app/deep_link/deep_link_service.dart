import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Service that listens for incoming deep links (Universal Links / App Links)
/// and routes referral magic links (/r/{token}) to the appropriate screen.
class DeepLinkService {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;
  GoRouter? _router;

  /// Initialize with a GoRouter instance. Call once from main.
  void init(GoRouter router) {
    _router = router;

    // Handle link that opened the app from terminated state
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) _handleUri(uri);
    });

    // Handle links while the app is running
    _sub = _appLinks.uriLinkStream.listen(_handleUri);
  }

  void _handleUri(Uri uri) {
    if (kDebugMode) {
      debugPrint('[DeepLinkService] Received URI: $uri');
    }

    try {
      // The Google OAuth callback (ajitfarraj://oauth?id_token=…) is consumed by
      // the dedicated listener in AuthRepository.loginWithGoogle — never route it
      // here. Guard explicitly so this custom-scheme URI is always ignored and
      // never reaches go_router (whose parser throws on non-http(s) schemes).
      if (uri.scheme == 'ajitfarraj' && uri.host == 'oauth') {
        return;
      }

      // Match /r/{token} referral magic links (works for both the https App Link
      // and any custom-scheme variant — we only read pathSegments, never origin).
      if (uri.pathSegments.length == 2 && uri.pathSegments[0] == 'r') {
        final token = uri.pathSegments[1];
        if (token.isNotEmpty) {
          _router?.go('/r/$token');
        }
      }
      // Any other/malformed link is intentionally ignored.
    } catch (e) {
      // Never let a bad deep link crash the app.
      if (kDebugMode) {
        debugPrint('[DeepLinkService] Ignored malformed URI "$uri": $e');
      }
    }
  }

  void dispose() {
    _sub?.cancel();
  }
}

/// Global singleton provider for [DeepLinkService]
final deepLinkServiceProvider = Provider<DeepLinkService>((ref) {
  final service = DeepLinkService();
  ref.onDispose(() => service.dispose());
  return service;
});

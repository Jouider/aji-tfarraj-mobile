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

    // Match /r/{token} pattern
    if (uri.pathSegments.length == 2 && uri.pathSegments[0] == 'r') {
      final token = uri.pathSegments[1];
      if (token.isNotEmpty) {
        _router?.go('/r/$token');
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

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Riverpod observer that captures provider errors and state transitions.
///
/// In debug mode errors are printed to the console.
/// In release mode they are reported via [FlutterError.reportError], which
/// can be forwarded to Crashlytics or any other crash reporter by setting
/// [FlutterError.onError] in main.dart once the package is added.
class AppProviderObserver extends ProviderObserver {
  const AppProviderObserver();

  @override
  void providerDidFail(
    ProviderBase<Object?> provider,
    Object error,
    StackTrace stackTrace,
    ProviderContainer container,
  ) {
    if (kDebugMode) {
      debugPrint(
        '[ProviderObserver] ${provider.name ?? provider.runtimeType} failed: $error',
      );
    } else {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'riverpod',
          context: ErrorDescription(
            'Error in provider: ${provider.name ?? provider.runtimeType}',
          ),
        ),
      );
    }
  }
}

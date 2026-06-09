import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:aji_tfarraj/app/config/app_config.dart';
import 'package:aji_tfarraj/firebase_options.dart';
import 'package:aji_tfarraj/app/router.dart';
import 'package:aji_tfarraj/app/localization/locale_provider.dart';
import 'package:aji_tfarraj/app/push/push_service.dart';
import 'package:aji_tfarraj/app/push/push_token_provider.dart';
import 'package:aji_tfarraj/app/deep_link/deep_link_service.dart';
import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/theme.dart';
import 'package:aji_tfarraj/app/theme/theme_mode_provider.dart';
import 'package:aji_tfarraj/app/monitoring/provider_observer.dart';
import 'package:aji_tfarraj/features/notifications/data/notification_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Android 15+ (SDK 35/36) enforces edge-to-edge. Opt in explicitly and use
  // fully transparent system bars so content draws behind them consistently
  // across Android versions (screens handle insets via SafeArea).
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarContrastEnforced: false,
  ));

  // Initialize French and Arabic locale data for date formatting
  await initializeDateFormatting('fr_FR', null);
  await initializeDateFormatting('ar', null);

  // Initialize SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();

  // Initialize Firebase with platform-specific options
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize Push Service after Firebase
    await PushService.instance.init();
  } catch (e) {
    // Firebase initialization may fail in development without proper config
    // App should continue to work without push notifications
    debugPrint('[Main] Firebase/Push init error (expected in dev): $e');
  }

  Widget buildApp() => ProviderScope(
        observers: const [AppProviderObserver()],
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        ],
        child: const AjiTfarrajApp(),
      );

  // Initialize Sentry when a DSN is provided (--dart-define=SENTRY_DSN=...).
  // The appRunner closure enables automatic capture of uncaught Flutter/Dart
  // errors (zone + FlutterError). Without a DSN, run the app directly.
  if (AppConfig.sentryEnabled) {
    await SentryFlutter.init(
      (options) {
        options.dsn = AppConfig.sentryDsn;
        options.environment = AppConfig.sentryEnvironment;
        options.tracesSampleRate = 0.2; // 20% of transactions
        options.sendDefaultPii = false; // GDPR — no PII by default
        // Drop expected 401s before they ever leave the device. Token expiry is
        // a normal, handled condition (ApiClient refreshes or redirects to
        // login), so a 401 must never surface as a Sentry error — regardless of
        // which Dio instance threw it. See GitHub issue #2.
        options.beforeSend = (event, hint) {
          final exc = event.throwable;
          if (exc is DioException && exc.response?.statusCode == 401) {
            return null;
          }
          return event;
        };
      },
      appRunner: () => runApp(buildApp()),
    );
  } else {
    runApp(buildApp());
  }
}

class AjiTfarrajApp extends ConsumerStatefulWidget {
  const AjiTfarrajApp({super.key, this.initializePushServices = true});

  /// Whether to wire up Firebase push notifications and deep-link handling
  /// after the first frame. Always `true` in production; widget tests pass
  /// `false` so the smoke test can build the app without a Firebase app or
  /// the platform channels (FCM, app_links) that aren't available off-device.
  final bool initializePushServices;

  @override
  ConsumerState<AjiTfarrajApp> createState() => _AjiTfarrajAppState();
}

class _AjiTfarrajAppState extends ConsumerState<AjiTfarrajApp> {
  @override
  void initState() {
    super.initState();
    if (!widget.initializePushServices) return;
    // Initialize push token after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePushServices();
    });
  }

  void _initializePushServices() {
    // Initialize FCM token
    ref.read(pushTokenProvider.notifier).initialize();

    // Set router for push navigation
    final router = ref.read(routerProvider);
    PushService.instance.setRouter(router);

    // Initialize deep link service for referral magic links
    ref.read(deepLinkServiceProvider).init(router);
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(flutterLocaleProvider);
    final textDirection = ref.watch(textDirectionProvider);
    final themeMode = ref.watch(themeModeProvider);

    // Resolve actual brightness BEFORE building ThemeData so that
    // AppColors / AppTypography getters return the correct values
    // when AppTheme.lightTheme / darkTheme are evaluated.
    final platformBrightness =
        MediaQuery.platformBrightnessOf(context);
    final resolvedBrightness = switch (themeMode) {
      ThemeMode.light => Brightness.light,
      ThemeMode.dark => Brightness.dark,
      ThemeMode.system => platformBrightness,
    };
    AppColors.updateBrightness(resolvedBrightness);

    // Set context and ref for PushService
    if (widget.initializePushServices) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          PushService.instance.setContext(context);
          PushService.instance.setRef(ref);
        }
      });
    }

    return Directionality(
      textDirection: textDirection,
      child: MaterialApp.router(
        title: 'Aji Tfarraj',
        debugShowCheckedModeBanner: false,
        locale: locale,
        supportedLocales: const [
          Locale('fr'),
          Locale('ar'),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        routerConfig: router,
        // AppColors uses static brightness state, so descendants that read
        // AppColors.xxx directly (instead of Theme.of) don't rebuild on
        // theme change. Keying the navigator subtree by resolved brightness
        // forces a full rebuild so every screen picks up the new colors.
        builder: (context, child) => KeyedSubtree(
          key: ValueKey(resolvedBrightness),
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}

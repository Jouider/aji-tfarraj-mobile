import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:aji_tfarraj/firebase_options.dart';
import 'package:aji_tfarraj/app/router.dart';
import 'package:aji_tfarraj/app/localization/locale_provider.dart';
import 'package:aji_tfarraj/app/push/push_service.dart';
import 'package:aji_tfarraj/app/push/push_token_provider.dart';
import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/monitoring/provider_observer.dart';
import 'package:aji_tfarraj/features/notifications/data/notification_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
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
  
  runApp(
    ProviderScope(
      observers: const [AppProviderObserver()],
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const AjiTfarrajApp(),
    ),
  );
}

class AjiTfarrajApp extends ConsumerStatefulWidget {
  const AjiTfarrajApp({super.key});

  @override
  ConsumerState<AjiTfarrajApp> createState() => _AjiTfarrajAppState();
}

class _AjiTfarrajAppState extends ConsumerState<AjiTfarrajApp> {
  @override
  void initState() {
    super.initState();
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
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(flutterLocaleProvider);
    final textDirection = ref.watch(textDirectionProvider);

    // Set context and ref for PushService
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        PushService.instance.setContext(context);
        PushService.instance.setRef(ref);
      }
    });

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
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: AppColors.backgroundWhite,
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primary,
            secondary: AppColors.secondary,
            surface: AppColors.backgroundGrey,
            onPrimary: Colors.white,
            onSecondary: Colors.black,
            onSurface: AppColors.textPrimary,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.backgroundWhite,
            foregroundColor: AppColors.textPrimary,
            elevation: 0,
            scrolledUnderElevation: 0,
            iconTheme: IconThemeData(color: AppColors.textPrimary),
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: AppColors.backgroundWhite,
            selectedItemColor: AppColors.secondary,
            unselectedItemColor: AppColors.textLight,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
          ),
          cardTheme: const CardThemeData(
            color: AppColors.backgroundGrey,
            elevation: 0,
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: AppColors.backgroundGrey,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.secondary, width: 1.5),
            ),
            hintStyle: const TextStyle(color: AppColors.textLight),
          ),
          dividerTheme: const DividerThemeData(
            color: AppColors.divider,
            space: 1,
            thickness: 1,
          ),
          chipTheme: ChipThemeData(
            backgroundColor: AppColors.backgroundGrey,
            selectedColor: AppColors.primary,
            labelStyle: const TextStyle(color: AppColors.textSecondary),
            side: const BorderSide(color: AppColors.border),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          ),
        ),
        routerConfig: router,
      ),
    );
  }
}

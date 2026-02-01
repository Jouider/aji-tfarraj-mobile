import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:aji_tfarraj/app/router.dart';
import 'package:aji_tfarraj/app/localization/locale_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize French and Arabic locale data for date formatting
  await initializeDateFormatting('fr_FR', null);
  await initializeDateFormatting('ar', null);
  
  runApp(
    const ProviderScope(
      child: AjiTfarrajApp(),
    ),
  );
}

class AjiTfarrajApp extends ConsumerWidget {
  const AjiTfarrajApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(flutterLocaleProvider);
    final textDirection = ref.watch(textDirectionProvider);

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
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        routerConfig: router,
      ),
    );
  }
}

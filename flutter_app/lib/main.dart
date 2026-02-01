import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:aji_tfarraj/app/router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize French locale data for date formatting
  await initializeDateFormatting('fr_FR', null);
  
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

    return MaterialApp.router(
      title: 'Aji Tfarraj',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}

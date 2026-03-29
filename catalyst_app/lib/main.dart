import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/app_observer.dart';
import 'core/router.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // NOTE: Replace these with your actual Supabase credentials to run the app.
  try {
    await Supabase.initialize(
      url: 'https://placeholder.supabase.co',
      anonKey: 'placeholder_key',
    );
  } catch (e) {
    debugPrint('Supabase initialization failed: $e');
  }

  runZonedGuarded(() {
    runApp(
      ProviderScope(
        observers: [AppProviderObserver()],
        child: const MyApp(),
      ),
    );
  }, (error, stack) {
    debugPrint('❗ Uncaught error: $error');
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Catalyst App',
      theme: AppTheme.darkTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

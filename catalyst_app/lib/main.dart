import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/app_observer.dart';
import 'core/router.dart';
import 'core/state/theme_provider.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  final bool hasSupabaseConfig =
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  try {
    if (hasSupabaseConfig) {
      await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
    } else {
      debugPrint(
        'Missing SUPABASE_URL or SUPABASE_ANON_KEY. '
        'Pass them using --dart-define.',
      );
    }
  } catch (e) {
    debugPrint('Supabase initialization failed: $e');
  }

  runZonedGuarded(
    () {
      runApp(
        ProviderScope(
          observers: [AppProviderObserver()],
          child: MyApp(hasSupabaseConfig: hasSupabaseConfig),
        ),
      );
    },
    (error, stack) {
      debugPrint('Uncaught error: $error');
    },
  );
}

class MyApp extends ConsumerWidget {
  final bool hasSupabaseConfig;

  const MyApp({super.key, required this.hasSupabaseConfig});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    if (!hasSupabaseConfig) {
      return MaterialApp(
        title: 'Catalyst App',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        debugShowCheckedModeBanner: false,
        home: const _ConfigErrorScreen(),
      );
    }

    return MaterialApp.router(
      title: 'Catalyst App',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

class _ConfigErrorScreen extends StatelessWidget {
  const _ConfigErrorScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Missing app configuration.\n'
            'Start with --dart-define=SUPABASE_URL=... '
            'and --dart-define=SUPABASE_ANON_KEY=...',
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.colorScheme.onSurface),
          ),
        ),
      ),
    );
  }
}

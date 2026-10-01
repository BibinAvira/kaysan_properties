import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'providers/theme_provider.dart';

void main() {
  final WidgetsBinding binding = WidgetsFlutterBinding.ensureInitialized();
  // Keep the native launch screen (logo on white) up until SplashView knows
  // whether there's a saved session — a returning user then goes straight
  // to Home without ever seeing the Flutter welcome screen.
  FlutterNativeSplash.preserve(widgetsBinding: binding);
  runApp(const ProviderScope(child: KaysanPropertiesApp()));
}

/// Root widget. Kept intentionally thin — theming, routing and DI are all
/// delegated to `core/` and `providers/`, per the MVC separation of
/// concerns described in the project README.
class KaysanPropertiesApp extends ConsumerWidget {
  const KaysanPropertiesApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeMode themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Kaysan Properties',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}

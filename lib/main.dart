import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/config/app_config.dart';
import 'core/router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'providers/auth_provider.dart';
import 'providers/currency_provider.dart';
import 'providers/property_provider.dart';
import 'providers/notification_provider.dart';
import 'services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!AppConfig.isConfigured) {
    runApp(const _ConfigError());
    return;
  }

  // Initialize Supabase, but never let a failure leave the app hanging on the
  // HTML loader. If init throws (bad key, network/CORS), show an error screen.
  String? initError;
  try {
    await SupabaseService.initialize();
  } catch (e) {
    initError = e.toString();
  }

  if (initError != null) {
    runApp(_InitError(message: initError));
    return;
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CurrencyProvider()),
        ChangeNotifierProvider(create: (_) => PropertyProvider()),
        ChangeNotifierProxyProvider<AuthProvider, NotificationProvider>(
          create: (_) => NotificationProvider(),
          update: (_, auth, notifications) {
            // Rebind the realtime stream whenever auth state changes so a
            // freshly logged-in user starts receiving notifications (and a
            // logged-out one stops).
            notifications?.refreshBinding();
            return notifications!;
          },
        ),
      ],
      child: const MatchSpaceApp(),
    ),
  );
}

class MatchSpaceApp extends StatelessWidget {
  const MatchSpaceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Match Space',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      onGenerateRoute: AppRouter.onGenerateRoute,
      initialRoute: '/',
    );
  }
}

/// Shown when Supabase keys haven't been pasted into app_config.dart.
class _ConfigError extends StatelessWidget {
  const _ConfigError();
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: AppColors.canvas,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.key_off_outlined,
                      size: 48, color: AppColors.terracotta),
                  const SizedBox(height: 16),
                  Text('Add your Supabase keys',
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center),
                  const SizedBox(height: 10),
                  const Text(
                    'Open lib/core/config/app_config.dart and paste your '
                    'Supabase anon key (and optionally pass keys with '
                    '--dart-define). Then restart the app.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.inkSoft, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shown when Supabase initialization fails at startup — so the app never
/// hangs on the HTML loader. Displays the underlying error for debugging.
class _InitError extends StatelessWidget {
  final String message;
  const _InitError({required this.message});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: AppColors.canvas,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off_outlined,
                      size: 48, color: AppColors.terracotta),
                  const SizedBox(height: 16),
                  const Text('Couldn\u2019t connect',
                      style: TextStyle(
                          fontSize: 24, fontWeight: FontWeight.w700),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 10),
                  const Text(
                    'The app started but couldn\u2019t reach Supabase. Check the '
                    'project URL and anon key, and that the project is active.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.inkSoft, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(message,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.inkFaint)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

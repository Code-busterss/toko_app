// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:toko_app/core/app_router.dart';
import 'package:toko_app/core/database_service.dart';
import 'package:toko_app/features/notifications/notification_service.dart';
import 'package:toko_app/features/settings/providers/settings_notifier.dart';
import 'package:toko_app/firebase_options.dart';

import 'core/theme/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (Auth only).
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Warm up the local database so first screen does not stall.
  await DatabaseService.instance.database;

  // Initialize local notifications.
  await NotificationService().init();

  runApp(
    const ProviderScope(
      child: TokoApp(),
    ),
  );
}

class TokoApp extends ConsumerWidget {
  const TokoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: 'Toko App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: AppRouter.router,
    );
  }
}

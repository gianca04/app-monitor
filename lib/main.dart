import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/router/app_router.dart';
import 'core/router/root_navigator_key.dart';
import 'core/theme_config.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/projectslocal/data/models/project_hive_model.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'features/camera/application/services/location_service.dart';

import 'core/constants/api_constants.dart';
import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sharedPreferences = await SharedPreferences.getInstance();

  // Load saved API Base URL
  final savedApiUrl = sharedPreferences.getString('api_base_url');
  if (savedApiUrl != null && savedApiUrl.isNotEmpty) {
    ApiConstants.baseUrl = savedApiUrl;
  }

  // Initialize Notifications
  await NotificationService().init();

  // Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(ProjectHiveModelAdapter()); // Register the adapter

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const MainApp(),
    ),
  );
}

class MainApp extends ConsumerStatefulWidget {
  const MainApp({super.key});

  @override
  ConsumerState<MainApp> createState() => _MainAppState();
}

class _MainAppState extends ConsumerState<MainApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Inicializar y forzar actualización al abrir la app
    LocationService().initialize();
    LocationService().forceUpdate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      LocationService().forceUpdate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = appRouter(ref);
    return MaterialApp.router(
      title: 'Industrial App',
      theme: AppTheme.industrialTheme,
      routerConfig: router,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', ''), Locale('es', '')],
      locale: const Locale('es', ''),
    );
  }
}

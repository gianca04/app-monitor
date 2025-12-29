import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/router/app_router.dart';
import 'core/theme_config.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/projectslocal/data/models/project_hive_model.dart';
import 'features/photoslocal/data/models/photo_local_model.dart';
import 'features/photoslocal/data/models/after_work_model.dart';
import 'features/photoslocal/data/models/before_work_model.dart';
import 'features/photoslocal/data/models/timestamps_model.dart';
import 'features/work_reports_local/data/models/work_report_local_model.dart';
import 'features/work_reports_local/data/models/resources_model.dart';
import 'features/work_reports_local/data/models/signatures_model.dart';
import 'features/work_reports_local/data/models/timestamps_local_model.dart';
import 'features/work_report_photos_local/data/models/work_report_photo_local_model.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sharedPreferences = await SharedPreferences.getInstance();

  // Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(ProjectHiveModelAdapter()); // Register the adapter
  Hive.registerAdapter(PhotoLocalModelAdapter());
  Hive.registerAdapter(AfterWorkModelAdapter());
  Hive.registerAdapter(BeforeWorkModelAdapter());
  Hive.registerAdapter(TimestampsModelAdapter());

  // Register Work Reports Local adapters
  Hive.registerAdapter(WorkReportLocalModelAdapter());
  Hive.registerAdapter(ResourcesModelAdapter());
  Hive.registerAdapter(SignaturesModelAdapter());
  Hive.registerAdapter(TimestampsLocalModelAdapter());

  // Register Work Report Photos Local adapters
  Hive.registerAdapter(WorkReportPhotoLocalModelAdapter());

  await Hive.openBox<PhotoLocalModel>('photoLocalBox');
  await Hive.openBox<WorkReportLocalModel>('work_reports_local');
  await Hive.openBox<WorkReportPhotoLocalModel>('work_report_photos_local');

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const MainApp(),
    ),
  );
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

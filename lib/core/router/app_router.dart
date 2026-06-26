import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import 'root_navigator_key.dart';
import '../widgets/app_layout.dart';
import '../../features/work_reports/presentation/screens/work_reports_list_screen.dart';
import '../../features/work_reports/presentation/screens/work_report_view_screen.dart';
import '../../features/work_reports/presentation/screens/work_report_create_screen.dart';
import '../../features/work_reports/presentation/screens/work_report_edit_screen.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/Positions/presentation/screens/positions_list_screen.dart';
import '../../features/Positions/presentation/screens/position_form_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/projects/presentation/screens/projects_list_screen.dart';

GoRouter appRouter(WidgetRef ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    redirect: (context, state) {
      final authState = ref.watch(authProvider);
      final isLoggedIn = authState.isLoggedIn;
      final isChecking = authState.isChecking;
      final isLoginRoute = state.matchedLocation == '/';

      if (isChecking) {
        return null; // No redirigir mientras se verifica
      }

      if (!isLoggedIn && !isLoginRoute) {
        return '/';
      }
      if (isLoggedIn && isLoginRoute) {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const LoginScreen()),
      ShellRoute(
        builder: (context, state, child) => AppLayout(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/work-reports',
            builder: (context, state) => const ProjectsListScreen(),
          ),
          GoRoute(
            path: '/work-reports/project/:projectId',
            builder: (context, state) {
              final projectId = int.parse(state.pathParameters['projectId']!);
              final extra = state.extra as Map<String, dynamic>?;
              return WorkReportsListScreen(projectId: projectId, extra: extra);
            },
          ),
          GoRoute(
            path: '/work-reports/create',
            builder: (context, state) {
              final projectIdStr = state.uri.queryParameters['projectId'];
              final projectId = projectIdStr != null ? int.tryParse(projectIdStr) : null;
              return WorkReportCreateScreen(projectId: projectId);
            },
          ),
          GoRoute(
            path: '/work-reports/:id',
            builder: (context, state) {
              final id = int.parse(state.pathParameters['id']!);
              return WorkReportViewScreen(id: id);
            },
          ),
          GoRoute(
            path: '/work-reports/:id/edit',
            builder: (context, state) {
              final id = int.parse(state.pathParameters['id']!);
              return WorkReportEditScreen(id: id);
            },
          ),
          GoRoute(
            path: '/positions',
            builder: (context, state) => const PositionsListScreen(),
          ),
          GoRoute(
            path: '/positions/add',
            builder: (context, state) => const PositionFormScreen(),
          ),
          GoRoute(
            path: '/positions/edit/:id',
            builder: (context, state) {
              final id = int.parse(state.pathParameters['id']!);
              return PositionFormScreen(positionId: id);
            },
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
}

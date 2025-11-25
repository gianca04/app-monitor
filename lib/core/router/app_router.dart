import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../widgets/app_layout.dart';
import '../../features/work_reports/presentation/screens/work_reports_list_screen.dart';
import '../../features/work_reports/presentation/screens/work_report_view_screen.dart';
import '../../features/work_reports/presentation/screens/work_report_create_screen.dart';
import '../../features/work_reports/presentation/screens/work_report_edit_screen.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

GoRouter appRouter(WidgetRef ref) {
  return GoRouter(
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
      GoRoute(
        path: '/',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppLayout(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/work-reports',
            builder: (context, state) => const WorkReportsListScreen(),
          ),
          GoRoute(
            path: '/work-reports/create',
            builder: (context, state) => const WorkReportCreateScreen(),
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
        ],
      ),
    ],
  );
}
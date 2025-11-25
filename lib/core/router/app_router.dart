import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/screens/login_screen.dart';

final appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const LoginScreen(),
    ),
  ],
);
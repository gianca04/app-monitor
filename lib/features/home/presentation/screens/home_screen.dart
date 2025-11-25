import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Bienvenido a la aplicación Monitor'),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => context.go('/work-reports'),
            child: const Text('Work Reports'),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () => context.go('/positions'),
            child: const Text('Positions'),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/position_provider.dart';

class PositionsListScreen extends ConsumerStatefulWidget {
  const PositionsListScreen({super.key});

  @override
  ConsumerState<PositionsListScreen> createState() => _PositionsListScreenState();
}

class _PositionsListScreenState extends ConsumerState<PositionsListScreen> {
  @override
  void initState() {
    super.initState();
    // Load positions on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(positionsProvider.notifier).loadPositions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final positions = ref.watch(positionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Positions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // Navigate to add position screen
              context.go('/positions/add');
            },
          ),
        ],
      ),
      body: positions.isEmpty
          ? const Center(child: Text('No positions found'))
          : ListView.builder(
              itemCount: positions.length,
              itemBuilder: (context, index) {
                final position = positions[index];
                return ListTile(
                  title: Text(position.name),
                  subtitle: Text('ID: ${position.id}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () async {
                      await ref.read(positionsProvider.notifier).deletePosition(position.id);
                    },
                  ),
                  onTap: () {
                    // Navigate to edit
                    context.go('/positions/edit/${position.id}');
                  },
                );
              },
            ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/positions_list_provider.dart';

class PositionsListWidget extends ConsumerStatefulWidget {
  const PositionsListWidget({super.key});

  @override
  ConsumerState<PositionsListWidget> createState() => _PositionsListWidgetState();
}

class _PositionsListWidgetState extends ConsumerState<PositionsListWidget> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      ref.read(positionsListProvider.notifier).loadMorePositions();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(positionsListProvider);

    if (state.isLoading && !state.hasData) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && !state.hasData) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: ${state.error}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(positionsListProvider.notifier).loadPositions(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Records counter
        if (state.hasData)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'Showing ${state.positions!.data.length} of ${state.positions!.total} positions',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ),
        // List
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.read(positionsListProvider.notifier).loadPositions();
            },
            child: ListView.builder(
              controller: _scrollController,
              itemCount: state.positions!.data.length + (state.isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == state.positions!.data.length) {
                  // Loading indicator at the end
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final position = state.positions!.data[index];
                return ListTile(
                  title: Text(position.name),
                  subtitle: Text('ID: ${position.id}'),
                  onTap: () {
                    // Navigate to position details
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
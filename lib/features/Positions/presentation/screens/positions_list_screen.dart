import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/positions_list_provider.dart';

class PositionsListScreen extends ConsumerWidget {
  const PositionsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(positionsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Positions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // Navigate to add position
            },
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(child: Text('Error: ${state.error}'))
              : state.positions == null
                  ? const Center(child: Text('No positions found'))
                  : Column(
                      children: [
                        // Search and filters
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: TextField(
                            decoration: const InputDecoration(
                              labelText: 'Search positions',
                              prefixIcon: Icon(Icons.search),
                            ),
                            onChanged: (value) {
                              ref.read(positionsListProvider.notifier).setSearch(value.isEmpty ? null : value);
                            },
                          ),
                        ),
                        // Sort options
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            children: [
                              const Text('Sort by:'),
                              const SizedBox(width: 8),
                              DropdownButton<String>(
                                value: state.sortBy,
                                items: const [
                                  DropdownMenuItem(value: 'name', child: Text('Name')),
                                  DropdownMenuItem(value: 'id', child: Text('ID')),
                                  DropdownMenuItem(value: 'created_at', child: Text('Created At')),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    ref.read(positionsListProvider.notifier).setSort(value, state.sortOrder!);
                                  }
                                },
                              ),
                              const SizedBox(width: 16),
                              DropdownButton<String>(
                                value: state.sortOrder,
                                items: const [
                                  DropdownMenuItem(value: 'asc', child: Text('Ascending')),
                                  DropdownMenuItem(value: 'desc', child: Text('Descending')),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    ref.read(positionsListProvider.notifier).setSort(state.sortBy!, value);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        // Per page
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            children: [
                              const Text('Per page:'),
                              const SizedBox(width: 8),
                              DropdownButton<int>(
                                value: state.perPage,
                                items: const [
                                  DropdownMenuItem(value: 5, child: Text('5')),
                                  DropdownMenuItem(value: 10, child: Text('10')),
                                  DropdownMenuItem(value: 15, child: Text('15')),
                                  DropdownMenuItem(value: 20, child: Text('20')),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    ref.read(positionsListProvider.notifier).setPerPage(value);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        // List
                        Expanded(
                          child: ListView.builder(
                            itemCount: state.positions!.data.length,
                            itemBuilder: (context, index) {
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
                        // Pagination
                        if (state.positions!.lastPage > 1)
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.chevron_left),
                                  onPressed: state.currentPage! > 1
                                      ? () => ref.read(positionsListProvider.notifier).setPage(state.currentPage! - 1)
                                      : null,
                                ),
                                Text('Page ${state.positions!.currentPage} of ${state.positions!.lastPage}'),
                                IconButton(
                                  icon: const Icon(Icons.chevron_right),
                                  onPressed: state.currentPage! < state.positions!.lastPage
                                      ? () => ref.read(positionsListProvider.notifier).setPage(state.currentPage! + 1)
                                      : null,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
    );
  }
}
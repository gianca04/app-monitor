import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/positions_list_provider.dart';

class PositionsListScreen extends ConsumerStatefulWidget {
  const PositionsListScreen({super.key});

  @override
  ConsumerState<PositionsListScreen> createState() => _PositionsListScreenState();
}

class _PositionsListScreenState extends ConsumerState<PositionsListScreen> {
  final ScrollController _scrollController = ScrollController();
  late VoidCallback _loadMoreCallback;

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
      _loadMoreCallback();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(positionsListProvider);

    _loadMoreCallback = () {
      if (!state.isLoadingMore && state.hasMorePages) {
        ref.read(positionsListProvider.notifier).loadMorePositions();
      }
    };

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
              : state.positions.isEmpty
                  ? const Center(child: Text('No positions found'))
                  : Column(
                      children: [
                        // Header with total count
                        Container(
                          padding: const EdgeInsets.all(16.0),
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total positions: ${state.total}',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${state.positions.length} loaded',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
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
                        // List with infinite scroll
                        Expanded(
                          child: ListView.builder(
                            controller: _scrollController,
                            itemCount: state.positions.length + (state.isLoadingMore && state.hasMorePages ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == state.positions.length) {
                                // Loading indicator at the end
                                return const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Center(child: CircularProgressIndicator()),
                                );
                              }

                              final position = state.positions[index];
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
                      ],
                    ),
    );
  }
}
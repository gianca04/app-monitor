import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/positions_list_provider.dart';

const List<DropdownMenuItem<String>> _sortByItems = [
  DropdownMenuItem(value: 'name', child: Text('Name')),
  DropdownMenuItem(value: 'id', child: Text('ID')),
  DropdownMenuItem(value: 'created_at', child: Text('Created At')),
];

const List<DropdownMenuItem<String>> _sortOrderItems = [
  DropdownMenuItem(value: 'asc', child: Text('Ascending')),
  DropdownMenuItem(value: 'desc', child: Text('Descending')),
];

const List<DropdownMenuItem<int>> _perPageItems = [
  DropdownMenuItem(value: 5, child: Text('5')),
  DropdownMenuItem(value: 10, child: Text('10')),
  DropdownMenuItem(value: 15, child: Text('15')),
  DropdownMenuItem(value: 20, child: Text('20')),
];

class FiltersWidget extends ConsumerWidget {
  const FiltersWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(positionsListProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sort options
          Row(
            children: [
              const Text('Sort by:'),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: state.sortBy,
                items: _sortByItems,
                onChanged: (value) {
                  if (value != null) {
                    ref.read(positionsListProvider.notifier).setSort(value, state.sortOrder!);
                  }
                },
              ),
              const SizedBox(width: 16),
              DropdownButton<String>(
                value: state.sortOrder,
                items: _sortOrderItems,
                onChanged: (value) {
                  if (value != null) {
                    ref.read(positionsListProvider.notifier).setSort(state.sortBy!, value);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Per page
          Row(
            children: [
              const Text('Per page:'),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: state.perPage,
                items: _perPageItems,
                onChanged: (value) {
                  if (value != null) {
                    ref.read(positionsListProvider.notifier).setPerPage(value);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
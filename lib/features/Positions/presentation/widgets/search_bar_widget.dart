import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/positions_list_provider.dart';

class SearchBarWidget extends ConsumerStatefulWidget {
  const SearchBarWidget({super.key});

  @override
  ConsumerState<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends ConsumerState<SearchBarWidget> {
  final TextEditingController _searchController = TextEditingController();
  String? _currentSearchValue;

  @override
  void initState() {
    super.initState();
    // Initialize with current search value from provider
    final state = ref.read(positionsListProvider);
    _currentSearchValue = state.search;
    _searchController.text = state.search ?? '';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch() {
    final searchValue = _searchController.text.trim();
    final newSearchValue = searchValue.isEmpty ? null : searchValue;

    // Only trigger search if value changed
    if (newSearchValue != _currentSearchValue) {
      _currentSearchValue = newSearchValue;
      ref.read(positionsListProvider.notifier).setSearch(newSearchValue);
    }
  }

  void _clearSearch() {
    _searchController.clear();
    _currentSearchValue = null;
    ref.read(positionsListProvider.notifier).setSearch(null);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search positions',
                prefixIcon: Icon(Icons.search),
              ),
              onSubmitted: (_) => _performSearch(),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _performSearch,
            icon: const Icon(Icons.search),
            label: const Text('Search'),
          ),
          if (_currentSearchValue?.isNotEmpty == true) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _clearSearch,
              tooltip: 'Clear search',
            ),
          ],
        ],
      ),
    );
  }
}
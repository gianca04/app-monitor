import 'dart:async';
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
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    // Inicializar con el valor de búsqueda actual del provider
    final state = ref.read(positionsListProvider);
    _searchController.text = state.search ?? '';
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    // Forzar la reconstrucción para actualizar la visibilidad de la 'X'
    setState(() {});

    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      _debounceTimer?.cancel();
      // Llama a setSearch(null) inmediatamente si está vacío
      ref.read(positionsListProvider.notifier).setSearch(null);
    } else {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 300), () {
        ref.read(positionsListProvider.notifier).setSearch(trimmed);
      });
    }
  }

  void _clearSearch() {
    _debounceTimer?.cancel();

    // 1. Borra el texto localmente y fuerza la reconstrucción
    _searchController.clear();
    setState(() {}); // 👈 ¡Añadido! Fuerza la actualización del UI.

    // 2. Establece la búsqueda en null en el provider y recarga
    ref.read(positionsListProvider.notifier).setSearch(null);
  }

  @override
  Widget build(BuildContext context) {
    // *** ELIMINAMOS EL 'ref.listen' para evitar la sobrescritura ***
    // Si la 'X' funciona como se espera, este bloque es el causante del problema.
    // Lo eliminamos para que el controlador local sea la fuente de verdad.

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search positions',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _clearSearch,
                        tooltip: 'Clear search',
                      )
                    : null,
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            // El botón de búsqueda también usa _onSearchChanged
            onPressed: () => _onSearchChanged(_searchController.text),
            icon: const Icon(Icons.search),
            label: const Text('Search'),
          ),
        ],
      ),
    );
  }
}
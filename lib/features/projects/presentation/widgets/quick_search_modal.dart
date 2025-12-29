import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme_config.dart';
import '../providers/projects_provider.dart';

class QuickSearchModal extends ConsumerStatefulWidget {
  const QuickSearchModal({super.key});

  @override
  _QuickSearchModalState createState() => _QuickSearchModalState();
}

class _QuickSearchModalState extends ConsumerState<QuickSearchModal> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    // Realizar búsqueda inicial para mostrar resultados al abrir el modal
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(quickSearchProvider.notifier).search('');
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    // Cancelar el timer anterior si existe
    _debounceTimer?.cancel();

    // Si el valor está vacío, buscar inmediatamente para limpiar resultados
    if (value.isEmpty) {
      ref.read(quickSearchProvider.notifier).search(value);
      return;
    }

    // Crear un nuevo timer con delay de 300ms
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      ref.read(quickSearchProvider.notifier).search(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final quickSearchState = ref.watch(quickSearchProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 15),

        TextField(
          controller: _controller,
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.search, color: AppTheme.textSecondary),
            labelText: 'Buscar proyecto',
            hintText: 'Ingrese nombre del proyecto, etc.',
            border: const OutlineInputBorder(),
          ),
          onChanged: _onSearchChanged,
        ),

        const SizedBox(height: 15),

        if (quickSearchState.isLoading)
          const Center(child: CircularProgressIndicator())
        else if (quickSearchState.error != null)
          Text(
            'Error: ${quickSearchState.error}',
            style: const TextStyle(color: AppTheme.error),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: quickSearchState.results.length,
            itemBuilder: (context, index) {
              final project = quickSearchState.results[index];

              return Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 4.0,
                  horizontal: 2.0,
                ),
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop(project);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      border: Border.all(color: AppTheme.border),
                      borderRadius: BorderRadius.circular(AppTheme.kRadius),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.assignment, color: AppTheme.primaryAccent),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                project.name ?? 'Sin nombre',
                                style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'ID: ${project.id ?? ''}',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        const SizedBox(height: 8),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/projects_provider.dart';

class QuickSearchModal extends ConsumerStatefulWidget {
  const QuickSearchModal({super.key});

  @override
  _QuickSearchModalState createState() => _QuickSearchModalState();
}

class _QuickSearchModalState extends ConsumerState<QuickSearchModal> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Hacer búsqueda inicial con cadena vacía si el controller está vacío
    if (_controller.text.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(quickSearchProvider.notifier).search('');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final quickSearchState = ref.watch(quickSearchProvider);

    return Column(
      children: [
        const SizedBox(height: 15),
        TextField(
          controller: _controller,
          decoration: const InputDecoration(
            labelText: 'Palabra clave',
            hintText: 'Ingrese el nombre del proyecto.',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            ref.read(quickSearchProvider.notifier).search(value);
          },
        ),
        const SizedBox(height: 16),
        if (quickSearchState.isLoading)
          const CircularProgressIndicator()
        else if (quickSearchState.error != null)
          Text('Error: ${quickSearchState.error}')
        else
          SizedBox(
            height: 300,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: quickSearchState.results.length,
              itemBuilder: (context, index) {
                final project = quickSearchState.results[index];
                return ListTile(
                  title: Text(project.name ?? 'Sin nombre'),
                  subtitle: Text('ID: ${project.id ?? ''}'),
                  onTap: () {
                    // Aquí puedes manejar la selección, por ejemplo, cerrar el modal y devolver el proyecto
                    Navigator.of(context).pop(project);
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/employees_provider.dart';

class QuickSearchModal extends ConsumerStatefulWidget {
  const QuickSearchModal({super.key});

  @override
  _QuickSearchModalState createState() => _QuickSearchModalState();
}

class _QuickSearchModalState extends ConsumerState<QuickSearchModal> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quickSearchState = ref.watch(quickSearchProvider);

    return Column(
      children: [
        TextField(
          controller: _controller,
          decoration: const InputDecoration(
            labelText: 'Palabra clave',
            hintText: 'Ingrese nombre, documento, etc.',
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
          Expanded(
            child: ListView.builder(
              itemCount: quickSearchState.results.length,
              itemBuilder: (context, index) {
                final employee = quickSearchState.results[index];
                return ListTile(
                  title: Text(employee.fullName ?? 'Sin nombre'),
                  subtitle: Text('${employee.documentNumber ?? ''} - ${employee.position ?? ''}'),
                  onTap: () {
                    // Aquí puedes manejar la selección, por ejemplo, cerrar el modal y devolver el empleado
                    Navigator.of(context).pop(employee);
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/modern_bottom_modal.dart';
import '../providers/employees_provider.dart';
import '../widgets/quick_search_modal.dart';
import '../widgets/employee_list_item.dart';
import '../../data/models/quick_search_response.dart';

class EmployeesListScreen extends ConsumerWidget {
  const EmployeesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeesState = ref.watch(employeesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Employees'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () async {
              final result = await ModernBottomModal.show<EmployeeQuick>(
                context,
                title: 'Búsqueda Rápida de Empleados',
                content: const QuickSearchModal(),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                ],
              );
              if (result != null) {
                // Manejar el resultado seleccionado
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Seleccionado: ${result.fullName}')),
                );
              }
            },
          ),
        ],
      ),
      body: employeesState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : employeesState.error != null
              ? Center(child: Text('Error: ${employeesState.error}'))
              : ListView.builder(
                  itemCount: employeesState.employees.length,
                  itemBuilder: (context, index) {
                    final employee = employeesState.employees[index];
                    return EmployeeListItem(
                      employee: employee,
                      onTap: () {
                        // TODO: Navigate to employee details
                      },
                    );
                  },
                ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/work_reports_provider.dart';
import '../widgets/work_report_list_item.dart';
import '../widgets/reports_empty_state.dart' as empty_state;
import '../widgets/reports_fab_menu.dart' as fab_menu;
// import 'package:monitor/core/theme_config.dart'; 

class WorkReportsListScreen extends ConsumerStatefulWidget {
  const WorkReportsListScreen({super.key});

  @override
  ConsumerState<WorkReportsListScreen> createState() =>
      _WorkReportsListScreenState();
}

class _WorkReportsListScreenState extends ConsumerState<WorkReportsListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(workReportsProvider.notifier).loadWorkReports(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(workReportsProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Buscar reportes...',
            hintStyle: TextStyle(color: const Color(0xFF8B949E)),
            filled: true,
            fillColor: const Color(0xFF0D1117),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4.0),
              borderSide: const BorderSide(color: Color(0xFF30363D)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4.0),
              borderSide: const BorderSide(color: Color(0xFF30363D)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4.0),
              borderSide: const BorderSide(color: Color(0xFF6E7681)),
            ),
            prefixIcon: const Icon(Icons.search, color: Color(0xFFFFAB00)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          style: const TextStyle(color: Color(0xFFE1E4E8)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: state.isLoading
                ? null
                : () => ref.read(workReportsProvider.notifier).loadWorkReports(),
            tooltip: 'RECARGAR',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showDateFilterDialog(context, ref),
            tooltip: 'FILTRAR',
          ),
        ],
      ),
      body: Stack(
        children: [
          if (state.isLoading)
            Center(child: CircularProgressIndicator(color: colorScheme.primary)),

          if (!state.isLoading)
            state.reports.isEmpty
                ? empty_state.ReportsEmptyState(
                    error: state.error,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(15.0),
                    itemCount: state.reports.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final report = state.reports[index];
                      return WorkReportListItem(
                        report: report,
                        onEdit: () => context.go(
                          '/work-reports/${report.id}/edit',
                        ),
                        onDelete: () => _confirmDelete(context, ref, report.id!),
                      );
                    },
                  ),

          // El FAB ahora es un widget autónomo
          Positioned(
            bottom: 16,
            right: 16,
            child: fab_menu.ReportsFabMenu(),
          ),
        ],
      ),
    );
  }

  // --- Métodos Auxiliares para Diálogos (Mucho más limpios) ---

  void _confirmDelete(BuildContext context, WidgetRef ref, int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('CONFIRMAR ELIMINACIÓN'),
        content: const Text(
          'Esta acción no se puede deshacer. ¿Eliminar registro permanentemente?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCELAR'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await ref.read(workReportsProvider.notifier).deleteWorkReport(id);
                // Success, list is reloaded automatically
              } catch (e) {
                // Error occurred, show SnackBar
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al eliminar el reporte: $e')),
                  );
                }
              }
            },
            child: Text(
              'ELIMINAR',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showDateFilterDialog(BuildContext context, WidgetRef ref) {
    // Obtenemos fechas actuales del provider
    final currentState = ref.read(workReportsProvider);
    DateTime? selectedFrom = currentState.dateFrom != null
        ? DateTime.parse(currentState.dateFrom!)
        : null;
    DateTime? selectedTo = currentState.dateTo != null
        ? DateTime.parse(currentState.dateTo!)
        : null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('RANGO DE FECHAS'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DateInput(
                label: 'DESDE',
                date: selectedFrom,
                onPick: (d) => setState(() => selectedFrom = d),
              ),
              const SizedBox(height: 16),
              _DateInput(
                label: 'HASTA',
                date: selectedTo,
                onPick: (d) => setState(() => selectedTo = d),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCELAR'),
            ),
            TextButton(
              onPressed: () {
                ref.read(workReportsProvider.notifier).setDateFilter(
                      selectedFrom?.toIso8601String().split('T')[0],
                      selectedTo?.toIso8601String().split('T')[0],
                    );
                Navigator.pop(context);
              },
              child: const Text('FILTRAR'),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget privado pequeño para evitar repetir código en el diálogo de fechas
class _DateInput extends StatelessWidget {
  final String label;
  final DateTime? date;
  final Function(DateTime) onPick;

  const _DateInput({required this.label, this.date, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return TextField(
      readOnly: true,
      controller: TextEditingController(
        text: date?.toIso8601String().split('T')[0],
      ),
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: const Icon(Icons.calendar_today, size: 16),
      ),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null) onPick(picked);
      },
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:monitor/core/theme_config.dart';
import '../providers/work_reports_provider.dart';
import '../widgets/work_report_list_item.dart';

class WorkReportsListScreen extends ConsumerStatefulWidget {
  const WorkReportsListScreen({super.key});

  @override
  ConsumerState<WorkReportsListScreen> createState() => _WorkReportsListScreenState();
}

class _WorkReportsListScreenState extends ConsumerState<WorkReportsListScreen> with TickerProviderStateMixin {
  bool _isExpanded = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.index = 1; // Iniciar en WEB
    Future.microtask(() => ref.read(workReportsProvider.notifier).loadWorkReports());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(workReportsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('WORK REPORTS'), // Mayúsculas para estilo industrial
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'LOCALES'),
            Tab(text: 'WEB'),
          ],
          onTap: (index) {
            final filter = index == 0 ? ReportFilter.local : ReportFilter.cloud;
            ref.read(workReportsProvider.notifier).setFilter(filter);
          },
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          unselectedLabelStyle: const TextStyle(fontSize: 14),
          indicatorColor: AppTheme.primaryAccent,
          labelColor: AppTheme.primaryAccent,
          unselectedLabelColor: AppTheme.textSecondary,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showDateFilterDialog,
            tooltip: 'Filtrar por fechas',
          )
        ],
      ),
      body: Stack(
        children: [
          state.isLoading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryAccent))
              : state.reports.isEmpty && state.error != null
                  ? Center(
                      child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.warning_amber_rounded, size: 48, color: AppTheme.error),
                        const SizedBox(height: 16),
                        Text(state.error!, style: TextStyle(color: AppTheme.error)),
                      ],
                    ))
                  : Column(
                      children: [
                        // Mostrar banner offline cuando estamos en modo offline
                        if (state.isOffline)
                          Container(
                            width: double.infinity,
                            color: AppTheme.warning.withOpacity(0.1),
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                const Icon(Icons.wifi_off, color: AppTheme.warning),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    state.error != null
                                        ? state.error!
                                        : 'Modo offline: Solo se muestran reportes locales. Se sincronizarán cuando haya conexión.',
                                    style: TextStyle(color: AppTheme.warning),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        // Mostrar mensaje cuando no hay reportes
                        if (state.reports.isEmpty)
                          Expanded(
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    state.isOffline ? Icons.wifi_off : Icons.assignment_outlined,
                                    size: 64,
                                    color: AppTheme.textSecondary,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    state.isOffline
                                        ? 'No hay reportes locales disponibles'
                                        : 'No hay reportes disponibles',
                                    style: TextStyle(color: AppTheme.textSecondary),
                                  ),
                                  if (!state.isOffline) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      'Toca el botón + para crear uno nuevo',
                                      style: TextStyle(color: AppTheme.textSecondary.withOpacity(0.7), fontSize: 14),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          )
                        else
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: ListView.builder(
                                itemCount: state.reports.length,
                                itemBuilder: (context, index) {
                                  final report = state.reports[index];

                                  return WorkReportListItem(
                                    report: report,
                                    onEdit: () => context.go('/work-reports/${report.id}/edit'),
                                    onDelete: () => _deleteReport(report.id!),
                                  );
                                },
                              ),
                            ),
                          ),
                      ],
                    ),
          Positioned(
            bottom: 16,
            right: 16,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_isExpanded) ...[
                  AnimatedOpacity(
                    opacity: _isExpanded ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: FloatingActionButton(
                      heroTag: 'cloud_fab',
                      onPressed: () => context.go('/work-reports/create?type=cloud'),
                      child: const Icon(Icons.cloud),
                      mini: true,
                      tooltip: 'Crear reporte en la nube',
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedOpacity(
                    opacity: _isExpanded ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: FloatingActionButton(
                      heroTag: 'local_fab',
                      onPressed: () => context.go('/work-reports/create?type=local'),
                      child: const Icon(Icons.save),
                      mini: true,
                      tooltip: 'Guardar reporte local',
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                FloatingActionButton(
                  heroTag: 'main_fab',
                  onPressed: () => setState(() => _isExpanded = !_isExpanded),
                  child: Icon(_isExpanded ? Icons.close : Icons.add),
                  tooltip: _isExpanded ? 'Cerrar opciones' : 'Nuevo reporte',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _deleteReport(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('CONFIRM DELETION'),
        content: const Text('This action cannot be undone. Eliminate record?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCEL', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              ref.read(workReportsProvider.notifier).deleteWorkReport(id);
              Navigator.of(context).pop();
            },
            child: const Text('DELETE', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.error)),
          ),
        ],
      ),
    );
  }

  void _showDateFilterDialog() {
    final currentState = ref.watch(workReportsProvider);
    DateTime? selectedFrom = currentState.dateFrom != null ? DateTime.parse(currentState.dateFrom!) : null;
    DateTime? selectedTo = currentState.dateTo != null ? DateTime.parse(currentState.dateTo!) : null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Filtrar por fechas'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                readOnly: true,
                decoration: const InputDecoration(labelText: 'Fecha desde'),
                controller: TextEditingController(text: selectedFrom?.toIso8601String().split('T')[0]),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedFrom ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                  );
                  if (picked != null) {
                    setState(() => selectedFrom = picked);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                readOnly: true,
                decoration: const InputDecoration(labelText: 'Fecha hasta'),
                controller: TextEditingController(text: selectedTo?.toIso8601String().split('T')[0]),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedTo ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                  );
                  if (picked != null) {
                    setState(() => selectedTo = picked);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('CANCELAR'),
            ),
            TextButton(
              onPressed: () {
                ref.read(workReportsProvider.notifier).setDateFilter(
                  selectedFrom?.toIso8601String().split('T')[0],
                  selectedTo?.toIso8601String().split('T')[0],
                );
                Navigator.of(context).pop();
              },
              child: const Text('APLICAR'),
            ),
          ],
        ),
      ),
    );
  }
}
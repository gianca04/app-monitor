import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/work_reports_provider.dart';
// Asegúrate de importar tu theme si lo necesitas referenciar directamente, 
// aunque usando Theme.of(context) es suficiente.

class WorkReportsListScreen extends ConsumerStatefulWidget {
  const WorkReportsListScreen({super.key});

  @override
  ConsumerState<WorkReportsListScreen> createState() => _WorkReportsListScreenState();
}

class _WorkReportsListScreenState extends ConsumerState<WorkReportsListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(workReportsProvider.notifier).loadWorkReports());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(workReportsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        title: const Text('WORK REPORTS'), // Mayúsculas para estilo industrial
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {}, // Placeholder para futuro filtro
            tooltip: 'Filter',
          )
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFAB00)))
          : state.reports.isEmpty && state.error != null
              ? Center(
                  child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.warning_amber_rounded, size: 48, color: Color(0xFFCF6679)),
                    const SizedBox(height: 16),
                    Text(state.error!, style: const TextStyle(color: Color(0xFFCF6679))),
                  ],
                ))
              : Column(
                  children: [
                    // Mostrar banner offline cuando estamos en modo offline
                    if (state.isOffline)
                      Container(
                        width: double.infinity,
                        color: Colors.orange.withOpacity(0.1),
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            const Icon(Icons.wifi_off, color: Colors.orange),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                state.error != null
                                    ? state.error!
                                    : 'Modo offline: Solo se muestran reportes locales. Se sincronizarán cuando haya conexión.',
                                style: TextStyle(color: Colors.orange[700]),
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
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                state.isOffline
                                    ? 'No hay reportes locales disponibles'
                                    : 'No hay reportes disponibles',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              if (!state.isOffline) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Toca el botón + para crear uno nuevo',
                                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
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
                              
                              // Diseño de Tarjeta Industrial
                              return Card(
                                child: InkWell(
                                  onTap: () => context.go('/work-reports/${report.id}'),
                                  borderRadius: BorderRadius.circular(4),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Encabezado de la tarjeta
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                report.name ?? 'UNTITLED REPORT',
                                                style: theme.textTheme.titleMedium?.copyWith(
                                                  fontSize: 16,
                                                  letterSpacing: 0.5,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            // ID o Código estilo "etiqueta"
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.black26,
                                                borderRadius: BorderRadius.circular(2),
                                                border: Border.all(color: Colors.white10),
                                              ),
                                              child: Text(
                                                'ID: ${report.id}',
                                                style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'Courier'), // Fuente monoespaciada si es posible
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        
                                        // Descripción
                                        if (report.description != null && report.description!.isNotEmpty)
                                          Text(
                                            report.description!,
                                            style: theme.textTheme.bodyMedium,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        
                                        const SizedBox(height: 16),
                                        const Divider(height: 1, color: Colors.white10),
                                        const SizedBox(height: 12),

                                        // Pie de tarjeta: Fecha y Acciones
                                        Row(
                                          children: [
                                            Icon(Icons.calendar_today_outlined, size: 14, color: theme.primaryColor),
                                            const SizedBox(width: 6),
                                            Text(
                                              report.reportDate ?? 'No Date',
                                              style: theme.textTheme.bodySmall,
                                            ),
                                            const Spacer(),
                                            
                                            // Acciones Minimalistas
                                            _ActionButton(
                                              icon: Icons.edit_outlined,
                                              onTap: () => context.go('/work-reports/${report.id}/edit'),
                                            ),
                                            const SizedBox(width: 8),
                                            _ActionButton(
                                              icon: Icons.delete_outline,
                                              color: theme.colorScheme.error,
                                              onTap: () => _deleteReport(report.id!),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/work-reports/create'),
        child: const Icon(Icons.add),
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
            child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              ref.read(workReportsProvider.notifier).deleteWorkReport(id);
              Navigator.of(context).pop();
            },
            child: const Text('DELETE', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFCF6679))),
          ),
        ],
      ),
    );
  }
}

// Widget auxiliar para botones pequeños
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  const _ActionButton({required this.icon, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white12),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, size: 18, color: color ?? Colors.grey[400]),
      ),
    );
  }
}
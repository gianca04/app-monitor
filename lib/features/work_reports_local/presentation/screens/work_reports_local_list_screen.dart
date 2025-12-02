import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme_config.dart';
import '../../domain/entities/work_report_local_entity.dart';
import '../providers/work_reports_local_provider.dart';
import '../../../settings/providers/connectivity_preferences_provider.dart';

class WorkReportsLocalListScreen extends ConsumerStatefulWidget {
  const WorkReportsLocalListScreen({super.key});

  @override
  ConsumerState<WorkReportsLocalListScreen> createState() => _WorkReportsLocalListScreenState();
}

class _WorkReportsLocalListScreenState extends ConsumerState<WorkReportsLocalListScreen> {
  bool _isSyncing = false;

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportsAsync = ref.watch(workReportsLocalListProvider);
    final unsyncedCountAsync = ref.watch(unsyncedWorkReportsLocalCountProvider);
    final isOnline = ref.watch(connectivityStatusProvider).maybeWhen(
      data: (status) => status,
      orElse: () => false,
    );

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        title: const Text(
          'REPORTES LOCALES',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        actions: [
          // Sync button
          unsyncedCountAsync.when(
            data: (count) {
              if (count == 0) return const SizedBox.shrink();
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.cloud_upload),
                    onPressed: _isSyncing || !isOnline ? null : () => _syncAll(),
                    tooltip: isOnline 
                        ? 'Sincronizar reportes' 
                        : 'Sin conexión',
                  ),
                  if (count > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
            loading: () => const SizedBox(
              width: 40,
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: Stack(
        children: [
          reportsAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.primaryAccent,
                ),
              ),
            ),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.redAccent,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${error.toString()}',
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.read(workReportsLocalListProvider.notifier).refresh(),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
            data: (reports) {
              if (reports.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.folder_open,
                        size: 64,
                        color: AppTheme.textSecondary.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No hay reportes locales',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Los reportes creados sin conexión\naparecerán aquí',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: reports.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final report = reports[index];
                  return _WorkReportCard(
                    report: report,
                    formatDate: _formatDate,
                  );
                },
              );
            },
          ),
          // Loading overlay for sync
          if (_isSyncing)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Sincronizando reportes...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.go('/work-reports-local/create');
        },
        backgroundColor: AppTheme.primaryAccent,
        child: const Icon(Icons.add, color: AppTheme.background),
      ),
    );
  }

  Future<void> _syncAll() async {
    final listNotifier = ref.read(workReportsLocalListProvider.notifier);
    
    setState(() => _isSyncing = true);

    try {
      final stats = await listNotifier.syncAll();
      
      setState(() => _isSyncing = false);
      
      if (stats != null) {
        final total = stats['total'] as int;
        final success = stats['success'] as int;
        final failed = stats['failed'] as int;
        
        if (mounted) {
          showDialog(
            context: context,
            builder: (dialogContext) => AlertDialog(
              backgroundColor: AppTheme.surface,
              title: const Text(
                'Sincronización Completada',
                style: TextStyle(color: AppTheme.textPrimary),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total: $total',
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                  Text(
                    'Exitosos: $success',
                    style: const TextStyle(color: Colors.greenAccent),
                  ),
                  if (failed > 0)
                    Text(
                      'Fallidos: $failed',
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  if (failed > 0 && stats['errors'] != null) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Errores:',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...(stats['errors'] as List<String>).map(
                      (error) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '• $error',
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    if (Navigator.of(dialogContext).canPop()) {
                      Navigator.of(dialogContext).pop();
                    }
                    // The list is already refreshed by the syncAll method
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isSyncing = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }
}


class _WorkReportCard extends StatelessWidget {
  final WorkReportLocalEntity report;
  final String Function(String?) formatDate;

  const _WorkReportCard({required this.report, required this.formatDate});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          context.go('/work-reports-local/${report.id}/edit');
        },
        borderRadius: BorderRadius.circular(4),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.border),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.primaryAccent),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.description_outlined,
                        color: AppTheme.primaryAccent,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            report.name,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (report.description != null)
                            Text(
                              report.description!,
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: AppTheme.textSecondary,
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, color: Colors.white10),

              // Details
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _InfoRow(
                      icon: Icons.business,
                      label: 'Proyecto ID',
                      value: '${report.projectId}',
                    ),
                    const SizedBox(height: 8),
                    _InfoRow(
                      icon: Icons.person,
                      label: 'Empleado ID',
                      value: '${report.employeeId}',
                    ),
                    if (report.startTime != null || report.endTime != null) ...[
                      const SizedBox(height: 8),
                      _InfoRow(
                        icon: Icons.access_time,
                        label: 'Horario',
                        value:
                            '${report.startTime ?? 'N/A'} - ${report.endTime ?? 'N/A'}',
                      ),
                    ],
                    if (report.createdAt != null) ...[
                      const SizedBox(height: 8),
                      _InfoRow(
                        icon: Icons.calendar_today,
                        label: 'Creado',
                        value: formatDate(report.createdAt),
                      ),
                    ],
                  ],
                ),
              ),

              // Footer - Status indicators
              if (report.supervisorSignature != null ||
                  report.managerSignature != null ||
                  report.isSynced ||
                  report.syncError != null)
                Column(
                  children: [
                    const Divider(height: 1, color: Colors.white10),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (report.isSynced)
                            const _StatusChip(
                              icon: Icons.cloud_done,
                              label: 'Sincronizado',
                              color: Colors.greenAccent,
                            ),
                          if (!report.isSynced && report.syncError != null)
                            const _StatusChip(
                              icon: Icons.error_outline,
                              label: 'Error Sync',
                              color: Colors.redAccent,
                            ),
                          if (report.supervisorSignature != null)
                            const _StatusChip(
                              icon: Icons.check_circle_outline,
                              label: 'Firma Supervisor',
                              color: Colors.blueAccent,
                            ),
                          if (report.managerSignature != null)
                            const _StatusChip(
                              icon: Icons.check_circle_outline,
                              label: 'Firma Gerente',
                              color: Colors.blueAccent,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppTheme.textSecondary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatusChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

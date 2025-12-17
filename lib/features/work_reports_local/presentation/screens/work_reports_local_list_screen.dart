import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme_config.dart';
import '../providers/work_reports_local_provider.dart';
import '../../../settings/providers/connectivity_preferences_provider.dart';
import '../../../work_report_photos_local/presentation/providers/work_report_photos_local_provider.dart';
import '../../domain/entities/work_report_local_entity.dart';
import '../widgets/work_report_local_list_item.dart';

class WorkReportsLocalListScreen extends ConsumerStatefulWidget {
  const WorkReportsLocalListScreen({super.key});

  @override
  ConsumerState<WorkReportsLocalListScreen> createState() => _WorkReportsLocalListScreenState();
}

class _WorkReportsLocalListScreenState extends ConsumerState<WorkReportsLocalListScreen> {
  bool _isSyncing = false;

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
                  return _WorkReportLocalListItemWithPhotos(
                    report: report,
                    isOnline: isOnline,
                    onEdit: () => context.go('/work-reports-local/${report.id}/edit'),
                    onDelete: () => _confirmDelete(report.id!),
                    onSync: !report.isSynced && isOnline 
                        ? () => _syncSingle(report.id!) 
                        : null,
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

  Future<void> _syncSingle(int reportId) async {
    final listNotifier = ref.read(workReportsLocalListProvider.notifier);
    
    setState(() => _isSyncing = true);

    try {
      await listNotifier.syncSingle(reportId);
      
      setState(() => _isSyncing = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reporte sincronizado exitosamente'),
            backgroundColor: Colors.greenAccent,
          ),
        );
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

  Future<void> _confirmDelete(int reportId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text(
          'Eliminar Reporte',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: const Text(
          '¿Estás seguro de que deseas eliminar este reporte local? Esta acción no se puede deshacer.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(workReportsLocalListProvider.notifier).delete(reportId);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reporte eliminado'),
              backgroundColor: Colors.greenAccent,
            ),
          );
        }
      } catch (e) {
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
}

// Widget que carga las fotos para cada item de la lista
class _WorkReportLocalListItemWithPhotos extends ConsumerWidget {
  final WorkReportLocalEntity report;
  final bool isOnline;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onSync;

  const _WorkReportLocalListItemWithPhotos({
    required this.report,
    required this.isOnline,
    this.onEdit,
    this.onDelete,
    this.onSync,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Si el reporte no tiene ID, no cargar fotos
    if (report.id == null) {
      return WorkReportLocalListItem(
        report: report,
        photos: const [],
        onEdit: onEdit,
        onDelete: onDelete,
        onSync: onSync,
      );
    }

    final photosAsync = ref.watch(photosByWorkReportLocalProvider(report.id!));

    return photosAsync.when(
      data: (photos) => WorkReportLocalListItem(
        report: report,
        photos: photos,
        onEdit: onEdit,
        onDelete: onDelete,
        onSync: onSync,
      ),
      loading: () => WorkReportLocalListItem(
        report: report,
        photos: const [],
        onEdit: onEdit,
        onDelete: onDelete,
        onSync: onSync,
      ),
      error: (_, __) => WorkReportLocalListItem(
        report: report,
        photos: const [],
        onEdit: onEdit,
        onDelete: onDelete,
        onSync: onSync,
      ),
    );
  }
}

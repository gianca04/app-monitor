import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_html/flutter_html.dart';
import 'dart:io';
import 'package:open_file/open_file.dart';
import '../providers/work_reports_provider.dart';
import '../../../photos/presentation/widgets/image_viewer.dart';
// import '../../../photos/presentation/widgets/image_preview_modal.dart'; // Unused
import '../../../../core/widgets/industrial_card.dart';
import '../../../../core/widgets/modern_bottom_modal.dart';
import '../../../../core/widgets/industrial_feedback.dart';
import '../widgets/work_report_view/work_report_section_header.dart';
import '../widgets/work_report_view/work_report_info_row.dart';
import '../widgets/work_report_view/work_report_resource_block.dart';
import '../widgets/work_report_view/work_report_photo_card.dart';

class WorkReportViewScreen extends ConsumerWidget {
  final int id;

  const WorkReportViewScreen({super.key, required this.id});

  String _extractDataUri(String url) {
    if (url.startsWith('data:')) {
      return url;
    }
    final dataIndex = url.indexOf('data:');
    if (dataIndex != -1) {
      return url.substring(dataIndex);
    }
    return url; // Fallback to original if no data: found
  }

  /*Future<void> _downloadPdf(BuildContext context, WidgetRef ref) async {
    final pdfNotifier = ref.read(workReportPdfProvider.notifier);

    // Mostrar diálogo de progreso
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Descargando PDF...',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
          ],
        ),
      ),
    );

    final file = await pdfNotifier.downloadPdf(id);

    if (context.mounted) {
      Navigator.of(context).pop(); // Cerrar diálogo de progreso
    }

    if (file != null && context.mounted) {
      // Éxito - mostrar opciones
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Theme.of(context).cardTheme.color,
          title: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              const Text('PDF Descargado'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'El archivo se guardó en:',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                file.path,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'CERRAR',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await OpenFile.open(file.path);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.black,
              ),
              child: const Text('ABRIR PDF'),
            ),
          ],
        ),
      );
    } else if (context.mounted) {
      // Error
      final pdfState = ref.read(workReportPdfProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(pdfState.error ?? 'Error al descargar el PDF'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
  */

  void _goBack(BuildContext context) {
    context.go('/work-reports');
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    int id,
  ) async {
    const double kIndRadius = 4.0; // Constants for local usage if not imported

    final confirmed = await ModernBottomModal.show<bool>(
      context,
      title: 'CONFIRMAR ELIMINACIÓN',
      content: const Text(
        'Esta acción no se puede deshacer. ¿Eliminar registro permanentemente?',
        style: TextStyle(color: Colors.white70),
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(kIndRadius),
              ),
            ),
            child: const Text(
              'ELIMINAR AHORA',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCELAR', style: TextStyle(color: Colors.grey)),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );

    if (confirmed != true) return;

    try {
      // Show loading indicator or block UI could be better in a real app
      // For now we trust the modal dismissal and async operation

      final response = await ref
          .read(workReportsProvider.notifier)
          .deleteWorkReport(id);

      if (context.mounted) {
        // Construimos la estructura de respuesta solicitada
        final result = {
          "success": true,
          "message":
              response['message'] ??
              "Reporte de trabajo eliminado exitosamente",
          "data": {"id": id},
          "meta": {
            "apiVersion": "1.0",
            "timestamp": DateTime.now().toIso8601String(),
          },
        };
        // Regresamos el resultado al ir a la lista
        context.go('/work-reports', extra: result);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          IndustrialFeedback.buildError(
            message: 'ERROR AL ELIMINAR: $e',
            onDismiss: () {},
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(workReportProvider(id));
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _goBack(context);
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.appBarTheme.backgroundColor,
          elevation: 0, // REGLA: Sombras eliminadas
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _goBack(context),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(color: colorScheme.outline, height: 1),
          ),
          actions: [
            // Botón de descarga PDF
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Center(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    // onTap: () => _downloadPdf(context, ref),
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: colorScheme.primary.withOpacity(0.5),
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.download_outlined,
                            size: 16,
                            color: colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // REGLA: Botón con borde y feedback contenido
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Center(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => context.go('/work-reports/$id/edit'),
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: colorScheme.primary.withOpacity(0.5),
                        ),
                        borderRadius: BorderRadius.circular(
                          4,
                        ), // REGLA: Radio 4
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.edit_outlined,
                            size: 16,
                            color: colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Botón de eliminar
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _confirmDelete(context, ref, id),
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: colorScheme.error.withOpacity(0.5),
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline,
                            size: 16,
                            color: colorScheme.error,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: state.isLoading
            ? Center(
                child: CircularProgressIndicator(color: colorScheme.primary),
              )
            : state.error != null
            ? Center(
                child: Text(
                  'Error: ${state.error}',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              )
            : state.report == null
            ? Center(
                child: Text(
                  'Report not found',
                  style: TextStyle(
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              )
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. GENERAL INFO SECTION
                    IndustrialCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          WorkReportSectionHeader(
                            theme: theme,
                            title: 'INFORMACIÓN GENERAL',
                            icon: Icons.info_outline,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            state.report!.name?.toUpperCase() ?? 'N/A',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontSize: 20,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: WorkReportInfoRow(
                                  theme: theme,
                                  label: 'FECHA',
                                  value: state.report!.reportDate,
                                ),
                              ),
                              Expanded(
                                child: WorkReportInfoRow(
                                  theme: theme,
                                  label: 'HORA INICIO',
                                  value: state.report!.startTime,
                                ),
                              ),
                              Expanded(
                                child: WorkReportInfoRow(
                                  theme: theme,
                                  label: 'HORA FIN',
                                  value: state.report!.endTime,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(
                            color: Colors.white10,
                            height: 1,
                          ), // REGLA: Separadores
                          const SizedBox(height: 16),
                          Text(
                            'DESCRIPCIÓN',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 12,
                            ),
                          ),
                          Html(
                            data: state.report!.description ?? '',
                            style: {
                              "body": Style(
                                color: colorScheme.onSurface,
                                margin: Margins.zero,
                                fontSize: FontSize(14),
                              ),
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 2. CONTEXT (PROJECT & EMPLOYEE)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IndustrialCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              WorkReportSectionHeader(
                                theme: theme,
                                title: 'SUPERVISOR',
                                icon: Icons.person_outline,
                              ),
                              const SizedBox(height: 12),
                              WorkReportInfoRow(
                                theme: theme,
                                label: 'NOMBRE',
                                value: state.report!.employee?.fullName,
                              ),
                              const SizedBox(height: 8),
                              WorkReportInfoRow(
                                theme: theme,
                                label: 'POSICIÓN',
                                value: state.report!.employee?.position?.name,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        IndustrialCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              WorkReportSectionHeader(
                                theme: theme,
                                title: 'PROYECTO',
                                icon: Icons.work_outline,
                              ),
                              const SizedBox(height: 12),
                              WorkReportInfoRow(
                                theme: theme,
                                label: 'NOMBRE',
                                value: state.report!.project?.name,
                              ),
                              const SizedBox(height: 8),
                              WorkReportInfoRow(
                                theme: theme,
                                label: 'ESTADO',
                                value: state.report!.project?.status,
                              ),
                              if (state.report!.project?.subClient != null) ...[
                                const SizedBox(height: 8),
                                WorkReportInfoRow(
                                  theme: theme,
                                  label: 'CLIENTE',
                                  value: state.report!.project?.subClient?.name,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // 3. RESOURCES SECTION
                    IndustrialCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          WorkReportSectionHeader(
                            theme: theme,
                            title: 'RECURSOS Y EJECUCIÓN',
                            icon: Icons.construction,
                          ),
                          const SizedBox(height: 12),
                          WorkReportResourceBlock(
                            theme: theme,
                            title: 'HERRAMIENTAS',
                            htmlContent: state.report!.resources?.tools,
                          ),
                          const Divider(color: Colors.white10),
                          WorkReportResourceBlock(
                            theme: theme,
                            title: 'PERSONAL',
                            htmlContent: state.report!.resources?.personnel,
                          ),
                          const Divider(color: Colors.white10),
                          WorkReportResourceBlock(
                            theme: theme,
                            title: 'MATERIALES',
                            htmlContent:
                                (state.report!.resources?.materials?.isEmpty ??
                                    true)
                                ? ''
                                : state.report!.resources!.materials,
                          ),
                          const Divider(color: Colors.white10),
                          WorkReportResourceBlock(
                            theme: theme,
                            title: 'SUGERENCIAS',
                            htmlContent: state.report!.suggestions,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 4. PHOTOS SECTION
                    if (state.report!.photos != null &&
                        state.report!.photos!.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          'EVIDENCIAS (${state.report!.summary?.photosCount ?? 0})',
                          style: theme.textTheme.bodySmall?.copyWith(
                            letterSpacing: 1.0,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      ...state.report!.photos!.map(
                        (photo) =>
                            WorkReportPhotoCard(theme: theme, photo: photo),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // 5. SIGNATURES & TIMESTAMPS
                    IndustrialCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          WorkReportSectionHeader(
                            theme: theme,
                            title: 'VALIDACIÓN',
                            icon: Icons.verified_user_outlined,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              if (state.report!.signatures?.supervisor != null)
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'SUPERVISOR',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(fontSize: 10),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.white10,
                                          ),
                                        ),
                                        child: ImageViewer(
                                          url: _extractDataUri(
                                            state
                                                .report!
                                                .signatures!
                                                .supervisor!,
                                          ),
                                          height: 100,
                                          width: double.infinity,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (state.report!.signatures?.supervisor !=
                                      null &&
                                  state.report!.signatures?.manager != null)
                                const SizedBox(width: 16),
                              if (state.report!.signatures?.manager != null)
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'MANAGER',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(fontSize: 10),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.white10,
                                          ),
                                        ),
                                        child: ImageViewer(
                                          url: _extractDataUri(
                                            state.report!.signatures!.manager!,
                                          ),
                                          height: 100,
                                          width: double.infinity,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(color: Colors.white10),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'CREADO: ${state.report!.timestamps?.createdAt ?? '-'}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontSize: 10,
                                    color: colorScheme.onSurface.withOpacity(
                                      0.5,
                                    ),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'UPDATED: ${state.report!.timestamps?.updatedAt ?? '-'}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontSize: 10,
                                    color: colorScheme.onSurface.withOpacity(
                                      0.5,
                                    ),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40), // Bottom padding
                  ],
                ),
              ),
      ),
    );
  }
}

// --- WIDGETS AUXILIARES PRIVADOS PARA DISEÑO INDUSTRIAL MOVIDOS A WIDGETS DEDICADOS ---

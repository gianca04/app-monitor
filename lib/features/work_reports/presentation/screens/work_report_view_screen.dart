import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_html/flutter_html.dart';
import 'dart:io';
import 'package:open_file/open_file.dart';
import '../providers/work_reports_provider.dart';
import '../../../photos/presentation/widgets/image_viewer.dart';
import '../../../photos/presentation/widgets/image_preview_modal.dart';
import '../../../../core/widgets/industrial_card.dart';
import '../../../../core/widgets/modern_bottom_modal.dart';
import '../../../work_report_pdf/presentation/providers/work_report_pdf_provider.dart';

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

  Future<void> _downloadPdf(BuildContext context, WidgetRef ref) async {
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

  void _goBack(BuildContext context) {
    context.go('/work-reports');
  }

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
                // Show loading indicator or block UI could be better, but keeping it simple as per previous pattern
                await ref
                    .read(workReportsProvider.notifier)
                    .deleteWorkReport(id);
                // On success, go back to list
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Reporte eliminado exitosamente'),
                    ),
                  );
                  context.go('/work-reports');
                }
              } catch (e) {
                // Error handled by provider/UI, but generally show snackbar
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al eliminar: $e')),
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
                    onTap: () => _downloadPdf(context, ref),
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
                          _SectionHeader(
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
                                child: _InfoRow(
                                  theme: theme,
                                  label: 'FECHA',
                                  value: state.report!.reportDate,
                                ),
                              ),
                              Expanded(
                                child: _InfoRow(
                                  theme: theme,
                                  label: 'HORA INICIO',
                                  value: state.report!.startTime,
                                ),
                              ),
                              Expanded(
                                child: _InfoRow(
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
                              _SectionHeader(
                                theme: theme,
                                title: 'SUPERVISOR',
                                icon: Icons.person_outline,
                              ),
                              const SizedBox(height: 12),
                              _InfoRow(
                                theme: theme,
                                label: 'NOMBRE',
                                value: state.report!.employee?.fullName,
                              ),
                              const SizedBox(height: 8),
                              _InfoRow(
                                theme: theme,
                                label: 'PISICIÓN',
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
                              _SectionHeader(
                                theme: theme,
                                title: 'PROYECTO',
                                icon: Icons.work_outline,
                              ),
                              const SizedBox(height: 12),
                              _InfoRow(
                                theme: theme,
                                label: 'NOMBRE',
                                value: state.report!.project?.name,
                              ),
                              const SizedBox(height: 8),
                              _InfoRow(
                                theme: theme,
                                label: 'ESTADO',
                                value: state.report!.project?.status,
                              ),
                              if (state.report!.project?.subClient != null) ...[
                                const SizedBox(height: 8),
                                _InfoRow(
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
                          _SectionHeader(
                            theme: theme,
                            title: 'RECURSOS Y EJECUCIÓN',
                            icon: Icons.construction,
                          ),
                          const SizedBox(height: 12),
                          _ResourceBlock(
                            theme: theme,
                            title: 'HERRAMIENTAS',
                            htmlContent: state.report!.resources?.tools,
                          ),
                          const Divider(color: Colors.white10),
                          _ResourceBlock(
                            theme: theme,
                            title: 'PERSONAL',
                            htmlContent: state.report!.resources?.personnel,
                          ),
                          const Divider(color: Colors.white10),
                          _ResourceBlock(
                            theme: theme,
                            title: 'MATERIALES',
                            htmlContent:
                                (state.report!.resources?.materials?.isEmpty ??
                                    true)
                                ? ''
                                : state.report!.resources!.materials,
                          ),
                          const Divider(color: Colors.white10),
                          _ResourceBlock(
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
                        (photo) => _PhotoEntryCard(theme: theme, photo: photo),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // 5. SIGNATURES & TIMESTAMPS
                    IndustrialCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionHeader(
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

// --- WIDGETS AUXILIARES PRIVADOS PARA DISEÑO INDUSTRIAL ---

class _SectionHeader extends StatelessWidget {
  final ThemeData theme;
  final String title;
  final IconData icon;
  const _SectionHeader({
    required this.theme,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final ThemeData theme;
  final String label;
  final String? value;
  const _InfoRow({required this.theme, required this.label, this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 10,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value ?? 'N/A',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _ResourceBlock extends StatelessWidget {
  final ThemeData theme;
  final String title;
  final String? htmlContent;
  const _ResourceBlock({
    required this.theme,
    required this.title,
    this.htmlContent,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
          Html(
            data: htmlContent ?? '',
            style: {
              "body": Style(
                color: theme.colorScheme.onSurface,
                margin: Margins.zero,
                fontSize: FontSize(13),
              ),
            },
          ),
        ],
      ),
    );
  }
}

class _PhotoEntryCard extends StatelessWidget {
  final ThemeData theme;
  final dynamic photo; // Tipar esto correctamente con tu modelo si es posible
  const _PhotoEntryCard({required this.theme, required this.photo});

  void _showPhotoModal(
    BuildContext context,
    String url,
    String title,
    String? description,
  ) {
    ModernBottomModal.show(
      context,
      title: title,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => _showFullScreenPhoto(context, url, title, description),
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: ImageViewer(
                url: url,
                width: MediaQuery.of(context).size.width,
                fit: BoxFit.fitWidth,
              ),
            ),
          ),
          if (description != null && description.isNotEmpty) ...[
            const SizedBox(height: 16),
            Html(
              data: description,
              style: {
                "body": Style(
                  color: theme.colorScheme.onSurface,
                  fontSize: FontSize(14),
                ),
              },
            ),
          ],
        ],
      ),
    );
  }

  void _showFullScreenPhoto(
    BuildContext context,
    String url,
    String title,
    String? description,
  ) {
    ImagePreviewModal.show(
      context,
      url: url,
      title: title,
      description: description,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        border: Border.all(color: theme.colorScheme.outline),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: theme.colorScheme.outline),
              ),
            ),
            child: Text(
              'PHOTO ID: ${photo.id ?? 'N/A'}',
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 10,
                fontFamily: 'monospace',
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (photo.beforeWork.photoPath != null)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ANTES',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () => _showPhotoModal(
                            context,
                            photo.beforeWork.photoPath!,
                            'FOTO ANTES DEL TRABAJO',
                            photo.beforeWork.description,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white10),
                            ),
                            child: ImageViewer(
                              url: photo.beforeWork.photoPath!,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Html(
                          data: photo.beforeWork.description ?? '',
                          style: {
                            "body": Style(
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.7,
                              ),
                              fontSize: FontSize(11),
                            ),
                          },
                        ),
                      ],
                    ),
                  ),
                if (photo.beforeWork.photoPath != null &&
                    photo.afterWork.photoPath != null)
                  const SizedBox(width: 12),
                if (photo.afterWork.photoPath != null)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DESPUES',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () => _showPhotoModal(
                            context,
                            photo.afterWork.photoPath!,
                            'FOTO DESPUÉS DEL TRABAJO',
                            photo.afterWork.description,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white10),
                            ),
                            child: ImageViewer(
                              url: photo.afterWork.photoPath!,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Html(
                          data: photo.afterWork.description ?? '',
                          style: {
                            "body": Style(
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.7,
                              ),
                              fontSize: FontSize(11),
                            ),
                          },
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

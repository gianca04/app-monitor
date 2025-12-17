import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/widgets/industrial_card.dart';
import '../../domain/entities/work_report_local_entity.dart';
import '../../../work_report_photos_local/domain/entities/work_report_photo_local_entity.dart';

// Definimos constantes locales para mantener la regla del 4
const double _kRadius = 4.0;
const double _kGridSpacing = 2.0;

class WorkReportLocalListItem extends StatelessWidget {
  final WorkReportLocalEntity report;
  final List<WorkReportPhotoLocalEntity> photos;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onSync;

  const WorkReportLocalListItem({
    super.key,
    required this.report,
    this.photos = const [],
    this.onEdit,
    this.onDelete,
    this.onSync,
  });

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return IndustrialCard(
      child: InkWell(
        onTap: () => context.go('/work-reports-local/${report.id}/edit'),
        borderRadius: BorderRadius.circular(_kRadius),
        child: Padding(
          padding: const EdgeInsets.all(0.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. HEADER: NAME & ID ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      report.name.toUpperCase(),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _SyncStatusBadge(
                        isSynced: report.isSynced,
                        hasError: report.syncError != null,
                      ),
                      const SizedBox(width: 6),
                      _IdBadge(id: report.id),
                    ],
                  ),
                ],
              ),

              // --- 2. DESCRIPTION (HTML PREVIEW) ---
              if (report.description != null && report.description!.isNotEmpty) ...[
                const SizedBox(height: 6),
                SizedBox(
                  height: 42,
                  child: Html(
                    data: report.description!,
                    style: {
                      "body": Style(
                        margin: Margins.zero,
                        padding: HtmlPaddings.zero,
                        fontSize: FontSize(13),
                        color: colorScheme.onSurface.withOpacity(0.7),
                        fontFamily: theme.textTheme.bodyMedium?.fontFamily,
                      ),
                      "p": Style(margin: Margins.zero, padding: HtmlPaddings.zero),
                    },
                  ),
                ),
              ],

              // --- 3. PHOTO GRID (TWITTER STYLE) ---
              if (photos.isNotEmpty) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 180,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(_kRadius),
                    child: _PhotoGrid(photos: photos),
                  ),
                ),
              ],

              // --- 4. SIGNATURES INDICATOR ---
              if (report.supervisorSignature != null || report.managerSignature != null) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (report.supervisorSignature != null)
                      _SignatureBadge(
                        label: 'SUPERVISOR',
                        icon: Icons.check_circle_outline,
                      ),
                    if (report.managerSignature != null)
                      _SignatureBadge(
                        label: 'GERENTE',
                        icon: Icons.check_circle_outline,
                      ),
                  ],
                ),
              ],

              const SizedBox(height: 12),
              const Divider(height: 1, color: Colors.white10),
              const SizedBox(height: 10),

              // --- 5. FOOTER: METADATA & ACTIONS ---
              Row(
                children: [
                  // Info Contextual
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FooterInfo(
                          icon: Icons.calendar_today_outlined,
                          text: _formatDate(report.createdAt),
                        ),
                        const SizedBox(height: 4),
                        _FooterInfo(
                          icon: Icons.work_outline,
                          text: 'PROYECTO #${report.projectId}',
                          isBold: true,
                        ),
                        if (report.startTime != null || report.endTime != null) ...[
                          const SizedBox(height: 4),
                          _FooterInfo(
                            icon: Icons.access_time,
                            text: '${report.startTime ?? 'N/A'} - ${report.endTime ?? 'N/A'}',
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Botones de Acción
                  Row(
                    children: [
                      if (!report.isSynced && onSync != null) ...[
                        _IndustrialActionButton(
                          icon: Icons.cloud_upload_outlined,
                          onTap: onSync,
                          color: Colors.greenAccent,
                          theme: theme,
                        ),
                        const SizedBox(width: 8),
                      ],
                      _IndustrialActionButton(
                        icon: Icons.edit_outlined,
                        onTap: onEdit ?? () => context.go('/work-reports-local/${report.id}/edit'),
                        theme: theme,
                      ),
                      if (onDelete != null) ...[
                        const SizedBox(width: 8),
                        _IndustrialActionButton(
                          icon: Icons.delete_outline,
                          onTap: onDelete,
                          color: theme.colorScheme.error,
                          theme: theme,
                        ),
                      ],
                    ],
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

// --- GRID LÓGICO DE IMÁGENES (Twitter Style) ---

class _PhotoGrid extends StatelessWidget {
  final List<WorkReportPhotoLocalEntity> photos;

  const _PhotoGrid({required this.photos});

  @override
  Widget build(BuildContext context) {
    int count = photos.length;

    if (count == 0) return const SizedBox();
    if (count == 1) return _buildImage(photos[0]);
    if (count == 2) {
      return Row(
        children: [
          Expanded(child: _buildImage(photos[0])),
          const SizedBox(width: _kGridSpacing),
          Expanded(child: _buildImage(photos[1])),
        ],
      );
    }
    if (count == 3) {
      return Row(
        children: [
          Expanded(child: _buildImage(photos[0])),
          const SizedBox(width: _kGridSpacing),
          Expanded(
            child: Column(
              children: [
                Expanded(child: _buildImage(photos[1])),
                const SizedBox(height: _kGridSpacing),
                Expanded(child: _buildImage(photos[2])),
              ],
            ),
          ),
        ],
      );
    }
    // 4 o más
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(child: _buildImage(photos[0])),
              const SizedBox(width: _kGridSpacing),
              Expanded(child: _buildImage(photos[1])),
            ],
          ),
        ),
        const SizedBox(height: _kGridSpacing),
        Expanded(
          child: Row(
            children: [
              Expanded(child: _buildImage(photos[2])),
              const SizedBox(width: _kGridSpacing),
              Expanded(
                child: count > 4
                    ? _buildOverlayImage(photos[3], count - 4)
                    : _buildImage(photos[3]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImage(WorkReportPhotoLocalEntity photo) {
    final path = _getImagePath(photo);
    if (path == null || path.isEmpty) {
      return Container(
        color: Colors.black12,
        width: double.infinity,
        height: double.infinity,
        child: const Center(
          child: Icon(Icons.broken_image, size: 20, color: Colors.white24),
        ),
      );
    }
    return Container(
      color: Colors.black12,
      width: double.infinity,
      height: double.infinity,
      child: Image.file(
        File(path),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Icon(Icons.broken_image, size: 20, color: Colors.white24),
        ),
      ),
    );
  }

  Widget _buildOverlayImage(WorkReportPhotoLocalEntity photo, int remaining) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildImage(photo),
        Container(
          color: Colors.black.withOpacity(0.6),
          child: Center(
            child: Text(
              '+$remaining',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String? _getImagePath(WorkReportPhotoLocalEntity photo) {
    return photo.photoPath ?? photo.beforeWorkPhotoPath;
  }
}// --- SUB-WIDGETS PRIVADOS PARA ORDEN ---

class _IdBadge extends StatelessWidget {
  final int? id;
  const _IdBadge({required this.id});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(_kRadius),
        border: Border.all(color: Colors.white10),
      ),
      child: Text(
        '#${id ?? '000'}',
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _SyncStatusBadge extends StatelessWidget {
  final bool isSynced;
  final bool hasError;

  const _SyncStatusBadge({required this.isSynced, required this.hasError});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final IconData icon;

    if (isSynced) {
      color = Colors.greenAccent;
      icon = Icons.cloud_done;
    } else if (hasError) {
      color = Colors.redAccent;
      icon = Icons.cloud_off;
    } else {
      color = Colors.orangeAccent;
      icon = Icons.cloud_queue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(_kRadius),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Icon(icon, size: 14, color: color),
    );
  }
}

class _SignatureBadge extends StatelessWidget {
  final String label;
  final IconData icon;

  const _SignatureBadge({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    const color = Colors.blueAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(_kRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
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

class _FooterInfo extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isBold;

  const _FooterInfo({required this.icon, required this.text, this.isBold = false});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface.withOpacity(0.6);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text.toUpperCase(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 11,
              color: isBold ? Theme.of(context).colorScheme.primary : color,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _IndustrialActionButton extends StatelessWidget {
  final String? label;
  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;
  final ThemeData theme;

  const _IndustrialActionButton({
    this.label,
    required this.icon,
    required this.theme,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final finalColor = color ?? theme.colorScheme.primary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_kRadius),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: finalColor.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(_kRadius),
          ),
          child: Row(
            children: [
              Icon(icon, size: 14, color: finalColor),
              if (label != null) ...[
                const SizedBox(width: 6),
                Text(
                  label!,
                  style: TextStyle(
                    color: finalColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

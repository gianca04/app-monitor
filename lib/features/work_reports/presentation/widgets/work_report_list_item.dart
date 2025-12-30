import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:go_router/go_router.dart';
import 'package:monitor/core/theme_config.dart'; // Asumo que tienes esto
import 'package:monitor/core/widgets/industrial_card.dart';
import 'package:monitor/core/widgets/industrial_feedback.dart';
import '../../data/models/work_report.dart';
import '../providers/work_reports_provider.dart';

// Definimos constantes locales para mantener la regla del 4
const double _kRadius = 4.0;
const double _kGridSpacing = 2.0;

class WorkReportListItem extends ConsumerWidget {
  final WorkReport report;
  // Botones de acción eliminados por solicitud del usuario
  // Se han movido a la vista de detalle

  const WorkReportListItem({super.key, required this.report});

  // Helper para manejar URLs o Base64 si es necesario
  String _getImageUrl(dynamic photo) {
    // Ajusta esta lógica según tu modelo de Photo.
    // Asumo que photo tiene una propiedad 'url' o 'path' o 'beforeWork.photoPath'
    // Ejemplo basado en tu código anterior:
    return photo.afterWork?.photoPath ?? photo.beforeWork?.photoPath ?? '';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Filtramos fotos válidas para el grid
    final photos = report.photos ?? [];
    // NOTA: Ajusta la lógica de arriba según cómo venga tu lista de fotos en el modelo WorkReport

    return IndustrialCard(
      child: InkWell(
        onTap: () => context.go('/work-reports/${report.id}'),
        borderRadius: BorderRadius.circular(_kRadius),
        child: Padding(
          padding: const EdgeInsets.all(0.0), // Padding más compacto
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. HEADER: NAME & ID ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      report.name?.toUpperCase() ?? 'UNTITLED REPORT',
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
                  _IdBadge(id: report.id),
                ],
              ),

              // --- 2. DESCRIPTION (HTML PREVIEW) ---
              if (report.description != null &&
                  report.description!.isNotEmpty) ...[
                const SizedBox(height: 6),
                SizedBox(
                  height:
                      42, // Altura fija para mantener uniformidad (aprox 2 líneas)
                  child: Html(
                    data: report.description!,
                    style: {
                      "body": Style(
                        margin: Margins.zero,
                        padding: HtmlPaddings.zero,
                        fontSize: FontSize(13),
                        color: colorScheme.onSurface.withOpacity(0.7),
                        maxLines: 2,
                        textOverflow: TextOverflow.ellipsis,
                        fontFamily: theme.textTheme.bodyMedium?.fontFamily,
                      ),
                      "p": Style(
                        margin: Margins.zero,
                        padding: HtmlPaddings.zero,
                      ),
                    },
                  ),
                ),
              ],

              // --- 3. PHOTO GRID (TWITTER STYLE) ---
              if (photos.isNotEmpty) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 180, // Altura contenida para el grid
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(_kRadius),
                    child: _PhotoGrid(
                      photos: photos,
                      getImageUrl: _getImageUrl,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 12),
              const Divider(height: 1, color: Colors.white10),
              const SizedBox(height: 10),

              // --- 4. FOOTER: METADATA ---
              Row(
                children: [
                  // Info Contextual
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FooterInfo(
                          icon: Icons.calendar_today_outlined,
                          text: report.reportDate ?? 'NO DATE',
                        ),
                        if (report.project?.name != null) ...[
                          const SizedBox(height: 4),
                          _FooterInfo(
                            icon: Icons.work_outline,
                            text: report.project!.name!,
                            isBold: true,
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Indicador visual simple para "ver detalles"
                  Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.onSurface.withOpacity(0.3),
                    size: 20,
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

// --- SUB-WIDGETS PRIVADOS PARA ORDEN ---

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

class _FooterInfo extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isBold;

  const _FooterInfo({
    required this.icon,
    required this.text,
    this.isBold = false,
  });

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

// _IndustrialActionButton eliminado ya que no se usa

// --- GRID LÓGICO DE IMÁGENES (Twitter Style) ---

class _PhotoGrid extends StatelessWidget {
  final List<dynamic> photos;
  final String Function(dynamic) getImageUrl;

  const _PhotoGrid({required this.photos, required this.getImageUrl});

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

  Widget _buildImage(dynamic photo) {
    final url = getImageUrl(photo);
    return Container(
      color: Colors.black12, // Placeholder color
      width: double.infinity,
      height: double.infinity,
      child: Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Icon(Icons.broken_image, size: 20, color: Colors.white24),
        ),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOverlayImage(dynamic photo, int remaining) {
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
}

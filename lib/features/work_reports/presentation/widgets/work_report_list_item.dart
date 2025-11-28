import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:monitor/core/widgets/industrial_card.dart';
import 'package:monitor/core/theme_config.dart';
import '../../data/models/work_report.dart';

class WorkReportListItem extends StatelessWidget {
  final WorkReport report;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const WorkReportListItem({
    super.key,
    required this.report,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return IndustrialCard(
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
                      style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'Courier'),
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
                    onTap: onEdit ?? () => context.go('/work-reports/${report.id}/edit'),
                  ),
                  const SizedBox(width: 8),
                  _ActionButton(
                    icon: Icons.delete_outline,
                    color: theme.colorScheme.error,
                    onTap: onDelete,
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

// Widget auxiliar para botones pequeños
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;

  const _ActionButton({required this.icon, this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.border),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, size: 18, color: color ?? AppTheme.textSecondary),
      ),
    );
  }
}
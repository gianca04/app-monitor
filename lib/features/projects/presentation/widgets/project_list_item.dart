import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme_config.dart';
import '../../../../core/widgets/industrial_card.dart';
import '../../data/models/project.dart';

class ProjectListItem extends StatelessWidget {
  final Project project;
  final VoidCallback? onTap;

  const ProjectListItem({super.key, required this.project, this.onTap});

  String _formatDateRange(String? start, String? end) {
    if (start == null && end == null) return 'Sin fecha definida';

    String formatSingleDate(String? dateStr) {
      if (dateStr == null) return '-';
      try {
        final date = DateTime.parse(dateStr);
        return DateFormat('dd/MM/yyyy').format(date);
      } catch (_) {
        return dateStr.split('T')[0];
      }
    }

    return '${formatSingleDate(start)}  ~  ${formatSingleDate(end)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final count = project.reportsCount ?? 0;

    return IndustrialCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Project Name
                Text(
                  project.name ?? 'Sin nombre',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // Client & Sub-Client Badges
                if (project.clientName != null ||
                    project.subClientName != null) ...[
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (project.clientName != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.secondaryAccent.withOpacity(0.08),
                            border: Border.all(
                              color: AppTheme.secondaryAccent.withOpacity(0.3),
                              width: 0.5,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${project.clientName}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.secondaryAccent,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      if (project.subClientName != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.textSecondary.withOpacity(0.06),
                            border: Border.all(
                              color: AppTheme.textSecondary.withOpacity(0.2),
                              width: 0.5,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${project.subClientName}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w500,
                              fontSize: 11,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],

                // Date Range
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 12,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _formatDateRange(project.startDate, project.endDate),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Right: Report Count Pill and Navigation Chevron
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: count > 0
                      ? AppTheme.primaryAccent
                      : AppTheme.borderHighContrast.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.insert_drive_file_outlined,
                      size: 11,
                      color: count > 0 ? Colors.white : AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: count > 0 ? Colors.white : AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.borderHighContrast,
                size: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

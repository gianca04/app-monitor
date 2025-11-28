import 'package:flutter/material.dart';
import '../../../../core/theme_config.dart';
import '../../../../core/widgets/industrial_card.dart';
import '../../data/models/project.dart';

class ProjectListItem extends StatelessWidget {
  final Project project;
  final VoidCallback? onTap;

  const ProjectListItem({
    super.key,
    required this.project,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IndustrialCard(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  project.name ?? 'Sin nombre',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  project.location ?? 'Sin ubicación',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${project.startDate ?? ''} - ${project.endDate ?? ''}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
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
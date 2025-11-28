import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme_config.dart';
import '../../../../core/widgets/industrial_card.dart';
import '../../data/models/photo.dart';

class PhotoListItem extends StatelessWidget {
  final Photo photo;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const PhotoListItem({
    super.key,
    required this.photo,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return IndustrialCard(
      onTap: () => context.go('/photos/${photo.id}'),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Photo ${photo.id} - Work Report ${photo.workReportId}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'After: ${photo.afterWork.description ?? 'No description'}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Before: ${photo.beforeWork.description ?? 'No description'}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ActionButton(
                icon: Icons.visibility,
                onTap: () => context.go('/photos/${photo.id}'),
                color: AppTheme.primaryAccent,
              ),
              const SizedBox(width: 8),
              _ActionButton(
                icon: Icons.edit,
                onTap: onEdit ?? () => context.go('/photos/${photo.id}/edit'),
                color: AppTheme.info,
              ),
              const SizedBox(width: 8),
              _ActionButton(
                icon: Icons.delete,
                onTap: onDelete,
                color: AppTheme.error,
              ),
            ],
          ),
        ],
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
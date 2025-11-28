import 'package:flutter/material.dart';
import '../../../../core/theme_config.dart';
import '../../../../core/widgets/industrial_card.dart';
import '../../data/models/employee.dart';

class EmployeeListItem extends StatelessWidget {
  final Employee employee;
  final VoidCallback? onTap;

  const EmployeeListItem({
    super.key,
    required this.employee,
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
                  employee.fullName ?? 'No name',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${employee.documentType ?? ''} ${employee.documentNumber ?? ''}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
                if (employee.dateContract != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Contrato: ${employee.dateContract}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                ],
              ],
            ),
          ),
          if (employee.active != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: employee.active! ? AppTheme.success : AppTheme.error,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                employee.active! ? 'Activo' : 'Inactivo',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
        ],
      ),
    );
  }
}
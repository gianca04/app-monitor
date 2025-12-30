import 'package:flutter/material.dart';

class WorkReportSectionHeader extends StatelessWidget {
  final ThemeData theme;
  final String title;
  final IconData icon;
  const WorkReportSectionHeader({
    super.key,
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

import 'package:flutter/material.dart';

class WorkReportInfoRow extends StatelessWidget {
  final ThemeData theme;
  final String label;
  final String? value;
  const WorkReportInfoRow({
    super.key,
    required this.theme,
    required this.label,
    this.value,
  });

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

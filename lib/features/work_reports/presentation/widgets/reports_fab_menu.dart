import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ReportsFabMenu extends StatefulWidget {
  const ReportsFabMenu({super.key});

  @override
  State<ReportsFabMenu> createState() => _ReportsFabMenuState();
}

class _ReportsFabMenuState extends State<ReportsFabMenu> {
  bool _isExpanded = false;

  void _toggle() {
    setState(() => _isExpanded = !_isExpanded);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_isExpanded) ...[
          _FabOption(
            icon: Icons.cloud_upload_outlined,
            label: 'NUBE',
            onTap: () => context.go('/work-reports/create?type=cloud'),
          ),
          const SizedBox(height: 12),
          _FabOption(
            icon: Icons.save_as_outlined,
            label: 'LOCAL',
            onTap: () => context.go('/work-reports/create?type=local'),
          ),
          const SizedBox(height: 12),
        ],
        FloatingActionButton(
          heroTag: 'main_fab',
          onPressed: _toggle,
          child: Icon(_isExpanded ? Icons.close : Icons.add),
        ),
      ],
    );
  }
}

class _FabOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _FabOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: theme.colorScheme.outline),
          ),
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
        const SizedBox(width: 8),
        FloatingActionButton(
          mini: true,
          heroTag: label,
          onPressed: onTap,
          child: Icon(icon),
        ),
      ],
    );
  }
}
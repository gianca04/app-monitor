import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../settings/providers/connectivity_provider.dart';
import '../../../settings/services/connectivity_service.dart';

class ReportsFabMenu extends ConsumerStatefulWidget {
  const ReportsFabMenu({super.key});

  @override
  ConsumerState<ReportsFabMenu> createState() => _ReportsFabMenuState();
}

class _ReportsFabMenuState extends ConsumerState<ReportsFabMenu> {
  bool _isExpanded = false;

  void _toggle() {
    setState(() => _isExpanded = !_isExpanded);
  }

  @override
  Widget build(BuildContext context) {
    final connectivityAsync = ref.watch(connectionStatusProvider);
    final isOnline = connectivityAsync.maybeWhen(
      data: (status) => status == ConnectionStatus.online,
      orElse: () => false,
    );

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_isExpanded) ...[
          _FabOption(
            icon: Icons.save_as_outlined,
            label: 'LOCAL',
            enabled: true,
            onTap: () => context.go('/work-reports/create?type=local'),
          ),
          const SizedBox(height: 12),
          _FabOption(
            icon: Icons.cloud_upload_outlined,
            label: 'NUBE',
            enabled: isOnline,
            onTap: isOnline ? () => context.go('/work-reports/create?type=cloud') : null,
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
  final bool enabled;
  final VoidCallback? onTap;

  const _FabOption({
    required this.icon,
    required this.label,
    required this.enabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final button = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: enabled ? theme.colorScheme.surface : theme.colorScheme.surface.withOpacity(0.5),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: enabled ? theme.colorScheme.outline : theme.colorScheme.outline.withOpacity(0.5)),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: enabled ? null : theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ),
        const SizedBox(width: 8),
        FloatingActionButton(
          mini: true,
          heroTag: label,
          onPressed: enabled ? onTap : null,
          backgroundColor: enabled ? null : theme.colorScheme.surface.withOpacity(0.5),
          foregroundColor: enabled ? null : theme.colorScheme.onSurface.withOpacity(0.5),
          child: Icon(icon),
        ),
      ],
    );

    if (!enabled) {
      return Tooltip(
        message: "Requiere conexión a internet",
        child: button,
      );
    }

    return button;
  }
}
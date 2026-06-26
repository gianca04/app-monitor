import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme_config.dart';
import '../../../../core/widgets/modern_bottom_modal.dart';
import '../widgets/work_report_form.dart';

class WorkReportCreateScreen extends StatelessWidget {
  final int? projectId;

  const WorkReportCreateScreen({super.key, this.projectId});

  void _goBack(BuildContext context) {
    if (projectId != null) {
      context.go('/work-reports/project/$projectId');
    } else {
      context.go('/work-reports');
    }
  }

  Future<bool> _showExitConfirmation(BuildContext context) async {
    final confirmed = await ModernBottomModal.show<bool>(
      context,
      title: 'DESCARTAR INFORME',
      content: const Text(
        'El informe de trabajo no se guardará y perderá los datos ingresados.',
        style: TextStyle(color: AppTheme.textSecondary),
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.kRadius),
              ),
            ),
            child: const Text(
              'DESCARTAR INFORME',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context, false),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.primaryAccent),
              foregroundColor: AppTheme.primaryAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.kRadius),
              ),
            ),
            child: const Text('SEGUIR EDITANDO'),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await _showExitConfirmation(context);
        if (shouldExit && context.mounted) {
          _goBack(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              final shouldExit = await _showExitConfirmation(context);
              if (shouldExit && context.mounted) {
                _goBack(context);
              }
            },
          ),
          title: const Text('Crear Reporte en la Nube'),
        ),
        body: WorkReportForm(preselectedProjectId: projectId),
      ),
    );
  }
}

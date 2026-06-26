import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme_config.dart';
import '../../../../core/widgets/modern_bottom_modal.dart';
import '../widgets/work_report_edit_form.dart';
import '../providers/work_reports_provider.dart';

class WorkReportEditScreen extends ConsumerWidget {
  final int id;

  const WorkReportEditScreen({super.key, required this.id});

  void _goBack(BuildContext context, int? projectId) {
    if (context.canPop()) {
      context.pop();
    } else if (projectId != null) {
      context.go('/work-reports/project/$projectId');
    } else {
      context.go('/work-reports');
    }
  }

  Future<bool> _showExitConfirmation(BuildContext context) async {
    final confirmed = await ModernBottomModal.show<bool>(
      context,
      title: 'DESCARTAR CAMBIOS',
      content: const Text(
        '¿Desea salir sin guardar los cambios del reporte de trabajo?',
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
              'DESCARTAR CAMBIOS',
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
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(workReportProvider(id));
    final projectId = state.report?.project?.id;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await _showExitConfirmation(context);
        if (shouldExit && context.mounted) {
          _goBack(context, projectId);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              final shouldExit = await _showExitConfirmation(context);
              if (shouldExit && context.mounted) {
                _goBack(context, projectId);
              }
            },
          ),
          title: const Text('Editar Reporte de trabajo'),
        ),
        body: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : state.error != null
            ? Center(child: Text('Error: ${state.error}'))
            : state.report == null
            ? const Center(child: Text('No se encontro el reporte'))
            : WorkReportEditForm(report: state.report!),
      ),
    );
  }
}

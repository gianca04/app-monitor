import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/work_report_form.dart';

class WorkReportCreateScreen extends StatelessWidget {
  const WorkReportCreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final queryParams = GoRouterState.of(context).uri.queryParameters;
    final type = queryParams['type']; // 'local' or 'cloud'

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/work-reports'),
        ),
        title: Text(type == 'local' ? 'Crear Reporte Local' : 'Crear Reporte en la Nube'),
      ),
      body: WorkReportForm(saveType: type),
    );
  }
}
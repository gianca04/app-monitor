import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widgets/work_report_edit_form.dart';
import '../providers/work_reports_provider.dart';

class WorkReportEditScreen extends ConsumerWidget {
  final int id;

  const WorkReportEditScreen({super.key, required this.id});

  void _goBack(BuildContext context) {
    context.go('/work-reports');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(workReportProvider(id));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _goBack(context);
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _goBack(context),
          ),
          title: const Text('Edit Work Report'),
        ),
        body: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : state.error != null
            ? Center(child: Text('Error: ${state.error}'))
            : state.report == null
            ? const Center(child: Text('Report not found'))
            : WorkReportEditForm(report: state.report!),
      ),
    );
  }
}

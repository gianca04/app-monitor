import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/work_report_form.dart';
import '../providers/work_reports_provider.dart';

class WorkReportEditScreen extends ConsumerWidget {
  final int id;

  const WorkReportEditScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(workReportProvider(id));

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Work Report')),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(child: Text('Error: ${state.error}'))
              : state.report == null
                  ? const Center(child: Text('Report not found'))
                  : WorkReportForm(report: state.report!),
    );
  }
}
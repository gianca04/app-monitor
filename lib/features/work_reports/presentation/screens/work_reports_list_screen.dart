import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/work_reports_provider.dart';

class WorkReportsListScreen extends ConsumerStatefulWidget {
  const WorkReportsListScreen({super.key});

  @override
  ConsumerState<WorkReportsListScreen> createState() => _WorkReportsListScreenState();
}

class _WorkReportsListScreenState extends ConsumerState<WorkReportsListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(workReportsProvider.notifier).loadWorkReports());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(workReportsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Work Reports')),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(child: Text('Error: ${state.error}'))
              : ListView.builder(
                  itemCount: state.reports.length,
                  itemBuilder: (context, index) {
                    final report = state.reports[index];
                    return ListTile(
                      title: Text(report.name ?? 'N/A'),
                      subtitle: Text('${report.description ?? ''}\n${report.reportDate ?? ''}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.visibility),
                            onPressed: () => context.go('/work-reports/${report.id}'),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => context.go('/work-reports/${report.id}/edit'),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _deleteReport(report.id!),
                          ),
                        ],
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/work-reports/create'),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _deleteReport(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Report'),
        content: const Text('Are you sure you want to delete this report?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(workReportsProvider.notifier).deleteWorkReport(id);
              Navigator.of(context).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
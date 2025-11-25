import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/work_reports_provider.dart';

class WorkReportViewScreen extends ConsumerWidget {
  final int id;

  const WorkReportViewScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(workReportProvider(id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Work Report Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.go('/work-reports/$id/edit'),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(child: Text('Error: ${state.error}'))
              : state.report == null
                  ? const Center(child: Text('Report not found'))
                  : Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Name: ${state.report!.name}', style: const TextStyle(fontSize: 18)),
                          const SizedBox(height: 8),
                          Text('Description: ${state.report!.description}'),
                          const SizedBox(height: 8),
                          Text('Report Date: ${state.report!.reportDate}'),
                          const SizedBox(height: 8),
                          Text('Start Time: ${state.report!.startTime ?? 'N/A'}'),
                          const SizedBox(height: 8),
                          Text('End Time: ${state.report!.endTime ?? 'N/A'}'),
                          const SizedBox(height: 8),
                          Text('Suggestions: ${state.report!.suggestions}'),
                        ],
                      ),
                    ),
    );
  }
}
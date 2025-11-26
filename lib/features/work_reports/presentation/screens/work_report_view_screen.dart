import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_html/flutter_html.dart';
import '../providers/work_reports_provider.dart';
import '../../../photos/presentation/widgets/image_viewer.dart';

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
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Name: ${state.report!.name}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            const Text('Description:', style: TextStyle(fontWeight: FontWeight.bold)),
                            Html(data: state.report!.description),
                            const SizedBox(height: 8),
                            Text('Report Date: ${state.report!.reportDate}'),
                            const SizedBox(height: 8),
                            Text('Start Time: ${state.report!.startTime ?? 'N/A'}'),
                            const SizedBox(height: 8),
                            Text('End Time: ${state.report!.endTime ?? 'N/A'}'),
                            const SizedBox(height: 16),
                            const Text('Resources:', style: TextStyle(fontWeight: FontWeight.bold)),
                            const Text('Tools:', style: TextStyle(fontWeight: FontWeight.bold)),
                            Html(data: state.report!.resources.tools),
                            const Text('Personnel:', style: TextStyle(fontWeight: FontWeight.bold)),
                            Html(data: state.report!.resources.personnel),
                            const Text('Materials:', style: TextStyle(fontWeight: FontWeight.bold)),
                            Html(data: state.report!.resources.materials.isEmpty ? 'None' : state.report!.resources.materials),
                            const SizedBox(height: 16),
                            const Text('Suggestions:', style: TextStyle(fontWeight: FontWeight.bold)),
                            Html(data: state.report!.suggestions),
                            const SizedBox(height: 16),
                            const Text('Signatures:', style: TextStyle(fontWeight: FontWeight.bold)),
                            if (state.report!.signatures.supervisor != null) ...[
                              const Text('Supervisor:'),
                              ImageViewer(url: state.report!.signatures.supervisor!),
                            ],
                            if (state.report!.signatures.manager != null) ...[
                              const Text('Manager:'),
                              ImageViewer(url: state.report!.signatures.manager!),
                            ],
                            const SizedBox(height: 16),
                            const Text('Timestamps:', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('Created At: ${state.report!.timestamps.createdAt}'),
                            Text('Updated At: ${state.report!.timestamps.updatedAt}'),
                            const SizedBox(height: 16),
                            const Text('Employee:', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('Name: ${state.report!.employee.fullName}'),
                            Text('Position: ${state.report!.employee.position.name}'),
                            const SizedBox(height: 16),
                            const Text('Project:', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('Name: ${state.report!.project.name}'),
                            Text('Status: ${state.report!.project.status}'),
                            Text('Start Date: ${state.report!.project.dates.startDate ?? 'N/A'}'),
                            Text('End Date: ${state.report!.project.dates.endDate ?? 'N/A'}'),
                            if (state.report!.project.subClient != null) ...[
                              Text('Sub Client: ${state.report!.project.subClient!.name}'),
                            ],
                            const SizedBox(height: 16),
                            const Text('Photos:', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('Count: ${state.report!.summary.photosCount}'),
                            ...state.report!.photos.map((photo) => Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8),
                                Text('Photo ID: ${photo.id}'),
                                if (photo.beforeWork.photoUrl != null) ...[
                                  const Text('Before Work:', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ImageViewer(url: photo.beforeWork.photoUrl!),
                                  Html(data: photo.beforeWork.description),
                                ],
                                if (photo.afterWork.photoUrl != null) ...[
                                  const Text('After Work:', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ImageViewer(url: photo.afterWork.photoUrl!),
                                  Html(data: photo.afterWork.description),
                                ],
                              ],
                            )),
                          ],
                        ),
                      ),
                    ),
    );
  }
}
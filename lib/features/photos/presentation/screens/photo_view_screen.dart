import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/photos_provider.dart';

class PhotoViewScreen extends ConsumerWidget {
  final int id;

  const PhotoViewScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(photoProvider(id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Photo Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.go('/photos/$id/edit'),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(child: Text('Error: ${state.error}'))
              : state.photo == null
                  ? const Center(child: Text('Photo not found'))
                  : Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ID: ${state.photo!.id}', style: const TextStyle(fontSize: 18)),
                          const SizedBox(height: 8),
                          Text('Work Report ID: ${state.photo!.workReportId}'),
                          const SizedBox(height: 16),
                          const Text('After Work:', style: TextStyle(fontWeight: FontWeight.bold)),
                          if (state.photo!.afterWork.photoUrl != null)
                            Image.network(state.photo!.afterWork.photoUrl!),
                          Text('Description: ${state.photo!.afterWork.description}'),
                          const SizedBox(height: 16),
                          const Text('Before Work:', style: TextStyle(fontWeight: FontWeight.bold)),
                          if (state.photo!.beforeWork.photoUrl != null)
                            Image.network(state.photo!.beforeWork.photoUrl!),
                          Text('Description: ${state.photo!.beforeWork.description}'),
                          const SizedBox(height: 16),
                          Text('Created At: ${state.photo!.timestamps.createdAt}'),
                          Text('Updated At: ${state.photo!.timestamps.updatedAt}'),
                        ],
                      ),
                    ),
    );
  }
}
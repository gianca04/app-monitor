import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/photos_provider.dart';

class PhotosListScreen extends ConsumerStatefulWidget {
  const PhotosListScreen({super.key});

  @override
  ConsumerState<PhotosListScreen> createState() => _PhotosListScreenState();
}

class _PhotosListScreenState extends ConsumerState<PhotosListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(photosProvider.notifier).loadPhotos());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(photosProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Photos')),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(child: Text('Error: ${state.error}'))
              : ListView.builder(
                  itemCount: state.photos.length,
                  itemBuilder: (context, index) {
                    final photo = state.photos[index];
                    return ListTile(
                      title: Text('Photo ${photo.id} - Work Report ${photo.workReportId}'),
                      subtitle: Text('After: ${photo.afterWork.description}\nBefore: ${photo.beforeWork.description}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.visibility),
                            onPressed: () => context.go('/photos/${photo.id}'),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => context.go('/photos/${photo.id}/edit'),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _deletePhoto(photo.id!),
                          ),
                        ],
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/photos/create'),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _deletePhoto(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Photo'),
        content: const Text('Are you sure you want to delete this photo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(photosProvider.notifier).deletePhoto(id);
              Navigator.of(context).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
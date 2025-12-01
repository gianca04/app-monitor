import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/photo_local_providers.dart';
import '../../domain/entities/photo_local.dart';
import '../../domain/entities/after_work.dart';
import '../../domain/entities/before_work.dart';
import '../../domain/entities/timestamps.dart';

class PhotosLocalPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photoLocals = ref.watch(photoLocalNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Photos Local'),
      ),
      body: ListView.builder(
        itemCount: photoLocals.length,
        itemBuilder: (context, index) {
          final photoLocal = photoLocals[index];
          return ListTile(
            title: Text('Work Report ID: ${photoLocal.workReportId}'),
            subtitle: Text('After Work: ${photoLocal.afterWork}, Before Work: ${photoLocal.beforeWork}'),
            trailing: IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                ref.read(photoLocalNotifierProvider.notifier).removePhotoLocal(photoLocal.id!);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // For demo, add a sample photo local
          final newPhotoLocal = PhotoLocal(
            workReportId: 1,
            afterWork: AfterWork.yes,
            beforeWork: BeforeWork.no,
            timestamps: Timestamps(
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
          ref.read(photoLocalNotifierProvider.notifier).addPhotoLocal(newPhotoLocal);
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
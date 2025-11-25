import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/photos_provider.dart';
import '../widgets/photo_form.dart';

class PhotoEditScreen extends ConsumerWidget {
  final int id;

  const PhotoEditScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(photoProvider(id));

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Photo')),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(child: Text('Error: ${state.error}'))
              : state.photo == null
                  ? const Center(child: Text('Photo not found'))
                  : PhotoForm(photo: state.photo!),
    );
  }
}
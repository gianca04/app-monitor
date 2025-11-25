import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/photos_provider.dart';
import '../widgets/photo_form.dart';

class PhotoCreateScreen extends ConsumerWidget {
  const PhotoCreateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Photo')),
      body: const PhotoForm(),
    );
  }
}
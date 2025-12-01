import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/usecases/photo_local_usecases.dart';
import '../../domain/entities/photo_local.dart';
import '../../data/repositories/photo_local_repository_impl.dart';
import '../../data/datasources/photo_local_local_datasource_impl.dart';
import '../../data/models/photo_local_model.dart';
import 'package:hive/hive.dart';

// Providers for dependencies
final photoLocalBoxProvider = Provider<Box<PhotoLocalModel>>((ref) {
  return Hive.box<PhotoLocalModel>('photoLocalBox');
});

final photoLocalDataSourceProvider = Provider<PhotoLocalLocalDataSourceImpl>((ref) {
  final box = ref.watch(photoLocalBoxProvider);
  return PhotoLocalLocalDataSourceImpl(box);
});

final photoLocalRepositoryProvider = Provider<PhotoLocalRepositoryImpl>((ref) {
  final dataSource = ref.watch(photoLocalDataSourceProvider);
  return PhotoLocalRepositoryImpl(dataSource);
});

// Use cases
final getPhotoLocalsProvider = Provider<GetPhotoLocals>((ref) {
  final repo = ref.watch(photoLocalRepositoryProvider);
  return GetPhotoLocals(repo);
});

final savePhotoLocalProvider = Provider<SavePhotoLocal>((ref) {
  final repo = ref.watch(photoLocalRepositoryProvider);
  return SavePhotoLocal(repo);
});

final deletePhotoLocalProvider = Provider<DeletePhotoLocal>((ref) {
  final repo = ref.watch(photoLocalRepositoryProvider);
  return DeletePhotoLocal(repo);
});

// State notifier for list of photo locals
class PhotoLocalNotifier extends StateNotifier<List<PhotoLocal>> {
  final GetPhotoLocals getPhotoLocals;
  final SavePhotoLocal savePhotoLocal;
  final DeletePhotoLocal deletePhotoLocal;

  PhotoLocalNotifier(this.getPhotoLocals, this.savePhotoLocal, this.deletePhotoLocal) : super([]) {
    loadPhotoLocals();
  }

  Future<void> loadPhotoLocals() async {
    final photoLocals = await getPhotoLocals();
    state = photoLocals;
  }

  Future<void> addPhotoLocal(PhotoLocal photoLocal) async {
    await savePhotoLocal(photoLocal);
    await loadPhotoLocals();
  }

  Future<void> removePhotoLocal(int id) async {
    await deletePhotoLocal(id);
    await loadPhotoLocals();
  }
}

final photoLocalNotifierProvider = StateNotifierProvider<PhotoLocalNotifier, List<PhotoLocal>>((ref) {
  final getPhotoLocals = ref.watch(getPhotoLocalsProvider);
  final savePhotoLocal = ref.watch(savePhotoLocalProvider);
  final deletePhotoLocal = ref.watch(deletePhotoLocalProvider);
  return PhotoLocalNotifier(getPhotoLocals, savePhotoLocal, deletePhotoLocal);
});
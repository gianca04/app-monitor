import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/usecases/get_photos_usecase.dart';
import '../../domain/usecases/get_photo_usecase.dart';
import '../../domain/usecases/create_photo_usecase.dart';
import '../../domain/usecases/update_photo_usecase.dart';
import '../../domain/usecases/delete_photo_usecase.dart';
import '../../data/models/photo.dart';
import '../../data/datasources/photos_datasource.dart';
import '../../data/repositories/photos_repository_impl.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

// Providers para dependencias
final photosDataSourceProvider = Provider((ref) => PhotosDataSourceImpl(ref.watch(authenticatedDioProvider)));
final photosRepositoryProvider = Provider((ref) => PhotosRepositoryImpl(ref.watch(photosDataSourceProvider)));
final getPhotosUseCaseProvider = Provider((ref) => GetPhotosUseCase(ref.watch(photosRepositoryProvider)));
final getPhotoUseCaseProvider = Provider((ref) => GetPhotoUseCase(ref.watch(photosRepositoryProvider)));
final createPhotoUseCaseProvider = Provider((ref) => CreatePhotoUseCase(ref.watch(photosRepositoryProvider)));
final updatePhotoUseCaseProvider = Provider((ref) => UpdatePhotoUseCase(ref.watch(photosRepositoryProvider)));
final deletePhotoUseCaseProvider = Provider((ref) => DeletePhotoUseCase(ref.watch(photosRepositoryProvider)));

// Estado para la lista
class PhotosState {
  final List<Photo> photos;
  final bool isLoading;
  final String? error;

  PhotosState({
    this.photos = const [],
    this.isLoading = false,
    this.error,
  });

  PhotosState copyWith({
    List<Photo>? photos,
    bool? isLoading,
    String? error,
  }) {
    return PhotosState(
      photos: photos ?? this.photos,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// Estado para un solo photo
class PhotoState {
  final Photo? photo;
  final bool isLoading;
  final String? error;

  PhotoState({
    this.photo,
    this.isLoading = false,
    this.error,
  });

  PhotoState copyWith({
    Photo? photo,
    bool? isLoading,
    String? error,
  }) {
    return PhotoState(
      photo: photo ?? this.photo,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class PhotosNotifier extends StateNotifier<PhotosState> {
  final GetPhotosUseCase getPhotosUseCase;
  final CreatePhotoUseCase createPhotoUseCase;
  final UpdatePhotoUseCase updatePhotoUseCase;
  final DeletePhotoUseCase deletePhotoUseCase;

  PhotosNotifier(
    this.getPhotosUseCase,
    this.createPhotoUseCase,
    this.updatePhotoUseCase,
    this.deletePhotoUseCase,
  ) : super(PhotosState());

  Future<void> loadPhotos() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final photos = await getPhotosUseCase.call();
      state = state.copyWith(photos: photos, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> createPhoto(int workReportId, MultipartFile photo, String descripcion, MultipartFile? beforeWorkPhoto, String? beforeWorkDescripcion) async {
    try {
      final newPhoto = await createPhotoUseCase.call(workReportId, photo, descripcion, beforeWorkPhoto, beforeWorkDescripcion);
      state = state.copyWith(photos: [...state.photos, newPhoto]);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updatePhoto(int id, MultipartFile? photo, String descripcion, MultipartFile? beforeWorkPhoto, String? beforeWorkDescripcion) async {
    try {
      final updatedPhoto = await updatePhotoUseCase.call(id, photo, descripcion, beforeWorkPhoto, beforeWorkDescripcion);
      final updatedPhotos = state.photos.map((p) => p.id == id ? updatedPhoto : p).toList();
      state = state.copyWith(photos: updatedPhotos);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deletePhoto(int id) async {
    try {
      await deletePhotoUseCase.call(id);
      final updatedPhotos = state.photos.where((p) => p.id != id).toList();
      state = state.copyWith(photos: updatedPhotos);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final photosProvider = StateNotifierProvider<PhotosNotifier, PhotosState>((ref) {
  return PhotosNotifier(
    ref.watch(getPhotosUseCaseProvider),
    ref.watch(createPhotoUseCaseProvider),
    ref.watch(updatePhotoUseCaseProvider),
    ref.watch(deletePhotoUseCaseProvider),
  );
});

class PhotoNotifier extends StateNotifier<PhotoState> {
  final GetPhotoUseCase getPhotoUseCase;

  PhotoNotifier(this.getPhotoUseCase) : super(PhotoState());

  Future<void> loadPhoto(int id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final photo = await getPhotoUseCase.call(id);
      state = state.copyWith(photo: photo, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final photoProvider = StateNotifierProvider.family<PhotoNotifier, PhotoState, int>((ref, id) {
  return PhotoNotifier(ref.watch(getPhotoUseCaseProvider));
});
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/work_report_pdf_datasource.dart';
import '../../data/repositories/work_report_pdf_repository_impl.dart';
import '../../domain/usecases/download_work_report_pdf_usecase.dart';

// Provider para el DataSource
final workReportPdfDataSourceProvider = Provider<WorkReportPdfDataSource>((ref) {
  final dio = ref.watch(authenticatedDioProvider);
  return WorkReportPdfDataSourceImpl(dio);
});

// Provider para el Repository
final workReportPdfRepositoryProvider = Provider((ref) {
  final dataSource = ref.watch(workReportPdfDataSourceProvider);
  return WorkReportPdfRepositoryImpl(dataSource);
});

// Provider para el UseCase
final downloadWorkReportPdfUseCaseProvider = Provider((ref) {
  final repository = ref.watch(workReportPdfRepositoryProvider);
  return DownloadWorkReportPdfUseCase(repository);
});

// Estado para la descarga del PDF
class WorkReportPdfState {
  final bool isDownloading;
  final File? downloadedFile;
  final String? error;
  final double? progress;

  WorkReportPdfState({
    this.isDownloading = false,
    this.downloadedFile,
    this.error,
    this.progress,
  });

  WorkReportPdfState copyWith({
    bool? isDownloading,
    File? downloadedFile,
    String? error,
    double? progress,
  }) {
    return WorkReportPdfState(
      isDownloading: isDownloading ?? this.isDownloading,
      downloadedFile: downloadedFile ?? this.downloadedFile,
      error: error,
      progress: progress,
    );
  }
}

// Notifier para manejar el estado de descarga
class WorkReportPdfNotifier extends StateNotifier<WorkReportPdfState> {
  final DownloadWorkReportPdfUseCase downloadUseCase;

  WorkReportPdfNotifier(this.downloadUseCase) : super(WorkReportPdfState());

  Future<File?> downloadPdf(int workReportId) async {
    state = state.copyWith(
      isDownloading: true,
      error: null,
      downloadedFile: null,
    );

    try {
      final file = await downloadUseCase(workReportId);
      state = state.copyWith(
        isDownloading: false,
        downloadedFile: file,
      );
      return file;
    } on DioException catch (e) {
      String errorMessage;
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.connectionError) {
        errorMessage = 'Error de conexión. Verifica tu conexión a internet.';
      } else if (e.type == DioExceptionType.badResponse) {
        errorMessage = 'Error del servidor. Inténtalo más tarde.';
      } else {
        errorMessage = 'Error al descargar el PDF. Por favor, intenta nuevamente.';
      }
      state = state.copyWith(
        isDownloading: false,
        error: errorMessage,
      );
      return null;
    } catch (e) {
      state = state.copyWith(
        isDownloading: false,
        error: 'Error inesperado al descargar el PDF. Por favor, intenta nuevamente.',
      );
      return null;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void reset() {
    state = WorkReportPdfState();
  }
}

// Provider principal para el estado de descarga
final workReportPdfProvider =
    StateNotifierProvider<WorkReportPdfNotifier, WorkReportPdfState>((ref) {
  final downloadUseCase = ref.watch(downloadWorkReportPdfUseCaseProvider);
  return WorkReportPdfNotifier(downloadUseCase);
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/datasources/quill_converter_data_source.dart';
import '../data/repositories/quill_converter_repository_impl.dart';
import '../domain/repositories/quill_converter_repository.dart';
import '../domain/usecases/quill_converter/convert_html_to_quill.dart';
import '../domain/usecases/quill_converter/convert_quill_to_html.dart';

/// Provider for the data source
final quillConverterDataSourceProvider = Provider<QuillConverterDataSource>(
  (ref) => QuillConverterDataSourceImpl(),
);

/// Provider for the repository
final quillConverterRepositoryProvider = Provider<QuillConverterRepository>(
  (ref) => QuillConverterRepositoryImpl(
    dataSource: ref.watch(quillConverterDataSourceProvider),
  ),
);

/// Provider for the ConvertQuillToHtml use case
final convertQuillToHtmlProvider = Provider<ConvertQuillToHtml>(
  (ref) => ConvertQuillToHtml(
    ref.watch(quillConverterRepositoryProvider),
  ),
);

/// Provider for the ConvertHtmlToQuill use case
final convertHtmlToQuillProvider = Provider<ConvertHtmlToQuill>(
  (ref) => ConvertHtmlToQuill(
    ref.watch(quillConverterRepositoryProvider),
  ),
);

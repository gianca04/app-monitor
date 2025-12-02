import 'package:dartz/dartz.dart';
import '../../error/failures.dart';
import '../../domain/entities/quill_conversion_result.dart';
import '../../domain/repositories/quill_converter_repository.dart';
import '../datasources/quill_converter_data_source.dart';

/// Implementation of QuillConverterRepository
class QuillConverterRepositoryImpl implements QuillConverterRepository {
  final QuillConverterDataSource dataSource;

  QuillConverterRepositoryImpl({
    required this.dataSource,
  });

  @override
  Future<Either<Failure, QuillConversionResult>> convertQuillToHtml(
    String quillDeltaJson,
  ) async {
    try {
      final html = dataSource.convertQuillToHtml(quillDeltaJson);
      return Right(QuillConversionResult(content: html));
    } catch (e) {
      return Left(
        ServerFailure(
          'Failed to convert Quill to HTML: ${e.toString()}',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, QuillConversionResult>> convertHtmlToQuill(
    String html,
  ) async {
    try {
      final quillJson = dataSource.convertHtmlToQuill(html);
      return Right(QuillConversionResult(content: quillJson));
    } catch (e) {
      return Left(
        ServerFailure(
          'Failed to convert HTML to Quill: ${e.toString()}',
        ),
      );
    }
  }
}

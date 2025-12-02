import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../entities/quill_conversion_result.dart';

/// Repository interface for Quill/HTML conversions
abstract class QuillConverterRepository {
  /// Converts Quill Delta JSON to HTML
  Future<Either<Failure, QuillConversionResult>> convertQuillToHtml(
    String quillDeltaJson,
  );

  /// Converts HTML to Quill Delta JSON
  Future<Either<Failure, QuillConversionResult>> convertHtmlToQuill(
    String html,
  );
}

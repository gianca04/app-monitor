import 'package:dartz/dartz.dart';
import '../../../error/failures.dart';
import '../../entities/quill_conversion_result.dart';
import '../../repositories/quill_converter_repository.dart';

/// Use case to convert Quill Delta JSON to HTML
class ConvertQuillToHtml {
  final QuillConverterRepository repository;

  ConvertQuillToHtml(this.repository);

  Future<Either<Failure, QuillConversionResult>> call(
    String quillDeltaJson,
  ) async {
    return await repository.convertQuillToHtml(quillDeltaJson);
  }
}

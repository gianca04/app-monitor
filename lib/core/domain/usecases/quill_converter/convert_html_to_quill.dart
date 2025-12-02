import 'package:dartz/dartz.dart';
import '../../../error/failures.dart';
import '../../entities/quill_conversion_result.dart';
import '../../repositories/quill_converter_repository.dart';

/// Use case to convert HTML to Quill Delta JSON
class ConvertHtmlToQuill {
  final QuillConverterRepository repository;

  ConvertHtmlToQuill(this.repository);

  Future<Either<Failure, QuillConversionResult>> call(String html) async {
    return await repository.convertHtmlToQuill(html);
  }
}

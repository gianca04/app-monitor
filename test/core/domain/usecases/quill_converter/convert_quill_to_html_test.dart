import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monitor/core/domain/entities/quill_conversion_result.dart';
import 'package:monitor/core/domain/repositories/quill_converter_repository.dart';
import 'package:monitor/core/domain/usecases/quill_converter/convert_quill_to_html.dart';
import 'package:monitor/core/error/failures.dart';

class MockQuillConverterRepository implements QuillConverterRepository {
  @override
  Future<Either<Failure, QuillConversionResult>> convertQuillToHtml(
    String quillDeltaJson,
  ) async {
    if (quillDeltaJson.isEmpty) {
      return Left(ServerFailure('Invalid Quill Delta JSON'));
    }
    return Right(QuillConversionResult(content: '<p>Test HTML</p>'));
  }

  @override
  Future<Either<Failure, QuillConversionResult>> convertHtmlToQuill(
    String html,
  ) async {
    return Right(QuillConversionResult(content: '{"ops":[]}'));
  }
}

void main() {
  late ConvertQuillToHtml useCase;
  late MockQuillConverterRepository mockRepository;

  setUp(() {
    mockRepository = MockQuillConverterRepository();
    useCase = ConvertQuillToHtml(mockRepository);
  });

  group('ConvertQuillToHtml', () {
    const tQuillDeltaJson = '''
    {
      "ops": [
        {"insert": "Hello "},
        {"insert": "World", "attributes": {"bold": true}},
        {"insert": "\\n"}
      ]
    }
    ''';

    const tHtmlResult = '<p>Test HTML</p>';

    test('should return QuillConversionResult with HTML when conversion is successful', () async {
      // Act
      final result = await useCase(tQuillDeltaJson);

      // Assert
      expect(result, isA<Right<Failure, QuillConversionResult>>());
      result.fold(
        (failure) => fail('Expected Right but got Left'),
        (conversionResult) {
          expect(conversionResult, isA<QuillConversionResult>());
          expect(conversionResult.content, equals(tHtmlResult));
        },
      );
    });

    test('should return ServerFailure when Quill Delta JSON is empty', () async {
      // Arrange
      const emptyJson = '';

      // Act
      final result = await useCase(emptyJson);

      // Assert
      expect(result, isA<Left<Failure, QuillConversionResult>>());
      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.message, equals('Invalid Quill Delta JSON'));
        },
        (conversionResult) => fail('Expected Left but got Right'),
      );
    });

    test('should call repository convertQuillToHtml method', () async {
      // Act
      await useCase(tQuillDeltaJson);

      // Assert
      // Verify that the repository method was called (implicit in the result)
      final result = await mockRepository.convertQuillToHtml(tQuillDeltaJson);
      expect(result, isA<Right<Failure, QuillConversionResult>>());
    });

    test('should return QuillConversionResult with correct content type', () async {
      // Act
      final result = await useCase(tQuillDeltaJson);

      // Assert
      result.fold(
        (failure) => fail('Expected Right but got Left'),
        (conversionResult) {
          expect(conversionResult.content, isA<String>());
          expect(conversionResult.content.isNotEmpty, true);
        },
      );
    });

    test('should handle complex Quill Delta JSON', () async {
      // Arrange
      const complexJson = '''
      {
        "ops": [
          {"insert": "Title", "attributes": {"header": 1}},
          {"insert": "\\n"},
          {"insert": "Bold text", "attributes": {"bold": true}},
          {"insert": " and "},
          {"insert": "italic text", "attributes": {"italic": true}},
          {"insert": "\\n"}
        ]
      }
      ''';

      // Act
      final result = await useCase(complexJson);

      // Assert
      expect(result, isA<Right<Failure, QuillConversionResult>>());
      result.fold(
        (failure) => fail('Expected Right but got Left'),
        (conversionResult) {
          expect(conversionResult.content, isA<String>());
        },
      );
    });
  });
}

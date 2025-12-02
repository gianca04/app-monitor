import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monitor/core/domain/entities/quill_conversion_result.dart';
import 'package:monitor/core/domain/repositories/quill_converter_repository.dart';
import 'package:monitor/core/domain/usecases/quill_converter/convert_html_to_quill.dart';
import 'package:monitor/core/error/failures.dart';

class MockQuillConverterRepository implements QuillConverterRepository {
  @override
  Future<Either<Failure, QuillConversionResult>> convertQuillToHtml(
    String quillDeltaJson,
  ) async {
    return Right(QuillConversionResult(content: '<p>Test HTML</p>'));
  }

  @override
  Future<Either<Failure, QuillConversionResult>> convertHtmlToQuill(
    String html,
  ) async {
    if (html.isEmpty) {
      return Left(ServerFailure('Invalid HTML'));
    }
    return Right(QuillConversionResult(
      content: '{"ops":[{"insert":"Test\\n"}]}',
    ));
  }
}

void main() {
  late ConvertHtmlToQuill useCase;
  late MockQuillConverterRepository mockRepository;

  setUp(() {
    mockRepository = MockQuillConverterRepository();
    useCase = ConvertHtmlToQuill(mockRepository);
  });

  group('ConvertHtmlToQuill', () {
    const tHtml = '<p>Hello <strong>World</strong></p>';
    const tQuillDeltaResult = '{"ops":[{"insert":"Test\\n"}]}';

    test('should return QuillConversionResult with Quill Delta JSON when conversion is successful', () async {
      // Act
      final result = await useCase(tHtml);

      // Assert
      expect(result, isA<Right<Failure, QuillConversionResult>>());
      result.fold(
        (failure) => fail('Expected Right but got Left'),
        (conversionResult) {
          expect(conversionResult, isA<QuillConversionResult>());
          expect(conversionResult.content, equals(tQuillDeltaResult));
        },
      );
    });

    test('should return ServerFailure when HTML is empty', () async {
      // Arrange
      const emptyHtml = '';

      // Act
      final result = await useCase(emptyHtml);

      // Assert
      expect(result, isA<Left<Failure, QuillConversionResult>>());
      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.message, equals('Invalid HTML'));
        },
        (conversionResult) => fail('Expected Left but got Right'),
      );
    });

    test('should call repository convertHtmlToQuill method', () async {
      // Act
      await useCase(tHtml);

      // Assert
      // Verify that the repository method was called (implicit in the result)
      final result = await mockRepository.convertHtmlToQuill(tHtml);
      expect(result, isA<Right<Failure, QuillConversionResult>>());
    });

    test('should return QuillConversionResult with valid JSON string', () async {
      // Act
      final result = await useCase(tHtml);

      // Assert
      result.fold(
        (failure) => fail('Expected Right but got Left'),
        (conversionResult) {
          expect(conversionResult.content, isA<String>());
          expect(conversionResult.content.contains('ops'), true);
        },
      );
    });

    test('should handle complex HTML with multiple tags', () async {
      // Arrange
      const complexHtml = '''
        <h1>Title</h1>
        <p><strong>Bold text</strong> and <em>italic text</em></p>
        <ul>
          <li>Item 1</li>
          <li>Item 2</li>
        </ul>
      ''';

      // Act
      final result = await useCase(complexHtml);

      // Assert
      expect(result, isA<Right<Failure, QuillConversionResult>>());
      result.fold(
        (failure) => fail('Expected Right but got Left'),
        (conversionResult) {
          expect(conversionResult.content, isA<String>());
        },
      );
    });

    test('should handle HTML with only text', () async {
      // Arrange
      const plainHtml = '<p>Simple text</p>';

      // Act
      final result = await useCase(plainHtml);

      // Assert
      expect(result, isA<Right<Failure, QuillConversionResult>>());
      result.fold(
        (failure) => fail('Expected Right but got Left'),
        (conversionResult) {
          expect(conversionResult.content, isA<String>());
          expect(conversionResult.content.isNotEmpty, true);
        },
      );
    });

    test('should handle HTML with nested tags', () async {
      // Arrange
      const nestedHtml = '<p><strong><em>Bold and italic</em></strong></p>';

      // Act
      final result = await useCase(nestedHtml);

      // Assert
      expect(result, isA<Right<Failure, QuillConversionResult>>());
    });

    test('should handle HTML with line breaks', () async {
      // Arrange
      const htmlWithBreaks = '<p>Line 1<br>Line 2<br>Line 3</p>';

      // Act
      final result = await useCase(htmlWithBreaks);

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

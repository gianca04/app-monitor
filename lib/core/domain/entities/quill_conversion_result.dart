import 'package:equatable/equatable.dart';

/// Entity representing the result of a Quill/HTML conversion
class QuillConversionResult extends Equatable {
  final String content;

  const QuillConversionResult({
    required this.content,
  });

  @override
  List<Object?> get props => [content];
}

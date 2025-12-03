import 'dart:convert';
import 'package:fleather/fleather.dart';
import 'package:parchment/codecs.dart';

/// Data source for Quill/HTML conversions
abstract class QuillConverterDataSource {
  /// Converts Quill Delta JSON to HTML
  String convertQuillToHtml(String quillDeltaJson);

  /// Converts HTML to Quill Delta JSON
  String convertHtmlToQuill(String html);
}

/// Implementation of QuillConverterDataSource using Fleather's native Parchment codecs
class QuillConverterDataSourceImpl implements QuillConverterDataSource {
  final ParchmentHtmlCodec _htmlCodec = const ParchmentHtmlCodec();

  @override
  String convertQuillToHtml(String quillDeltaJson) {
    try {
      // Parse the JSON string to get the delta operations
      final Map<String, dynamic> deltaMap = json.decode(quillDeltaJson);
      final List<dynamic> ops = deltaMap['ops'] ?? [];

      // Create a ParchmentDocument from the delta
      final doc = ParchmentDocument.fromJson(ops);

      // Convert to HTML using Parchment's native codec
      final html = _htmlCodec.encode(doc);
      print('🔄 [Delta→HTML] Output: ${html.substring(0, html.length > 100 ? 100 : html.length)}...');
      return html;
    } catch (e) {
      print('❌ [Delta→HTML] Error: $e');
      throw Exception('Failed to convert Quill to HTML: $e');
    }
  }

  @override
  String convertHtmlToQuill(String html) {
    try {
      // Check if input is empty or just whitespace
      if (html.trim().isEmpty) {
        return json.encode({'ops': [{'insert': '\n'}]});
      }

      print('🔄 [HTML→Delta] Input: ${html.substring(0, html.length > 100 ? 100 : html.length)}...');

      // Use Parchment's native HTML codec for robust HTML to Delta conversion
      final doc = _htmlCodec.decode(html);
      final delta = doc.toDelta();
      
      // Convert to JSON format
      final List<dynamic> ops = delta.toJson();
      final Map<String, dynamic> deltaMap = {'ops': ops};
      
      final result = json.encode(deltaMap);
      print('🔄 [HTML→Delta] Output: ${result.substring(0, result.length > 200 ? 200 : result.length)}...');
      return result;
    } catch (e) {
      print('❌ [HTML→Delta] Error: $e');
      // Return a simple delta with the HTML as plain text (fallback)
      return json.encode({
        'ops': [
          {'insert': _stripHtmlTags(html)},
          {'insert': '\n'}
        ]
      });
    }
  }

  /// Strips HTML tags from a string (fallback for error cases)
  String _stripHtmlTags(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .trim();
  }
}

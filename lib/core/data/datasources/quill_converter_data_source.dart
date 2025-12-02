import 'dart:convert';
import 'package:fleather/fleather.dart';

/// Data source for Quill/HTML conversions
abstract class QuillConverterDataSource {
  /// Converts Quill Delta JSON to HTML
  String convertQuillToHtml(String quillDeltaJson);

  /// Converts HTML to Quill Delta JSON
  String convertHtmlToQuill(String html);
}

/// Implementation of QuillConverterDataSource using Fleather
class QuillConverterDataSourceImpl implements QuillConverterDataSource {
  @override
  String convertQuillToHtml(String quillDeltaJson) {
    try {
      // Parse the JSON string to get the delta operations
      final Map<String, dynamic> deltaMap = json.decode(quillDeltaJson);
      final List<dynamic> ops = deltaMap['ops'] ?? [];

      // Create a ParchmentDocument from the delta
      final doc = ParchmentDocument.fromJson(ops);

      // Convert to HTML
      final html = _documentToHtml(doc);
      return html;
    } catch (e) {
      throw Exception('Failed to convert Quill to HTML: $e');
    }
  }

  @override
  String convertHtmlToQuill(String html) {
    try {
      // Parse HTML and convert to Delta operations
      final doc = _htmlToDocument(html);

      // Convert document to JSON
      final delta = doc.toDelta();
      final Map<String, dynamic> deltaMap = {
        'ops': delta.toJson(),
      };

      return json.encode(deltaMap);
    } catch (e) {
      throw Exception('Failed to convert HTML to Quill: $e');
    }
  }

  /// Helper method to convert ParchmentDocument to HTML
  String _documentToHtml(ParchmentDocument doc) {
    final StringBuffer buffer = StringBuffer();
    
    for (final node in doc.root.children) {
      if (node is LineNode) {
        _lineToHtml(node, buffer);
      }
    }

    return buffer.toString();
  }

  /// Helper method to convert a line node to HTML
  void _lineToHtml(LineNode line, StringBuffer buffer) {
    final style = line.style;
    final isHeading = style.get(ParchmentAttribute.heading) != null;
    final isList = style.get(ParchmentAttribute.block) != null;

    if (isHeading) {
      final level = style.get(ParchmentAttribute.heading)?.value ?? 1;
      buffer.write('<h$level>');
      _writeInlineContent(line, buffer);
      buffer.write('</h$level>');
    } else if (isList) {
      final blockType = style.get(ParchmentAttribute.block)?.value;
      if (blockType == 'ul') {
        buffer.write('<li>');
        _writeInlineContent(line, buffer);
        buffer.write('</li>');
      } else if (blockType == 'ol') {
        buffer.write('<li>');
        _writeInlineContent(line, buffer);
        buffer.write('</li>');
      } else {
        buffer.write('<p>');
        _writeInlineContent(line, buffer);
        buffer.write('</p>');
      }
    } else {
      buffer.write('<p>');
      _writeInlineContent(line, buffer);
      buffer.write('</p>');
    }
  }

  /// Helper method to write inline content with formatting
  void _writeInlineContent(LineNode line, StringBuffer buffer) {
    for (final child in line.children) {
      if (child is TextNode) {
        final text = child.value;
        final style = child.style;

        final isBold = style.contains(ParchmentAttribute.bold);
        final isItalic = style.contains(ParchmentAttribute.italic);
        final isUnderline = style.contains(ParchmentAttribute.underline);
        final isStrikethrough = style.contains(ParchmentAttribute.strikethrough);

        String content = text.toString();

        if (isBold) content = '<strong>$content</strong>';
        if (isItalic) content = '<em>$content</em>';
        if (isUnderline) content = '<u>$content</u>';
        if (isStrikethrough) content = '<s>$content</s>';

        buffer.write(content);
      }
    }
  }

  /// Helper method to convert HTML to ParchmentDocument
  ParchmentDocument _htmlToDocument(String html) {
    // Basic HTML parsing - converts common tags to Quill operations
    final delta = Delta();
    
    // Remove HTML tags and create plain text document
    // This is a simplified version - you might want to use an HTML parser
    final plainText = html
        .replaceAll(RegExp(r'<h[1-6]>'), '')
        .replaceAll(RegExp(r'</h[1-6]>'), '\n')
        .replaceAll(RegExp(r'<p>'), '')
        .replaceAll(RegExp(r'</p>'), '\n')
        .replaceAll(RegExp(r'<br\s*/?>'), '\n')
        .replaceAll(RegExp(r'<strong>|</strong>'), '')
        .replaceAll(RegExp(r'<em>|</em>'), '')
        .replaceAll(RegExp(r'<u>|</u>'), '')
        .replaceAll(RegExp(r'<s>|</s>'), '')
        .replaceAll(RegExp(r'<li>'), '')
        .replaceAll(RegExp(r'</li>'), '\n')
        .replaceAll(RegExp(r'<ul>|</ul>|<ol>|</ol>'), '');

    if (plainText.isNotEmpty) {
      delta.insert(plainText);
    }

    return ParchmentDocument.fromDelta(delta);
  }
}

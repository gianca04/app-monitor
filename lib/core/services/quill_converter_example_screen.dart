import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/quill_converter_providers.dart';

/// Example screen demonstrating how to use the Quill Converter Service
class QuillConverterExampleScreen extends ConsumerStatefulWidget {
  const QuillConverterExampleScreen({super.key});

  @override
  ConsumerState<QuillConverterExampleScreen> createState() =>
      _QuillConverterExampleScreenState();
}

class _QuillConverterExampleScreenState
    extends ConsumerState<QuillConverterExampleScreen> {
  final TextEditingController _quillController = TextEditingController();
  final TextEditingController _htmlController = TextEditingController();
  String _result = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Example Quill Delta JSON
    _quillController.text = '''
{
  "ops": [
    {"insert": "Hello "},
    {"insert": "World", "attributes": {"bold": true}},
    {"insert": "\\n"}
  ]
}
''';

    // Example HTML
    _htmlController.text = '<p>Hello <strong>World</strong></p>';
  }

  Future<void> _convertQuillToHtml() async {
    setState(() {
      _isLoading = true;
      _result = '';
    });

    final convertQuillToHtml = ref.read(convertQuillToHtmlProvider);
    final result = await convertQuillToHtml(_quillController.text);

    result.fold(
      (failure) {
        setState(() {
          _result = 'Error: ${failure.message}';
          _isLoading = false;
        });
      },
      (conversionResult) {
        setState(() {
          _result = 'HTML Result:\n${conversionResult.content}';
          _isLoading = false;
        });
      },
    );
  }

  Future<void> _convertHtmlToQuill() async {
    setState(() {
      _isLoading = true;
      _result = '';
    });

    final convertHtmlToQuill = ref.read(convertHtmlToQuillProvider);
    final result = await convertHtmlToQuill(_htmlController.text);

    result.fold(
      (failure) {
        setState(() {
          _result = 'Error: ${failure.message}';
          _isLoading = false;
        });
      },
      (conversionResult) {
        setState(() {
          _result = 'Quill Delta JSON Result:\n${conversionResult.content}';
          _isLoading = false;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quill Converter Example'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Quill to HTML Section
            const Text(
              'Convert Quill Delta to HTML',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _quillController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Quill Delta JSON',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isLoading ? null : _convertQuillToHtml,
              child: const Text('Convert to HTML'),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),

            // HTML to Quill Section
            const Text(
              'Convert HTML to Quill Delta',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _htmlController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'HTML',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isLoading ? null : _convertHtmlToQuill,
              child: const Text('Convert to Quill Delta'),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),

            // Result Section
            const Text(
              'Result',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
                color: Colors.grey[100],
              ),
              constraints: const BoxConstraints(minHeight: 100),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Text(
                      _result.isEmpty ? 'No result yet' : _result,
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _quillController.dispose();
    _htmlController.dispose();
    super.dispose();
  }
}

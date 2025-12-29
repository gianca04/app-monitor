import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'image_viewer.dart';

class ImagePreviewModal extends StatelessWidget {
  final String? url;
  final Uint8List? bytes;
  final String title;
  final String? description;

  const ImagePreviewModal({
    super.key,
    this.url,
    this.bytes,
    required this.title,
    this.description,
  });

  static Future<void> show(
    BuildContext context, {
    String? url,
    Uint8List? bytes,
    required String title,
    String? description,
  }) {
    return showDialog(
      context: context,
      builder: (context) => ImagePreviewModal(
        url: url,
        bytes: bytes,
        title: title,
        description: description,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String? imageUrl;
    if (bytes != null) {
      imageUrl = 'data:image/jpeg;base64,${base64Encode(bytes!)}';
    } else if (url != null) {
      imageUrl = url!.startsWith('data:')
          ? url
          : (url!.startsWith('http') ? url : 'data:image/jpeg;base64,$url');
    }

    if (imageUrl == null) {
      return const SizedBox.shrink();
    }

    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: EdgeInsets.zero,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: Center(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 8.0,
                  child: ImageViewer(
                    url: imageUrl,
                    width: MediaQuery.of(context).size.width,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            if (description != null && description!.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                width: double.infinity,
                color: Colors.black.withOpacity(0.8),
                child: SingleChildScrollView(
                  child: Html(
                    data: description!,
                    style: {
                      "body": Style(
                        color: Colors.white,
                        fontSize: FontSize(16),
                        margin: Margins.zero,
                      ),
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

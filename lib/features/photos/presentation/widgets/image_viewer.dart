import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';

class ImageViewer extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;

  const ImageViewer({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    final defaultWidth = width ?? double.infinity;
    final defaultHeight = height;

    if (url.startsWith('data:')) {
      final parts = url.split(',');
      if (parts.length == 2) {
        try {
          final base64String = parts[1];
          final bytes = base64Decode(base64String);
          return Image.memory(
            bytes,
            width: defaultWidth,
            height: defaultHeight,
            fit: fit,
          );
        } catch (e) {
          return _errorWidget(
            defaultWidth,
            defaultHeight,
            'Error loading image',
          );
        }
      } else {
        return _errorWidget(defaultWidth, defaultHeight, 'Invalid image data');
      }
    } else if (url.startsWith('http')) {
      return Image.network(
        url,
        width: defaultWidth,
        height: defaultHeight,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return SizedBox(
            width: defaultWidth,
            height: defaultHeight,
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => _errorWidget(
          defaultWidth,
          defaultHeight,
          'Error loading network image',
        ),
      );
    } else {
      // Assume it's a local file path
      final file = File(url.replaceFirst('file://', ''));
      if (file.existsSync()) {
        return Image.file(
          file,
          width: defaultWidth,
          height: defaultHeight,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => _errorWidget(
            defaultWidth,
            defaultHeight,
            'Error loading local file',
          ),
        );
      } else {
        // Final fallback: try as base64 without prefix if it looks like one
        try {
          final bytes = base64Decode(url);
          return Image.memory(
            bytes,
            width: defaultWidth,
            height: defaultHeight,
            fit: fit,
          );
        } catch (_) {
          return _errorWidget(
            defaultWidth,
            defaultHeight,
            'File not found / Invalid path',
          );
        }
      }
    }
  }

  Widget _errorWidget(double width, double? height, String message) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[300],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, color: Colors.red, size: 48),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(color: Colors.red, fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

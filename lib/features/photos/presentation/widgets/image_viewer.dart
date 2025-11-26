import 'package:flutter/material.dart';
import 'dart:convert';

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
    final screenWidth = MediaQuery.of(context).size.width;
    final defaultWidth = width ?? screenWidth;
    final defaultHeight = height ?? 200.0;

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
          return Container(
            width: defaultWidth,
            height: defaultHeight,
            color: Colors.grey[300],
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, color: Colors.red, size: 48),
                SizedBox(height: 8),
                Text('Error loading image', style: TextStyle(color: Colors.red)),
              ],
            ),
          );
        }
      } else {
        return Container(
          width: defaultWidth,
          height: defaultHeight,
          color: Colors.grey[300],
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, color: Colors.red, size: 48),
              SizedBox(height: 8),
              Text('Invalid image data', style: TextStyle(color: Colors.red)),
            ],
          ),
        );
      }
    } else {
      return Image.network(
        url,
        width: defaultWidth,
        height: defaultHeight,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: defaultWidth,
            height: defaultHeight,
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: defaultWidth,
            height: defaultHeight,
            color: Colors.grey[300],
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, color: Colors.red, size: 48),
                SizedBox(height: 8),
                Text('Error loading image', style: TextStyle(color: Colors.red)),
              ],
            ),
          );
        },
      );
    }
  }
}
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'image_viewer.dart';
import 'image_preview_modal.dart';

/// A widget that displays an image and opens a zoomable preview modal on tap.
/// If no image is provided, it shows a placeholder with an optional tap action.
class PhotoActionViewer extends StatelessWidget {
  final String? url;
  final Uint8List? bytes;
  final String title;
  final String? description;
  final double? height;
  final double? width;
  final BoxFit fit;
  final VoidCallback? onPlaceholderTap;
  final VoidCallback? onImageTap;
  final String placeholderLabel;
  final double borderRadius;
  final Color borderColor;

  const PhotoActionViewer({
    super.key,
    this.url,
    this.bytes,
    required this.title,
    this.description,
    this.height = 200,
    this.width = double.infinity,
    this.fit = BoxFit.cover,
    this.onPlaceholderTap,
    this.onImageTap,
    this.placeholderLabel = 'TAP TO ADD PHOTO',
    this.borderRadius = 4.0,
    this.borderColor = Colors.white10,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = bytes != null || url != null;

    return InkWell(
      onTap: hasPhoto
          ? (onImageTap ??
                () => ImagePreviewModal.show(
                  context,
                  url: url,
                  bytes: bytes,
                  title: title,
                  description: description,
                ))
          : onPlaceholderTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.black26,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: hasPhoto
            ? ClipRRect(
                borderRadius: BorderRadius.circular(borderRadius - 1),
                child: bytes != null
                    ? Image.memory(bytes!, fit: fit)
                    : ImageViewer(url: url!, height: height, fit: fit),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.camera_alt, color: Colors.grey, size: 40),
                  const SizedBox(height: 8),
                  Text(
                    placeholderLabel,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
      ),
    );
  }
}

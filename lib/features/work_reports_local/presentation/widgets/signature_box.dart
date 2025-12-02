import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

class SignatureBox extends StatelessWidget {
  final String title;
  final String? base64;
  final VoidCallback onTap;

  const SignatureBox({
    super.key,
    required this.title,
    this.base64,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          child: Container(
            height: 80,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white24),
              borderRadius: BorderRadius.circular(4),
              color: Colors.black26,
            ),
            child: base64 != null && base64!.isNotEmpty
                ? _buildSignatureImage(base64!)
                : const Center(
                    child: Icon(
                      Icons.edit,
                      color: Colors.grey,
                      size: 24,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignatureImage(String base64String) {
    try {
      // Handle data URL format: "data:image/png;base64,..."
      String cleanBase64 = base64String;
      if (base64String.contains(',')) {
        cleanBase64 = base64String.split(',').last;
      }

      final Uint8List bytes = base64Decode(cleanBase64);
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.memory(
          bytes,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Center(
              child: Icon(
                Icons.broken_image,
                color: Colors.red,
                size: 24,
              ),
            );
          },
        ),
      );
    } catch (e) {
      return const Center(
        child: Icon(
          Icons.error,
          color: Colors.red,
          size: 24,
        ),
      );
    }
  }
}
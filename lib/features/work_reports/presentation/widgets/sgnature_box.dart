import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'industrial_selector.dart';

class SignatureBox extends StatelessWidget {
  final String title;
  final Uint8List? bytes;
  final VoidCallback onTap;

  const SignatureBox({required this.title, this.bytes, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasSig = bytes != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(kIndRadius),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: kIndSurface,
          border: Border.all(color: hasSig ? kIndAccent : kIndBorder),
          borderRadius: BorderRadius.circular(kIndRadius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              color: Colors.white10,
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: hasSig
                  ? Padding(
                      padding: const EdgeInsets.all(4),
                      child: Image.memory(bytes!, fit: BoxFit.contain),
                    )
                  : const Center(
                      child: Text(
                        'TOCAR PARA FIRMAR',
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class ImageCompressionService {
  /// Compresses [imageBytes] to WebP format.
  Future<Uint8List> compressToWebp(Uint8List imageBytes);
}

class ImageCompressionServiceImpl implements ImageCompressionService {
  @override
  Future<Uint8List> compressToWebp(Uint8List imageBytes) async {
    try {
      print(
        '🔄 [COMPRESSION] Starting WebP compression. Original size: ${imageBytes.length} bytes',
      );

      final result = await FlutterImageCompress.compressWithList(
        imageBytes,
        minHeight: 1920,
        minWidth: 1080,
        quality: 85,
        format: CompressFormat.webp,
      );

      print('✅ [COMPRESSION] Completed. New size: ${result.length} bytes');
      return result;
    } catch (e) {
      print('⚠️ [COMPRESSION] Failed: $e');
      return imageBytes; // Return original if compression fails
    }
  }
}

final imageCompressionServiceProvider = Provider<ImageCompressionService>((
  ref,
) {
  return ImageCompressionServiceImpl();
});

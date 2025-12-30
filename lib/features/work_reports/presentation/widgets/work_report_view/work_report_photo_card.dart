import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart'; // import flutter_html
import 'package:monitor/core/widgets/modern_bottom_modal.dart'; // fix absolute path usage for core
import '../../../../photos/presentation/widgets/image_viewer.dart';
import '../../../../photos/presentation/widgets/image_preview_modal.dart';
import '../../../../photos/data/models/photo.dart';

class WorkReportPhotoCard extends StatelessWidget {
  final ThemeData theme;
  final Photo photo;
  const WorkReportPhotoCard({
    super.key,
    required this.theme,
    required this.photo,
  });

  void _showPhotoModal(
    BuildContext context,
    String url,
    String title,
    String? description,
  ) {
    ModernBottomModal.show(
      context,
      title: title,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => _showFullScreenPhoto(context, url, title, description),
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: ImageViewer(
                url: url,
                width: MediaQuery.of(context).size.width,
                fit: BoxFit.fitWidth,
              ),
            ),
          ),
          if (description != null && description.isNotEmpty) ...[
            const SizedBox(height: 16),
            Html(
              data: description,
              style: {
                "body": Style(
                  color: theme.colorScheme.onSurface,
                  fontSize: FontSize(14),
                ),
              },
            ),
          ],
        ],
      ),
    );
  }

  void _showFullScreenPhoto(
    BuildContext context,
    String url,
    String title,
    String? description,
  ) {
    ImagePreviewModal.show(
      context,
      url: url,
      title: title,
      description: description,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        border: Border.all(color: theme.colorScheme.outline),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: theme.colorScheme.outline),
              ),
            ),
            child: Text(
              'FOTO ID: ${photo.id ?? 'N/A'}',
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 10,
                fontFamily: 'monospace',
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (photo.beforeWork.photoPath != null)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ANTES',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () => _showPhotoModal(
                            context,
                            photo.beforeWork.photoPath!,
                            'FOTO ANTES DEL TRABAJO',
                            photo.beforeWork.description,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white10),
                            ),
                            child: ImageViewer(
                              url: photo.beforeWork.photoPath!,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Html(
                          data: photo.beforeWork.description ?? '',
                          style: {
                            "body": Style(
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.7,
                              ),
                              fontSize: FontSize(11),
                            ),
                          },
                        ),
                      ],
                    ),
                  ),
                if (photo.beforeWork.photoPath != null &&
                    photo.afterWork.photoPath != null)
                  const SizedBox(width: 12),
                if (photo.afterWork.photoPath != null)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DESPUES',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () => _showPhotoModal(
                            context,
                            photo.afterWork.photoPath!,
                            'FOTO DESPUÉS DEL TRABAJO',
                            photo.afterWork.description,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white10),
                            ),
                            child: ImageViewer(
                              url: photo.afterWork.photoPath!,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Html(
                          data: photo.afterWork.description ?? '',
                          style: {
                            "body": Style(
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.7,
                              ),
                              fontSize: FontSize(11),
                            ),
                          },
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

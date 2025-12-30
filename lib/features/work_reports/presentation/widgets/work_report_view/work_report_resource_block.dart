import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

class WorkReportResourceBlock extends StatelessWidget {
  final ThemeData theme;
  final String title;
  final String? htmlContent;
  const WorkReportResourceBlock({
    super.key,
    required this.theme,
    required this.title,
    this.htmlContent,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
          Html(
            data: htmlContent ?? '',
            style: {
              "body": Style(
                color: theme.colorScheme.onSurface,
                margin: Margins.zero,
                fontSize: FontSize(13),
              ),
            },
          ),
        ],
      ),
    );
  }
}

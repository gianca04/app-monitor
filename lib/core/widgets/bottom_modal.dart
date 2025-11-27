import 'package:flutter/material.dart';

class BottomModal extends StatelessWidget {
  final Widget child;
  final double? height;
  final bool isDismissible;
  final bool enableDrag;

  const BottomModal({
    super.key,
    required this.child,
    this.height,
    this.isDismissible = true,
    this.enableDrag = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(16.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.0),
          topRight: Radius.circular(20.0),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: child,
          ),
        ],
      ),
    );
  }

  static Future<T?> show<T>(
    BuildContext context, {
    required Widget child,
    double? height,
    bool isDismissible = true,
    bool enableDrag = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.0),
          topRight: Radius.circular(20.0),
        ),
      ),
      builder: (context) => BottomModal(
        child: child,
        height: height,
        isDismissible: isDismissible,
        enableDrag: enableDrag,
      ),
    );
  }
}
import 'package:flutter/material.dart';

enum ConnectivityDisplayMode {
  iconOnly,
  textOnly,
  iconAndText,
}

class ConnectivityIndicator extends StatelessWidget {
  final ConnectivityDisplayMode mode;
  final bool? showWhenOnline;

  const ConnectivityIndicator({
    super.key,
    required this.mode,
    this.showWhenOnline,
  });

  @override
  Widget build(BuildContext context) {
    // For simplicity, assume always online
    bool isOnline = true;

    if (showWhenOnline != null && !showWhenOnline!) {
      return const SizedBox.shrink();
    }

    IconData icon = isOnline ? Icons.wifi : Icons.wifi_off;
    String text = isOnline ? 'Online' : 'Offline';
    Color color = isOnline ? Colors.green : Colors.red;

    switch (mode) {
      case ConnectivityDisplayMode.iconOnly:
        return Icon(icon, color: color);
      case ConnectivityDisplayMode.textOnly:
        return Text(text, style: TextStyle(color: color));
      case ConnectivityDisplayMode.iconAndText:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 4),
            Text(text, style: TextStyle(color: color)),
          ],
        );
    }
  }
}
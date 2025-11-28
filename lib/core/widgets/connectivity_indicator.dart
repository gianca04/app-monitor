
import 'package:flutter/material.dart';

enum ConnectivityDisplayMode {
  iconOnly,
  textOnly,
  iconAndText,
}

class ConnectivityIndicator extends StatelessWidget {
  final ConnectivityDisplayMode mode;
  final bool? showWhenOnline;
  final bool isOnline;

  const ConnectivityIndicator({
    super.key,
    required this.mode,
    this.showWhenOnline,
    required this.isOnline,
  });

  @override
  Widget build(BuildContext context) {
    if (showWhenOnline != null && !showWhenOnline! && isOnline) {
      return const SizedBox.shrink();
    }

    switch (mode) {
      case ConnectivityDisplayMode.iconOnly:
        IconData icon = isOnline ? Icons.wifi : Icons.wifi_off;
        Color color = isOnline ? Colors.green : Colors.red;
        return Icon(icon, color: color);
      case ConnectivityDisplayMode.textOnly:
        String text = isOnline ? 'Online' : 'Offline';
        Color color = isOnline ? Colors.green : Colors.red;
        return Text(text, style: TextStyle(color: color));
      case ConnectivityDisplayMode.iconAndText:
        IconData icon = isOnline ? Icons.wifi : Icons.wifi_off;
        String text = isOnline ? 'Online' : 'Offline';
        Color color = isOnline ? Colors.green : Colors.red;
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
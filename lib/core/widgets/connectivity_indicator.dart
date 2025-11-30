
import 'package:flutter/material.dart';
import '../../core/theme_config.dart';

enum ConnectivityDisplayMode {
  iconOnly,
  textOnly,
  iconAndText,
  dotOnly,
  badge,
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
        Color color = isOnline ? AppTheme.success : AppTheme.error;
        return Icon(icon, color: color);
      case ConnectivityDisplayMode.textOnly:
        String text = isOnline ? 'Online' : 'Offline';
        Color color = isOnline ? AppTheme.success : AppTheme.error;
        return Text(text, style: TextStyle(color: color));
      case ConnectivityDisplayMode.iconAndText:
        IconData icon = isOnline ? Icons.wifi : Icons.wifi_off;
        String text = isOnline ? 'Online' : 'Offline';
        Color color = isOnline ? AppTheme.success : AppTheme.error;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 4),
            Text(text, style: TextStyle(color: color)),
          ],
        );
      case ConnectivityDisplayMode.dotOnly:
        Color color = isOnline ? AppTheme.success : AppTheme.error;
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        );
      case ConnectivityDisplayMode.badge:
        IconData icon = isOnline ? Icons.wifi : Icons.wifi_off;
        String label = isOnline ? 'ON' : 'OFF';
        Color color = isOnline ? AppTheme.success : AppTheme.error;
        return Badge(
          label: Text(label, style: TextStyle(color: Colors.white, fontSize: 8)),
          backgroundColor: color,
          child: Icon(icon, color: color),
        );
    }
  }
}
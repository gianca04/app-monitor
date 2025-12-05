/// Preferencias del usuario para el indicador de conectividad
class ConnectivityPreferences {
  final bool isEnabled;
  final int displayMode; // 0: iconOnly, 1: iconWithText, 2: dotOnly, 3: badge
  final bool showWhenOnline;
  final bool showNotifications;
  final bool vibrateOnDisconnect;
  final bool playSoundOnChange;

  const ConnectivityPreferences({
    this.isEnabled = true,
    this.displayMode = 0,
    this.showWhenOnline = false,
    this.showNotifications = true,
    this.vibrateOnDisconnect = false,
    this.playSoundOnChange = false,
  });

  ConnectivityPreferences copyWith({
    bool? isEnabled,
    int? displayMode,
    bool? showWhenOnline,
    bool? showNotifications,
    bool? vibrateOnDisconnect,
    bool? playSoundOnChange,
  }) {
    return ConnectivityPreferences(
      isEnabled: isEnabled ?? this.isEnabled,
      displayMode: displayMode ?? this.displayMode,
      showWhenOnline: showWhenOnline ?? this.showWhenOnline,
      showNotifications: showNotifications ?? this.showNotifications,
      vibrateOnDisconnect: vibrateOnDisconnect ?? this.vibrateOnDisconnect,
      playSoundOnChange: playSoundOnChange ?? this.playSoundOnChange,
    );
  }

  String get displayModeName {
    switch (displayMode) {
      case 0:
        return 'Solo icono';
      case 1:
        return 'Icono con texto';
      case 2:
        return 'Punto de color';
      case 3:
        return 'Badge';
      default:
        return 'Solo icono';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'isEnabled': isEnabled,
      'displayMode': displayMode,
      'showWhenOnline': showWhenOnline,
      'showNotifications': showNotifications,
      'vibrateOnDisconnect': vibrateOnDisconnect,
      'playSoundOnChange': playSoundOnChange,
    };
  }

  factory ConnectivityPreferences.fromJson(Map<String, dynamic> json) {
    return ConnectivityPreferences(
      isEnabled: json['isEnabled'] ?? true,
      displayMode: json['displayMode'] ?? 0,
      showWhenOnline: json['showWhenOnline'] ?? false,
      showNotifications: json['showNotifications'] ?? true,
      vibrateOnDisconnect: json['vibrateOnDisconnect'] ?? false,
      playSoundOnChange: json['playSoundOnChange'] ?? false,
    );
  }
}
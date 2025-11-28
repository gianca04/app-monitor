import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

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

/// StateNotifier para las preferencias de conectividad
class ConnectivityPreferencesNotifier extends StateNotifier<ConnectivityPreferences> {
  final FlutterSecureStorage _storage;

  ConnectivityPreferencesNotifier(this._storage) : super(const ConnectivityPreferences()) {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final data = await _storage.read(key: 'connectivity_preferences');
      if (data != null) {
        final json = data as Map<String, dynamic>?;
        if (json != null) {
          state = ConnectivityPreferences.fromJson(json);
        }
      }
    } catch (e) {
      // Usar valores por defecto si hay error
    }
  }

  Future<void> _savePreferences() async {
    try {
      await _storage.write(
        key: 'connectivity_preferences',
        value: state.toJson().toString(),
      );
    } catch (e) {
      // Ignorar errores de guardado
    }
  }

  Future<void> updatePreference({
    bool? isEnabled,
    int? displayMode,
    bool? showWhenOnline,
    bool? showNotifications,
    bool? vibrateOnDisconnect,
    bool? playSoundOnChange,
  }) async {
    state = state.copyWith(
      isEnabled: isEnabled,
      displayMode: displayMode,
      showWhenOnline: showWhenOnline,
      showNotifications: showNotifications,
      vibrateOnDisconnect: vibrateOnDisconnect,
      playSoundOnChange: playSoundOnChange,
    );
    await _savePreferences();
  }

  Future<void> resetToDefaults() async {
    state = const ConnectivityPreferences();
    await _savePreferences();
  }
}

/// Provider para el StateNotifier de preferencias
final connectivityPreferencesNotifierProvider =
    StateNotifierProvider<ConnectivityPreferencesNotifier, ConnectivityPreferences>((ref) {
  final storage = FlutterSecureStorage();
  return ConnectivityPreferencesNotifier(storage);
});

/// Provider para el estado de conectividad
final connectivityStatusProvider = StreamProvider<bool>((ref) {
  final connectivity = Connectivity();
  return connectivity.onConnectivityChanged.map((result) => result != ConnectivityResult.none);
});
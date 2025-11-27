import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Preferencias del usuario para el indicador de conectividad
class ConnectivityPreferences {
  final bool isEnabled;
  final int displayMode; // 0: iconOnly, 1: iconWithText, 2: dotOnly, 3: badge
  final bool showWhenOnline;

  const ConnectivityPreferences({
    this.isEnabled = true,
    this.displayMode = 0,
    this.showWhenOnline = false,
  });

  ConnectivityPreferences copyWith({
    bool? isEnabled,
    int? displayMode,
    bool? showWhenOnline,
  }) {
    return ConnectivityPreferences(
      isEnabled: isEnabled ?? this.isEnabled,
      displayMode: displayMode ?? this.displayMode,
      showWhenOnline: showWhenOnline ?? this.showWhenOnline,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isEnabled': isEnabled,
      'displayMode': displayMode,
      'showWhenOnline': showWhenOnline,
    };
  }

  factory ConnectivityPreferences.fromJson(Map<String, dynamic> json) {
    return ConnectivityPreferences(
      isEnabled: json['isEnabled'] ?? true,
      displayMode: json['displayMode'] ?? 0,
      showWhenOnline: json['showWhenOnline'] ?? false,
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
        state = ConnectivityPreferences.fromJson(data as Map<String, dynamic>);
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

  void toggleEnabled() {
    state = state.copyWith(isEnabled: !state.isEnabled);
    _savePreferences();
  }

  void setDisplayMode(int mode) {
    state = state.copyWith(displayMode: mode);
    _savePreferences();
  }

  void toggleShowWhenOnline() {
    state = state.copyWith(showWhenOnline: !state.showWhenOnline);
    _savePreferences();
  }
}

/// Provider para el StateNotifier de preferencias
final connectivityPreferencesNotifierProvider =
    StateNotifierProvider<ConnectivityPreferencesNotifier, ConnectivityPreferences>((ref) {
  final storage = FlutterSecureStorage();
  return ConnectivityPreferencesNotifier(storage);
});
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../data/datasources/connectivity_preferences_data_source.dart';
import '../data/repositories/connectivity_preferences_repository.dart';
import '../domain/entities/connectivity_preferences.dart';

/// StateNotifier para las preferencias de conectividad
class ConnectivityPreferencesNotifier extends StateNotifier<ConnectivityPreferences> {
  final ConnectivityPreferencesRepository _repository;

  ConnectivityPreferencesNotifier(this._repository) : super(const ConnectivityPreferences()) {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      state = await _repository.getPreferences();
    } catch (e) {
      // Usar valores por defecto si hay error
    }
  }

  Future<void> _savePreferences() async {
    try {
      await _repository.savePreferences(state);
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
  final dataSource = ConnectivityPreferencesDataSourceImpl();
  final repository = ConnectivityPreferencesRepositoryImpl(dataSource);
  return ConnectivityPreferencesNotifier(repository);
});

/// Provider para el estado de conectividad
final connectivityStatusProvider = StreamProvider<bool>((ref) {
  final connectivity = Connectivity();
  return connectivity.onConnectivityChanged.map((result) => result != ConnectivityResult.none);
});
import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Estados de conexión posibles
enum ConnectionStatus {
  /// Conectado a Internet
  online,

  /// Conectado a red pero sin acceso a Internet
  noInternet,

  /// Sin conexión de red
  offline,
}

/// Servicio para monitorear el estado de conectividad
class ConnectivityService {
  final Connectivity _connectivity;
  final StreamController<ConnectionStatus> _statusController =
      StreamController<ConnectionStatus>.broadcast();

  ConnectivityService(this._connectivity) {
    _init();
  }

  /// Stream del estado de conexión actual
  Stream<ConnectionStatus> get connectionStatus => _statusController.stream;

  /// Estado de conexión actual
  ConnectionStatus get currentStatus => _currentStatus;
  ConnectionStatus _currentStatus = ConnectionStatus.offline;

  void _init() {
    // Escuchar cambios en la conectividad
    _connectivity.onConnectivityChanged.listen(_onConnectivityChanged);

    // Verificar estado inicial
    _checkConnectivity();
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    _checkConnectivity();
  }

  Future<void> _checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();

      if (results.contains(ConnectivityResult.none)) {
        _updateStatus(ConnectionStatus.offline);
        return;
      }

      // Si hay conexión de red, verificar acceso a Internet
      final hasInternet = await _hasInternetAccess();
      final newStatus = hasInternet ? ConnectionStatus.online : ConnectionStatus.noInternet;
      _updateStatus(newStatus);
    } catch (e) {
      _updateStatus(ConnectionStatus.offline);
    }
  }

  Future<bool> _hasInternetAccess() async {
    try {
      // Intentar conectar a un servidor confiable
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));

      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  void _updateStatus(ConnectionStatus status) {
    if (_currentStatus != status) {
      _currentStatus = status;
      _statusController.add(status);
    }
  }

  /// Forzar verificación manual de conectividad
  Future<void> checkConnectivity() async {
    await _checkConnectivity();
  }

  void dispose() {
    _statusController.close();
  }
}
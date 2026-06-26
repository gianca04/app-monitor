import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

/// Servicio singleton que mantiene la ubicación GPS actualizada en background.
/// Actualiza cada 60 segundos para evitar bloquear la captura de fotos.
class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  Timer? _timer;
  Position? _currentPosition;
  String _currentCity = 'Obteniendo GPS...';
  bool _isInitialized = false;

  /// Posición GPS actual (puede ser null si aún no se ha obtenido).
  Position? get currentPosition => _currentPosition;

  /// Ciudad actual como string legible.
  String get currentCity => _currentCity;

  /// True si ya se obtuvo al menos una lectura de GPS.
  bool get hasLocation => _currentPosition != null;

  /// Inicializa el servicio: obtiene ubicación inmediata y programa actualizaciones periódicas.
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    // Obtener ubicación inicial de forma inmediata
    await _updateLocation();

    // Programar actualización cada 60 segundos
    _timer = Timer.periodic(const Duration(seconds: 60), (_) {
      _updateLocation();
    });
  }

  /// Actualiza la posición GPS y la ciudad.
  Future<void> _updateLocation() async {
    try {
      _currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      final placemarks = await placemarkFromCoordinates(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );

      if (placemarks.isNotEmpty) {
        _currentCity = placemarks.first.locality ??
            placemarks.first.subAdministrativeArea ??
            'Ubicación desconocida';
      }

      debugPrint('📍 GPS actualizado: $_currentCity '
          '(${_currentPosition!.latitude.toStringAsFixed(4)}, '
          '${_currentPosition!.longitude.toStringAsFixed(4)})');
    } catch (e) {
      debugPrint('⚠️ Error actualizando GPS: $e');
      if (_currentCity == 'Obteniendo GPS...') {
        _currentCity = 'Ubicación no disponible';
      }
      // Mantiene la última ubicación conocida si ya tenía una
    }
  }

  /// Fuerza una actualización inmediata (útil al volver de background).
  Future<void> forceUpdate() async {
    await _updateLocation();
  }

  /// Libera recursos y detiene el timer.
  void dispose() {
    _timer?.cancel();
    _timer = null;
    _isInitialized = false;
  }
}

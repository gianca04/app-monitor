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

  /// Coordenadas actuales formateadas.
  String get currentCoordinates {
    if (_currentPosition == null) return '';
    return '${_currentPosition!.latitude.toStringAsFixed(5)}, ${_currentPosition!.longitude.toStringAsFixed(5)}';
  }

  /// Actualiza la posición GPS y la ciudad.
  Future<void> _updateLocation() async {
    try {
      try {
        _currentPosition = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 10),
          ),
        );
      } on TimeoutException {
        // debugPrint('⚠️ Timeout obteniendo GPS actual, intentando última ubicación conocida...');
        _currentPosition = await Geolocator.getLastKnownPosition() ?? _currentPosition;
      } catch (e) {
        // debugPrint('⚠️ Error en getCurrentPosition: $e');
        _currentPosition = await Geolocator.getLastKnownPosition() ?? _currentPosition;
      }

      if (_currentPosition == null) {
        throw Exception('No se pudo obtener ninguna ubicación GPS (ni actual ni cacheada)');
      }

      final placemarks = await placemarkFromCoordinates(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );

      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        
        List<String> parts = [];
        if (p.name != null && p.name!.isNotEmpty && p.name != p.street) parts.add(p.name!);
        if (p.street != null && p.street!.isNotEmpty) parts.add(p.street!);
        if (p.subLocality != null && p.subLocality!.isNotEmpty) parts.add(p.subLocality!);
        if (p.locality != null && p.locality!.isNotEmpty) parts.add(p.locality!);
        
        // Evitar redundancias
        parts = parts.toSet().toList();
        
        // Tomamos hasta las 2 partes más específicas (ej: Tienda Plaza Vea, Curumuy)
        _currentCity = parts.take(2).join(', ');
        if (_currentCity.isEmpty) {
           _currentCity = p.subAdministrativeArea ?? 'Ubicación desconocida';
        }
      }

      // debugPrint('📍 GPS actualizado: $_currentCity '
      //     '(${_currentPosition!.latitude.toStringAsFixed(4)}, '
      //     '${_currentPosition!.longitude.toStringAsFixed(4)})');
    } catch (e) {
      // debugPrint('⚠️ Fallo global actualizando GPS: $e');
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

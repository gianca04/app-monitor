import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../application/services/location_service.dart';
import '../../application/services/watermark_service.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({Key? key}) : super(key: key);

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  List<CameraDescription> _backCameras = [];
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  bool _isSwitchingCamera = false;

  // Controls state
  FlashMode _flashMode = FlashMode.auto;
  double _minZoom = 1.0;
  double _maxZoom = 1.0;
  double _currentZoom = 1.0;
  double _minExposure = 0.0;
  double _maxExposure = 0.0;
  double _currentExposure = 0.0;

  // Zoom button presets (dynamically generated)
  List<_ZoomPreset> _zoomPresets = [];

  // Current lens direction
  CameraLensDirection _currentLensDirection = CameraLensDirection.back;


  // Focus & Exposure UI
  Offset? _focusPoint;
  bool _showFocusReticle = false;

  // Watermark state & Live overlay
  final LocationService _locationService = LocationService();
  final WatermarkService _watermarkService = WatermarkService();
  Timer? _clockTimer;
  DateTime _currentTime = DateTime.now();
  
  Map<String, double>? _wmLayout;
  bool _wmLayoutLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Iniciar servicios
    _locationService.initialize();
    _watermarkService.preload();
    _loadWatermarkLayout();
    
    // Reloj para la marca de agua en vivo
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() { _currentTime = DateTime.now(); });
    });

    _initialize();
  }

  Future<void> _loadWatermarkLayout() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _wmLayout = {
        'logo_x': prefs.getDouble('wm_logo_x') ?? 0.05,
        'logo_y': prefs.getDouble('wm_logo_y') ?? 0.05,
        'logo_scale': prefs.getDouble('wm_logo_scale') ?? 1.0,
        'time_x': prefs.getDouble('wm_time_x') ?? 0.05,
        'time_y': prefs.getDouble('wm_time_y') ?? 0.85,
        'time_scale': prefs.getDouble('wm_time_scale') ?? 1.0,
        'loc_x': prefs.getDouble('wm_location_x') ?? 0.05,
        'loc_y': prefs.getDouble('wm_location_y') ?? 0.70,
        'loc_scale': prefs.getDouble('wm_location_scale') ?? 1.0,
      };
      _wmLayoutLoaded = true;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clockTimer?.cancel();
    _locationService.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCameraController(cameraController.description);
    }
  }

  Future<void> _initialize() async {
    final hasPermissions = await _requestPermissions();
    if (!hasPermissions) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Se requieren permisos de cámara y ubicación.')),
        );
      }
      return;
    }

    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se encontraron cámaras.')),
          );
        }
        return;
      }

      // Separate back cameras for lens switching
      _backCameras = _cameras
          .where((c) => c.lensDirection == CameraLensDirection.back)
          .toList();

      debugPrint('=== CÁMARAS DETECTADAS ===');
      debugPrint('Total cámaras: ${_cameras.length}');
      debugPrint('Cámaras traseras: ${_backCameras.length}');
      for (int i = 0; i < _cameras.length; i++) {
        debugPrint('  [$i] ${_cameras[i].name} - ${_cameras[i].lensDirection} - sensorOrientation: ${_cameras[i].sensorOrientation}');
      }

      // Start with first back camera
      final backCamera = _backCameras.isNotEmpty
          ? _backCameras.first
          : _cameras.first;



      await _initCameraController(backCamera);
    } catch (e) {
      debugPrint('Error inicializando cámara: $e');
    }
  }

  Future<void> _initCameraController(CameraDescription description) async {
    final CameraController cameraController = CameraController(
      description,
      ResolutionPreset.high, // Cambiado de max a high para mejor rendimiento
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    _controller = cameraController;

    try {
      await cameraController.initialize();
      await cameraController.setFlashMode(_flashMode);

      _minZoom = await cameraController.getMinZoomLevel();
      _maxZoom = await cameraController.getMaxZoomLevel();
      _currentZoom = _minZoom;

      _minExposure = await cameraController.getMinExposureOffset();
      _maxExposure = await cameraController.getMaxExposureOffset();

      _currentLensDirection = description.lensDirection;

      // Build zoom presets based on actual device capabilities
      _buildZoomPresets();

      debugPrint('=== CONTROLADOR INICIALIZADO ===');
      debugPrint('Cámara: ${description.name}');
      debugPrint('Zoom min: $_minZoom, max: $_maxZoom');
      debugPrint('Exposure min: $_minExposure, max: $_maxExposure');
      debugPrint('Resolución: ${cameraController.value.previewSize}');

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _isSwitchingCamera = false;
        });
      }
    } on CameraException catch (e) {
      debugPrint('Error al inicializar controlador: $e');
    }
  }

  /// Build zoom presets dynamically based on the device's zoom range.
  void _buildZoomPresets() {
    _zoomPresets = [];

    // Ultra-wide: if minZoom < 1.0 (some devices report 0.5 or 0.6)
    if (_minZoom < 0.95) {
      final label = '.${(_minZoom * 10).round()}';
      _zoomPresets.add(_ZoomPreset(zoom: _minZoom, label: label));
    }

    // Standard 1x (always available)
    _zoomPresets.add(_ZoomPreset(zoom: 1.0, label: '1x'));

    // 2x if supported
    if (_maxZoom >= 2.0) {
      _zoomPresets.add(_ZoomPreset(zoom: 2.0, label: '2x'));
    }

    // 5x if supported (telephoto)
    if (_maxZoom >= 5.0) {
      _zoomPresets.add(_ZoomPreset(zoom: 5.0, label: '5x'));
    }

    // 10x if supported (super telephoto)
    if (_maxZoom >= 10.0) {
      _zoomPresets.add(_ZoomPreset(zoom: 10.0, label: '10x'));
    }
  }

  Future<bool> _requestPermissions() async {
    final cameraStatus = await Permission.camera.request();
    final locationStatus = await Permission.locationWhenInUse.request();
    return cameraStatus.isGranted && locationStatus.isGranted;
  }

  /// Switch between front and back cameras.
  void _switchCamera() async {
    if (_cameras.length < 2 || _controller == null) return;

    setState(() {
      _isCameraInitialized = false;
      _isSwitchingCamera = true;
    });

    CameraDescription newCamera;
    if (_currentLensDirection == CameraLensDirection.back) {
      // Switch to front
      newCamera = _cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras.first,
      );
    } else {
      // Switch to back
      newCamera = _backCameras.isNotEmpty ? _backCameras.first : _cameras.first;
    }

    await _initCameraController(newCamera);
  }

  void _toggleFlash() async {
    if (_controller == null) return;

    FlashMode nextMode;
    if (_flashMode == FlashMode.auto) {
      nextMode = FlashMode.off;
    } else if (_flashMode == FlashMode.off) {
      nextMode = FlashMode.always;
    } else {
      nextMode = FlashMode.auto;
    }

    try {
      await _controller!.setFlashMode(nextMode);
      setState(() {
        _flashMode = nextMode;
      });
    } catch (e) {
      debugPrint('Error al cambiar flash: $e');
    }
  }

  void _setZoom(double zoom) async {
    if (_controller == null) return;
    // Clamp to device's actual range
    final clampedZoom = zoom.clamp(_minZoom, _maxZoom);
    try {
      await _controller!.setZoomLevel(clampedZoom);
      setState(() {
        _currentZoom = clampedZoom;
      });
    } catch (e) {
      debugPrint('Error al ajustar zoom: $e');
    }
  }

  void _onTapToFocus(TapDownDetails details, BoxConstraints constraints) async {
    if (_controller == null || !_isCameraInitialized) return;

    final offset = Offset(
      details.localPosition.dx / constraints.maxWidth,
      details.localPosition.dy / constraints.maxHeight,
    );

    setState(() {
      _focusPoint = details.localPosition;
      _showFocusReticle = true;
    });

    try {
      await _controller!.setFocusPoint(offset);
      await _controller!.setExposurePoint(offset);
    } catch (e) {
      debugPrint('Error al establecer punto de enfoque: $e');
    }

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showFocusReticle = false;
        });
      }
    });
  }

  void _onVerticalDragExposure(DragUpdateDetails details) async {
    if (_controller == null || !_isCameraInitialized) return;

    double delta = -details.primaryDelta! / 50.0;
    double newExposure = _currentExposure + delta;
    newExposure = newExposure.clamp(_minExposure, _maxExposure);

    try {
      await _controller!.setExposureOffset(newExposure);
      setState(() {
        _currentExposure = newExposure;
        _showFocusReticle = true;
      });
    } catch (e) {
      debugPrint('Error al ajustar exposición: $e');
    }
  }

  void _onScaleZoom(ScaleUpdateDetails details) {
    if (_controller == null || !_isCameraInitialized) return;
    final newZoom = (_currentZoom * details.scale).clamp(_minZoom, _maxZoom);
    _setZoom(newZoom);
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized || _isProcessing) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final XFile picture = await _controller!.takePicture();

      final watermarkedFile = await _watermarkService.addWatermark(
        imageFile: File(picture.path),
        latitude: _locationService.currentPosition?.latitude ?? 0.0,
        longitude: _locationService.currentPosition?.longitude ?? 0.0,
        city: _locationService.currentCity,
      );

      if (mounted && watermarkedFile != null) {
        _showImagePreview(watermarkedFile);
      }
    } catch (e) {
      debugPrint('Error al tomar foto: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al capturar la imagen.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showImagePreview(File image) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        contentPadding: EdgeInsets.zero,
        content: Stack(
          children: [
            Image.file(image, fit: BoxFit.contain),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized || _controller == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: Colors.grey.shade700,
                strokeWidth: 2.0,
              ),
              const SizedBox(height: 16),
              Text(
                _isSwitchingCamera ? 'Cambiando cámara...' : 'Iniciando cámara...',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            _buildTopBar(),
            // Camera preview in 3:4 with proper cropping
            Expanded(child: _buildCameraPreview()),
            // Bottom controls
            _buildBottomControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Flash button
          _buildTopButton(
            icon: _flashMode == FlashMode.auto
                ? Icons.flash_auto
                : _flashMode == FlashMode.always
                    ? Icons.flash_on
                    : Icons.flash_off,
            onTap: _toggleFlash,
            label: _flashMode == FlashMode.auto
                ? 'AUTO'
                : _flashMode == FlashMode.always
                    ? 'ON'
                    : 'OFF',
          ),
          // Exposure indicator
          if (_currentExposure != 0.0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.wb_sunny_outlined, size: 16, color: Colors.amber.shade700),
                  const SizedBox(width: 4),
                  Text(
                    '${_currentExposure > 0 ? "+" : ""}${_currentExposure.toStringAsFixed(1)}',
                    style: TextStyle(
                      color: Colors.grey.shade800,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          // Switch camera
          if (_cameras.length > 1)
            _buildTopButton(
              icon: Icons.flip_camera_ios_outlined,
              onTap: _switchCamera,
            )
          else
            const SizedBox(width: 44),
        ],
      ),
    );
  }

  Widget _buildTopButton({required IconData icon, required VoidCallback onTap, String? label}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.grey.shade800, size: 22),
            if (label != null) ...[
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Build the camera preview properly cropped to 3:4 without distortion.
  Widget _buildCameraPreview() {
    final cameraValue = _controller!.value;
    // Camera preview size (width x height as reported by the sensor,
    // which is in landscape orientation)
    final previewSize = cameraValue.previewSize!;
    // The camera reports width > height (landscape sensor).
    // In portrait mode the actual preview is rotated, so:
    //   displayWidth = previewSize.height
    //   displayHeight = previewSize.width
    final double cameraAspectRatio = previewSize.height / previewSize.width;

    return LayoutBuilder(
      builder: (context, constraints) {
        // The available space for the preview
        final double availableWidth = constraints.maxWidth;
        final double availableHeight = constraints.maxHeight;

        // We want a 3:4 viewport (width:height)
        double viewportWidth, viewportHeight;
        if (availableHeight / availableWidth > (4.0 / 3.0)) {
          // Available space is taller than 4:3 — fit by width
          viewportWidth = availableWidth;
          viewportHeight = availableWidth * (4.0 / 3.0);
        } else {
          // Available space is wider than 3:4 — fit by height
          viewportHeight = availableHeight;
          viewportWidth = availableHeight * (3.0 / 4.0);
        }

        // Now we need to scale the camera preview so it *fills* this 3:4 viewport
        // without distortion — overflow gets clipped.
        //
        // cameraAspectRatio = camera display width / camera display height (in portrait)
        // viewportAspectRatio = viewportWidth / viewportHeight = 3/4
        final double viewportAspectRatio = viewportWidth / viewportHeight;

        // Scale factor to make the camera fill the viewport (cover behavior)
        double scale;
        if (cameraAspectRatio > viewportAspectRatio) {
          // Camera is wider than viewport → match heights, overflow width
          scale = viewportHeight / (viewportWidth / cameraAspectRatio);
        } else {
          // Camera is taller than viewport → match widths, overflow height
          scale = viewportWidth / (viewportHeight * cameraAspectRatio);
        }

        // Ensure scale is at least 1.0
        scale = max(scale, 1.0);

        return Center(
          child: SizedBox(
            width: viewportWidth,
            height: viewportHeight,
            child: ClipRect(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // --- CAPA 1: Cámara con Zoom (Oversized) ---
                  OverflowBox(
                    alignment: Alignment.center,
                    maxWidth: double.infinity,
                    maxHeight: double.infinity,
                    child: SizedBox(
                      width: viewportWidth * scale,
                      height: viewportHeight * scale,
                      child: GestureDetector(
                        onTapDown: (details) {
                          _onTapToFocus(
                            details,
                            BoxConstraints.tight(Size(viewportWidth * scale, viewportHeight * scale)),
                          );
                        },
                        onVerticalDragUpdate: _onVerticalDragExposure,
                        onScaleUpdate: _onScaleZoom,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            FittedBox(
                              fit: BoxFit.cover,
                              child: SizedBox(
                                width: previewSize.height,
                                height: previewSize.width,
                                child: CameraPreview(_controller!),
                              ),
                            ),
                            if (_showFocusReticle && _focusPoint != null)
                              Positioned(
                                left: _focusPoint!.dx - 35,
                                top: _focusPoint!.dy - 35,
                                child: _buildFocusReticle(),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // --- CAPA 2: Marca de agua WYSIWYG (Restringida al Viewport 3:4) ---
                  if (_wmLayoutLoaded)
                    IgnorePointer(
                      child: Stack(
                        fit: StackFit.expand,
                        children: _buildLiveWatermark(viewportWidth, viewportHeight),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildLiveWatermark(double width, double height) {
    if (_wmLayout == null) return [];
    
    // Scale proporcional a una pantalla móvil estándar (375px)
    double baseScale = width / 375.0;

    return [
      // LOGO
      Positioned(
        left: _wmLayout!['logo_x']! * width,
        top: _wmLayout!['logo_y']! * height,
        child: Transform.scale(
          scale: _wmLayout!['logo_scale']! * baseScale,
          alignment: Alignment.topLeft,
          child: Image.asset(
            'assets/images/png/Logo.png',
            width: 100, // Matching editor base size
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),
      ),
      // FECHA Y HORA
      Positioned(
        left: _wmLayout!['time_x']! * width,
        top: _wmLayout!['time_y']! * height,
        child: Transform.scale(
          scale: _wmLayout!['time_scale']! * baseScale,
          alignment: Alignment.topLeft,
          child: _buildTimeElementLive(),
        ),
      ),
      // UBICACIÓN
      Positioned(
        left: _wmLayout!['loc_x']! * width,
        top: _wmLayout!['loc_y']! * height,
        child: Transform.scale(
          scale: _wmLayout!['loc_scale']! * baseScale,
          alignment: Alignment.topLeft,
          child: _buildLocationElementLive(),
        ),
      ),
    ];
  }

  Widget _buildTimeElementLive() {
    final timeStr = DateFormat('HH:mm').format(_currentTime);
    final dateStr = DateFormat('dd/MM/yyyy').format(_currentTime);
    String dayStr = DateFormat('E', 'es').format(_currentTime);
    dayStr = dayStr.substring(0, 1).toUpperCase() + dayStr.substring(1);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          timeStr,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w300,
            height: 1.0,
            shadows: [Shadow(blurRadius: 2, color: Colors.black)],
          ),
        ),
        const SizedBox(width: 8),
        Container(height: 20, width: 2, color: Colors.amber),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(dateStr, style: const TextStyle(color: Colors.white, fontSize: 8, shadows: [Shadow(blurRadius: 2, color: Colors.black)])),
            Text(dayStr, style: const TextStyle(color: Colors.white, fontSize: 8, shadows: [Shadow(blurRadius: 2, color: Colors.black)])),
          ],
        ),
      ],
    );
  }

  Widget _buildLocationElementLive() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _locationService.currentCity,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(blurRadius: 2, color: Colors.black)],
          ),
        ),
        const Text(
          'Empresa: SAT INDUSTRIALES',
          style: TextStyle(
            color: Colors.white,
            fontSize: 9,
            shadows: [Shadow(blurRadius: 2, color: Colors.black)],
          ),
        ),
      ],
    );
  }

  Widget _buildFocusReticle() {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: _showFocusReticle ? 1.0 : 0.0,
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.amber, width: 2),
        ),
        child: Center(
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.amber, width: 1.5),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(top: 12, bottom: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Zoom presets row
          if (_zoomPresets.length > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _zoomPresets.map((preset) {
                  final isSelected = (_currentZoom - preset.zoom).abs() < 0.3;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: GestureDetector(
                      onTap: () => _setZoom(preset.zoom),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: isSelected ? 42 : 36,
                        height: isSelected ? 42 : 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? Colors.grey.shade800
                              : Colors.grey.shade200,
                        ),
                        child: Center(
                          child: Text(
                            preset.label,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.grey.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: isSelected ? 13 : 11,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          // Capture button
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _takePicture,
                child: Container(
                  height: 76,
                  width: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.transparent,
                    border: Border.all(color: Colors.grey.shade400, width: 4),
                  ),
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      height: _isProcessing ? 45 : 62,
                      width: _isProcessing ? 45 : 62,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isProcessing ? Colors.grey.shade300 : Colors.grey.shade800,
                      ),
                      child: _isProcessing
                          ? const Padding(
                              padding: EdgeInsets.all(10),
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A zoom preset button value
class _ZoomPreset {
  final double zoom;
  final String label;

  const _ZoomPreset({required this.zoom, required this.label});
}

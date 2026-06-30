import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:monitor/core/theme_config.dart';
import 'package:monitor/core/widgets/modern_bottom_modal.dart';

class WatermarkEditorScreen extends StatefulWidget {
  const WatermarkEditorScreen({super.key});

  @override
  State<WatermarkEditorScreen> createState() => _WatermarkEditorScreenState();
}

class _WatermarkEditorScreenState extends State<WatermarkEditorScreen> {
  // Elements state: (x, y) in percentages (0.0 to 1.0) and scale (0.5 to 2.0)
  // Element 0: Logo
  // Element 1: Time & Date
  // Element 2: Location

  List<Offset> _positions = [
    const Offset(0.04888569730586374, 0.03871862040876778), // Logo default
    const Offset(0.04359275950871635, 0.8919667320793845), // Time default
    const Offset(0.04749281893819335, 0.7902510367298579), // Location default
  ];

  List<double> _scales = [1.0, 1.0, 1.1296037946428565];

  int _activeElementIndex = 0; // The element currently selected for scaling
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _positions[0] = Offset(
        prefs.getDouble('wm_logo_x') ?? 0.04888569730586374,
        prefs.getDouble('wm_logo_y') ?? 0.03871862040876778,
      );
      _scales[0] = prefs.getDouble('wm_logo_scale') ?? 1.0;

      _positions[1] = Offset(
        prefs.getDouble('wm_time_x') ?? 0.04359275950871635,
        prefs.getDouble('wm_time_y') ?? 0.8919667320793845,
      );
      _scales[1] = prefs.getDouble('wm_time_scale') ?? 1.0;

      _positions[2] = Offset(
        prefs.getDouble('wm_location_x') ?? 0.04749281893819335,
        prefs.getDouble('wm_location_y') ?? 0.7902510367298579,
      );
      _scales[2] = prefs.getDouble('wm_location_scale') ?? 1.1296037946428565;

      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    final logMessage =
        '''LOGO: x=${_positions[0].dx.toStringAsFixed(3)}, y=${_positions[0].dy.toStringAsFixed(3)}, scale=${_scales[0].toStringAsFixed(2)}
FECHA/HORA: x=${_positions[1].dx.toStringAsFixed(3)}, y=${_positions[1].dy.toStringAsFixed(3)}, scale=${_scales[1].toStringAsFixed(2)}
UBICACIÓN: x=${_positions[2].dx.toStringAsFixed(3)}, y=${_positions[2].dy.toStringAsFixed(3)}, scale=${_scales[2].toStringAsFixed(2)}''';

    final confirmed = await ModernBottomModal.show<bool>(
      context,
      title: 'CONFIRMAR CAMBIOS',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '¿Deseas sobreescribir los cambios?',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
          /*const SizedBox(height: 16),
          Text(
            logMessage,
            style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary),
          ),*/
        ],
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.kRadius),
              ),
            ),
            child: const Text(
              'SOBREESCRIBIR',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context, false),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.primaryAccent),
              foregroundColor: AppTheme.primaryAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.kRadius),
              ),
            ),
            child: const Text('CANCELAR'),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );

    if (confirmed != true) return;

    final prefs = await SharedPreferences.getInstance();

    // TEMPORAL: Print de coordenadas y escalas
    // debugPrint('=== GUARDANDO CONFIGURACIÓN DE MARCA DE AGUA ===');
    // debugPrint(
    //   'LOGO: x=${_positions[0].dx}, y=${_positions[0].dy}, scale=${_scales[0]}',
    // );
    // debugPrint(
    //   'TIME: x=${_positions[1].dx}, y=${_positions[1].dy}, scale=${_scales[1]}',
    // );
    // debugPrint(
    //   'LOCATION: x=${_positions[2].dx}, y=${_positions[2].dy}, scale=${_scales[2]}',
    // );
    // debugPrint('================================================');

    await prefs.setDouble('wm_logo_x', _positions[0].dx);
    await prefs.setDouble('wm_logo_y', _positions[0].dy);
    await prefs.setDouble('wm_logo_scale', _scales[0]);

    await prefs.setDouble('wm_time_x', _positions[1].dx);
    await prefs.setDouble('wm_time_y', _positions[1].dy);
    await prefs.setDouble('wm_time_scale', _scales[1]);

    await prefs.setDouble('wm_location_x', _positions[2].dx);
    await prefs.setDouble('wm_location_y', _positions[2].dy);
    await prefs.setDouble('wm_location_scale', _scales[2]);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configuración guardada correctamente.')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryAccent),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        title: const Text(
          'EDITOR DE MARCA DE AGUA',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: AppTheme.primaryAccent),
            onPressed: _saveSettings,
            tooltip: 'Guardar',
          ),
        ],
      ),
      body: Column(
        children: [
          // Explicación
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Arrastra los elementos para cambiar su posición. Selecciona uno para cambiar su tamaño con el control inferior.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),

          // Área de vista previa (3:4)
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black,
                    border: Border.all(color: AppTheme.border, width: 2),
                    image: const DecorationImage(
                      image: AssetImage(
                        'assets/images/png/auth_background.png',
                      ),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        Colors.black54,
                        BlendMode.darken,
                      ),
                    ),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
                        children: [
                          _buildDraggableElement(
                            index: 0,
                            constraints: constraints,
                            child: _buildLogoElement(),
                          ),
                          _buildDraggableElement(
                            index: 1,
                            constraints: constraints,
                            child: _buildTimeElement(),
                          ),
                          _buildDraggableElement(
                            index: 2,
                            constraints: constraints,
                            child: _buildLocationElement(),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),

          // Controles de escala
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            decoration: const BoxDecoration(
              color: AppTheme.surface,
              border: Border(top: BorderSide(color: AppTheme.border)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'TAMAÑO: ${_getElementName(_activeElementIndex)}',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    fontSize: 12,
                  ),
                ),
                Slider(
                  value: _scales[_activeElementIndex],
                  min: 0.5,
                  max: 2.5,
                  activeColor: AppTheme.primaryAccent,
                  inactiveColor: AppTheme.border,
                  onChanged: (value) {
                    setState(() {
                      _scales[_activeElementIndex] = value;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getElementName(int index) {
    switch (index) {
      case 0:
        return 'LOGO';
      case 1:
        return 'FECHA Y HORA';
      case 2:
        return 'UBICACIÓN';
      default:
        return '';
    }
  }

  Widget _buildDraggableElement({
    required int index,
    required BoxConstraints constraints,
    required Widget child,
  }) {
    final pos = _positions[index];
    final left = pos.dx * constraints.maxWidth;
    final top = pos.dy * constraints.maxHeight;
    final isSelected = _activeElementIndex == index;

    // Scale proporcional a una pantalla móvil estándar (375px)
    final baseScale = constraints.maxWidth / 375.0;

    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onTapDown: (_) {
          setState(() {
            _activeElementIndex = index;
          });
        },
        onPanUpdate: (details) {
          setState(() {
            _activeElementIndex = index;
            // Calcular nuevo porcentaje
            double newX = pos.dx + (details.delta.dx / constraints.maxWidth);
            double newY = pos.dy + (details.delta.dy / constraints.maxHeight);

            // Limitar a los bordes
            newX = newX.clamp(0.0, 0.95);
            newY = newY.clamp(0.0, 0.95);

            _positions[index] = Offset(newX, newY);
          });
        },
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            border: isSelected
                ? Border.all(color: AppTheme.primaryAccent, width: 2)
                : Border.all(color: Colors.transparent, width: 2),
          ),
          child: Transform.scale(
            scale: _scales[index] * baseScale,
            alignment: Alignment.topLeft,
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildLogoElement() {
    return Image.asset(
      'assets/images/png/Logo.png',
      width: 100, // Tamaño base visual
      errorBuilder: (_, __, ___) =>
          const Text('LOGO', style: TextStyle(color: Colors.white)),
    );
  }

  Widget _buildTimeElement() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          '13:33',
          style: TextStyle(
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
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '26/06/2026',
              style: TextStyle(
                color: Colors.white,
                fontSize: 8,
                shadows: [Shadow(blurRadius: 2, color: Colors.black)],
              ),
            ),
            Text(
              'Vie',
              style: TextStyle(
                color: Colors.white,
                fontSize: 8,
                shadows: [Shadow(blurRadius: 2, color: Colors.black)],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLocationElement() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Piura',
          style: TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(blurRadius: 2, color: Colors.black)],
          ),
        ),
        Text(
          'SAT INDUSTRIALES',
          style: TextStyle(
            color: Colors.white,
            fontSize: 9,
            shadows: [Shadow(blurRadius: 2, color: Colors.black)],
          ),
        ),
      ],
    );
  }
}

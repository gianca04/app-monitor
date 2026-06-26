import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme_config.dart';

class AppLayout extends StatefulWidget {
  final Widget child;

  const AppLayout({super.key, required this.child});

  @override
  State<AppLayout> createState() => _AppLayoutState();
}

class _AppLayoutState extends State<AppLayout> {
  int _selectedIndex = 0;
  late final List<String> _paths;
  late final RouterDelegate _routerDelegate;

  // Usar colores del tema industrial unificado
  Color get _kBorderColor => AppTheme.border;
  Color get _kBgColor => AppTheme.background;
  Color get _kBarColor => AppTheme.surface;

  @override
  void initState() {
    super.initState();
    _paths = ['/home', '/work-reports', '/profile', '/settings'];
    final router = GoRouter.of(context);
    _routerDelegate = router.routerDelegate;
    _routerDelegate.addListener(_onRouteChange);
    _selectedIndex = _getIndexFromLocation(
      _routerDelegate.currentConfiguration.uri.path,
    );
  }

  @override
  void dispose() {
    _routerDelegate.removeListener(_onRouteChange);
    super.dispose();
  }

  void _onRouteChange() {
    setState(() {
      _selectedIndex = _getIndexFromLocation(
        _routerDelegate.currentConfiguration.uri.path,
      );
    });
  }

  int _getIndexFromLocation(String location) {
    if (location == '/home') return 0;
    if (location.startsWith('/work-reports')) return 1;
    if (location.startsWith('/profile')) return 2;
    if (location.startsWith('/settings')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBgColor,
      body: widget.child,

      // Reemplazo de SalomonBottomBar por implementación Industrial
      bottomNavigationBar: _IndustrialBottomBar(
        currentIndex: _selectedIndex,
        onTap: (index) => GoRouter.of(context).go(_paths[index]),
        backgroundColor: _kBarColor,
        borderColor: _kBorderColor,
        items: [
          _IndustrialBarItem(icon: Icons.camera_alt, label: "CÁMARA"),
          _IndustrialBarItem(
            icon: Icons.table_chart_outlined,
            label: "REPORTES",
          ),
          _IndustrialBarItem(icon: Icons.person_outline, label: "PERFIL"),
          _IndustrialBarItem(icon: Icons.tune, label: "AJUSTES"),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// WIDGETS DE DISEÑO INDUSTRIAL (Custom)
// -----------------------------------------------------------------------------

/// Reemplazo "Technical" para SalomonBottomBar
/// Usa formas rectangulares y bordes en lugar de píldoras rellenas.
class _IndustrialBottomBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<_IndustrialBarItem> items;
  final Color backgroundColor;
  final Color borderColor;

  const _IndustrialBottomBar({
    required this.currentIndex,
    required this.onTap,
    required this.items,
    required this.backgroundColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(top: BorderSide(color: borderColor, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      // SafeArea asegura que no choquemos con la barra de gestos inferior de Android/iOS
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          // Añadimos MainAxisSize.min para asegurar que la fila no intente crecer verticalmente
          mainAxisSize: MainAxisSize.min,
          children: items.asMap().entries.map((entry) {
            final int index = entry.key;
            final _IndustrialBarItem item = entry.value;
            final bool isSelected = index == currentIndex;
            final Color activeColor = AppTheme.primaryAccent;

            return Expanded(
              flex: isSelected ? 2 : 1,
              child: GestureDetector(
                onTap: () => onTap(index),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? activeColor.withOpacity(0.1)
                        : Colors.transparent,
                    border: isSelected
                        ? Border.all(color: activeColor)
                        : Border.all(color: Colors.transparent),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        item.icon,
                        size: 20,
                        color: isSelected
                            ? activeColor
                            : AppTheme.textSecondary,
                      ),
                      Flexible(
                        child: ClipRect(
                          child: AnimatedAlign(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOutCubic,
                            alignment: Alignment.centerLeft,
                            widthFactor: isSelected ? 1.0 : 0.0,
                            // --- LA CORRECCIÓN CLAVE ESTÁ AQUÍ ---
                            // Forzamos a que la altura sea exactamente la del texto
                            heightFactor: 1.0,
                            // -------------------------------------
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Text(
                                item.label,
                                style: TextStyle(
                                  color: activeColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  letterSpacing: 0.5,
                                ),
                                maxLines: 1,
                                softWrap: false,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _IndustrialBarItem {
  final IconData icon;
  final String label;
  _IndustrialBarItem({required this.icon, required this.label});
}

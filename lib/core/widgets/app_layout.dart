import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
// Asegúrate de que las rutas a tus archivos sean correctas
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/settings/providers/connectivity_preferences_provider.dart';
import '../../features/settings/providers/connectivity_provider.dart';
import '../../features/settings/presentation/widgets/connectivity_indicator.dart';

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

  // Constantes de diseño industrial para este layout
  final Color _kBorderColor = Colors.grey.shade700;
  final Color _kBgColor = const Color(0xFF121212); // Fondo muy oscuro
  final Color _kBarColor = const Color(0xFF1E1E1E); // Fondo de barras

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
      appBar: AppBar(
        backgroundColor: _kBarColor, // Fondo sólido técnico
        elevation: 0,
        titleSpacing: 0,
        // Borde inferior en el AppBar para separar del contenido
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.white10, height: 1),
        ),
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: SvgPicture.asset(
            'assets/images/svg/logo.svg',
            height: 24,
            width: 24,
          ),
        ),
        actions: [
          Consumer(
            builder: (context, ref, child) {
              final preferences = ref.watch(
                connectivityPreferencesNotifierProvider,
              );
              final connectivityAsync = ref.watch(connectionStatusProvider);

              // Lógica de visualización mantenida
              final bool isEnabled = preferences.isEnabled;
              final int displayModeIndex = preferences.displayMode;

              ConnectivityDisplayMode mode;
              switch (displayModeIndex) {
                case 0:
                  mode = ConnectivityDisplayMode.iconOnly;
                  break;
                case 1:
                  mode = ConnectivityDisplayMode.iconWithText;
                  break;
                case 2:
                  mode = ConnectivityDisplayMode.dotOnly;
                  break;
                case 3:
                  mode = ConnectivityDisplayMode.badge;
                  break;
                default:
                  mode = ConnectivityDisplayMode.iconOnly;
              }

              if (!isEnabled) {
                return const Padding(
                  padding: EdgeInsets.only(right: 16.0),
                  child: _ProfileIcon(iconSize: 20),
                );
              }

              return connectivityAsync.when(
                data: (status) => Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ConnectivityIndicator(
                        mode: mode,
                        showWhenOnline: preferences.showWhenOnline,
                      ),
                      const SizedBox(width: 16),
                      const _ProfileIcon(iconSize: 20),
                    ],
                  ),
                ),
                loading: () => const Padding(
                  padding: EdgeInsets.only(right: 16.0),
                  child: _ProfileIcon(iconSize: 20),
                ),
                error: (_, __) => const Padding(
                  padding: EdgeInsets.only(right: 16.0),
                  child: _ProfileIcon(iconSize: 20),
                ),
              );
            },
          ),
        ],
      ),
      body: widget.child,

      // Reemplazo de SalomonBottomBar por implementación Industrial
      bottomNavigationBar: _IndustrialBottomBar(
        currentIndex: _selectedIndex,
        onTap: (index) => GoRouter.of(context).go(_paths[index]),
        backgroundColor: _kBarColor,
        borderColor: _kBorderColor,
        items: [
          _IndustrialBarItem(icon: Icons.grid_view, label: "INICIO"),
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
    super.key,
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
            final Color activeColor = const Color(0xFFFFAB00);

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
                        color: isSelected ? activeColor : Colors.grey.shade500,
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

// -----------------------------------------------------------------------------
// PROFILE ICON (Tu código industrial integrado)
// -----------------------------------------------------------------------------

enum Menu { itemOne, itemTwo, itemThree }

class _ProfileIcon extends ConsumerWidget {
  final double iconSize;

  const _ProfileIcon({this.iconSize = 20});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Colores del sistema
    final borderColor = Colors.grey.shade700;
    final menuBgColor = const Color.fromARGB(255, 0, 0, 0);
    final textColor = Colors.white;

    return Theme(
      data: Theme.of(context).copyWith(
        popupMenuTheme: PopupMenuThemeData(
          color: menuBgColor,
          textStyle: TextStyle(color: textColor),
          enableFeedback: true,
          // Eliminamos shape por defecto del theme para controlarlo abajo
        ),
      ),
      child: PopupMenuButton<Menu>(
        // TRIGGER
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(
            Icons.person_outline,
            size: iconSize,
            color: Colors.grey.shade300,
          ),
        ),

        // MENÚ FLOTANTE
        elevation: 0,
        offset: const Offset(0, 45),
        shape: RoundedRectangleBorder(
          side: BorderSide(color: borderColor, width: 1),
          borderRadius: BorderRadius.circular(4),
        ),

        // LÓGICA
        onSelected: (Menu item) {
          switch (item) {
            case Menu.itemOne:
              GoRouter.of(context).go('/profile');
              break;
            case Menu.itemTwo:
              GoRouter.of(context).go('/settings');
              break;
            case Menu.itemThree:
              ref.read(authProvider.notifier).logout();
              break;
          }
        },

        // ITEMS
        itemBuilder: (BuildContext context) => <PopupMenuEntry<Menu>>[
          _buildMenuItem(
            value: Menu.itemOne,
            text: 'PERFIL',
            icon: Icons.badge_outlined,
          ),
          const PopupMenuDivider(height: 1),
          _buildMenuItem(
            value: Menu.itemTwo,
            text: 'CONFIGURACIÓN',
            icon: Icons.settings_outlined,
          ),
          const PopupMenuDivider(height: 1),
          _buildMenuItem(
            value: Menu.itemThree,
            text: 'CERRAR SESIÓN',
            icon: Icons.power_settings_new,
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  PopupMenuItem<Menu> _buildMenuItem({
    required Menu value,
    required String text,
    required IconData icon,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? Colors.redAccent : Colors.white;

    return PopupMenuItem<Menu>(
      value: value,
      height: 40,
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: color.withOpacity(isDestructive ? 1 : 0.7),
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

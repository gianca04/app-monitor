import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/settings/providers/connectivity_preferences_provider.dart';
import '../widgets/connectivity_indicator.dart';

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

  @override
  void initState() {
    super.initState();
    _paths = ['/home', '/work-reports', '/profile', '/settings'];
    final router = GoRouter.of(context);
    _routerDelegate = router.routerDelegate;
    _routerDelegate.addListener(_onRouteChange);
    _selectedIndex = _getIndexFromLocation(_routerDelegate.currentConfiguration.uri.path);
  }

  @override
  void dispose() {
    _routerDelegate.removeListener(_onRouteChange);
    super.dispose();
  }

  void _onRouteChange() {
    setState(() {
      _selectedIndex = _getIndexFromLocation(_routerDelegate.currentConfiguration.uri.path);
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        title: Consumer(
          builder: (context, ref, child) {
            final preferences = ref.watch(connectivityPreferencesNotifierProvider);
            final connectivityAsync = ref.watch(connectivityStatusProvider);
            if (preferences.isEnabled) {
              ConnectivityDisplayMode mode;
              switch (preferences.displayMode) {
                case 0:
                  mode = ConnectivityDisplayMode.iconOnly;
                  break;
                case 1:
                  mode = ConnectivityDisplayMode.iconAndText;
                  break;
                case 2:
                  mode = ConnectivityDisplayMode.iconOnly; // Placeholder for dot
                  break;
                case 3:
                  mode = ConnectivityDisplayMode.iconOnly; // Placeholder for badge
                  break;
                default:
                  mode = ConnectivityDisplayMode.iconOnly;
              }
              return connectivityAsync.when(
                data: (isOnline) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      ConnectivityIndicator(
                        mode: mode,
                        showWhenOnline: preferences.showWhenOnline,
                        isOnline: isOnline,
                      ),
                    ],
                  ),
                ),
                loading: () => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SvgPicture.asset(
                        'assets/images/svg/logo.svg',
                        height: 24,
                        width: 24,
                      ),
                    ],
                  ),
                ),
                error: (error, stack) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SvgPicture.asset(
                        'assets/images/svg/logo.svg',
                        height: 24,
                        width: 24,
                      ),
                    ],
                  ),
                ),
              );
            } else {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SvgPicture.asset(
                      'assets/images/svg/logo.svg',
                      height: 24,
                      width: 24,
                    ),
                  ],
                ),
              );
            }
          },
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: CircleAvatar(child: _ProfileIcon()),
          ),
        ],
      ),
      body: widget.child,
      bottomNavigationBar: SalomonBottomBar(
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFFFFAB00), // primaryAccent
        unselectedItemColor: const Color(0xFF8B949E), // textSecondary
        onTap: (index) {
          GoRouter.of(context).go(_paths[index]);
        },
        items: _navBarItems,
      ),
    );
  }
}

final _navBarItems = [
  SalomonBottomBarItem(
    icon: const Icon(Icons.home),
    title: const Text("Inicio"),
    selectedColor: const Color(0xFFFFAB00),
  ),
  SalomonBottomBarItem(
    icon: const Icon(Icons.work),
    title: const Text("Reportes"),
    selectedColor: const Color(0xFFFFAB00),
  ),
  SalomonBottomBarItem(
    icon: const Icon(Icons.person),
    title: const Text("Perfil"),
    selectedColor: const Color(0xFFFFAB00),
  ),
  SalomonBottomBarItem(
    icon: const Icon(Icons.settings),
    title: const Text("Configuración"),
    selectedColor: const Color(0xFFFFAB00),
  ),
];

enum Menu { itemOne, itemTwo, itemThree }

class _ProfileIcon extends ConsumerWidget {
  const _ProfileIcon();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<Menu>(
      icon: const Icon(Icons.person),
      offset: const Offset(0, 40),
      onSelected: (Menu item) {
        switch (item) {
          case Menu.itemThree:
            ref.read(authProvider.notifier).logout();
            break;
          default:
            break;
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<Menu>>[
        const PopupMenuItem<Menu>(value: Menu.itemOne, child: Text('Account')),
        const PopupMenuItem<Menu>(value: Menu.itemTwo, child: Text('Settings')),
        const PopupMenuItem<Menu>(
          value: Menu.itemThree,
          child: Text('Sign Out'),
        ),
      ],
    );
  }
}
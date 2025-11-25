import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

class AppLayout extends ConsumerWidget {
  final Widget child;

  AppLayout({super.key, required this.child});

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.of(context).size.width;
    final bool isLargeScreen = width > 800;

    return Theme(
      data: ThemeData.dark(),
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          titleSpacing: 0,
          leading: isLargeScreen
              ? null
              : IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                ),
          title: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Logo",
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isLargeScreen) Expanded(child: _navBarItems(context, ref)),
              ],
            ),
          ),
          actions: const [
            Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: CircleAvatar(child: _ProfileIcon()),
            ),
          ],
        ),
        drawer: isLargeScreen ? null : _drawer(context, ref),
        body: child, // Aquí se inyecta el contenido de la ruta
      ),
    );
  }

  Widget _drawer(BuildContext context, WidgetRef ref) => Drawer(
    child: ListView(
      children: _menuItems
          .map(
            (item) => ListTile(
              onTap: () => _onMenuItemTap(context, ref, item),
              title: Text(item),
            ),
          )
          .toList(),
    ),
  );

  Widget _navBarItems(BuildContext context, WidgetRef ref) => Row(
    mainAxisAlignment: MainAxisAlignment.end,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: _menuItems
        .map(
          (item) => InkWell(
            onTap: () => _onMenuItemTap(context, ref, item),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 24.0,
                horizontal: 16,
              ),
              child: Text(item, style: const TextStyle(fontSize: 18)),
            ),
          ),
        )
        .toList(),
  );

  void _onMenuItemTap(BuildContext context, WidgetRef ref, String item) {
    switch (item) {
      case 'Work Reports':
        GoRouter.of(context).go('/work-reports');
        break;
      case 'Sign Out':
        ref.read(authProvider.notifier).logout();
        break;
      default:
        // Handle other items
        break;
    }
    _scaffoldKey.currentState?.openEndDrawer();
  }
}

final List<String> _menuItems = <String>[
  'Work Reports',
  'About',
  'Contact',
  'Settings',
  'Sign Out',
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
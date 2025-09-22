import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:heavy_new/foundation/ui/bottom_bar.dart';
import 'package:heavy_new/foundation/ui/app_icons.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child, required this.path});
  final Widget child;
  final String path; // passed from ShellRoute: state.uri.path

  static const _mainTabs = <String>{'/', '/equipments', '/settings'};

  static int _indexFor(String p) {
    switch (p) {
      case '/':
        return 0;
      case '/equipments':
        return 1;
      case '/settings':
        return 2;
      default:
        return -1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final idx = _indexFor(path);
    final showDock = _mainTabs.contains(path);

    return Scaffold(
      body: child,
      bottomNavigationBar: showDock
          ? ModernBottomBar(
              currentIndex: idx, // 0..2 here
              items: const [
                ModernNavItem(glyph: AppGlyph.truck, label: 'Home'),
                ModernNavItem(glyph: AppGlyph.search, label: 'Browse'),
                ModernNavItem(glyph: AppGlyph.Settings, label: 'Settings'),
              ],
              onChanged: (i) {
                switch (i) {
                  case 0:
                    context.go('/');
                    break;
                  case 1:
                    context.go('/equipments');
                    break;
                  case 2:
                    context.go('/settings');
                    break;
                }
              },
            )
          : null, // hidden on non-main routes (e.g. /equipment/123)
    );
  }
}

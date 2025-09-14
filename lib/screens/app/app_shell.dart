// lib/screens/app_shell.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:heavy_new/foundation/ui/bottom_bar.dart';
import 'package:heavy_new/foundation/ui/app_icons.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child, required this.path});
  final Widget child;
  final String path; // <- the URI path, no query/fragment

  // Only these routes show the dock
  static const _mainTabs = <String>{'/', '/equipments', '/settings'};

  bool get _showDock => _mainTabs.contains(path);

  int get _index {
    switch (path) {
      case '/':
        return 0;
      case '/equipments':
        return 1;
      case '/settings':
        return 2;
      default:
        return -1; // not a main tab
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: _showDock
          ? ModernBottomBar(
              currentIndex: _index, // 0..2 only when shown
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
          : null, // <- hides dock for any non-main route
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:Ajjara/foundation/ui/bottom_bar.dart';
import 'package:Ajjara/foundation/ui/app_icons.dart';
import 'package:Ajjara/l10n/app_localizations.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child, required this.path});
  final Widget child;
  final String path; // from ShellRoute: state.uri.path

  // Top-level tab indexes
  static const int _homeIdx = 0;
  static const int _browseIdx = 1;
  static const int _settingsIdx = 2;

  // Exact tab routes
  static const _homePath = '/';
  static const _browsePath = '/equipments';
  static const _settingsPath = '/settings';

  // Is it one of the three main screens?
  static bool _isMain(String p) =>
      p == _homePath || p == _browsePath || p == _settingsPath;

  // Which tab to highlight for any deep path
  static int _indexForDeep(String p) {
    if (p == _homePath) return _homeIdx;
    if (p == _browsePath || p.startsWith('/equipment')) return _browseIdx;
    if (p == _settingsPath || p.startsWith('/settings/')) return _settingsIdx;
    // Fallback: show Home as selected
    return _homeIdx;
  }

  static String _routeForIndex(int i) {
    switch (i) {
      case _homeIdx:
        return _homePath;
      case _browseIdx:
        return _browsePath;
      case _settingsIdx:
        return _settingsPath;
      default:
        return _homePath;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Normalize (strip query)
    final p = path.split('?').first;
    final isMain = _isMain(p);
    final currentIndex = _indexForDeep(p);

    final bar = ModernBottomBar(
      currentIndex: currentIndex,
      items: [
        ModernNavItem(glyph: AppGlyph.truck, label: l10n.home),
        ModernNavItem(glyph: AppGlyph.search, label: l10n.browse),
        ModernNavItem(glyph: AppGlyph.settings, label: l10n.settings),
      ],
      onChanged: (i) {
        if (!isMain) return; // locked off-main
        final target = _routeForIndex(i);
        if (p == target) return;
        context.push(target); // keep push so back button appears
      },
    );

    // When locked: dim + ignore taps (still occupies space)
    final bottomBar = isMain
        ? bar
        : IgnorePointer(
            ignoring: true,
            child: Opacity(opacity: 0.6, child: bar),
          );

    return Scaffold(body: child, bottomNavigationBar: bottomBar);
  }
}

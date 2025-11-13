import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';

import 'package:Ajjara/core/auth/auth_store.dart';
import 'package:Ajjara/foundation/ui/ui_kit.dart';
import 'package:Ajjara/l10n/app_localizations.dart';
import 'package:Ajjara/main.dart' show navigatorKey;

class SessionManager {
  static const _kLoginFlag = 'is_logged_in'; // simple durable flag
  // (Optional) keep last login time if you still want analytics
  static const _kLoginAtMs = 'login_at_ms';

  /// Call this right after a successful login.
  Future<void> startFreshSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kLoginFlag, true);
    await prefs.setInt(_kLoginAtMs, DateTime.now().millisecondsSinceEpoch);
    // No timers, no expiry.
  }

  /// Call this on app startup to restore the session if present.
  Future<void> enforceNow() async {
    final prefs = await SharedPreferences.getInstance();
    final logged = prefs.getBool(_kLoginFlag) ?? false;

    if (logged) {
      // If your AuthStore needs rehydration (e.g., load token/user from disk), do it here.
      // Otherwise do nothing—the user stays logged in.
      if (!AuthStore.instance.isLoggedIn) {
        await AuthStore.instance.trySilentRefresh(); // implement if needed
      }
    } else {
      // Not logged; you may choose to navigate to auth.
      // final ctx = navigatorKey.currentContext; ctx?.go('/auth');
    }
  }

  /// Explicit logout only (clears durable flag and delegates to AuthStore).
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kLoginFlag);
    await prefs.remove(_kLoginAtMs);

    if (AuthStore.instance.isLoggedIn) {
      await AuthStore.instance.logout();
    }

    final ctx = navigatorKey.currentContext;
    if (ctx != null) {
      final l10n = AppLocalizations.of(ctx);
      AppSnack.info(ctx, l10n?.signedOut ?? 'Signed out.');
      ctx.go('/auth');
    }
  }
}

final sessionManager = SessionManager();

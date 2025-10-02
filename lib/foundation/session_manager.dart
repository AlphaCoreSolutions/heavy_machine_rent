import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:heavy_new/foundation/ui/ui_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';

import 'package:heavy_new/core/auth/auth_store.dart';
import 'package:heavy_new/l10n/app_localizations.dart';

import 'package:heavy_new/main.dart'
    show navigatorKey; // reuse your root navigator

class SessionManager with WidgetsBindingObserver {
  static const _kLoginAtMs = 'login_at_ms';
  static const sessionDuration = Duration(minutes: 3); //for testing

  Timer? _expiryTimer;

  /// Call this right after a successful login.
  Future<void> startFreshSession({bool reset = false}) async {
    WidgetsBinding.instance.addObserver(this);
    final prefs = await SharedPreferences.getInstance();

    if (!reset && prefs.containsKey(_kLoginAtMs)) {
      // A session already exists -> don't refresh; just ensure timer matches.
      await enforceNow();
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    await prefs.setInt(_kLoginAtMs, now);
    _scheduleTimer(sessionDuration);
  }

  /// Call this once on app startup (and it’s safe to call again on resume).
  Future<void> enforceNow() async {
    WidgetsBinding.instance.addObserver(this);
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_kLoginAtMs);
    if (ms == null) {
      _cancelTimer();
      return; // not logged in or we don't manage this session
    }
    final loginAt = DateTime.fromMillisecondsSinceEpoch(ms);
    final elapsed = DateTime.now().difference(loginAt);
    if (elapsed >= sessionDuration) {
      await _expireSession();
    } else {
      _scheduleTimer(sessionDuration - elapsed);
    }
  }

  void _scheduleTimer(Duration remaining) {
    _cancelTimer();
    _expiryTimer = Timer(remaining, _expireSession);
  }

  void _cancelTimer() {
    _expiryTimer?.cancel();
    _expiryTimer = null;
  }

  Future<void> _expireSession() async {
    _cancelTimer();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kLoginAtMs);

    // If already signed out, nothing to do.
    if (!AuthStore.instance.isLoggedIn) return;

    await AuthStore.instance.logout();

    // Optional UX: nudge user and navigate to auth.
    final ctx = navigatorKey.currentContext;
    if (ctx != null) {
      final l10n = AppLocalizations.of(ctx);
      AppSnack.info(
        ctx,
        l10n?.sessionExpired ?? 'Session expired. Please sign in again.',
      );
      // Send the user to the auth screen or home; choose one:
      ctx.go('/auth'); // or ctx.go('/');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-check on resume in case the app was backgrounded for > 2 hours.
    if (state == AppLifecycleState.resumed) {
      // Fire and forget; timer will be rescheduled/expired inside.
      enforceNow();
    }
  }
}

final sessionManager = SessionManager();

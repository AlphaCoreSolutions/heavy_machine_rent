// lib/screens/app/app_prefs.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ===== Notification prefs (unchanged API, with a couple of niceties) =====
class NotificationPrefs {
  final bool pushEnabled;
  final bool inAppEnabled;
  final bool emailEnabled;
  final bool soundEnabled;
  final TimeOfDay? quietFrom; // demo only
  final TimeOfDay? quietTo; // demo only

  const NotificationPrefs({
    this.pushEnabled = true,
    this.inAppEnabled = true,
    this.emailEnabled = false,
    this.soundEnabled = true,
    this.quietFrom,
    this.quietTo,
  });

  NotificationPrefs copyWith({
    bool? pushEnabled,
    bool? inAppEnabled,
    bool? emailEnabled,
    bool? soundEnabled,
    TimeOfDay? quietFrom,
    TimeOfDay? quietTo,
  }) {
    return NotificationPrefs(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      inAppEnabled: inAppEnabled ?? this.inAppEnabled,
      emailEnabled: emailEnabled ?? this.emailEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      quietFrom: quietFrom ?? this.quietFrom,
      quietTo: quietTo ?? this.quietTo,
    );
  }

  Map<String, dynamic> toJson() => {
    'push': pushEnabled,
    'inapp': inAppEnabled,
    'email': emailEnabled,
    'sound': soundEnabled,
    'qFrom': quietFrom == null
        ? null
        : '${quietFrom!.hour}:${quietFrom!.minute}',
    'qTo': quietTo == null ? null : '${quietTo!.hour}:${quietTo!.minute}',
  };

  factory NotificationPrefs.fromJson(Map<String, dynamic> json) {
    TimeOfDay? parse(String? hhmm) {
      if (hhmm == null || !hhmm.contains(':')) return null;
      final p = hhmm.split(':');
      final h = int.tryParse(p[0]) ?? 0;
      final m = int.tryParse(p[1]) ?? 0;
      return TimeOfDay(hour: h, minute: m);
    }

    return NotificationPrefs(
      pushEnabled: json['push'] ?? true,
      inAppEnabled: json['inapp'] ?? true,
      emailEnabled: json['email'] ?? false,
      soundEnabled: json['sound'] ?? true,
      quietFrom: parse(json['qFrom']),
      quietTo: parse(json['qTo']),
    );
  }
}

/// ===== AppPrefs: single source of truth for theme/locale/notifications =====
/// - Theme: defaults to system; persists user override
/// - Locale: null == follow system; persists user override (en/ar)
/// - Notifications: persisted as JSON
class AppPrefs {
  AppPrefs._();
  static final AppPrefs instance = AppPrefs._();

  // Reactive values the app listens to
  final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.system);

  /// null = system; otherwise explicit Locale('en') or Locale('ar')
  final ValueNotifier<Locale?> locale = ValueNotifier<Locale?>(null);

  final ValueNotifier<NotificationPrefs> notifications =
      ValueNotifier<NotificationPrefs>(const NotificationPrefs());

  // Storage keys
  static const _kTheme = 'prefs.themeMode';
  static const _kLocale = 'prefs.locale'; // '' or missing == system
  static const _kNotif = 'prefs.notifications';

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    final sp = await SharedPreferences.getInstance();

    // === THEME ===
    final t = sp.getString(_kTheme);
    if (t != null && t.isNotEmpty) {
      final found = ThemeMode.values.where((m) => m.name == t);
      themeMode.value = found.isNotEmpty ? found.first : ThemeMode.system;
    } else {
      themeMode.value = ThemeMode.system;
    }

    // === LOCALE ===
    // null/'' -> system (null); otherwise 'en' or 'ar'
    final l = sp.getString(_kLocale);
    if (l == null || l.isEmpty) {
      locale.value = null; // follow system
    } else {
      locale.value = Locale(l);
    }

    // === NOTIFICATIONS ===
    final n = sp.getString(_kNotif);
    if (n != null && n.isNotEmpty) {
      try {
        notifications.value = NotificationPrefs.fromJson(
          Map<String, dynamic>.from(jsonDecode(n)),
        );
      } catch (_) {
        // keep defaults on parse failure
      }
    }

    _initialized = true;
  }

  /// Set theme. Persist exact user choice.
  Future<void> setTheme(ThemeMode mode) async {
    themeMode.value = mode;
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kTheme, mode.name);
  }

  /// Set locale. Pass null to follow system. Persist '' for system.
  Future<void> setLocale(Locale? v) async {
    locale.value = v;
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kLocale, v?.languageCode ?? '');
  }

  /// Set notifications JSON blob.
  Future<void> setNotifications(NotificationPrefs v) async {
    notifications.value = v;
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kNotif, jsonEncode(v.toJson()));
  }

  /// Optional utilities
  bool get isSystemLocale => locale.value == null;
  String get localeCode => locale.value?.languageCode ?? 'system';

  /// Quick toggles (optional sugar)
  Future<void> cycleTheme() async {
    final order = [ThemeMode.system, ThemeMode.light, ThemeMode.dark];
    final i = order.indexOf(themeMode.value);
    final next = order[(i + 1) % order.length];
    await setTheme(next);
  }

  /// Reset everything to defaults (system theme/locale, default notifications)
  Future<void> resetAll() async {
    await setTheme(ThemeMode.system);
    await setLocale(null);
    await setNotifications(const NotificationPrefs());
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  }) => NotificationPrefs(
    pushEnabled: pushEnabled ?? this.pushEnabled,
    inAppEnabled: inAppEnabled ?? this.inAppEnabled,
    emailEnabled: emailEnabled ?? this.emailEnabled,
    soundEnabled: soundEnabled ?? this.soundEnabled,
    quietFrom: quietFrom ?? this.quietFrom,
    quietTo: quietTo ?? this.quietTo,
  );

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
    TimeOfDay? _parse(String? hhmm) {
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
      quietFrom: _parse(json['qFrom']),
      quietTo: _parse(json['qTo']),
    );
  }
}

class AppPrefs {
  AppPrefs._();
  static final AppPrefs instance = AppPrefs._();

  // Reactive values the app can listen to
  final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.light);

  /// null = system, otherwise a concrete locale (en / ar)
  final ValueNotifier<Locale?> locale = ValueNotifier(const Locale('en'));
  final ValueNotifier<NotificationPrefs> notifications = ValueNotifier(
    const NotificationPrefs(),
  );

  // Storage keys
  static const _kTheme = 'prefs.themeMode';
  static const _kLocale = 'prefs.locale';
  static const _kNotif = 'prefs.notifications';

  Future<void> init() async {
    final sp = await SharedPreferences.getInstance();

    final t = sp.getString(_kTheme);
    if (t != null) {
      themeMode.value = ThemeMode.values.firstWhere(
        (m) => m.name == t,
        orElse: () => ThemeMode.light,
      );
    }

    final l = sp.getString(_kLocale);
    if (l == null || l.isEmpty) {
      locale.value = const Locale('en');
    } else {
      locale.value = Locale(l);
    }

    final n = sp.getString(_kNotif);
    if (n != null && n.isNotEmpty) {
      try {
        notifications.value = NotificationPrefs.fromJson(
          Map<String, dynamic>.from(jsonDecode(n)),
        );
      } catch (_) {}
    }
  }

  Future<void> setTheme(ThemeMode mode) async {
    themeMode.value = mode;
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kTheme, mode.name);
  }

  Future<void> setLocale(Locale? v) async {
    locale.value = v;
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kLocale, v?.languageCode ?? '');
  }

  Future<void> setNotifications(NotificationPrefs v) async {
    notifications.value = v;
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kNotif, jsonEncode(v.toJson()));
  }
}

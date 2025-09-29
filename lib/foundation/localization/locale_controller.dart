import 'package:flutter/material.dart';

class LocaleController extends ChangeNotifier {
  Locale? _locale;
  Locale? get locale => _locale;

  final List<Locale> supported = const [Locale('en'), Locale('ar')];

  void setLocale(Locale? l) {
    if (l == null) return;
    if (!supported.contains(Locale(l.languageCode))) return;
    _locale = l;
    notifyListeners();
  }

  void clear() {
    _locale = null;
    notifyListeners();
  }
}

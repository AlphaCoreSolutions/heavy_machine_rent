import 'package:flutter/material.dart';
import 'package:heavy_new/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
  Locale get locale => Localizations.localeOf(this);
  bool get isArabic => locale.languageCode == 'ar';
}

const _arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

extension ArabicDigits on String {
  String toArabicDigits() => replaceAllMapped(RegExp(r"[0-9]"), (m) {
    final d = int.parse(m.group(0)!);
    return _arabicDigits[d];
  });
}

String formatCurrency(
  BuildContext context,
  num value, {
  int decimals = 0,
  String symbol = 'JD',
}) {
  final tag = Localizations.localeOf(context).toLanguageTag();
  final f = NumberFormat.currency(
    locale: tag,
    symbol: symbol,
    decimalDigits: decimals,
  );
  final out = f.format(value);
  return context.isArabic ? out.toArabicDigits() : out;
}

String formatDateYMD(BuildContext context, DateTime date) {
  final tag = Localizations.localeOf(context).toLanguageTag();
  final f = DateFormat.yMMMd(tag);
  final out = f.format(date);
  return context.isArabic ? out.toArabicDigits() : out;
}

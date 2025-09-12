import 'package:intl/intl.dart';

class Money {
  /// Display code "SAR" consistently. Use symbol if you add a custom font later.
  static const String code = 'SAR';

  /// Formats a number as SAR with smart decimals (0 or 2).
  static String format(num? amount, {bool withCode = true}) {
    final value = (amount ?? 0).toDouble();
    final hasCents = (value % 1) != 0;
    final f = NumberFormat.currency(
      locale: 'en', // tweak if you localize later
      name: withCode ? code : '', // uses code in front when true
      symbol: withCode ? code : '', // keep as text "SAR"
      decimalDigits: hasCents ? 2 : 0,
    );
    return f.format(value);
  }

  /// Convenience for unit pricing, e.g. "SAR 1,600/day"
  static String per(String unit, num? amount) => '${format(amount)}/$unit';
}

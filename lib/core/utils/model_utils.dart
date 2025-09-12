import 'package:intl/intl.dart';

DateTime? dt(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  if (v is String && v.isNotEmpty) {
    return DateTime.tryParse(v);
  }
  return null;
}

num? fnum(dynamic v) {
  if (v == null) return null;
  if (v is num) return v;
  if (v is String) return num.tryParse(v);
  return null;
}

String fmtDate(DateTime d) {
  // yyyy-MM-dd
  final mm = d.month.toString().padLeft(2, '0');
  final dd = d.day.toString().padLeft(2, '0');
  return '${d.year}-$mm-$dd';
}

// Add this next to your existing dt() / fnum() helpers.
int? fint(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v);
  if (v is Map) {
    // Try common keys you may see from your API
    final candidates = [
      'id',
      'requestId',
      'organizationId',
      'applicationUserId',
      'domainDetailId',
      'value',
      'key',
    ];
    for (final k in candidates) {
      final x = v[k];
      if (x is int) return x;
      if (x is String) return int.tryParse(x);
      if (x is double) return x.toInt();
    }
  }
  return null;
}

// Optional: safe date string -> DateTime?
DateTime? dtLoose(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  if (v is String) {
    // Try full ISO or just yyyy-MM-dd
    return DateTime.tryParse(v) ??
        (v.contains('T') ? DateTime.tryParse(v.split('T').first) : null);
  }
  if (v is int) {
    // sometimes epoch ms
    return DateTime.fromMillisecondsSinceEpoch(v, isUtc: false);
  }
  return null;
}

String? s(dynamic v) => v is String ? v : null;
int? i(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse('$v');
}

bool? b(dynamic v) {
  if (v == null) return null;
  if (v is bool) return v;
  final t = '$v'.toLowerCase();
  if (t == 'true' || t == '1') return true;
  if (t == 'false' || t == '0') return false;
  return null;
}

Map<String, dynamic>? m(dynamic v) =>
    v is Map ? Map<String, dynamic>.from(v) : null;
List<Map<String, dynamic>> lm(dynamic v) => (v is List)
    ? v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
    : const [];

// json_sugar.dart

dynamic gv(Map<String, dynamic> j, List<String> keys) {
  for (final k in keys) {
    if (j.containsKey(k) && j[k] != null) return j[k];
  }
  return null;
}

String? sx(dynamic v) {
  if (v == null) return null;
  if (v is String) return v;
  if (v is num || v is bool) return '$v';
  return null; // maps/arrays ignored for string fields
}

int? ix(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

bool? bx(dynamic v) {
  if (v == null) return null;
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) {
    final t = v.toLowerCase();
    if (t == 'true' || t == '1' || t == 'yes') return true;
    if (t == 'false' || t == '0' || t == 'no') return false;
  }
  return null;
}

/// Normalize any of: "yyyy-MM-dd", ISO strings, millis, seconds, or {year,month,day}
String? ymdFromAny(dynamic v) {
  if (v == null) return null;

  DateTime? d;

  if (v is String) {
    // Already YMD?
    if (v.length >= 10 && v[4] == '-' && v[7] == '-') {
      // If longer (ISO), we still parse to be safe then cut date
      try {
        d = DateTime.parse(v);
      } catch (_) {
        // If parse fails but string looks like YMD, just trim it.
        return v.substring(0, 10);
      }
      return DateFormat('yyyy-MM-dd').format(d);
    }
    // Try ISO parse anyway
    try {
      d = DateTime.parse(v);
      return DateFormat('yyyy-MM-dd').format(d);
    } catch (_) {
      return v; // leave as-is if it's some other string
    }
  }

  if (v is num) {
    // Heuristic: > 10^12 ~ millis; > 10^9 ~ seconds
    d = v > 20000000000
        ? DateTime.fromMillisecondsSinceEpoch(v.toInt(), isUtc: true)
        : v > 2000000000
        ? DateTime.fromMillisecondsSinceEpoch((v * 1000).toInt(), isUtc: true)
        : DateTime.fromMillisecondsSinceEpoch(v.toInt(), isUtc: true);
    return DateFormat('yyyy-MM-dd').format(d);
  }

  if (v is Map) {
    final y = v['year'] ?? v['Year'];
    final m = v['month'] ?? v['Month'];
    final d0 = v['day'] ?? v['Day'];
    if (y is num && m is num && d0 is num) {
      final dt = DateTime(y.toInt(), m.toInt(), d0.toInt());
      return DateFormat('yyyy-MM-dd').format(dt);
    }
    final iso = v['iso'] ?? v['Iso'] ?? v['date'] ?? v['Date'];
    if (iso is String) {
      try {
        final dt = DateTime.parse(iso);
        return DateFormat('yyyy-MM-dd').format(dt);
      } catch (_) {}
      if (iso.length >= 10) return iso.substring(0, 10);
    }
  }

  return null;
}

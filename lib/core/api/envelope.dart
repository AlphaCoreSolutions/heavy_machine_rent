// lib/core/api/envelope.dart
import 'dart:convert';

class ApiEnvelope {
  final bool? flag;
  final int? responseType;
  final String? message;
  final int? modelId;
  final dynamic data;

  // ✅ Tokens used by auth flows
  final String? token;
  final String? refreshToken;

  // Keep raw around for debugging / edge cases
  final Map<String, dynamic> raw;

  const ApiEnvelope({
    this.flag,
    this.responseType,
    this.message,
    this.modelId,
    this.data,
    this.token,
    this.refreshToken,
    this.raw = const {},
  });

  /// Your existing call sites that pass a Map can keep using this.
  factory ApiEnvelope.fromJson(Map<String, dynamic> json) =>
      ApiEnvelope._fromMap(_toMap(json));

  /// Use this when you might have String / Map / List / anything.
  factory ApiEnvelope.fromAny(dynamic raw) => ApiEnvelope._fromMap(_toMap(raw));

  static ApiEnvelope _fromMap(Map<String, dynamic> map) {
    final data = map['data'] ?? map['model'] ?? map['result'] ?? map['payload'];

    // Pull tokens from top level or nested data
    final token = _firstString([
      map['token'],
      map['accessToken'],
      map['jwt'],
      map['bearerToken'],
      if (data is Map) data['token'],
      if (data is Map) data['accessToken'],
      if (data is Map) data['jwt'],
      if (data is Map) data['bearerToken'],
    ]);

    final refreshToken = _firstString([
      map['refreshToken'],
      map['refresh'],
      if (data is Map) data['refreshToken'],
      if (data is Map) data['refresh'],
    ]);

    return ApiEnvelope(
      flag: _toBool(map['flag'] ?? map['success'] ?? map['ok']),
      responseType: _toInt(map['responseType'] ?? map['type']),
      message: _toMessage(
        map['message'] ??
            map['Message'] ??
            map['title'] ??
            map['Title'] ??
            map['error'] ??
            map['Error'] ??
            map['errors'],
      ),
      modelId: _toInt(map['modelId'] ?? map['id'] ?? map['Id']),
      data: data,
      token: token,
      refreshToken: refreshToken,
      raw: map,
    );
  }

  // --- helpers ---------------------------------------------------------------

  static Map<String, dynamic> _toMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is String) {
      try {
        return _toMap(jsonDecode(raw));
      } catch (_) {}
    }
    if (raw is List && raw.isNotEmpty && raw.first is Map) {
      return Map<String, dynamic>.from(raw.first as Map);
    }
    return <String, dynamic>{};
  }

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v');
  }

  static bool? _toBool(dynamic v) {
    if (v == null) return null;
    if (v is bool) return v;
    final s = '$v'.toLowerCase();
    if (s == 'true' || s == '1') return true;
    if (s == 'false' || s == '0') return false;
    return null;
  }

  static String? _firstString(Iterable candidates) {
    for (final v in candidates) {
      if (v is String && v.trim().isNotEmpty) return v;
    }
    return null;
  }

  /// Coerces maps/lists into a readable message, avoids cast crashes.
  static String? _toMessage(dynamic v) {
    if (v == null) return null;
    if (v is String) return v;
    if (v is List) {
      final parts = v.map(_toMessage).whereType<String>().toList();
      return parts.isEmpty ? '$v' : parts.join('\n');
    }
    if (v is Map) {
      final parts = <String>[];
      v.forEach((k, val) {
        final s = _toMessage(val);
        if (s != null && s.trim().isNotEmpty) parts.add('$k: $s');
      });
      return parts.isEmpty ? jsonEncode(v) : parts.join('\n');
    }
    return '$v';
  }

  Map<String, dynamic> toJson() => {
    'flag': flag,
    'responseType': responseType,
    'message': message,
    'modelId': modelId,
    'data': data,
    'token': token,
    'refreshToken': refreshToken,
  };
}

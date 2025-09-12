// lib/core/auth/jwt_utils.dart
import 'dart:convert';

class JwtClaims {
  final int? userId;
  final String? name;
  final String? email;
  final String? mobile;
  final DateTime? exp;

  JwtClaims({this.userId, this.name, this.email, this.mobile, this.exp});
}

class JwtUtils {
  static JwtClaims tryDecode(String jwt) {
    try {
      final parts = jwt.split('.');
      if (parts.length != 3) return JwtClaims();
      final payload = utf8.decode(base64Url.decode(_pad(parts[1])));
      final map = jsonDecode(payload) as Map<String, dynamic>;
      return JwtClaims(
        userId: int.tryParse(
          '${map["http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier"] ?? map["sub"] ?? ""}',
        ),
        name:
            map["http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name"] ??
            map["name"],
        email:
            map["http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"] ??
            map["email"],
        mobile:
            map["http://schemas.xmlsoap.org/ws/2005/05/identity/claims/mobilephone"] ??
            map["phone"],
        exp: _parseDate(
          map["http://schemas.microsoft.com/ws/2008/06/identity/claims/expiration"] ??
              map["exp"],
        ),
      );
    } catch (_) {
      return JwtClaims();
    }
  }

  static String _pad(String s) =>
      s + List.filled((4 - s.length % 4) % 4, '=').join();
  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is num) return DateTime.fromMillisecondsSinceEpoch(v.toInt() * 1000);
    if (v is String) {
      final dt = DateTime.tryParse(v);
      return dt;
    }
    return null;
  }
}

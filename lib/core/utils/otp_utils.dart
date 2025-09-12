// lib/core/auth/otp_utils.dart
String? extractOtpFromMessage(String? message) {
  if (message == null) return null;
  final m = RegExp(r'(\d{4,6})').firstMatch(message);
  return m?.group(1);
}

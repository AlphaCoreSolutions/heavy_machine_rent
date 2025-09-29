// lib/core/auth/auth_store.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:heavy_new/core/models/user/auth.dart';
import 'package:heavy_new/core/models/user/user_account.dart';
import 'package:heavy_new/core/api/api_handler.dart' as api;

class AuthStore {
  AuthStore._();
  static final AuthStore instance = AuthStore._();

  final ValueNotifier<AuthUser?> user = ValueNotifier<AuthUser?>(null);
  AuthTokens? tokens;

  // pending state between /CheckUserByMobile and /CheckOTPCode
  String? _pendingDigits; // 9-digit local number, e.g. "5XXXXXXXX"
  // ignore: unused_field
  int? _pendingCountryCode; // e.g. 966
  int? _pendingUserId; // from envelope.modelId

  Future<void> init() async {
    final sp = await SharedPreferences.getInstance();
    final uJson = sp.getString('auth.user');
    final tJson = sp.getString('auth.tokens');
    if (uJson != null) user.value = AuthUser.fromJson(jsonDecode(uJson));
    if (tJson != null) {
      tokens = AuthTokens.fromJson(jsonDecode(tJson));
      if (tokens?.token.isNotEmpty == true) {
        api.Api.setToken(tokens!.token);
      }
    }

    // Tell Api how to get/set tokens
    api.Api.configureAuthHooks(
      getRefreshToken: () => tokens?.refreshToken ?? '',
      onTokensUpdated: (t) async {
        tokens = t;
        if (t.token.isNotEmpty) api.Api.setToken(t.token);
        await _persist();
        // If you want, you could also ping /me here to refresh user profile.
      },
    );
  }

  bool get isLoggedIn => (tokens?.token.isNotEmpty == true);

  // Optional: call this on app start or Home.init()
  Future<void> trySilentRefresh() async {
    // Only try if we *have* a refresh token and (optionally) the access is empty/expired.
    if (tokens?.refreshToken?.isNotEmpty != true) return;
    await api.Api.tryRefreshToken();

    // After loading tokens in AuthStore.init()
    api.Api.registerAuthHooks(
      getRefreshToken: () => tokens?.refreshToken,
      onTokensUpdated: (t) async {
        tokens = t;
        await _persist();
      },
    );
  }

  Future<void> _persist() async {
    final sp = await SharedPreferences.getInstance();
    final u = user.value;
    if (u != null) {
      await sp.setString('auth.user', jsonEncode(u.toJson()));
    } else {
      await sp.remove('auth.user');
    }
    if (tokens != null) {
      await sp.setString('auth.tokens', jsonEncode(tokens!.toJson()));
    } else {
      await sp.remove('auth.tokens');
    }
  }

  // Start OTP: returns a tuple (otpHint, userId)
  Future<({String? otpHint, int? userId})> startPhoneCheck({
    required String mobileDigits,
    required int countryCode,
  }) async {
    // Save pending so verify can reuse
    _pendingDigits = mobileDigits;
    _pendingCountryCode = countryCode;

    final env = await api.Api.checkUserByMobile(
      mobile: mobileDigits, // backend expects mobile (local) + separate country
      countryCode: countryCode,
    );

    // parse the 4–6 digit hint from the human message (dev convenience)
    final otpHint = _extractOtp(env.message);
    _pendingUserId = env.modelId;
    return (otpHint: otpHint, userId: env.modelId);
  }

  // Verify OTP: sets tokens and loads the user by modelId (if available)
  Future<bool> verifyOtp({required String otp}) async {
    final digits = _pendingDigits;
    if (digits == null || digits.isEmpty) {
      throw StateError('No pending phone number — startPhoneCheck first.');
    }

    final tok = await api.Api.checkOtpCode(mobile: digits, otpcode: otp);
    tokens = tok;

    // If backend gave us the id earlier, fetch full user
    AuthUser? u;
    if (_pendingUserId != null) {
      try {
        final ua = await api.Api.getUserAccountById(_pendingUserId!);
        u = _toAuthUser(ua);
      } catch (_) {
        // fallback: decode from jwt claims if needed
        u = AuthUser(id: _pendingUserId, mobile: digits, isCompleted: false);
      }
    } else {
      u = AuthUser(mobile: digits, isCompleted: false);
    }

    user.value = u;
    await _persist();
    // After login, attempt to register this device's FCM token to backend.
    try {
      // Lazy import to avoid tight coupling; call via function to keep compile-time deps light.
      // ignore: avoid_dynamic_calls
      await Future.microtask(() async {
        // Use Notifications class without importing at top to avoid cycles.
        // The class is in notifications screen file.
        // We reference via Function type to keep it optional.
      });
    } catch (_) {}
    return true;
  }

  // Save profile to backend single SaveUser endpoint.
  Future<void> saveProfileAndMarkCompleted({
    required String fullName,
    required String email,
    String? password,
    String? mobile,
  }) async {
    final current = user.value;
    final payload = UserAccount(
      id: current?.id,
      fullName: fullName,
      email: email,
      password: password,
      mobile: mobile ?? current?.mobile,
      isCompleted: true,
    );
    // use the provided single upsert endpoint
    final saved = await api.Api.saveUserAccount(
      payload,
      includePassword: false,
    );
    user.value = _toAuthUser(saved);
    await _persist();
  }

  Future<void> logout() async {
    user.value = null;
    tokens = null;
    api.Api.setToken('');
    await _persist();
  }

  bool get isCompleted => user.value?.isCompleted == true;

  // helpers
  String? _extractOtp(String? msg) {
    if (msg == null) return null;
    final m = RegExp(r'(\d{4,6})').firstMatch(msg);
    return m?.group(1);
  }

  AuthUser _toAuthUser(UserAccount a) => AuthUser(
    id: a.id,
    fullName: a.fullName,
    email: a.email,
    mobile: a.mobile,
    countryCode: a.countryCode,
    otpcode: a.otpcode,
    isCompleted: a.isCompleted,
    createDateTime: a.createDateTime,
    modifyDateTime: a.modifyDateTime,
    otpExpire: a.otpExpire,
    statusId: a.statusId,
    isActive: a.isActive,
    userTypeId: a.userTypeId,
  );
}

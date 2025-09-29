import 'dart:developer' as dev show log;

import 'package:heavy_new/core/auth/auth_store.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:heavy_new/core/api/api_handler.dart';
import 'package:heavy_new/core/models/admin/notifications_model.dart';

class CrudService {
  /// Ensure the current user's FCM [token] is present in the backend.
  /// - If it already exists for this user, do nothing (and return the existing record).
  /// - If not, create it.
  ///
  /// Returns the saved/existing NotificationsModel when possible.
  static Future<NotificationsModel?> saveUserToken(String token) async {
    final userId = AuthStore.instance.user.value?.id;

    if (userId == null || userId == 0) {
      dev.log('saveUserToken: no signed-in user; skipping');
      return null;
    }
    final trimmedToken = token.trim();
    if (trimmedToken.isEmpty) {
      dev.log('saveUserToken: empty token; skipping');
      return null;
    }

    try {
      // 1) Fetch all tokens for this user
      final existing = await Api.getNotfTokenById(userId);

      // 2) If this exact token already exists, keep it (no duplicate insert)
      final found = existing.firstWhere(
        (t) => (t.token ?? '').trim() == trimmedToken,
        orElse: () => NotificationsModel(userId: null, token: null),
      );

      if ((found.token ?? '').isNotEmpty) {
        dev.log('User token already exists; using existing: $trimmedToken');
        return found;
      }

      // 3) Otherwise, save as new with platform id (1=iOS, 2=Android, 3=Web)
      final platformId = switch (defaultTargetPlatform) {
        TargetPlatform.iOS => 1,
        TargetPlatform.android => 2,
        _ => 3,
      };
      final saved = await Api.addNotfToken(
        NotificationsModel(
          userId: userId,
          token: trimmedToken,
          platformId: platformId,
        ),
      );
      dev.log('User token saved successfully: $trimmedToken');
      return saved;
    } catch (e) {
      dev.log('Error saving user token: $e');
      return null;
    }
  }

  /// Send a notification via backend FCM endpoint.
  static Future<UserMessage?> sendNotifMessage(
    int userMessageId,
    String token,
    int userId,
    String titleEnglish,
    String titleArabic,
    String messageArabic,
    String messageEnglish,
    int screenId,
    int senderId,
    String screenPath,
    int modelId,
    int platformId,
  ) async {
    final currentUserId = AuthStore.instance.user.value?.id ?? 0;

    try {
      final msg = UserMessage(
        userMessageId: userMessageId, // you passed 0 earlier; keep param
        userId: currentUserId, // sender/current user id
        token: token,
        titleArabic: titleArabic,
        titleEnglish: titleEnglish, // ✅ fixed (was titleArabic)
        messageArabic: messageArabic,
        messageEnglish: messageEnglish,
        modelId: modelId,
        platformId: platformId,
        screenId: screenId,
        screenPath: screenPath,
        senderId: senderId,
      );

      final sent = await Api.sendNotif(msg);
      dev.log(
        'Notification sent -> token:$token user:$userId "$titleEnglish" "$messageEnglish"',
      );
      return sent;
    } catch (e) {
      dev.log('Error Sending Notification: $e');
      return null;
    }
  }
}

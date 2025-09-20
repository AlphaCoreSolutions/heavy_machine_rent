import 'dart:developer' as dev show log;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:heavy_new/core/api/api_handler.dart';
import 'package:heavy_new/core/models/admin/notifications_model.dart';

class CrudService {
  static Future saveUserToken(String token) async {
    User? user = FirebaseAuth.instance.currentUser;

    try {
      await Api.addNotfToken(
        NotificationsModel(
          userId: int.tryParse(user?.uid ?? '0'),
          token: token,
        ),
      );
      dev.log('User token saved successfully: $token');
    } catch (e) {
      print('Error saving user token: $e');
    }
  }

  static Future sendNotifMessage(
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
    User? user = FirebaseAuth.instance.currentUser;

    try {
      await Api.sendNotif(
        UserMessage(
          userMessageId: 0,
          userId: int.tryParse(user?.uid ?? '0'),
          token: token,
          titleArabic: titleArabic,
          titleEnglish: titleArabic,
          messageArabic: messageArabic,
          messageEnglish: messageEnglish,
          modelId: modelId,
          platformId: platformId,
          screenId: screenId,
          screenPath: screenPath,
          senderId: senderId,
        ),
      );
      dev.log(
        'Notification sent: $token, $userId, $titleEnglish $messageEnglish',
      );
    } catch (e) {
      print('Error Sending Notification: $e');
    }
  }
}

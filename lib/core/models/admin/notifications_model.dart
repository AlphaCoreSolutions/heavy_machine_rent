class NotificationsModel {
  int? userId;
  String? token;
  int? platformId;

  NotificationsModel({this.userId, this.token, this.platformId});

  factory NotificationsModel.fromJson(Map<String, dynamic> json) {
    return NotificationsModel(
      userId: json['applicationUserId'] as int?,
      token: json['tokenUser'] as String?,
      platformId: json['platformId'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'applicationUserId': userId,
      'tokenUser': token,
      'platformId': platformId,
    };
  }

  static empty() {}
}

class UserMessage {
  int? userMessageId;
  int? userId;
  String? titleArabic;
  String? titleEnglish;
  String? messageArabic;
  String? messageEnglish;
  String? screenArabic;
  String? screenEnglish;
  String? imagePath;
  int? senderId;
  int? screenId;
  String? screenPath;
  int? platformId;
  int? modelId;
  String? token;
  int? mainMessageId;

  UserMessage({
    this.userMessageId,
    this.userId,
    this.titleArabic,
    this.titleEnglish,
    this.messageArabic,
    this.messageEnglish,
    this.screenArabic,
    this.screenEnglish,
    this.senderId,
    this.screenId,
    this.screenPath,
    this.platformId,
    this.modelId,
    this.token,
    this.mainMessageId,
    this.imagePath,
  });

  factory UserMessage.fromJson(Map<String, dynamic> json) {
    return UserMessage(
      userMessageId: json['userMessageId'] as int?,
      userId: json['applicationUserId'] as int?,
      titleArabic: json['titleArabic'] as String?,
      titleEnglish: json['titleEnglish'] as String?,
      messageArabic: json['messageArabic'] as String?,
      messageEnglish: json['titleEnglish'] as String?,
      screenArabic: json['screenArabic'] as String?,
      screenEnglish: json['screenEnglish'] as String?,
      screenId: json['screenId'] as int?,
      senderId: json['senderId'] as int?,
      screenPath: json['screenPath'] as String?,
      modelId: json['modelId'] as int?,
      platformId: json['platformId'] as int?,
      token: json['tokenUser'] as String?,
      imagePath: json['imagePath'] as String?,
      mainMessageId: json['mainMessageId'] as int?,

      /*
       'userMessageId': 963,
        'applicationUserId': 9,
        'titleArabic': 'Test',
        'titleEnglish': 'Test',
        'messageArabic': 'Test Message',
        'messageEnglish': 'Test Message',
          'senderId': 0,
        'screenId': 1,
        'screenArabic': 'screen',
        'screenEnglish': 'screen',
        'screenPath': '/us/contct/3',
        'className': 'screen',
        'modelId': 3,
        'imagePath': 'string',
        'platformId': 1,
        'tokenUser': 'epQUpJu7vucguqV8R4dCex:APA91bG2kZqzzpZm7gL73VRDb6vB4kK0xf_wg8t3-mOs67FrCEhnqywrxPLLyUm9fUX_ZffHZk7xxygfLft1w7V4i7AAFNmlv45ZHP97EDjkEj0bMP4NsiE',
        'mainMessageId': 0
      */
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userMessageId': 0,
      'applicationUserId': userId,
      'titleArabic': titleArabic,
      'titleEnglish': titleEnglish,
      'messageArabic': messageArabic,
      'messageEnglish': messageEnglish,
      'screenArabic': screenArabic,
      'screenEnglish': screenEnglish,
      'senderId': senderId,
      'screenId': screenId,
      'screenPath': screenPath,
      'className': "",
      'modelId': modelId,
      'platformId': platformId,
      'tokenUser': token,
      'imagePath': imagePath,
      'mainMessageId': 0,
    };
  }
}

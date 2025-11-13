import 'package:Ajjara/core/utils/model_utils.dart';

class AuthUser {
  final int? id;
  final String? fullName;
  final String? email;
  final String? password;
  final String? mobile;
  final int? countryCode;
  final String? otpcode;
  final bool? isCompleted;
  final DateTime? createDateTime;
  final DateTime? modifyDateTime;
  final DateTime? otpExpire;
  final int? statusId;
  final bool? isActive;
  final int? userTypeId;

  AuthUser({
    this.id,
    this.fullName,
    this.email,
    this.password,
    this.mobile,
    this.countryCode,
    this.otpcode,
    this.isCompleted,
    this.createDateTime,
    this.modifyDateTime,
    this.otpExpire,
    this.statusId,
    this.isActive,
    this.userTypeId,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
    id: json['id'],
    fullName: json['fullName'],
    email: json['email'],
    password: json['password'],
    mobile: json['mobile'],
    countryCode: json['countryCode'],
    otpcode: json['otpcode'],
    isCompleted: json['isCompleted'],
    createDateTime: dt(json['createDateTime']),
    modifyDateTime: dt(json['modifyDateTime']),
    otpExpire: dt(json['otpExpire']),
    statusId: json['statusId'],
    isActive: json['isActive'],
    userTypeId: json['userTypeId'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'fullName': fullName,
    'email': email,
    'password': password,
    'mobile': mobile,
    'countryCode': countryCode,
    'otpcode': otpcode,
    'isCompleted': isCompleted,
    'createDateTime': createDateTime?.toIso8601String(),
    'modifyDateTime': modifyDateTime?.toIso8601String(),
    'otpExpire': otpExpire?.toIso8601String(),
    'statusId': statusId,
    'isActive': isActive,
    'userTypeId': userTypeId,
  };
}

class LoginRequest {
  final String email;
  final String password;
  LoginRequest({required this.email, required this.password});
  Map<String, dynamic> toJson() => {'email': email, 'password': password};
}

class RegisterRequest {
  final String email;
  final String password;
  final String fullName;
  final String confirmPassword;
  RegisterRequest({
    required this.email,
    required this.password,
    required this.fullName,
    required this.confirmPassword,
  });
  Map<String, dynamic> toJson() => {
    'email': email,
    'password': password,
    'fullName': fullName,
    'confirmPassword': confirmPassword,
  };
}

class RefreshTokenRequest {
  final String token;
  RefreshTokenRequest(this.token);
  Map<String, dynamic> toJson() => {'token': token};
}

class AuthTokens {
  final String token;
  final String? refreshToken;
  final DateTime? expiresAt;
  AuthTokens({required this.token, this.refreshToken, this.expiresAt});
  factory AuthTokens.fromJson(Map<String, dynamic> json) => AuthTokens(
    token: json['token'] ?? json['accessToken'] ?? json['jwt'],
    refreshToken: json['refreshToken'],
    expiresAt: dt(json['expiresAt']) ?? dt(json['expiry']) ?? dt(json['exp']),
  );
  Map<String, dynamic> toJson() => {
    'token': token,
    'refreshToken': refreshToken,
    'expiresAt': expiresAt?.toIso8601String(),
  };
}

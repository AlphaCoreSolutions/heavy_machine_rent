import 'package:ajjara/core/utils/model_utils.dart';

class UserAccount {
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

  UserAccount({
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
  factory UserAccount.fromJson(Map<String, dynamic> json) => UserAccount(
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

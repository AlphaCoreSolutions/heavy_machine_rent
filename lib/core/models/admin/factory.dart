import 'package:Ajjara/core/utils/model_utils.dart';

class FactoryModel {
  final int? factoryId;
  final String? nameArabic;
  final String? nameEnglish;
  final String? logoPath;
  final bool? isActive;
  final DateTime? createDateTime;
  final DateTime? modifyDateTime;
  FactoryModel({
    this.factoryId,
    this.nameArabic,
    this.nameEnglish,
    this.logoPath,
    this.isActive,
    this.createDateTime,
    this.modifyDateTime,
  });
  factory FactoryModel.fromJson(Map<String, dynamic> json) => FactoryModel(
    factoryId: json['factoryId'],
    nameArabic: json['nameArabic'],
    nameEnglish: json['nameEnglish'],
    logoPath: json['logoPath'],
    isActive: json['isActive'],
    createDateTime: dt(json['createDateTime']),
    modifyDateTime: dt(json['modifyDateTime']),
  );
  Map<String, dynamic> toJson() => {
    'factoryId': factoryId,
    'nameArabic': nameArabic,
    'nameEnglish': nameEnglish,
    'logoPath': logoPath,
    'isActive': isActive,
    'createDateTime': createDateTime?.toIso8601String(),
    'modifyDateTime': modifyDateTime?.toIso8601String(),
  };
}

import 'package:heavy_new/core/utils/model_utils.dart';

class TermCondition {
  final int? termConditionId;
  final String? nameArabic;
  final String? descArabic;
  final String? nameEnglish;
  final String? descEnglish;
  final int? orderBy;
  final bool? isActive;
  final DateTime? createDateTime;
  final DateTime? modifyDateTime;
  TermCondition({
    this.termConditionId,
    this.nameArabic,
    this.descArabic,
    this.nameEnglish,
    this.descEnglish,
    this.orderBy,
    this.isActive,
    this.createDateTime,
    this.modifyDateTime,
  });
  factory TermCondition.fromJson(Map<String, dynamic> json) => TermCondition(
    termConditionId: json['termConditionId'],
    nameArabic: json['nameArabic'],
    descArabic: json['descArabic'],
    nameEnglish: json['nameEnglish'],
    descEnglish: json['descEnglish'],
    orderBy: json['orderBy'],
    isActive: json['isActive'],
    createDateTime: dt(json['createDateTime']),
    modifyDateTime: dt(json['modifyDateTime']),
  );
  Map<String, dynamic> toJson() => {
    'termConditionId': termConditionId,
    'nameArabic': nameArabic,
    'descArabic': descArabic,
    'nameEnglish': nameEnglish,
    'descEnglish': descEnglish,
    'orderBy': orderBy,
    'isActive': isActive,
    'createDateTime': createDateTime?.toIso8601String(),
    'modifyDateTime': modifyDateTime?.toIso8601String(),
  };
}

import 'package:ajjara/core/utils/model_utils.dart';

class EquipmentListModel {
  final int? equipmentListId;
  final String? nameEnglish;
  final String? nameArabic;
  final String? primaryUseEnglish;
  final String? primaryUseArabic;
  final String? imagePath;
  final bool? isActive;
  final DateTime? createDateTime;
  final DateTime? modifyDateTime;
  EquipmentListModel({
    this.equipmentListId,
    this.nameEnglish,
    this.nameArabic,
    this.primaryUseEnglish,
    this.primaryUseArabic,
    this.imagePath,
    this.isActive,
    this.createDateTime,
    this.modifyDateTime,
  });
  factory EquipmentListModel.fromJson(Map<String, dynamic> json) =>
      EquipmentListModel(
        equipmentListId: json['equipmentListId'],
        nameEnglish: json['nameEnglish'],
        nameArabic: json['nameArabic'],
        primaryUseEnglish: json['primaryUseEnglish'],
        primaryUseArabic: json['primaryUseArabic'],
        imagePath: json['imagePath'],
        isActive: json['isActive'],
        createDateTime: dt(json['createDateTime']),
        modifyDateTime: dt(json['modifyDateTime']),
      );
  Map<String, dynamic> toJson() => {
    'equipmentListId': equipmentListId,
    'nameEnglish': nameEnglish,
    'nameArabic': nameArabic,
    'primaryUseEnglish': primaryUseEnglish,
    'primaryUseArabic': primaryUseArabic,
    'imagePath': imagePath,
    'isActive': isActive,
    'createDateTime': createDateTime?.toIso8601String(),
    'modifyDateTime': modifyDateTime?.toIso8601String(),
  };
}

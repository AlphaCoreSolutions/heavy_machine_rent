import 'package:heavy_new/core/utils/model_utils.dart';

class Brand {
  final int? id;
  final String? nameArabic;
  final String? nameEnglish;
  final bool? isActive;
  final DateTime? createDateTime;
  final DateTime? modifyDateTime;

  Brand({
    this.id,
    this.nameArabic,
    this.nameEnglish,
    this.isActive,
    this.createDateTime,
    this.modifyDateTime,
  });

  factory Brand.fromJson(Map<String, dynamic> json) => Brand(
    id: json['id'],
    nameArabic: json['nameArabic'],
    nameEnglish: json['nameEnglish'],
    isActive: json['isActive'],
    createDateTime: dt(json['createDateTime']),
    modifyDateTime: dt(json['modifyDateTime']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'nameArabic': nameArabic,
    'nameEnglish': nameEnglish,
    'isActive': isActive,
    'createDateTime': createDateTime?.toIso8601String(),
    'modifyDateTime': modifyDateTime?.toIso8601String(),
  };
}

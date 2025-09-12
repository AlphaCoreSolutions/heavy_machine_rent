import 'package:heavy_new/core/utils/model_utils.dart';

class Nationality {
  final int? nationalityId;
  final String? nationalityAlphaCode2;
  final String? nationalityAlphaCode3;
  final String? nationalityNumericCode;
  final String? nationalityNameArabic;
  final String? nationalityNameEnglish;
  final String? regionName;
  final String? continentName;
  final bool? isActive;
  final DateTime? createDateTime;
  final DateTime? modifyDateTime;
  final List<dynamic>? cities; // kept dynamic due to schema variability

  Nationality({
    this.nationalityId,
    this.nationalityAlphaCode2,
    this.nationalityAlphaCode3,
    this.nationalityNumericCode,
    this.nationalityNameArabic,
    this.nationalityNameEnglish,
    this.regionName,
    this.continentName,
    this.isActive,
    this.createDateTime,
    this.modifyDateTime,
    this.cities,
  });
  factory Nationality.fromJson(Map<String, dynamic> json) => Nationality(
    nationalityId: json['nationalityId'],
    nationalityAlphaCode2: json['nationalityAlphaCode2'],
    nationalityAlphaCode3: json['nationalityAlphaCode3'],
    nationalityNumericCode: json['nationalityNumericCode'],
    nationalityNameArabic: json['nationalityNameArabic'],
    nationalityNameEnglish: json['nationalityNameEnglish'],
    regionName: json['regionName'],
    continentName: json['continentName'],
    isActive: json['isActive'],
    createDateTime: dt(json['createDateTime']),
    modifyDateTime: dt(json['modifyDateTime']),
    cities: json['cities'] is List ? List<dynamic>.from(json['cities']) : null,
  );
  Map<String, dynamic> toJson() => {
    'nationalityId': nationalityId,
    'nationalityAlphaCode2': nationalityAlphaCode2,
    'nationalityAlphaCode3': nationalityAlphaCode3,
    'nationalityNumericCode': nationalityNumericCode,
    'nationalityNameArabic': nationalityNameArabic,
    'nationalityNameEnglish': nationalityNameEnglish,
    'regionName': regionName,
    'continentName': continentName,
    'isActive': isActive,
    'createDateTime': createDateTime?.toIso8601String(),
    'modifyDateTime': modifyDateTime?.toIso8601String(),
    'cities': cities,
  };
}

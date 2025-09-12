// city.dart
import 'package:heavy_new/core/utils/model_utils.dart';

class CountryRef {
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

  CountryRef({
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
  });

  factory CountryRef.fromJson(Map<String, dynamic> json) => CountryRef(
    nationalityId: ix(gv(json, ['nationalityId', 'NationalityId'])),
    nationalityAlphaCode2: sx(
      gv(json, ['nationalityAlphaCode2', 'NationalityAlphaCode2']),
    ),
    nationalityAlphaCode3: sx(
      gv(json, ['nationalityAlphaCode3', 'NationalityAlphaCode3']),
    ),
    nationalityNumericCode: sx(
      gv(json, ['nationalityNumericCode', 'NationalityNumericCode']),
    ),
    nationalityNameArabic: sx(
      gv(json, ['nationalityNameArabic', 'NationalityNameArabic']),
    ),
    nationalityNameEnglish: sx(
      gv(json, ['nationalityNameEnglish', 'NationalityNameEnglish']),
    ),
    regionName: sx(gv(json, ['regionName', 'RegionName'])),
    continentName: sx(gv(json, ['continentName', 'ContinentName'])),
    isActive: bx(gv(json, ['isActive', 'IsActive'])),
    createDateTime: dt(gv(json, ['createDateTime', 'CreateDateTime'])),
    modifyDateTime: dt(gv(json, ['modifyDateTime', 'ModifyDateTime'])),
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
  };
}

class City {
  final int? cityId;
  final String? nameEnglish;
  final String? nameArabic;
  final String? latitude;
  final String? longitude;
  final int? nationalityId;
  final CountryRef? country;

  City({
    this.cityId,
    this.nameEnglish,
    this.nameArabic,
    this.latitude,
    this.longitude,
    this.nationalityId,
    this.country,
  });

  factory City.fromJson(Map<String, dynamic> json) => City(
    cityId: ix(gv(json, ['cityId', 'CityId', 'id', 'Id'])),
    nameEnglish: sx(gv(json, ['nameEnglish', 'NameEnglish'])),
    nameArabic: sx(gv(json, ['nameArabic', 'NameArabic'])),
    latitude: sx(gv(json, ['latitude', 'Latitude'])),
    longitude: sx(gv(json, ['longitude', 'Longitude'])),
    nationalityId: ix(gv(json, ['nationalityId', 'NationalityId'])),
    country: (gv(json, ['country', 'Country']) is Map)
        ? CountryRef.fromJson(
            Map<String, dynamic>.from(gv(json, ['country', 'Country'])),
          )
        : null,
  );

  Map<String, dynamic> toJson() => {
    'cityId': cityId,
    'nameEnglish': nameEnglish,
    'nameArabic': nameArabic,
    'latitude': latitude,
    'longitude': longitude,
    'nationalityId': nationalityId,
    'country': country?.toJson(),
  };
}

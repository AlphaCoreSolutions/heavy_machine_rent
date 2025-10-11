// organization_summary.dart
import 'package:heavy_new/core/models/equipment/equipment.dart';
import 'package:heavy_new/core/models/organization/organization_user.dart';
import 'package:heavy_new/core/models/organization/organization_file.dart';
import 'package:heavy_new/core/models/user/city.dart';
import 'package:heavy_new/core/utils/model_utils.dart'; // City

class OrganizationSummary {
  final int? organizationId;
  final String? organizationCode;
  final String? nameArabic;
  final String? nameEnglish;
  final String? briefArabic;
  final String? briefEnglish;
  final String? crNumber;
  final String? vatNumber;
  final String? mainMobile;
  final String? secondMobile;
  final String? mainEmail;
  final String? secondEmail;
  final String? iban;
  final String? bankName;
  final int? statusId;
  final int? countryId;
  final int? cityId;
  final String? fullAddress;
  final String? tradeNameArabic;
  final String? tradeNameEnglish;
  final String? logoPath;
  final bool? isActive;
  final int? typeId;
  final DateTime? createDateTime;
  final DateTime? modifyDateTime;

  final DomainDetailRef? status;
  final dynamic country;
  final City? city;

  final List<OrganizationUser> organizationUsers;
  final List<OrganizationFileModel> organizationFiles;

  OrganizationSummary({
    this.organizationId,
    this.organizationCode,
    this.nameArabic,
    this.nameEnglish,
    this.briefArabic,
    this.briefEnglish,
    this.crNumber,
    this.vatNumber,
    this.mainMobile,
    this.secondMobile,
    this.mainEmail,
    this.secondEmail,
    this.iban,
    this.bankName,
    this.statusId,
    this.countryId,
    this.cityId,
    this.fullAddress,
    this.tradeNameArabic,
    this.tradeNameEnglish,
    this.logoPath,
    this.isActive,
    this.typeId,
    this.createDateTime,
    this.modifyDateTime,
    this.status,
    this.country,
    this.city,
    this.organizationUsers = const [],
    this.organizationFiles = const [],
  });

  factory OrganizationSummary.fromJson(Map<String, dynamic> json) {
    final root = (json['data'] is Map)
        ? Map<String, dynamic>.from(json['data'])
        : (json['result'] is Map)
        ? Map<String, dynamic>.from(json['result'])
        : (json['payload'] is Map)
        ? Map<String, dynamic>.from(json['payload'])
        : json;

    dynamic v(List<String> k) => gv(root, k);

    return OrganizationSummary(
      organizationId: ix(v(['organizationId', 'OrganizationId'])),
      organizationCode: sx(v(['organizationCode', 'OrganizationCode'])),
      nameArabic: sx(v(['nameArabic', 'NameArabic'])),
      nameEnglish: sx(v(['nameEnglish', 'NameEnglish'])),
      briefArabic: sx(v(['briefArabic', 'BriefArabic'])),
      briefEnglish: sx(v(['briefEnglish', 'BriefEnglish'])),
      crNumber: sx(v(['crNumber', 'CRNumber'])),
      vatNumber: sx(v(['vatNumber', 'VATNumber'])),
      mainMobile: sx(v(['mainMobile', 'MainMobile'])),
      secondMobile: sx(v(['secondMobile', 'SecondMobile'])),
      mainEmail: sx(v(['mainEmail', 'MainEmail'])),
      secondEmail: sx(v(['secondEmail', 'SecondEmail'])),
      iban: sx(v(['iban', 'IBAN'])),
      bankName: sx(v(['bankName', 'BankName'])),
      statusId: ix(v(['statusId', 'StatusId'])),
      countryId: ix(v(['countryId', 'CountryId'])),
      cityId: ix(v(['cityId', 'CityId'])),
      fullAddress: sx(v(['fullAddress', 'FullAddress'])),
      tradeNameArabic: sx(v(['tradeNameArabic', 'TradeNameArabic'])),
      tradeNameEnglish: sx(v(['tradeNameEnglish', 'TradeNameEnglish'])),
      logoPath: sx(v(['logoPath', 'LogoPath'])),
      isActive: bx(v(['isActive', 'IsActive'])),
      typeId: ix(v(['typeId', 'TypeId'])),
      createDateTime: dt(v(['createDateTime', 'CreateDateTime'])),
      modifyDateTime: dt(v(['modifyDateTime', 'ModifyDateTime'])),

      status: (gv(root, ['status', 'Status']) is Map)
          ? DomainDetailRef.fromJson(
              Map<String, dynamic>.from(gv(root, ['status', 'Status'])),
            )
          : null,
      country: gv(root, ['country', 'Country']),
      city: (gv(root, ['city', 'City']) is Map)
          ? City.fromJson(Map<String, dynamic>.from(gv(root, ['city', 'City'])))
          : null,

      organizationUsers:
          (gv(root, ['organizationUsers', 'OrganizationUsers']) is List)
          ? List<Map<String, dynamic>>.from(
              gv(root, ['organizationUsers', 'OrganizationUsers']),
            ).map((e) => OrganizationUser.fromJson(e)).toList()
          : const [],
      organizationFiles:
          (gv(root, ['organizationFiles', 'OrganizationFiles']) is List)
          ? List<Map<String, dynamic>>.from(
              gv(root, ['organizationFiles', 'OrganizationFiles']),
            ).map((e) => OrganizationFileModel.fromJson(e)).toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() => {
    'organizationId': organizationId,
    'organizationCode': organizationCode,
    'nameArabic': nameArabic,
    'nameEnglish': nameEnglish,
    'briefArabic': briefArabic,
    'briefEnglish': briefEnglish,
    'crNumber': crNumber,
    'vatNumber': vatNumber,
    'mainMobile': mainMobile,
    'secondMobile': secondMobile,
    'mainEmail': mainEmail,
    'secondEmail': secondEmail,
    'iban': iban,
    'bankName': bankName,
    'statusId': statusId,
    'countryId': countryId,
    'cityId': cityId,
    'fullAddress': fullAddress,
    'tradeNameArabic': tradeNameArabic,
    'tradeNameEnglish': tradeNameEnglish,
    'logoPath': logoPath,
    'isActive': isActive,
    'typeId': typeId,
    'createDateTime': createDateTime?.toIso8601String(),
    'modifyDateTime': modifyDateTime?.toIso8601String(),
  };

  factory OrganizationSummary.fromJsonActive(Map<String, dynamic> json) =>
      OrganizationSummary(
        organizationId: _toInt(json['organizationId'] ?? json['id']),
        isActive: _toBool(json['isActive']),
      );

  Map<String, dynamic> toJsonActive() => {
    'organizationId': organizationId,
    'isActive': isActive,
  };
}

int? _toInt(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString());
}

bool _toBool(dynamic v) {
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) {
    final s = v.toLowerCase();
    return s == 'true' || s == '1';
  }
  return false;
}

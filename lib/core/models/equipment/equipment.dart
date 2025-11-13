import 'package:ajjara/core/models/organization/organization_summary.dart';
import 'package:ajjara/core/utils/model_utils.dart';

class DomainDetailRef {
  final int? domainDetailId;
  final String? detailNameArabic;
  final String? detailNameEnglish;
  DomainDetailRef({
    this.domainDetailId,
    this.detailNameArabic,
    this.detailNameEnglish,
  });
  factory DomainDetailRef.fromJson(Map<String, dynamic> json) =>
      DomainDetailRef(
        domainDetailId: json['domainDetailId'],
        detailNameArabic: json['detailNameArabic'],
        detailNameEnglish: json['detailNameEnglish'],
      );

  get domain => null;
  Map<String, dynamic> toJson() => {
    'domainDetailId': domainDetailId,
    'detailNameArabic': detailNameArabic,
    'detailNameEnglish': detailNameEnglish,
  };
}

class EquipmentListSummary {
  final int? equipmentListId;
  final String? nameEnglish;
  final String? nameArabic;
  final String? primaryUseEnglish;
  final String? primaryUseArabic;
  final String? imagePath;
  final bool? isActive;
  EquipmentListSummary({
    this.equipmentListId,
    this.nameEnglish,
    this.nameArabic,
    this.primaryUseEnglish,
    this.primaryUseArabic,
    this.imagePath,
    this.isActive,
  });
  factory EquipmentListSummary.fromJson(Map<String, dynamic> json) =>
      EquipmentListSummary(
        equipmentListId: json['equipmentListId'],
        nameEnglish: json['nameEnglish'],
        nameArabic: json['nameArabic'],
        primaryUseEnglish: json['primaryUseEnglish'],
        primaryUseArabic: json['primaryUseArabic'],
        imagePath: json['imagePath'],
        isActive: json['isActive'],
      );
  Map<String, dynamic> toJson() => {
    'equipmentListId': equipmentListId,
    'nameEnglish': nameEnglish,
    'nameArabic': nameArabic,
    'primaryUseEnglish': primaryUseEnglish,
    'primaryUseArabic': primaryUseArabic,
    'imagePath': imagePath,
    'isActive': isActive,
  };
}

class EquipmentDriver {
  final int? equipmentDriverId;
  final int? equipmentId;
  final String? driverNameArabic;
  final String? driverNameEnglish;
  final int? driverNationalityId;
  final bool? isActive;
  final DateTime? createDateTime;
  final DateTime? modifyDateTime;
  final List<EquipmentDriverFile>? equipmentDriverFiles;

  EquipmentDriver({
    this.equipmentDriverId,
    this.equipmentId,
    this.driverNameArabic,
    this.driverNameEnglish,
    this.driverNationalityId,
    this.isActive,
    this.createDateTime,
    this.modifyDateTime,
    this.equipmentDriverFiles,
  });

  factory EquipmentDriver.fromJson(Map<String, dynamic> json) =>
      EquipmentDriver(
        equipmentDriverId: json['equipmentDriverId'],
        equipmentId: json['equipmentId'],
        driverNameArabic: json['driverNameArabic'],
        driverNameEnglish: json['driverNameEnglish'],
        driverNationalityId: json['driverNationalityId'],
        isActive: json['isActive'],
        createDateTime: dt(json['createDateTime']),
        modifyDateTime: dt(json['modifyDateTime']),
        equipmentDriverFiles: (json['equipmentDriverFiles'] is List)
            ? (json['equipmentDriverFiles'] as List)
                  .map(
                    (e) => EquipmentDriverFile.fromJson(
                      Map<String, dynamic>.from(e),
                    ),
                  )
                  .toList()
            : null,
      );

  Map<String, dynamic> toJson() => {
    'equipmentDriverId': equipmentDriverId,
    'equipmentId': equipmentId,
    'driverNameArabic': driverNameArabic,
    'driverNameEnglish': driverNameEnglish,
    'driverNationalityId': driverNationalityId,
    'isActive': isActive,
    'createDateTime': createDateTime?.toIso8601String(),
    'modifyDateTime': modifyDateTime?.toIso8601String(),
    'equipmentDriverFiles': equipmentDriverFiles
        ?.map((e) => e.toJson())
        .toList(),
  };
}

class EquipmentTerm {
  final int? equipmentTermId;
  final int? equipmentId;
  final String? descArabic;
  final String? descEnglish;
  final int? orderBy;
  final bool? isActive;
  final DateTime? createDateTime;
  final DateTime? modifyDateTime;
  // 'equipment' field omitted to avoid deep cycles
  EquipmentTerm({
    this.equipmentTermId,
    this.equipmentId,
    this.descArabic,
    this.descEnglish,
    this.orderBy,
    this.isActive,
    this.createDateTime,
    this.modifyDateTime,
  });
  factory EquipmentTerm.fromJson(Map<String, dynamic> json) => EquipmentTerm(
    equipmentTermId: json['equipmentTermId'],
    equipmentId: json['equipmentId'],
    descArabic: json['descArabic'],
    descEnglish: json['descEnglish'],
    orderBy: json['orderBy'],
    isActive: json['isActive'],
    createDateTime: dt(json['createDateTime']),
    modifyDateTime: dt(json['modifyDateTime']),
  );
  Map<String, dynamic> toJson() => {
    'equipmentTermId': equipmentTermId,
    'equipmentId': equipmentId,
    'descArabic': descArabic,
    'descEnglish': descEnglish,
    'orderBy': orderBy,
    'isActive': isActive,
    'createDateTime': createDateTime?.toIso8601String(),
    'modifyDateTime': modifyDateTime?.toIso8601String(),
  };
}

class EquipmentImage {
  final int? equipmentImageId;
  final int? equipmentId;
  final String? equipmentPath;
  final bool? isActive;
  final DateTime? createDateTime;
  final DateTime? modifyDateTime;

  EquipmentImage({
    this.equipmentImageId,
    this.equipmentId,
    this.equipmentPath,
    this.isActive,
    this.createDateTime,
    this.modifyDateTime,
  });
  factory EquipmentImage.fromJson(Map<String, dynamic> json) => EquipmentImage(
    equipmentImageId: json['equipmentImageId'],
    equipmentId: json['equipmentId'],
    equipmentPath: json['equipmentPath'],
    isActive: json['isActive'],
    createDateTime: dt(json['createDateTime']),
    modifyDateTime: dt(json['modifyDateTime']),
  );
  Map<String, dynamic> toJson() => {
    'equipmentImageId': equipmentImageId,
    'equipmentId': equipmentId,
    'equipmentPath': equipmentPath,
    'isActive': isActive,
    'createDateTime': createDateTime?.toIso8601String(),
    'modifyDateTime': modifyDateTime?.toIso8601String(),
  };
}

class EquipmentCertificate {
  final int? equipmentCertificateId;
  final int? equipmentId;
  final int? typeId;
  final String? nameArabic;
  final String? nameEnglish;
  final String? issueDate; // yyyy-MM-dd
  final String? expireDate; // yyyy-MM-dd
  final bool? isExpire;
  final bool? isActive;
  final DateTime? createDateTime;
  final DateTime? modifyDateTime;
  final String? documentPath;
  final String? documentType;
  final bool? isImage;

  EquipmentCertificate({
    this.equipmentCertificateId,
    this.equipmentId,
    this.typeId,
    this.nameArabic,
    this.nameEnglish,
    this.issueDate,
    this.expireDate,
    this.isExpire,
    this.isActive,
    this.createDateTime,
    this.modifyDateTime,
    this.documentPath,
    this.documentType,
    this.isImage,
  });

  factory EquipmentCertificate.fromJson(Map<String, dynamic> json) =>
      EquipmentCertificate(
        equipmentCertificateId: json['equipmentCertificateId'],
        equipmentId: json['equipmentId'],
        typeId: json['typeId'],
        nameArabic: json['nameArabic'],
        nameEnglish: json['nameEnglish'],
        issueDate: json['issueDate'],
        expireDate: json['expireDate'],
        isExpire: json['isExpire'],
        isActive: json['isActive'],
        createDateTime: dt(json['createDateTime']),
        modifyDateTime: dt(json['modifyDateTime']),
        documentPath: json['documentPath'],
        documentType: json['documentType'],
        isImage: json['isImage'],
      );

  Map<String, dynamic> toJson() => {
    'equipmentCertificateId': equipmentCertificateId,
    'equipmentId': equipmentId,
    'typeId': typeId,
    'nameArabic': nameArabic,
    'nameEnglish': nameEnglish,
    'issueDate': issueDate,
    'expireDate': expireDate,
    'isExpire': isExpire,
    'isActive': isActive,
    'createDateTime': createDateTime?.toIso8601String(),
    'modifyDateTime': modifyDateTime?.toIso8601String(),
    'documentPath': documentPath,
    'documentType': documentType,
    'isImage': isImage,
  };
}

class Equipment {
  final int? equipmentId;
  final String? descArabic;
  final String? descEnglish;
  final bool? isActive;
  final DateTime? createDateTime;
  final DateTime? modifyDateTime;
  final int? equipmentListId;
  final int? factoryId;
  final int? statusId;
  final num? mileage;
  final int? categoryId;
  final int? fuelResponsibilityId;
  final int? driverTransResponsibilityId;
  final int? driverFoodResponsibilityId;
  final int? driverHousingResponsibilityId;
  final int? vendorId;
  final bool? rentOutRegion;
  final int? transferTypeId;
  final int? transferResponsibilityId;
  final num? rentPricePerDay;
  final num? rentPricePerHour;
  final bool? isDistancePrice;
  final num? rentPricePerDistance;
  final num? distanceKilo;
  final bool? haveCertificates;
  final num? downPaymentPerc;

  final num? equipmentWeight;
  final String? equipmentPath;
  final int? quantity;
  final int? reservedQuantity;
  final int? availableQuantity;
  final int? rentQuantity;

  final DomainDetailRef? status;
  final EquipmentListSummary? equipmentList;
  final DomainDetailRef? category;
  final DomainDetailRef? fuelResponsibility;
  final DomainDetailRef? transferType;
  final DomainDetailRef? transferResponsibility;
  final OrganizationSummary? organization;
  final List<EquipmentDriver>? drivers;
  final List<EquipmentTerm>? equipmentTerms;
  final List<EquipmentImage>? equipmentImages;
  final List<EquipmentCertificate>? equipmentCertificates;

  Equipment({
    this.equipmentId,
    this.descArabic,
    this.descEnglish,
    this.isActive,
    this.createDateTime,
    this.modifyDateTime,
    this.equipmentListId,
    this.factoryId,
    this.statusId,
    this.mileage,
    this.categoryId,
    this.fuelResponsibilityId,
    this.driverTransResponsibilityId,
    this.driverFoodResponsibilityId,
    this.driverHousingResponsibilityId,
    this.vendorId,
    this.rentOutRegion,
    this.transferTypeId,
    this.transferResponsibilityId,
    this.rentPricePerDay,
    this.rentPricePerHour,
    this.isDistancePrice,
    this.rentPricePerDistance,
    this.distanceKilo,
    this.haveCertificates,
    this.downPaymentPerc,

    this.equipmentWeight,
    this.equipmentPath,
    this.quantity,
    this.reservedQuantity,
    this.availableQuantity,
    this.rentQuantity,
    this.status,
    this.equipmentList,
    this.category,
    this.fuelResponsibility,
    this.transferType,
    this.transferResponsibility,
    this.organization,
    this.drivers,
    this.equipmentTerms,
    this.equipmentImages,
    this.equipmentCertificates,
  });

  factory Equipment.fromJson(Map<String, dynamic> json) => Equipment(
    equipmentId: json['equipmentId'],
    descArabic: json['descArabic'],
    descEnglish: json['descEnglish'],
    isActive: json['isActive'],
    createDateTime: dt(json['createDateTime']),
    modifyDateTime: dt(json['modifyDateTime']),
    equipmentListId: json['equipmentListId'],
    factoryId: json['factoryId'],
    driverTransResponsibilityId: json['driverTransResponsibilityId'],
    driverFoodResponsibilityId: json['driverFoodResponsibilityId'],
    driverHousingResponsibilityId: json['driverHousingResponsibilityId'],
    statusId: json['statusId'],
    mileage: fnum(json['mileage']),
    categoryId: json['categoryId'],
    fuelResponsibilityId: json['fuelResponsibilityId'],
    vendorId: json['vendorId'],
    rentOutRegion: json['rentOutRegion'],
    transferTypeId: json['transferTypeId'],
    transferResponsibilityId: json['transferResponsibilityId'],
    rentPricePerDay: fnum(json['rentPricePerDay']),
    rentPricePerHour: fnum(json['rentPricePerHour']),
    isDistancePrice: json['isDistancePrice'],
    rentPricePerDistance: fnum(json['rentPricePerDistance']),
    distanceKilo: fnum(json['distanceKilo']),
    haveCertificates: json['haveCertificates'],
    downPaymentPerc: fnum(json['downPaymentPerc']),

    equipmentWeight: fnum(json['equipmentWeight']),
    equipmentPath: json['equipmentPath'],
    quantity: json['quantity'],
    reservedQuantity: json['reservedQuantity'],
    availableQuantity: json['availableQuantity'],
    rentQuantity: json['rentQuantity'],
    status: json['status'] == null
        ? null
        : DomainDetailRef.fromJson(Map<String, dynamic>.from(json['status'])),
    equipmentList: json['equipmentList'] == null
        ? null
        : EquipmentListSummary.fromJson(
            Map<String, dynamic>.from(json['equipmentList']),
          ),
    category: json['category'] == null
        ? null
        : DomainDetailRef.fromJson(Map<String, dynamic>.from(json['category'])),
    fuelResponsibility: json['fuelResponsibility'] == null
        ? null
        : DomainDetailRef.fromJson(
            Map<String, dynamic>.from(json['fuelResponsibility']),
          ),
    transferType: json['transferType'] == null
        ? null
        : DomainDetailRef.fromJson(
            Map<String, dynamic>.from(json['transferType']),
          ),
    transferResponsibility: json['transferResponsibility'] == null
        ? null
        : DomainDetailRef.fromJson(
            Map<String, dynamic>.from(json['transferResponsibility']),
          ),
    organization: json['organization'] == null
        ? null
        : OrganizationSummary.fromJson(
            Map<String, dynamic>.from(json['organization']),
          ),
    drivers: (json['drivers'] is List)
        ? (json['drivers'] as List)
              .map(
                (e) => EquipmentDriver.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList()
        : null,
    equipmentTerms: (json['equipmentTerms'] is List)
        ? (json['equipmentTerms'] as List)
              .map((e) => EquipmentTerm.fromJson(Map<String, dynamic>.from(e)))
              .toList()
        : null,
    equipmentImages: (json['equipmentImages'] is List)
        ? (json['equipmentImages'] as List)
              .map((e) => EquipmentImage.fromJson(Map<String, dynamic>.from(e)))
              .toList()
        : null,
    equipmentCertificates: (json['equipmentCertificates'] is List)
        ? (json['equipmentCertificates'] as List)
              .map(
                (e) =>
                    EquipmentCertificate.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList()
        : null,
  );

  /// UI & controller sometimes call `fromMap`; just forward to fromJson.
  factory Equipment.fromMap(Map<String, dynamic> map) =>
      Equipment.fromJson(map);

  /// Common UI helpers so we don't duplicate this logic in cards/list items.
  String get title {
    final en = (descEnglish ?? '').trim();
    if (en.isNotEmpty) return en;
    return (descArabic ?? '').trim();
  }

  /// Prefer the explicit `equipmentPath`, otherwise fall back to first image.
  String? get coverPath {
    if ((equipmentPath ?? '').trim().isNotEmpty) return equipmentPath;
    final imgs = equipmentImages;
    if (imgs != null && imgs.isNotEmpty) {
      return imgs.first.equipmentPath;
    }
    return null;
  }

  /// Convenience numeric getters (some UIs expect double)
  double? get rentPerDayDouble =>
      rentPricePerDay == null ? null : (rentPricePerDay!).toDouble();

  double? get rentPerHourDouble =>
      rentPricePerHour == null ? null : (rentPricePerHour!).toDouble();

  double? get rentPerDistanceDouble =>
      rentPricePerDistance == null ? null : (rentPricePerDistance!).toDouble();

  Map<String, dynamic> toJson() => {
    'equipmentId': equipmentId,
    'descArabic': descArabic,
    'descEnglish': descEnglish,
    'isActive': isActive,
    'createDateTime': createDateTime?.toIso8601String(),
    'modifyDateTime': modifyDateTime?.toIso8601String(),
    'equipmentListId': equipmentListId,
    'factoryId': factoryId,
    'driverTransResponsibilityId': driverTransResponsibilityId,
    'driverFoodResponsibilityId': driverFoodResponsibilityId,
    'driverHousingResponsibilityId': driverHousingResponsibilityId,
    'statusId': statusId,
    'mileage': mileage,
    'categoryId': categoryId,
    'fuelResponsibilityId': fuelResponsibilityId,
    'vendorId': vendorId,
    'rentOutRegion': rentOutRegion,
    'transferTypeId': transferTypeId,
    'transferResponsibilityId': transferResponsibilityId,
    'rentPricePerDay': rentPricePerDay,
    'rentPricePerHour': rentPricePerHour,
    'isDistancePrice': isDistancePrice,
    'rentPricePerDistance': rentPricePerDistance,
    'distanceKilo': distanceKilo,
    'haveCertificates': haveCertificates,
    'downPaymentPerc': downPaymentPerc,

    'equipmentWeight': equipmentWeight,
    'equipmentPath': equipmentPath,
    'quantity': quantity,
    'reservedQuantity': reservedQuantity,
    'availableQuantity': availableQuantity,
    'rentQuantity': rentQuantity,
    'status': status?.toJson(),
    'equipmentList': equipmentList?.toJson(),
    'category': category?.toJson(),
    'fuelResponsibility': fuelResponsibility?.toJson(),
    'transferType': transferType?.toJson(),
    'transferResponsibility': transferResponsibility?.toJson(),
    'organization': organization?.toJson(),
    'drivers': drivers?.map((e) => e.toJson()).toList(),
    'equipmentTerms': equipmentTerms?.map((e) => e.toJson()).toList(),
    'equipmentImages': equipmentImages?.map((e) => e.toJson()).toList(),
    'equipmentCertificates': equipmentCertificates
        ?.map((e) => e.toJson())
        .toList(),
  };

  copyWith({required bool isActive}) {}

  // --- Minimal (de)serialization just for the active toggle ---
  factory Equipment.fromJsonActive(Map<String, dynamic> json) {
    final int id = _toInt(
      json['equipmentId'] ?? json['EquipmentId'] ?? json['id'],
    )!;
    final bool active =
        _toBoolN(json['isActive'] ?? json['IsActive'] ?? json['active']) ??
        false;
    return Equipment(equipmentId: id, isActive: active);
  }

  Map<String, dynamic> toJsonActive() => {
    'equipmentId': equipmentId,
    'isActive': isActive,
  };
}

// Helpers (put them near your models utils)
int? _toInt(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString());
}

bool? _toBoolN(dynamic v) {
  if (v == null) return null;
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) {
    final s = v.toLowerCase();
    return s == 'true' || s == '1';
  }
  return null;
}

class EquipmentSearch {
  final int? equipmentId;
  final String? descArabic;
  final String? descEnglish;
  final bool? isActive;
  final DateTime? createDateTime;
  final DateTime? modifyDateTime;
  final int? equipmentListId;
  final int? factoryId;
  final int? statusId;
  final num? mileage;
  final int? categoryId;
  final int? fuelResponsibilityId;
  final int? vendorId;
  final bool? rentOutRegion;
  final int? transferTypeId;
  final int? transferResponsibilityId;
  final num? rentPricePerDay;
  final num? rentPricePerHour;
  final bool? isDistancePrice;
  final num? rentPricePerDistance;
  final num? distanceKilo;
  final bool? haveCertificates;
  final num? downPaymentPerc;

  final num? equipmentWeight;
  final String? equipmentPath;
  final int? quantity;
  final int? reservedQuantity;
  final int? availableQuantity;
  final int? rentQuantity;

  EquipmentSearch({
    this.equipmentId,
    this.descArabic,
    this.descEnglish,
    this.isActive,
    this.createDateTime,
    this.modifyDateTime,
    this.equipmentListId,
    this.factoryId,
    this.statusId,
    this.mileage,
    this.categoryId,
    this.fuelResponsibilityId,
    this.vendorId,
    this.rentOutRegion,
    this.transferTypeId,
    this.transferResponsibilityId,
    this.rentPricePerDay,
    this.rentPricePerHour,
    this.isDistancePrice,
    this.rentPricePerDistance,
    this.distanceKilo,
    this.haveCertificates,
    this.downPaymentPerc,

    this.equipmentWeight,
    this.equipmentPath,
    this.quantity,
    this.reservedQuantity,
    this.availableQuantity,
    this.rentQuantity,
  });

  Map<String, dynamic> toJson() => {
    'equipmentId': equipmentId,
    'descArabic': descArabic,
    'descEnglish': descEnglish,
    'isActive': isActive,
    'createDateTime': createDateTime?.toIso8601String(),
    'modifyDateTime': modifyDateTime?.toIso8601String(),
    'equipmentListId': equipmentListId,
    'factoryId': factoryId,
    'statusId': statusId,
    'mileage': mileage,
    'categoryId': categoryId,
    'fuelResponsibilityId': fuelResponsibilityId,
    'vendorId': vendorId,
    'rentOutRegion': rentOutRegion,
    'transferTypeId': transferTypeId,
    'transferResponsibilityId': transferResponsibilityId,
    'rentPricePerDay': rentPricePerDay,
    'rentPricePerHour': rentPricePerHour,
    'isDistancePrice': isDistancePrice,
    'rentPricePerDistance': rentPricePerDistance,
    'distanceKilo': distanceKilo,
    'haveCertificates': haveCertificates,
    'downPaymentPerc': downPaymentPerc,

    'equipmentWeight': equipmentWeight,
    'equipmentPath': equipmentPath,
    'quantity': quantity,
    'reservedQuantity': reservedQuantity,
    'availableQuantity': availableQuantity,
    'rentQuantity': rentQuantity,
  };
}

// -------- EquipmentDriverFile --------
class EquipmentDriverFile {
  final int? equipmentDriverFileId;
  final int? equipmentDriverId;
  final String? filePath;
  final int? fileTypeId;
  final String? fileDescriptionEnglish;
  final String? fileDescriptionArabic;
  final String? startDate; // yyyy-MM-dd
  final String? endDate; // yyyy-MM-dd
  final bool? isActive;
  final bool? isExpire;
  final bool? isImage;
  final DateTime? createDateTime;
  final DateTime? modifyDateTime;

  EquipmentDriverFile({
    this.equipmentDriverFileId,
    this.equipmentDriverId,
    this.filePath,
    this.fileTypeId,
    this.fileDescriptionEnglish,
    this.fileDescriptionArabic,
    this.startDate,
    this.endDate,
    this.isActive,
    this.isExpire,
    this.isImage,
    this.createDateTime,
    this.modifyDateTime,
  });

  factory EquipmentDriverFile.fromJson(Map<String, dynamic> json) =>
      EquipmentDriverFile(
        equipmentDriverFileId: json['equipmentDriverFileId'],
        equipmentDriverId: json['equipmentDriverId'],
        filePath: json['filePath'],
        fileTypeId: json['fileTypeId'],
        fileDescriptionEnglish: json['fileDescriptionEnglish'],
        fileDescriptionArabic: json['fileDescriptionArabic'],
        startDate: json['startDate'],
        endDate: json['endDate'],
        isActive: json['isActive'],
        isExpire: json['isExpire'],
        isImage: json['isImage'],
        createDateTime: dt(json['createDateTime']),
        modifyDateTime: dt(json['modifyDateTime']),
      );

  Map<String, dynamic> toJson() => {
    'equipmentDriverFileId': equipmentDriverFileId,
    'equipmentDriverId': equipmentDriverId,
    'filePath': filePath,
    'fileTypeId': fileTypeId,
    'fileDescriptionEnglish': fileDescriptionEnglish,
    'fileDescriptionArabic': fileDescriptionArabic,
    'startDate': startDate,
    'endDate': endDate,
    'isActive': isActive,
    'isExpire': isExpire,
    'isImage': isImage,
    'createDateTime': createDateTime?.toIso8601String(),
    'modifyDateTime': modifyDateTime?.toIso8601String(),
  };
}

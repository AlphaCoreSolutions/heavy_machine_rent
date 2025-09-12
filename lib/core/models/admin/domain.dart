import 'package:heavy_new/core/utils/model_utils.dart';

class DomainDetail {
  final int? domainDetailId;
  final String? detailNameArabic;
  final String? detailNameEnglish;
  final bool? isOffline;
  final bool? isSync;
  final int? offlineId;
  final DateTime? syncDateTime;
  final DateTime? modifyDateTime;
  final int? domainId;

  DomainDetail({
    this.domainDetailId,
    this.detailNameArabic,
    this.detailNameEnglish,
    this.isOffline,
    this.isSync,
    this.offlineId,
    this.syncDateTime,
    this.modifyDateTime,
    this.domainId,
  });

  factory DomainDetail.fromJson(Map<String, dynamic> json) => DomainDetail(
    domainDetailId: json['domainDetailId'] ?? json['id'],
    detailNameArabic: json['detailNameArabic'],
    detailNameEnglish: json['detailNameEnglish'],
    isOffline: json['isOffline'],
    isSync: json['isSync'],
    offlineId: json['offlineId'],
    syncDateTime: dt(json['syncDateTime']),
    modifyDateTime: dt(json['modifyDateTime']),
    domainId: json['domainId'],
  );

  Map<String, dynamic> toJson() => {
    'domainDetailId': domainDetailId,
    'detailNameArabic': detailNameArabic,
    'detailNameEnglish': detailNameEnglish,
    'isOffline': isOffline,
    'isSync': isSync,
    'offlineId': offlineId,
    'syncDateTime': syncDateTime?.toIso8601String(),
    'modifyDateTime': modifyDateTime?.toIso8601String(),
    'domainId': domainId,
  };
}

class Domain {
  final int? domainId;
  final String? domainNameArabic;
  final String? domainNameEnglish;
  final bool? isOffline;
  final bool? isSync;
  final int? offlineId;
  final DateTime? syncDateTime;
  final DateTime? modifyDateTime;
  final List<DomainDetail>? domainDetails;

  Domain({
    this.domainId,
    this.domainNameArabic,
    this.domainNameEnglish,
    this.isOffline,
    this.isSync,
    this.offlineId,
    this.syncDateTime,
    this.modifyDateTime,
    this.domainDetails,
  });

  factory Domain.fromJson(Map<String, dynamic> json) => Domain(
    domainId: json['domainId'] ?? json['id'],
    domainNameArabic: json['domainNameArabic'],
    domainNameEnglish: json['domainNameEnglish'],
    isOffline: json['isOffline'],
    isSync: json['isSync'],
    offlineId: json['offlineId'],
    syncDateTime: dt(json['syncDateTime']),
    modifyDateTime: dt(json['modifyDateTime']),
    domainDetails: (json['domainDetails'] is List)
        ? (json['domainDetails'] as List)
              .map(
                (e) =>
                    DomainDetail.fromJson(Map<String, dynamic>.from(e as Map)),
              )
              .toList()
        : null,
  );

  Map<String, dynamic> toJson() => {
    'domainId': domainId,
    'domainNameArabic': domainNameArabic,
    'domainNameEnglish': domainNameEnglish,
    'isOffline': isOffline,
    'isSync': isSync,
    'offlineId': offlineId,
    'syncDateTime': syncDateTime?.toIso8601String(),
    'modifyDateTime': modifyDateTime?.toIso8601String(),
    'domainDetails': domainDetails?.map((e) => e.toJson()).toList(),
  };
}

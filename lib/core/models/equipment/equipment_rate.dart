import 'package:ajjara/core/utils/model_utils.dart';

class EquipmentRate {
  final int? equipmentRateId;
  final int? equipmentId;
  final int? customerId;
  final num? rateScore;
  final String? rateComment;
  final DateTime? createDateTime;
  final DateTime? modifyDateTime;
  EquipmentRate({
    this.equipmentRateId,
    this.equipmentId,
    this.customerId,
    this.rateScore,
    this.rateComment,
    this.createDateTime,
    this.modifyDateTime,
  });
  factory EquipmentRate.fromJson(Map<String, dynamic> json) => EquipmentRate(
    equipmentRateId: json['equipmentRateId'],
    equipmentId: json['equipmentId'],
    customerId: json['customerId'],
    rateScore: fnum(json['rateScore']),
    rateComment: json['rateComment'],
    createDateTime: dt(json['createDateTime']),
    modifyDateTime: dt(json['modifyDateTime']),
  );
  Map<String, dynamic> toJson() => {
    'equipmentRateId': equipmentRateId,
    'equipmentId': equipmentId,
    'customerId': customerId,
    'rateScore': rateScore,
    'rateComment': rateComment,
    'createDateTime': createDateTime?.toIso8601String(),
    'modifyDateTime': modifyDateTime?.toIso8601String(),
  };
}

import 'package:ajjara/core/utils/model_utils.dart';

class EquipmentLocation {
  final int? equipmentLocationId;
  final int? equipmentId;
  final String? locationDescription;
  final String? longitude;
  final String? latitude;
  final bool? isActive;
  final DateTime? createDateTime;
  final DateTime? modifyDateTime;
  EquipmentLocation({
    this.equipmentLocationId,
    this.equipmentId,
    this.locationDescription,
    this.longitude,
    this.latitude,
    this.isActive,
    this.createDateTime,
    this.modifyDateTime,
  });
  factory EquipmentLocation.fromJson(Map<String, dynamic> json) =>
      EquipmentLocation(
        equipmentLocationId: json['equipmentLocationId'],
        equipmentId: json['equipmentId'],
        locationDescription: json['locationDescription'],
        longitude: json['longitude'],
        latitude: json['latitude'],
        isActive: json['isActive'],
        createDateTime: dt(json['createDateTime']),
        modifyDateTime: dt(json['modifyDateTime']),
      );
  Map<String, dynamic> toJson() => {
    'equipmentLocationId': equipmentLocationId,
    'equipmentId': equipmentId,
    'locationDescription': locationDescription,
    'longitude': longitude,
    'latitude': latitude,
    'isActive': isActive,
    'createDateTime': createDateTime?.toIso8601String(),
    'modifyDateTime': modifyDateTime?.toIso8601String(),
  };
}

import 'package:heavy_new/core/utils/model_utils.dart';

class EqContract {
  final int? contractId;
  final String? contractNo;
  final String? contractDate; // yyyy-MM-dd
  final int? numberDays;
  final String? fromDate; // yyyy-MM-dd
  final String? toDate; // yyyy-MM-dd
  final int? statusId;
  final int? equipmentId;
  final int? fuelResponsibility;
  final num? rentPricePerDay;
  final num? rentPricePerHour;
  final bool? isDistancePrice;
  final num? rentPricePerDistance;
  final int? vendorId;
  final int? customerId;
  final bool? isVendorAccept;
  final bool? isCustomerAccept;
  final DateTime? createDateTime;
  final DateTime? modifyDateTime;
  final num? downPayment;
  final bool? isDriverFood;
  final bool? isDriverHousing;
  final int? driverNationalityId;
  final num? equipmentWeight;

  EqContract({
    this.contractId,
    this.contractNo,
    this.contractDate,
    this.numberDays,
    this.fromDate,
    this.toDate,
    this.statusId,
    this.equipmentId,
    this.fuelResponsibility,
    this.rentPricePerDay,
    this.rentPricePerHour,
    this.isDistancePrice,
    this.rentPricePerDistance,
    this.vendorId,
    this.customerId,
    this.isVendorAccept,
    this.isCustomerAccept,
    this.createDateTime,
    this.modifyDateTime,
    this.downPayment,
    this.isDriverFood,
    this.isDriverHousing,
    this.driverNationalityId,
    this.equipmentWeight,
  });

  factory EqContract.fromJson(Map<String, dynamic> json) => EqContract(
    contractId: json['contractId'],
    contractNo: json['contractNo'],
    contractDate: json['contractDate'],
    numberDays: json['numberDays'],
    fromDate: json['fromDate'],
    toDate: json['toDate'],
    statusId: json['statusId'],
    equipmentId: json['equipmentId'],
    fuelResponsibility: json['fuelResponsibility'],
    rentPricePerDay: fnum(json['rentPricePerDay']),
    rentPricePerHour: fnum(json['rentPricePerHour']),
    isDistancePrice: json['isDistancePrice'],
    rentPricePerDistance: fnum(json['rentPricePerDistance']),
    vendorId: json['vendorId'],
    customerId: json['customerId'],
    isVendorAccept: json['isVendorAccept'],
    isCustomerAccept: json['isCustomerAccept'],
    createDateTime: dt(json['createDateTime']),
    modifyDateTime: dt(json['modifyDateTime']),
    downPayment: fnum(json['downPayment']),
    isDriverFood: json['isDriverFood'],
    isDriverHousing: json['isDriverHousing'],
    driverNationalityId: json['driverNationalityId'],
    equipmentWeight: fnum(json['equipmentWeight']),
  );

  Map<String, dynamic> toJson() => {
    'contractId': contractId,
    'contractNo': contractNo,
    'contractDate': contractDate,
    'numberDays': numberDays,
    'fromDate': fromDate,
    'toDate': toDate,
    'statusId': statusId,
    'equipmentId': equipmentId,
    'fuelResponsibility': fuelResponsibility,
    'rentPricePerDay': rentPricePerDay,
    'rentPricePerHour': rentPricePerHour,
    'isDistancePrice': isDistancePrice,
    'rentPricePerDistance': rentPricePerDistance,
    'vendorId': vendorId,
    'customerId': customerId,
    'isVendorAccept': isVendorAccept,
    'isCustomerAccept': isCustomerAccept,
    'createDateTime': createDateTime?.toIso8601String(),
    'modifyDateTime': modifyDateTime?.toIso8601String(),
    'downPayment': downPayment,
    'isDriverFood': isDriverFood,
    'isDriverHousing': isDriverHousing,
    'driverNationalityId': driverNationalityId,
    'equipmentWeight': equipmentWeight,
  };
}

class EqContractSearch {
  final int? contractId;
  final String? contractNo;
  final String? contractDate;
  final int? numberDays;
  final String? fromDate;
  final String? toDate;
  final int? statusId;
  final int? equipmentId;
  final int? fuelResponsibility;
  final num? rentPricePerDay;
  final num? rentPricePerHour;
  final bool? isDistancePrice;
  final num? rentPricePerDistance;
  final int? vendorId;
  final int? customerId;
  final bool? isVendorAccept;
  final bool? isCustomerAccept;
  final DateTime? createDateTime;
  final DateTime? modifyDateTime;
  final num? downPayment;
  final bool? isDriverFood;
  final bool? isDriverHousing;
  final int? driverNationalityId;
  final num? equipmentWeight;

  EqContractSearch({
    this.contractId,
    this.contractNo,
    this.contractDate,
    this.numberDays,
    this.fromDate,
    this.toDate,
    this.statusId,
    this.equipmentId,
    this.fuelResponsibility,
    this.rentPricePerDay,
    this.rentPricePerHour,
    this.isDistancePrice,
    this.rentPricePerDistance,
    this.vendorId,
    this.customerId,
    this.isVendorAccept,
    this.isCustomerAccept,
    this.createDateTime,
    this.modifyDateTime,
    this.downPayment,
    this.isDriverFood,
    this.isDriverHousing,
    this.driverNationalityId,
    this.equipmentWeight,
  });

  Map<String, dynamic> toJson() => {
    'contractId': contractId,
    'contractNo': contractNo,
    'contractDate': contractDate,
    'numberDays': numberDays,
    'fromDate': fromDate,
    'toDate': toDate,
    'statusId': statusId,
    'equipmentId': equipmentId,
    'fuelResponsibility': fuelResponsibility,
    'rentPricePerDay': rentPricePerDay,
    'rentPricePerHour': rentPricePerHour,
    'isDistancePrice': isDistancePrice,
    'rentPricePerDistance': rentPricePerDistance,
    'vendorId': vendorId,
    'customerId': customerId,
    'isVendorAccept': isVendorAccept,
    'isCustomerAccept': isCustomerAccept,
    'createDateTime': createDateTime?.toIso8601String(),
    'modifyDateTime': modifyDateTime?.toIso8601String(),
    'downPayment': downPayment,
    'isDriverFood': isDriverFood,
    'isDriverHousing': isDriverHousing,
    'driverNationalityId': driverNationalityId,
    'equipmentWeight': equipmentWeight,
  };
}

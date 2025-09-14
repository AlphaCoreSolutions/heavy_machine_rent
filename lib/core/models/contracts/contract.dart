class ContractModel {
  final int? contractId;
  final int? contractNo;
  final String? contractDate;
  final String? fromDate;
  final String? toDate;
  final int? requestId;
  final int? equipmentId;
  final int? vendorId;
  final int? customerId;
  final int? statusId;
  final bool? isVendorAccept;
  final bool? isCustomerAccept;
  final int? driverId;

  ContractModel({
    this.contractId,
    this.contractNo,
    this.contractDate,
    this.fromDate,
    this.toDate,
    this.requestId,
    this.equipmentId,
    this.vendorId,
    this.customerId,
    this.statusId,
    this.isVendorAccept,
    this.isCustomerAccept,
    this.driverId,
  });

  factory ContractModel.fromJson(Map<String, dynamic> j) => ContractModel(
    contractId: j['contractId'] ?? j['ContractId'],
    contractNo: j['contractNo'] ?? j['ContractNo'],
    contractDate: j['contractDate'] ?? j['ContractDate'],
    fromDate: j['fromDate'] ?? j['FromDate'],
    toDate: j['toDate'] ?? j['ToDate'],
    requestId: j['requestId'] ?? j['RequestId'],
    equipmentId: j['equipmentId'] ?? j['EquipmentId'],
    vendorId: j['vendorId'] ?? j['VendorId'],
    customerId: j['customerId'] ?? j['CustomerId'],
    statusId: j['statusId'] ?? j['StatusId'],
    isVendorAccept: j['isVendorAccept'] ?? j['IsVendorAccept'],
    isCustomerAccept: j['isCustomerAccept'] ?? j['IsCustomerAccept'],
    driverId: j['driverId'] ?? j['DriverId'],
  );

  Map<String, dynamic> toJson() => {
    'contractId': contractId ?? 0,
    'contractNo': contractNo ?? 0,
    'contractDate': contractDate,
    'fromDate': fromDate,
    'toDate': toDate,
    'requestId': requestId ?? 0,
    'equipmentId': equipmentId ?? 0,
    'vendorId': vendorId ?? 0,
    'customerId': customerId ?? 0,
    'statusId': statusId ?? 0,
    'isVendorAccept': isVendorAccept ?? false,
    'isCustomerAccept': isCustomerAccept ?? false,
    'driverId': driverId ?? 0,
  };
}

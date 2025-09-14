class ContractSlice {
  final int? contractSliceId;
  final int? contractId;
  final int? requestId;
  final int? equipmentId;
  final int? requestDriverLocationId;
  final int? driverNationalityId;
  final int? driverId;
  final bool? isCompleted;
  final String? startDateTime; // ISO
  final String? endDateTime; // ISO
  final bool? isRecived;

  ContractSlice({
    this.contractSliceId,
    this.contractId,
    this.requestId,
    this.equipmentId,
    this.requestDriverLocationId,
    this.driverNationalityId,
    this.driverId,
    this.isCompleted,
    this.startDateTime,
    this.endDateTime,
    this.isRecived,
  });

  factory ContractSlice.fromJson(Map<String, dynamic> j) => ContractSlice(
    contractSliceId: j['contractSliceId'] ?? j['ContractSliceId'],
    contractId: j['contractId'] ?? j['ContractId'],
    requestId: j['requestId'] ?? j['RequestId'],
    equipmentId: j['equipmentId'] ?? j['EquipmentId'],
    requestDriverLocationId:
        j['requestDriverLocationId'] ?? j['RequestDriverLocationId'],
    driverNationalityId: j['driverNationalityId'] ?? j['DriverNationalityId'],
    driverId: j['driverId'] ?? j['DriverId'],
    isCompleted: j['isCompleted'] ?? j['IsCompleted'],
    startDateTime: j['startDateTime'] ?? j['StartDateTime'],
    endDateTime: j['endDateTime'] ?? j['EndDateTime'],
    isRecived: j['isRecived'] ?? j['IsRecived'],
  );

  Map<String, dynamic> toJson() => {
    'contractSliceId': contractSliceId ?? 0,
    'contractId': contractId ?? 0,
    'requestId': requestId ?? 0,
    'equipmentId': equipmentId ?? 0,
    'requestDriverLocationId': requestDriverLocationId ?? 0,
    'driverNationalityId': driverNationalityId ?? 0,
    'driverId': driverId ?? 0,
    'isCompleted': isCompleted ?? false,
    'startDateTime': startDateTime,
    'endDateTime': endDateTime,
    'isRecived': isRecived ?? false,
  };
}

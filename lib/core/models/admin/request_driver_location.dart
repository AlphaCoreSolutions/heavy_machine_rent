class RequestDriverLocation {
  final int requestDriverLocationId;
  final int requestId;
  final int equipmentId;
  final String equipmentNumber;
  final int driverNationalityId;
  final int equipmentDriverId;
  final String otherNotes;
  final String pickupAddress;
  final String pLongitude;
  final String pLatitude;
  final String dropoffAddress;
  final String dLongitude;
  final String dLatitude;

  RequestDriverLocation({
    required this.requestDriverLocationId,
    required this.requestId,
    required this.equipmentId,
    required this.equipmentNumber,
    required this.driverNationalityId,
    required this.equipmentDriverId,
    required this.otherNotes,
    required this.pickupAddress,
    required this.pLongitude,
    required this.pLatitude,
    required this.dropoffAddress,
    required this.dLongitude,
    required this.dLatitude,
  });

  Map<String, dynamic> toApiEmbedded() => {
    "requestDriverLocationId": requestDriverLocationId,
    "requestId": requestId, // 0 for embedded add
    "equipmentId": equipmentId,
    "equipmentNumber": equipmentNumber,
    "driverNationalityId": driverNationalityId,
    "equipmentDriverId": equipmentDriverId,
    "otherNotes": otherNotes,
    "pickupAddress": pickupAddress,
    "pLongitude": pLongitude,
    "pLatitude": pLatitude,
    "dropoffAddress": dropoffAddress,
    "dLongitude": dLongitude,
    "dLatitude": dLatitude,
  };

  factory RequestDriverLocation.fromJson(Map<String, dynamic> j) {
    String s(dynamic v, {String d = ''}) => (v?.toString() ?? d);
    int i(dynamic v) =>
        (v is num) ? v.toInt() : int.tryParse('${v ?? 0}') ?? 0;

    return RequestDriverLocation(
      requestDriverLocationId: i(j['requestDriverLocationId']),
      requestId: i(j['requestId']),
      equipmentId: i(j['equipmentId']),
      equipmentNumber: s(j['equipmentNumber']),
      driverNationalityId: i(j['driverNationalityId']),
      equipmentDriverId: i(j['equipmentDriverId']),
      otherNotes: s(j['otherNotes']),
      pickupAddress: s(j['pickupAddress'], d: ' '),
      pLongitude: s(j['pLongitude'], d: '0'),
      pLatitude: s(j['pLatitude'], d: '0'),
      dropoffAddress: s(j['dropoffAddress']),
      dLongitude: s(j['dLongitude']),
      dLatitude: s(j['dLatitude']),
    );
  }

  RequestDriverLocation copyWith({int? equipmentDriverId}) =>
      RequestDriverLocation(
        requestDriverLocationId: requestDriverLocationId,
        requestId: requestId,
        equipmentId: equipmentId,
        equipmentNumber: equipmentNumber,
        driverNationalityId: driverNationalityId,
        equipmentDriverId: equipmentDriverId ?? this.equipmentDriverId,
        otherNotes: otherNotes,
        pickupAddress: pickupAddress,
        pLongitude: pLongitude,
        pLatitude: pLatitude,
        dropoffAddress: dropoffAddress,
        dLongitude: dLongitude,
        dLatitude: dLatitude,
      );

  /// Payload for UPDATE (assign driver)
  Map<String, dynamic> toApiUpdateAssign(int equipmentDriver) => {
    "requestDriverLocationId": requestDriverLocationId,
    "equipmentDriver": equipmentDriver, // per your API
  };
}

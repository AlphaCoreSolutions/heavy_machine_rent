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
    String _s(dynamic v, {String d = ''}) => (v?.toString() ?? d);
    int _i(dynamic v) =>
        (v is num) ? v.toInt() : int.tryParse('${v ?? 0}') ?? 0;

    return RequestDriverLocation(
      requestDriverLocationId: _i(j['requestDriverLocationId']),
      requestId: _i(j['requestId']),
      equipmentId: _i(j['equipmentId']),
      equipmentNumber: _s(j['equipmentNumber']),
      driverNationalityId: _i(j['driverNationalityId']),
      equipmentDriverId: _i(j['equipmentDriverId']),
      otherNotes: _s(j['otherNotes']),
      pickupAddress: _s(j['pickupAddress'], d: ' '),
      pLongitude: _s(j['pLongitude'], d: '0'),
      pLatitude: _s(j['pLatitude'], d: '0'),
      dropoffAddress: _s(j['dropoffAddress']),
      dLongitude: _s(j['dLongitude']),
      dLatitude: _s(j['dLatitude']),
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

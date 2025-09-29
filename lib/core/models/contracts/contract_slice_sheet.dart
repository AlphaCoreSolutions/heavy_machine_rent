class ContractSliceSheet {
  final int? contractSliceSheetId;
  final int? contractSliceId;
  final String? sliceDate; // yyyy-MM-dd
  final num? dailyHours;
  final num? actualHours;
  final num? overHours;
  final num? totalHours;
  final int? customerUserId;
  final bool? isCustomerAccept;
  final int? vendorUserId;
  final bool? isVendorAccept;
  final String? customerNote;
  final String? vendorNote;

  ContractSliceSheet({
    this.contractSliceSheetId,
    this.contractSliceId,
    this.sliceDate,
    this.dailyHours,
    this.actualHours,
    this.overHours,
    this.totalHours,
    this.customerUserId,
    this.isCustomerAccept,
    this.vendorUserId,
    this.isVendorAccept,
    this.customerNote,
    this.vendorNote,
  });

  factory ContractSliceSheet.fromJson(Map<String, dynamic> j) =>
      ContractSliceSheet(
        contractSliceSheetId:
            j['contractSliceSheetId'] ?? j['ContractSliceSheetId'],
        contractSliceId: j['contractSliceId'] ?? j['ContractSliceId'],
        sliceDate: j['sliceDate'] ?? j['SliceDate'],
        dailyHours: j['dailyHours'] ?? j['DailyHours'],
        actualHours: j['actualHours'] ?? j['ActualHours'],
        overHours: j['overHours'] ?? j['OverHours'],
        totalHours: j['totalHours'] ?? j['TotalHours'],
        customerUserId: j['customerUserId'] ?? j['CustomerUserId'],
        isCustomerAccept: j['isCustomerAccept'] ?? j['IsCustomerAccept'],
        vendorUserId: j['vendorUserId'] ?? j['VendorUserId'],
        isVendorAccept: j['isVendorAccept'] ?? j['IsVendorAccept'],
        customerNote: j['customerNote'] ?? j['CustomerNote'],
        vendorNote: j['vendorNote'] ?? j['VendorNote'],
      );

  Map<String, dynamic> toJson() => {
    'contractSliceSheetId': contractSliceSheetId ?? 0,
    'contractSliceId': contractSliceId ?? 0,
    'sliceDate': sliceDate,
    'dailyHours': dailyHours ?? 0,
    'actualHours': actualHours ?? 0,
    'overHours': overHours ?? 0,
    'totalHours': totalHours ?? 0,
    'customerUserId': customerUserId ?? 0,
    'isCustomerAccept': isCustomerAccept ?? true,
    'vendorUserId': vendorUserId ?? 0,
    'isVendorAccept': isVendorAccept ?? true,
    'customerNote': customerNote ?? '',
    'vendorNote': vendorNote ?? '',
  };

  ContractSliceSheet copyWith({
    required int contractSliceSheetId,
    int? contractSliceId,
    required String sliceDate,
    num? dailyHours,
    num? actualHours,
    num? overHours,
    num? totalHours,
    String? customerNote,
    String? vendorNote,
  }) {
    return ContractSliceSheet(
      contractSliceSheetId: contractSliceSheetId,
      contractSliceId: contractSliceId ?? this.contractSliceId,
      sliceDate: sliceDate,
      dailyHours: dailyHours ?? this.dailyHours,
      actualHours: actualHours ?? this.actualHours,
      overHours: overHours ?? this.overHours,
      totalHours: totalHours ?? this.totalHours,
      customerUserId: customerUserId,
      isCustomerAccept: isCustomerAccept,
      vendorUserId: vendorUserId,
      isVendorAccept: isVendorAccept,
      customerNote: customerNote ?? this.customerNote,
      vendorNote: vendorNote ?? this.vendorNote,
    );
  }
}

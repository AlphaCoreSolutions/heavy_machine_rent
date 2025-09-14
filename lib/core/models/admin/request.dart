import 'package:heavy_new/core/models/admin/request_driver_location.dart';
import 'package:heavy_new/core/models/equipment/equipment.dart';
import 'package:heavy_new/core/models/organization/organization_summary.dart';
import 'package:heavy_new/core/utils/model_utils.dart';

class RequestFileModel {
  final int? requestFileId;
  final int? requestId;
  final int? typeId;
  final dynamic filePath; // type varies in schema
  final dynamic fileDescription; // type varies
  final dynamic isApprove; // type varies
  List<RequestDriverLocation>? requestDriverLocations;
  RequestFileModel({
    this.requestFileId,
    this.requestId,
    this.typeId,
    this.filePath,
    this.fileDescription,
    this.isApprove,
  });
  factory RequestFileModel.fromJson(Map<String, dynamic> json) =>
      RequestFileModel(
        requestFileId: json['requestFileId'],
        requestId: json['requestId'],
        typeId: json['typeId'],
        filePath: json['filePath'],
        fileDescription: json['fileDescription'],
        isApprove: json['isApprove'],
      );
  Map<String, dynamic> toJson() => {
    'requestFileId': requestFileId,
    'requestId': requestId,
    'typeId': typeId,
    'filePath': filePath,
    'fileDescription': fileDescription,
    'isApprove': isApprove,
  };
}

class RequestTermModel {
  final int? requestTermId;
  final int? requestId;
  final String? descArabic;
  final String? descEnglish;
  final int? orderBy;
  RequestTermModel({
    this.requestTermId,
    this.requestId,
    this.descArabic,
    this.descEnglish,
    this.orderBy,
  });
  factory RequestTermModel.fromJson(Map<String, dynamic> json) =>
      RequestTermModel(
        requestTermId: json['requestTermId'],
        requestId: json['requestId'],
        descArabic: json['descArabic'],
        descEnglish: json['descEnglish'],
        orderBy: json['orderBy'],
      );
  Map<String, dynamic> toJson() => {
    'requestTermId': requestTermId,
    'requestId': requestId,
    'descArabic': descArabic,
    'descEnglish': descEnglish,
    'orderBy': orderBy,
  };
}

class RequestModel {
  final int? requestId;
  final int? requestNo;
  final int? vendorId;
  final int? customerId;
  final bool? isVendorAccept;
  final bool? isCustomerAccept;
  final int? requestedQuantity;
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
  final DateTime? createDateTime;
  final DateTime? modifyDateTime;
  final num? downPayment;
  final bool? isDriverFood;
  final bool? isDriverHousing;
  final int? driverNationalityId;
  final num? equipmentWeight;
  final int? driverId;
  final num? totalPrice;
  final num? vatPrice;
  final num? afterVatPrice;

  final Equipment? equipment;
  final OrganizationSummary? vendor;
  final OrganizationSummary? customer;
  final DomainDetailRef? status;
  final DomainDetailRef? fuelResponsibilityDomain;
  final List<RequestTermModel>? requestTerms;
  final List<RequestFileModel>? requestFiles;

  /*
  request driver location
 {
  "requestId": 0,
  "requestNo": 0,
  "requestDate": "2025-09-11",
  "vendorId": 0,
  "customerId": 0,
  "isVendorAccept": true,
  "isCustomerAccept": true,
  "vendorNotes": "string",
  "customerNotes": "string",
  "equipmentId": 0,
  "requestedQuantity": 0,
  "requiredDays": 0,
  "fromDate": "2025-09-11",
  "toDate": "2025-09-11",
  "statusId": 0,
  "fuelResponsibilityId": 0,
  "rentPricePerDay": 0,
  "rentPricePerHour": 0,
  "isDistancePrice": true,
  "rentPricePerDistance": 0,
  "createDateTime": "2025-09-11T18:30:03.835Z",
  "modifyDateTime": "2025-09-11T18:30:03.835Z",
  "downPayment": 0,
  "driverNationalityId": 0,
  "driverFoodResponsibilityId": 0,
  "driverHousingResponsibilityId": 0,
  "driverTransResponsibilityId": 0,
  "equipmentWeight": 0,
  "driverId": 0,
  "totalPrice": 0,
  "vatPrice": 0,
  "afterVatPrice": 0,
 "requestDriverLocations": [
    {
      "requestDriverLocationId": 0,
      "requestId": 0,
      "equipmentId": 0,
      "equipmentNumber": "string",
      "driverNationalityId": 0,
      "equipmentDriverId": 0,
      "otherNotes": "string",
      "pickupAddress": "string",
      "pLongitude": "string",
      "pLatitude": "string",
      "dropoffAddress": "string",
      "dLongitude": "string",
      "dLatitude": "string",
  },
  {
      "requestDriverLocationId": 0,
      "requestId": 0,
      "equipmentId": 0,
      "equipmentNumber": "string",
      "driverNationalityId": 0,
      "equipmentDriverId": 0,
      "otherNotes": "string",
      "pickupAddress": "string",
      "pLongitude": "string",
      "pLatitude": "string",
      "dropoffAddress": "string",
      "dLongitude": "string",
      "dLatitude": "string",
  },
  {
      "requestDriverLocationId": 0,
      "requestId": 0,
      "equipmentId": 0,
      "equipmentNumber": "string",
      "driverNationalityId": 0,
      "equipmentDriverId": 0,
      "otherNotes": "string",
      "pickupAddress": "string",
      "pLongitude": "string",
      "pLatitude": "string",
      "dropoffAddress": "string",
      "dLongitude": "string",
      "dLatitude": "string",
  }
  and so on
  
  ],
}

    public async Task ConfirmRequest()
    {
        var result = ResponseResult.Failed();

        ShowProgress = true;
        ShowAlert = false;

        if (RequestId > 0)
        {
            if (Request.StatusId == 34 && IsRequest == false)
                Request.StatusId = 35;
            else if (Request.StatusId == 34 && IsRequest == true)
                Request.StatusId = 36;
            else if (Request.StatusId == 36)
                Request.StatusId = 37;
            else if (Request.StatusId == 35)
                Request.StatusId = 37;
            if (IsRequest)
                Request.IsCustomerAccept = true;
            else
                Request.IsVendorAccept = true;

            Request.ModifyDateTime = DateTime.Now.ArabicDate();


            if (Request.StatusId == 37)
            {
                Request.IsCustomerAccept = true;
                Request.IsVendorAccept = true;
            }
            
            if(Request.RequestDriverLocations== null)
                Request.RequestDriverLocations = new List<RequestDriverLocation>();

            Request.RequestDriverLocations = DriverLocations;

            result = await RequestInterface.Update(Request);
        }

        if (result.Flag)
        {
            ResultId = 1;
            ResultMessage = result.Message;
            await GetRequest();
        }
        else
        {
            ResultId = 4;
            ResultMessage = result.Message;
        }
        await GetRequest();
        ShowProgress = false;
        ShowAlert = true;
    }

    public async Task CancelRequest()
    {
        var result = ResponseResult.Failed();

        ShowProgress = true;
        ShowAlert = false;

        if (RequestId > 0)
        {
            Request.StatusId = 38;
            Request.IsCustomerAccept = false;
            Request.ModifyDateTime = DateTime.Now.ArabicDate();

            result = await RequestInterface.Update(Request);
        }

        if (result.Flag)
        {
            ResultId = 1;
            ResultMessage = result.Message + " | " + Request.Status!.DetailName;
            await GetRequest();
        }
        else
        {
            ResultId = 4;
            ResultMessage = result.Message;
        }
        ShowAlert = true;
        ShowProgress = false;
    }

}
this is the code to know where the request should be, requests, orders, or contracts screen

the request should have this thing with it 
  */

  RequestModel({
    this.requestId,
    this.requestNo,
    this.vendorId,
    this.customerId,
    this.isVendorAccept,
    this.isCustomerAccept,
    this.requestedQuantity,
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
    this.createDateTime,
    this.modifyDateTime,
    this.downPayment,
    this.isDriverFood,
    this.isDriverHousing,
    this.driverNationalityId,
    this.equipmentWeight,
    this.driverId,
    this.totalPrice,
    this.vatPrice,
    this.afterVatPrice,
    this.equipment,
    this.vendor,
    this.customer,
    this.status,
    this.fuelResponsibilityDomain,
    this.requestTerms,
    this.requestFiles,
  });
  factory RequestModel.fromJson(Map<String, dynamic> json) => RequestModel(
    requestId: fint(json['requestId']),
    requestNo: fint(json['requestNo']),
    vendorId: fint(json['vendorId']),
    customerId: fint(json['customerId']),
    isVendorAccept: json['isVendorAccept'],
    isCustomerAccept: json['isCustomerAccept'],
    requestedQuantity: fint(json['requistedQuantity']),
    numberDays: fint(json['requiredDays']),
    // Keep your model's types as-is (String?) but normalize to string safely:
    fromDate: json['fromDate']?.toString(),
    toDate: json['toDate']?.toString(),
    statusId: fint(json['statusId']),
    equipmentId: fint(json['equipmentId']),
    fuelResponsibility: fint(json['fuelResponsibility']),
    rentPricePerDay: fnum(json['rentPricePerDay']),
    rentPricePerHour: fnum(json['rentPricePerHour']),
    isDistancePrice: json['isDistancePrice'],
    rentPricePerDistance: fnum(json['rentPricePerDistance']),
    createDateTime: dt(json['createDateTime']),
    modifyDateTime: dt(json['modifyDateTime']),
    downPayment: fnum(json['downPayment']),
    isDriverFood: json['isDriverFood'],
    isDriverHousing: json['isDriverHousing'],
    driverNationalityId: fint(json['driverNationalityId']),
    equipmentWeight: fnum(json['equipmentWeight']),
    driverId: fint(json['driverId']),
    totalPrice: fnum(json['totalPrice']),
    vatPrice: fnum(json['vatPrice']),
    afterVatPrice: fnum(json['afterVatPrice']),
    equipment: json['equipment'] == null
        ? null
        : Equipment.fromJson(Map<String, dynamic>.from(json['equipment'])),
    vendor: json['vendor'] == null
        ? null
        : OrganizationSummary.fromJson(
            Map<String, dynamic>.from(json['vendor']),
          ),
    customer: json['customer'] == null
        ? null
        : OrganizationSummary.fromJson(
            Map<String, dynamic>.from(json['customer']),
          ),
    status: json['status'] == null
        ? null
        : DomainDetailRef.fromJson(Map<String, dynamic>.from(json['status'])),
    fuelResponsibilityDomain: json['fuelResponsibilityDomain'] == null
        ? null
        : DomainDetailRef.fromJson(
            Map<String, dynamic>.from(json['fuelResponsibilityDomain']),
          ),
    requestTerms: (json['requestTerms'] is List)
        ? (json['requestTerms'] as List)
              .map(
                (e) => RequestTermModel.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList()
        : null,
    requestFiles: (json['requestFiles'] is List)
        ? (json['requestFiles'] as List)
              .map(
                (e) => RequestFileModel.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList()
        : null,
  );

  Map<String, dynamic> toJson() => {
    'requestId': requestId,
    'requestNo': requestNo,
    'vendorId': vendorId,
    'customerId': customerId,
    'isVendorAccept': isVendorAccept,
    'isCustomerAccept': isCustomerAccept,
    'requistedQuantity': requestedQuantity,
    'requiredDays': numberDays,
    'fromDate': fromDate,
    'toDate': toDate,
    'statusId': statusId,
    'equipmentId': equipmentId,
    'fuelResponsibility': fuelResponsibility,
    'rentPricePerDay': rentPricePerDay,
    'rentPricePerHour': rentPricePerHour,
    'isDistancePrice': isDistancePrice,
    'rentPricePerDistance': rentPricePerDistance,
    'createDateTime': createDateTime?.toIso8601String(),
    'modifyDateTime': modifyDateTime?.toIso8601String(),
    'downPayment': downPayment,
    'isDriverFood': isDriverFood,
    'isDriverHousing': isDriverHousing,
    'driverNationalityId': driverNationalityId,
    'equipmentWeight': equipmentWeight,
    'driverId': driverId,
    'totalPrice': totalPrice,
    'vatPrice': vatPrice,
    'afterVatPrice': afterVatPrice,
    'equipment': equipment?.toJson(),
    'vendor': vendor?.toJson(),
    'customer': customer?.toJson(),
    'status': status?.toJson(),
    'fuelResponsibilityDomain': fuelResponsibilityDomain?.toJson(),
    'requestTerms': requestTerms?.map((e) => e.toJson()).toList(),
    'requestFiles': requestFiles?.map((e) => e.toJson()).toList(),
  };
}

/// Request payload used by POST /Request/add
class RequestDraft {
  int requestId;
  int requestNo;
  DateTime requestDate;
  int vendorId;
  int customerId;
  bool isVendorAccept;
  bool isCustomerAccept;
  String vendorNotes;
  String customerNotes;
  int equipmentId;
  int requestedQuantity;
  int requiredDays; // << use this key (not numberDays)
  DateTime fromDate;
  DateTime toDate;
  int statusId;
  num rentPricePerDay;
  num rentPricePerHour;
  bool isDistancePrice;
  num rentPricePerDistance;
  DateTime createDateTime;
  DateTime modifyDateTime;
  num downPayment;
  int driverNationalityId; // root-level, keep 0
  int fuelResponsibilityId;
  int driverFoodResponsibilityId;
  int driverHousingResponsibilityId;
  int driverTransResponsibilityId;
  num equipmentWeight;
  int driverId; // keep 0
  num totalPrice;
  num vatPrice;
  num afterVatPrice;
  bool isAgreeTerms;

  // NEW: embedded RDL array
  List<RequestDriverLocation> requestDriverLocations;

  RequestDraft({
    this.requestId = 0,
    this.requestNo = 0,
    this.isAgreeTerms = true,
    required this.requestDate,
    required this.vendorId,
    required this.customerId,
    this.isVendorAccept = true,
    this.isCustomerAccept = true,
    this.vendorNotes = "",
    this.customerNotes = "",
    required this.equipmentId,
    required this.requestedQuantity,
    required this.requiredDays,
    required this.fromDate,
    required this.toDate,
    this.statusId = 0,
    this.rentPricePerDay = 0,
    this.rentPricePerHour = 0,
    required this.isDistancePrice,
    this.rentPricePerDistance = 0,
    DateTime? createDateTime,
    DateTime? modifyDateTime,
    this.downPayment = 0,
    this.driverNationalityId = 0,
    this.fuelResponsibilityId = 0,
    this.driverFoodResponsibilityId = 0,
    this.driverHousingResponsibilityId = 0,
    this.driverTransResponsibilityId = 0,
    this.equipmentWeight = 0,
    this.driverId = 0,
    this.totalPrice = 0,
    this.vatPrice = 0,
    this.afterVatPrice = 0,
    this.requestDriverLocations = const [],
  }) : createDateTime = createDateTime ?? DateTime.now(),
       modifyDateTime = modifyDateTime ?? DateTime.now();

  String _ymd(DateTime d) => d.toIso8601String().split('T').first;

  Map<String, dynamic> toApi() => {
    "requestId": requestId,
    "requestNo": requestNo,
    "isAgreeTerms": true,
    "requestDate": _ymd(requestDate),
    "vendorId": vendorId,
    "customerId": customerId,
    "isVendorAccept": isVendorAccept,
    "isCustomerAccept": isCustomerAccept,
    "vendorNotes": vendorNotes,
    "customerNotes": customerNotes,
    "equipmentId": equipmentId,
    "requestedQuantity": requestedQuantity,
    "requiredDays": requiredDays, // << exact key
    "fromDate": _ymd(fromDate),
    "toDate": _ymd(toDate),
    "statusId": statusId,
    "fuelResponsibilityId": fuelResponsibilityId,
    "rentPricePerDay": rentPricePerDay,
    "rentPricePerHour": rentPricePerHour,
    "isDistancePrice": isDistancePrice,
    "rentPricePerDistance": rentPricePerDistance,
    "createDateTime": createDateTime.toIso8601String(),
    "modifyDateTime": modifyDateTime.toIso8601String(),
    "downPayment": downPayment,
    "driverNationalityId": driverNationalityId,
    "driverFoodResponsibilityId": driverFoodResponsibilityId,
    "driverHousingResponsibilityId": driverHousingResponsibilityId,
    "driverTransResponsibilityId": driverTransResponsibilityId,
    "equipmentWeight": equipmentWeight,
    "driverId": driverId,
    "totalPrice": totalPrice,
    "vatPrice": vatPrice,
    "afterVatPrice": afterVatPrice,
    "requestDriverLocations": requestDriverLocations
        .map((x) => x.toApiEmbedded())
        .toList(),
  };
}

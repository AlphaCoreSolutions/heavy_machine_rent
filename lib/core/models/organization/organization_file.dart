// organization_file.dart
import 'package:heavy_new/core/models/equipment/equipment.dart';
import 'package:heavy_new/core/utils/model_utils.dart'; // for dt() if you use it elsewhere

class OrganizationFileModel {
  final int? organizationFileId;
  final int? organizationId;
  final int? fileTypeId;
  final String? fileTypeExt;
  final bool? isImage;
  final String? descFileType;
  final String? fileName;
  final bool? isExpired;

  /// store as 'yyyy-MM-dd' string for UI simplicity
  final String? issueDate;
  final String? enDate;
  final bool? isActive;
  final DateTime? createDateTime;
  final DateTime? modifyDateTime;
  final DomainDetailRef? fileType;

  OrganizationFileModel({
    this.organizationFileId,
    this.organizationId,
    this.fileTypeId,
    this.fileTypeExt,
    this.isImage,
    this.descFileType,
    this.fileName,
    this.isExpired,
    this.issueDate,
    this.enDate,
    this.isActive,
    this.createDateTime,
    this.modifyDateTime,
    this.fileType,
  });

  factory OrganizationFileModel.fromJson(Map<String, dynamic> json) {
    return OrganizationFileModel(
      organizationFileId: ix(
        gv(json, ['organizationFileId', 'OrganizationFileId']),
      ),
      organizationId: ix(gv(json, ['organizationId', 'OrganizationId'])),
      fileTypeId: ix(gv(json, ['fileTypeId', 'FileTypeId'])),
      fileTypeExt: sx(gv(json, ['fileTypeExt', 'FileTypeExt'])),
      isImage: bx(gv(json, ['isImage', 'IsImage'])),
      descFileType: sx(gv(json, ['descFileType', 'DescFileType'])),
      fileName: sx(gv(json, ['fileName', 'FileName'])),
      isExpired: bx(gv(json, ['isExpired', 'IsExpired'])),
      issueDate: ymdFromAny(gv(json, ['issueDate', 'IssueDate'])),
      enDate: ymdFromAny(gv(json, ['enDate', 'EnDate'])),
      isActive: bx(gv(json, ['isActive', 'IsActive'])),
      createDateTime: dt(gv(json, ['createDateTime', 'CreateDateTime'])),
      modifyDateTime: dt(gv(json, ['modifyDateTime', 'ModifyDateTime'])),
      fileType: (gv(json, ['fileType', 'FileType']) is Map)
          ? DomainDetailRef.fromJson(
              Map<String, dynamic>.from(gv(json, ['fileType', 'FileType'])),
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'organizationFileId': organizationFileId,
    'organizationId': organizationId,
    'fileTypeId': fileTypeId,
    'fileTypeExt': fileTypeExt,
    'isImage': isImage,
    'descFileType': descFileType,
    'fileName': fileName,
    'isExpired': isExpired,
    'issueDate': issueDate,
    'enDate': enDate,
    'isActive': isActive,
    'createDateTime': createDateTime?.toIso8601String(),
    'modifyDateTime': modifyDateTime?.toIso8601String(),
    'fileType': fileType?.toJson(),
  };

  OrganizationFileModel copyWith({
    int? organizationFileId,
    int? organizationId,
    int? fileTypeId,
    String? fileTypeExt,
    bool? isImage,
    String? descFileType,
    String? fileName,
    bool? isExpired,
    String? issueDate,
    String? enDate,
    bool? isActive,
    DateTime? createDateTime,
    DateTime? modifyDateTime,
    DomainDetailRef? fileType,
  }) {
    return OrganizationFileModel(
      organizationFileId: organizationFileId ?? this.organizationFileId,
      organizationId: organizationId ?? this.organizationId,
      fileTypeId: fileTypeId ?? this.fileTypeId,
      fileTypeExt: fileTypeExt ?? this.fileTypeExt,
      isImage: isImage ?? this.isImage,
      descFileType: descFileType ?? this.descFileType,
      fileName: fileName ?? this.fileName,
      isExpired: isExpired ?? this.isExpired,
      issueDate: issueDate ?? this.issueDate,
      enDate: enDate ?? this.enDate,
      isActive: isActive ?? this.isActive,
      createDateTime: createDateTime ?? this.createDateTime,
      modifyDateTime: modifyDateTime ?? this.modifyDateTime,
      fileType: fileType ?? this.fileType,
    );
  }
}

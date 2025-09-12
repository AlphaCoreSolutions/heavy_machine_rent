// organization_user.dart
import 'package:heavy_new/core/models/user/auth.dart';
import 'package:heavy_new/core/utils/model_utils.dart';

class OrganizationUser {
  final int? organizationUserId;
  final int? organizationId;
  final int? applicationUserId;
  final int? statusId;
  final bool? isActive;
  final DateTime? createDateTime;
  final DateTime? modifyDateTime;
  final AuthUser? applicationUser;

  OrganizationUser({
    this.organizationUserId,
    this.organizationId,
    this.applicationUserId,
    this.statusId,
    this.isActive,
    this.createDateTime,
    this.modifyDateTime,
    this.applicationUser,
  });

  factory OrganizationUser.fromJson(
    Map<String, dynamic> json,
  ) => OrganizationUser(
    organizationUserId: ix(
      gv(json, ['organizationUserId', 'OrganizationUserId']),
    ),
    organizationId: ix(gv(json, ['organizationId', 'OrganizationId'])),
    applicationUserId: ix(gv(json, ['applicationUserId', 'ApplicationUserId'])),
    statusId: ix(gv(json, ['statusId', 'StatusId'])),
    isActive: bx(gv(json, ['isActive', 'IsActive'])),
    createDateTime: dt(gv(json, ['createDateTime', 'CreateDateTime'])),
    modifyDateTime: dt(gv(json, ['modifyDateTime', 'ModifyDateTime'])),
    applicationUser: (gv(json, ['applicationUser', 'ApplicationUser']) is Map)
        ? AuthUser.fromJson(
            Map<String, dynamic>.from(
              gv(json, ['applicationUser', 'ApplicationUser']),
            ),
          )
        : null,
  );

  Map<String, dynamic> toJson() => {
    'organizationUserId': organizationUserId,
    'organizationId': organizationId,
    'applicationUserId': applicationUserId,
    'statusId': statusId,
    'isActive': isActive,
    'createDateTime': createDateTime?.toIso8601String(),
    'modifyDateTime': modifyDateTime?.toIso8601String(),
    'applicationUser': applicationUser?.toJson(),
  };
}

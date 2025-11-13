import 'package:flutter/material.dart';
import 'package:Ajjara/core/auth/auth_store.dart';
import 'package:Ajjara/core/api/api_handler.dart' as api;
import 'package:Ajjara/core/models/equipment/equipment.dart';
import 'package:Ajjara/core/models/admin/domain.dart'; // DomainDetail
import 'package:Ajjara/core/models/organization/organization_user.dart';
import 'package:Ajjara/foundation/ui/app_icons.dart';
import 'package:Ajjara/foundation/ui/ui_extras.dart';
import 'package:Ajjara/foundation/ui/ui_kit.dart';
import 'package:Ajjara/l10n/app_localizations.dart';

import 'package:Ajjara/screens/equipment_screens/equipment_editor_screen.dart';
import 'package:Ajjara/screens/equipment_screens/equipment_settings_screen.dart';
import 'package:Ajjara/screens/organization_screens/organization_hub_screen.dart';
import 'package:Ajjara/screens/auth_profile_screens/phone_auth_screen.dart';

extension _L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}

class EquipmentManagementScreen extends StatefulWidget {
  const EquipmentManagementScreen({super.key});
  @override
  State<EquipmentManagementScreen> createState() =>
      _EquipmentManagementScreenState();
}

class _EquipmentManagementScreenState extends State<EquipmentManagementScreen> {
  // Mapping (by OrganizationUser row)
  int? _orgUserId; // == vendorId for Equipment (backend wants orgId here)
  int? _orgId;
  int? _userId;

  bool _loadingMapping = true;
  Future<List<Equipment>>? _future;

  // Small domain cache (domainId -> details)
  final Map<int, List<DomainDetail>> _domCache = {};

  @override
  void initState() {
    super.initState();
    _future = Future.value(const <Equipment>[]);
    _bootstrap();
  }

  Future<List<Equipment>> _fetchVendorList() async {
    final idOrg = _orgId;
    if (idOrg == null) return const <Equipment>[];
    return await api.Api.getEquipmentsByVendorId(vendorId: idOrg);
  }

  Future<void> _bootstrap() async {
    final auth = AuthStore.instance;
    if (!auth.isLoggedIn) return;

    try {
      setState(() => _loadingMapping = true);

      _userId = auth.user.value?.id;

      final all = await api.Api.getOrganizationUsers();
      OrganizationUser? me;
      for (final ou in all) {
        if (ou.applicationUserId == _userId) {
          me = ou;
          break;
        }
      }

      if (me != null) {
        _orgUserId = me.organizationUserId;
        _orgId = me.organizationId;

        // ⬇️ initial load uses the same path as pull-to-refresh
        if (mounted) await _refresh();
      } else {
        debugPrint(
          '[EquipMgmt] no OrganizationUser row for applicationUserId=$_userId',
        );
        if (mounted) {
          setState(() => _future = Future.value(const <Equipment>[]));
        }
      }
    } catch (e) {
      debugPrint('[EquipMgmt] bootstrap error: $e');
      if (mounted) setState(() => _future = Future.error(e));
    } finally {
      if (mounted) setState(() => _loadingMapping = false);
    }
  }

  Future<void> _refresh() async {
    if (_orgId == null && _orgUserId == null) {
      if (mounted) {
        setState(() {
          _future = Future.value(const <Equipment>[]);
        });
      }
      return;
    }

    debugPrint(
      '[EquipMgmt] manual refresh (orgId=$_orgId, orgUserId=$_orgUserId)',
    );
    try {
      final list = await _fetchVendorList();
      debugPrint('[EquipMgmt] vendor list count=${list.length}');
      for (final e in list) {
        debugPrint(
          '[EquipMgmt] · id=${e.equipmentId} vendorId=${e.vendorId} active=${e.isActive} title="${e.title}"',
        );
      }
      if (!mounted) return;
      setState(() {
        _future = Future.value(list);
      });
    } on api.ApiException catch (ex) {
      debugPrint('[EquipMgmt] vendor list error: $ex');
      if (!mounted) return;
      setState(() {
        _future = Future.value(const <Equipment>[]);
      });
    }
  }

  // ------- Helpers for nested DomainDetail (server validation requires names)
  Future<List<DomainDetail>> _loadDomain(int domainId) async {
    if (_domCache.containsKey(domainId)) return _domCache[domainId]!;
    final list = await api.Api.getDomainDetailsByDomainId(domainId);
    _domCache[domainId] = list;
    return list;
  }

  Future<DomainDetail?> _getDetailById(int domainId, int? detailId) async {
    if (detailId == null) return null;
    final list = await _loadDomain(domainId);
    for (final d in list) {
      if (d.domainDetailId == detailId) return d;
    }
    return null;
  }

  Map<String, dynamic>? _asNested(DomainDetail? d) {
    if (d == null) return null;
    String en = (d.detailNameEnglish ?? '').trim();
    String ar = (d.detailNameArabic ?? '').trim();
    if (en.length < 3) en = 'N/A';
    if (ar.length < 3) ar = 'غير محدد';
    return {
      'domainDetailId': d.domainDetailId,
      'detailNameArabic': ar,
      'detailNameEnglish': en,
    };
  }

  String? _prettyValidationErrors(Map<String, dynamic>? problem) {
    if (problem == null) return null;
    if (problem['errors'] is Map) {
      final m = problem['errors'] as Map;
      final lines = m.entries
          .map((e) {
            final key = '${e.key}'.trim();
            final vals = (e.value is List)
                ? (e.value as List).join('\n  • ')
                : '${e.value}';
            return '• $key:\n  • $vals';
          })
          .join('\n');
      return lines.isEmpty ? null : lines;
    }
    if (problem['title'] is String) return problem['title'] as String;
    return problem.toString();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final auth = AuthStore.instance;

    // Not logged in
    if (!auth.isLoggedIn) {
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.myEquipmentTitle)),
        body: Center(
          child: Glass(
            radius: 18,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.l10n.signInRequired,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.l10n.myEquipSignInBody,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  BrandButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const PhoneAuthScreen(),
                      ),
                    ),
                    icon: AIcon(
                      AppGlyph.login,
                      color: Colors.white,
                      selected: true,
                    ),
                    child: Text(context.l10n.actionSignIn),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Loading mapping
    if (_loadingMapping) {
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.myEquipmentTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // No organization mapping
    if (_orgId == null || _orgUserId == null) {
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.myEquipmentTitle)),
        body: Center(
          child: Glass(
            radius: 18,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.l10n.orgNeededTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.l10n.orgNeededBody,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  BrandButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const OrganizationScreen(),
                      ),
                    ),
                    icon: AIcon(
                      AppGlyph.organization,
                      color: Colors.white,
                      selected: true,
                    ),
                    child: Text(context.l10n.actionAddOrganization),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Has mapping → list + FAB
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.myEquipmentTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          debugPrint('[EquipMgmt] FAB: add flow start');

          // 1) Collect minimal fields from editor
          final res = await Navigator.of(context).push<Map<String, dynamic>>(
            MaterialPageRoute(
              builder: (_) =>
                  const EquipmentEditorScreen(forceShowPanels: false),
            ),
          );
          debugPrint('[EquipMgmt] editor result=null? ${res == null}');
          if (res == null || res['equipment'] == null) return;

          final draft = res['equipment'] as Equipment;

          // 2) Resolve nested DomainDetails with names (server validates them)
          final dCategory = await _getDetailById(9, draft.categoryId);
          final dTransferType = await _getDetailById(8, draft.transferTypeId);
          final dFuel = await _getDetailById(7, draft.fuelResponsibilityId);
          final dTransferResp = await _getDetailById(
            7,
            draft.transferResponsibilityId,
          );

          // 3) Build payload
          final payload = Map<String, dynamic>.from(draft.toJson())
            ..removeWhere((k, v) => v == null)
            ..addAll({
              // mapping / ownership
              'vendorId': _orgId, // backend expects orgId here
              'organizationUserId': _orgUserId,
              'organizationId': _orgId,
              'applicationUserId': _userId,
              'organization': {'organizationId': _orgId},
            });

          if (dCategory != null) payload['category'] = _asNested(dCategory);
          if (dFuel != null) payload['fuelResponsibility'] = _asNested(dFuel);
          if (dTransferType != null) {
            payload['transferType'] = _asNested(dTransferType);
          }
          if (dTransferResp != null) {
            payload['transferResponsibility'] = _asNested(dTransferResp);
          }

          // never send these when creating
          payload.remove('equipmentId');
          payload.remove('equipmentPath');
          payload.remove('rentOutRegion');

          debugPrint('[EquipMgmt] addEquipment payload => $payload');

          // 4) Create once
          try {
            final resp = await api.Api.addEquipmentRaw(payload);
            debugPrint('[EquipMgmt] addEquipment response => $resp');
            if (!mounted) return;
            AppSnack.success(context, context.l10n.submittedMayTakeMoment);
            await _refresh(); // authoritative list
          } on api.ApiException catch (ex) {
            final details = _prettyValidationErrors(ex.details);
            if (!mounted) return;
            await showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: Text(context.l10n.cantAddEquipment),
                content: SingleChildScrollView(
                  child: Text(details ?? ex.message),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(context.l10n.actionOk),
                  ),
                ],
              ),
            );
          } catch (e, st) {
            debugPrint('[EquipMgmt] addEquipment unexpected: $e\n$st');
            if (!mounted) return;
            AppSnack.error(context, context.l10n.unexpectedErrorWithMsg('$e'));
          }
        },
        icon: const Icon(Icons.add),
        label: Text(context.l10n.actionAddEquipment),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Equipment>>(
          future: _future ?? _fetchVendorList(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return ListView(
                children: const [ShimmerTile(), ShimmerTile(), ShimmerTile()],
              );
            }
            if (snap.hasError) {
              return ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      context.l10n.failedToLoadYourEquipment('${snap.error}'),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ],
              );
            }

            final items = snap.data ?? const <Equipment>[];
            if (items.isEmpty) {
              return ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      context.l10n.noEquipmentYetTapAdd,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ],
              );
            }

            return ListView.builder(
              itemCount: items.length,
              itemBuilder: (_, i) {
                final e = items[i];

                final String? primaryName = (e.coverPath?.isNotEmpty ?? false)
                    ? e.coverPath
                    : (e.equipmentImages
                              ?.firstWhere(
                                (img) => (img.equipmentPath ?? '').isNotEmpty,
                                orElse: () => EquipmentImage(),
                              )
                              .equipmentPath ??
                          e.equipmentList?.imagePath);
                final List<String> candidates =
                    api.Api.equipmentImageCandidates(primaryName);
                debugPrint(
                  '[Mgmt] image for #${e.equipmentId} primary="$primaryName"',
                );
                for (final u in candidates) {
                  debugPrint('  → $u');
                }

                return SlidableEquipmentTile(
                  title: e.title,
                  subtitle:
                      e.category?.detailNameEnglish ??
                      e.equipmentList?.primaryUseEnglish ??
                      '—',
                  pricePerDay: e.rentPerDayDouble ?? 0,
                  imageWidget: FallbackNetworkImage(
                    candidates: candidates,

                    placeholderColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    fit: BoxFit.cover,
                  ),
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => EquipmentSettingsScreen(
                          equipmentId: e.equipmentId ?? 0,
                        ),
                      ),
                    );
                    // reflect any edits when returning
                    await _refresh();
                  },
                  onRent: () =>
                      AppSnack.info(context, context.l10n.openAsCustomerToRent),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

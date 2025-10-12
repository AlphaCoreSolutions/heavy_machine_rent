// lib/screens/request_details_screen.dart
import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:heavy_new/core/models/equipment/equipment.dart';
import 'package:heavy_new/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

import 'package:heavy_new/core/api/api_handler.dart' as api;
import 'package:heavy_new/core/api/envelope.dart';
import 'package:heavy_new/core/auth/auth_store.dart';
import 'package:heavy_new/core/models/admin/request.dart';
import 'package:heavy_new/core/models/admin/request_driver_location.dart';
import 'package:heavy_new/core/models/organization/organization_user.dart';
import 'package:heavy_new/core/models/organization/organization_summary.dart';
import 'package:heavy_new/core/models/user/nationality.dart';
import 'package:heavy_new/core/utils/model_utils.dart';

import 'package:heavy_new/foundation/ui/ui_extras.dart';
import 'package:heavy_new/foundation/ui/ui_kit.dart';

import 'package:heavy_new/screens/contract_screens/contracts_screen.dart';

extension _L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}

class RequestDetailsScreen extends StatefulWidget {
  const RequestDetailsScreen({super.key, required this.requestId});
  final int requestId;

  @override
  State<RequestDetailsScreen> createState() => _RequestDetailsScreenState();
}

class _RequestDetailsScreenState extends State<RequestDetailsScreen> {
  // Request root
  late Future<RequestModel> _reqFuture;

  // Split loads
  Future<List<RequestDriverLocation>>? _rdlsFuture;
  Future<List<EquipmentDriver>>? _driversFuture;
  late Future<List<Nationality>> _natsFuture;

  // Parties / Equipment / Nationality by ID
  Future<OrganizationSummary>? _vendorByIdFuture;
  Future<OrganizationSummary>? _customerByIdFuture;
  Future<Equipment>? _equipmentByIdFuture;
  Future<Nationality>? _driverNationalityByIdFuture;

  // Domains / misc
  final _dateFmt = DateFormat('yyyy-MM-dd');
  static const _ccy = 'SAR';
  Map<int, String> _statusById = {};
  // ignore: unused_field
  bool _statusLoading = false;
  // ignore: unused_field
  String? _statusError;

  // Org (am I vendor?) — still used for permissions, not shown to users
  int? _myOrgId;
  // ignore: unused_field
  bool _orgLoading = false;

  // Keep ids we fetched for
  int? _rdlsForReqId;
  int? _driversForEqId;

  // selections (per RDL tile key)
  final Map<int, int> _assignDriverByTileKey = {};
  bool _confirmSubmitting = false;

  @override
  void initState() {
    super.initState();
    _reqFuture = api.Api.getRequestById(widget.requestId);
    _natsFuture = api.Api.getNationalities();
    _loadStatusDomain();
    _resolveMyOrg();
    _ensureRdlFuture(widget.requestId); // split the load early
  }

  // ---- small helpers ----
  String _money(num? n) => '$_ccy ${((n ?? 0).toDouble()).toStringAsFixed(2)}';

  Future<void> _loadStatusDomain() async {
    setState(() {
      _statusLoading = true;
      _statusError = null;
    });
    try {
      final rows = await api.Api.getDomainDetailsByDomainId(12);
      final map = <int, String>{};
      for (final d in rows) {
        final id = d.domainDetailId ?? -1;
        final en = (d.detailNameEnglish ?? '').trim();
        final ar = (d.detailNameArabic ?? '').trim();
        map[id] = en.isNotEmpty ? en : (ar.isNotEmpty ? ar : '#$id');
      }
      if (!mounted) return;
      setState(() => _statusById = map);
    } catch (e) {
      if (!mounted) return;
      setState(() => _statusError = context.l10n.errorLoadStatusDomain);
    } finally {
      if (mounted) setState(() => _statusLoading = false);
    }
  }

  Future<void> _resolveMyOrg() async {
    setState(() => _orgLoading = true);
    try {
      final u = AuthStore.instance.user.value;
      if (u == null) return;
      final rows = await api.Api.getOrganizationUsers();
      final me = rows.firstWhere(
        (m) => (m.applicationUserId == u.id) && (m.isActive == true),
        orElse: () => OrganizationUser(),
      );
      if (!mounted) return;
      setState(() => _myOrgId = me.organizationId);
    } catch (e) {
      dev.log('resolve org failed: $e', name: 'RequestDetails');
    } finally {
      if (mounted) setState(() => _orgLoading = false);
    }
  }

  // party/equipment/nationality futures
  void _ensurePartyFutures(int? vendorId, int? customerId) {
    if (vendorId != null && vendorId > 0) {
      _vendorByIdFuture ??= api.Api.getOrganizationById(vendorId);
    }
    if (customerId != null && customerId > 0) {
      _customerByIdFuture ??= api.Api.getOrganizationById(customerId);
    }
  }

  void _ensureEquipmentByIdFuture(int? equipmentId) {
    if (equipmentId != null && equipmentId > 0) {
      _equipmentByIdFuture ??= api.Api.getEquipmentById(equipmentId);
    }
  }

  void _ensureNationalityByIdFuture(int? natId) {
    if (natId != null && natId > 0) {
      _driverNationalityByIdFuture ??= api.Api.getNationalityById(natId);
    }
  }

  String _statusLabel(RequestModel r) {
    final en = (r.status?.detailNameEnglish ?? '').trim();
    final ar = (r.status?.detailNameArabic ?? '').trim();
    if (en.isNotEmpty) return en;
    if (ar.isNotEmpty) return ar;
    final id = r.statusId;
    if (id == null) return '';
    return _statusById[id] ?? '#$id';
  }

  bool _iAmVendor(RequestModel r) {
    final me = _myOrgId ?? 0;
    final v = r.vendorId ?? r.vendor?.organizationId ?? -1;
    return me != 0 && v == me;
  }

  bool _vendorCanConfirm(RequestModel r) {
    if (!_iAmVendor(r)) return false;
    if (r.isVendorAccept == true && r.statusId == 37) return false;
    return true;
  }

  // ---- data loaders ----
  Future<List<RequestDriverLocation>> _fetchRDLs(int requestId) {
    final sql =
        'select * from RequestDriverLocations where RequestId = $requestId';
    return api.Api.searchRequestDriverLocation(sql);
  }

  void _ensureRdlFuture(int? requestId) {
    if (requestId == null || requestId == 0) return;
    if (_rdlsFuture == null || _rdlsForReqId != requestId) {
      _rdlsForReqId = requestId;
      _rdlsFuture = _fetchRDLs(requestId);
    }
  }

  void _ensureDriversFuture(int? equipmentId) {
    if (equipmentId == null || equipmentId == 0) return;
    if (_driversFuture == null || _driversForEqId != equipmentId) {
      _driversForEqId = equipmentId;
      _driversFuture = api.Api.getEquipmentDriversByEquipmentId(equipmentId);
    }
  }

  Future<void> _refreshRdl() async {
    if (_rdlsForReqId == null) return;
    setState(() {
      _rdlsFuture = _fetchRDLs(_rdlsForReqId!);
    });
  }

  // A consistent key to store selections for a tile (RDL id if present else negative index)
  int _tileKeyFor(RequestDriverLocation u, int index) {
    final rid = u.requestDriverLocationId;
    return rid > 0 ? rid : -(index + 1);
  }

  // Filter + dedupe drivers by nationality
  List<EquipmentDriver> _driversForNat(List<EquipmentDriver> all, int? natId) {
    final Map<int, EquipmentDriver> byId = {};
    for (final d in all) {
      if ((d.driverNationalityId ?? -1) == (natId ?? -1)) {
        final id = d.equipmentDriverId ?? 0;
        if (id > 0) byId[id] = d;
      }
    }
    return byId.values.toList();
  }

  bool _everyRdlHasAtLeastOneChoice(
    List<RequestDriverLocation> rdls,
    List<EquipmentDriver> all,
  ) {
    for (var i = 0; i < rdls.length; i++) {
      final u = rdls[i];
      if (_driversForNat(all, u.driverNationalityId).isEmpty) return false;
    }
    return true;
  }

  bool _allAssignedValid(
    List<RequestDriverLocation> rdls,
    List<EquipmentDriver> all,
  ) {
    final validIds = all
        .map((d) => d.equipmentDriverId)
        .whereType<int>()
        .toSet();
    for (var i = 0; i < rdls.length; i++) {
      final u = rdls[i];
      final key = _tileKeyFor(u, i);
      final chosen = _assignDriverByTileKey[key] ?? (u.equipmentDriverId);
      if (chosen <= 0) return false;
      if (!validIds.contains(chosen)) return false;
    }
    return true;
  }

  Future<void> _confirmAndMakeContract(
    RequestModel r,
    List<RequestDriverLocation> rdls,
    List<EquipmentDriver> allDrivers,
  ) async {
    if (r.requestId == null || r.requestId == 0) {
      AppSnack.error(context, context.l10n.errorInvalidRequestId);
      return;
    }

    // Strict guards
    if (!_everyRdlHasAtLeastOneChoice(rdls, allDrivers)) {
      AppSnack.error(context, context.l10n.errorUnitHasNoDriverForNationality);
      return;
    }
    if (!_allAssignedValid(rdls, allDrivers)) {
      AppSnack.error(context, context.l10n.errorAssignDriverEachUnit);
      return;
    }

    // merge choices
    final rdlsAssigned = <RequestDriverLocation>[];
    for (var i = 0; i < rdls.length; i++) {
      final u = rdls[i];
      final key = _tileKeyFor(u, i);
      final chosen = _assignDriverByTileKey[key] ?? (u.equipmentDriverId);
      rdlsAssigned.add(u.copyWith(equipmentDriverId: chosen));
    }

    setState(() => _confirmSubmitting = true);
    try {
      // 1) Update the request with assigned drivers
      final updatedOk = await api.Api.updateRequestWithRDLs(
        request: r,
        rdlsAssigned: rdlsAssigned,
      );
      if (!updatedOk) {
        AppSnack.error(context, context.l10n.errorUpdateFailedFlagFalse);
        return;
      }

      // 2) Create contract
      final raw = await api.Api.addContractFromRequest(
        request: r,
        rdlsAssigned: rdlsAssigned,
      );

      final env = ApiEnvelope.fromAny(raw);
      final ok = (env.flag == true) || ((env.modelId ?? 0) > 0);
      if (!ok) {
        final msg = (env.message?.trim().isNotEmpty ?? false)
            ? env.message!
            : context.l10n.errorContractCreationFailed;
        AppSnack.error(context, msg);
        return;
      }

      if (!mounted) return;
      AppSnack.success(context, context.l10n.snackContractCreated);

      // 3) Navigate to contracts screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ContractsScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      AppSnack.error(context, '$e');
    } finally {
      if (mounted) setState(() => _confirmSubmitting = false);
    }
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.requestDetailsTitle),
        actions: [
          IconButton(
            tooltip: context.l10n.actionRefresh,
            onPressed: () {
              setState(() {
                _reqFuture = api.Api.getRequestById(widget.requestId);
              });
              _refreshRdl();
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<RequestModel>(
        future: _reqFuture,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return ListView(children: const [ShimmerTile(), ShimmerTile()]);
          }
          if (snap.hasError || !snap.hasData) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(context.l10n.failedToLoadRequest),
              ),
            );
          }

          final r = snap.data!;
          _ensureRdlFuture(r.requestId);
          _ensureDriversFuture(r.equipmentId);
          _ensurePartyFutures(r.vendorId, r.customerId);
          _ensureEquipmentByIdFuture(r.equipmentId);
          _ensureNationalityByIdFuture(r.driverNationalityId);

          final fromDt = dtLoose(r.fromDate);
          final toDt = dtLoose(r.toDate);
          final from = fromDt != null ? _dateFmt.format(fromDt) : '—';
          final to = toDt != null ? _dateFmt.format(toDt) : '—';
          final days = r.numberDays ?? 0;

          final base = r.rentPricePerDay != null
              ? (r.rentPricePerDay! * days)
              : 0;
          final distance =
              (r.isDistancePrice == true && (r.rentPricePerDistance ?? 0) > 0)
              ? (r.rentPricePerDistance ?? 0)
              : 0;
          final vat = r.vatPrice ?? 0;
          final total = r.afterVatPrice ?? r.totalPrice ?? 0;
          final dp = r.downPayment ?? 0;

          final statusStr = _statusLabel(r);
          final canConfirm = _vendorCanConfirm(r);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              // ---------- Header (no request number) ----------
              Glass(
                radius: 18,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: cs.surfaceContainerHighest,
                        child: Icon(
                          Icons.request_page_outlined,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Just the title (localized), no number
                            Text(
                              context.l10n.requestDetailsTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 8),
                            if (statusStr.isNotEmpty)
                              Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: cs.primaryContainer,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    statusStr,
                                    softWrap: false,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(
                                          color: cs.onPrimaryContainer,
                                        ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ---------- Duration ----------
              Glass(
                radius: 18,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.sectionDuration,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 12,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _iconText(
                            Icons.calendar_today_outlined,
                            '${context.l10n.fromDate} $from',
                          ),
                          _iconText(
                            Icons.arrow_forward,
                            '${context.l10n.toDate} $to',
                          ),
                          _iconText(
                            Icons.schedule_outlined,
                            '$days ${context.l10n.daysSuffix}',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ---------- Parties (names via ID lookups) ----------
              Glass(
                radius: 18,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.sectionParties,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),

                      // Vendor
                      FutureBuilder<OrganizationSummary>(
                        future: _vendorByIdFuture,
                        builder: (context, vs) {
                          final name = vs.data != null
                              ? _orgNameOnly(vs.data)
                              : _orgNameOnly(r.vendor);
                          return _kvLine(
                            context,
                            context.l10n.labelVendor,
                            name,
                          );
                        },
                      ),

                      // Customer
                      FutureBuilder<OrganizationSummary>(
                        future: _customerByIdFuture,
                        builder: (context, csnap) {
                          final name = csnap.data != null
                              ? _orgNameOnly(csnap.data)
                              : _orgNameOnly(r.customer);
                          return _kvLine(
                            context,
                            context.l10n.labelCustomer,
                            name,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ---------- Equipment (name only) ----------
              Glass(
                radius: 18,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.sectionEquipment,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      FutureBuilder<Equipment>(
                        future: _equipmentByIdFuture,
                        builder: (context, esnap) {
                          final label = esnap.data != null
                              ? _equipDisplay(esnap.data)
                              : _equipDisplay(r.equipment);
                          return _kvLine(
                            context,
                            context.l10n.labelItem,
                            label,
                          );
                        },
                      ),
                      _kvLine(
                        context,
                        context.l10n.labelRequestedQty,
                        _safe(r.requestedQuantity?.toString()),
                      ),
                      // Driver nationality resolved by ID
                      // Driver nationalities (may be multiple when qty > 1)
                      FutureBuilder<List<RequestDriverLocation>>(
                        future: _rdlsFuture,
                        builder: (context, rdlSnap) {
                          // If we don't have RDLs yet, fall back to the old single id → name path
                          final fallbackNatId = r.driverNationalityId;
                          if (rdlSnap.connectionState ==
                              ConnectionState.waiting) {
                            return _kvLine(
                              context,
                              context.l10n.labelDriverNationality,
                              '—',
                            );
                          }

                          final rdls =
                              rdlSnap.data ?? const <RequestDriverLocation>[];
                          final natIds = rdls
                              .map((u) => u.driverNationalityId)
                              .whereType<int>()
                              .toSet();

                          // If no per-unit nationality IDs, use the single root-level one
                          if (natIds.isEmpty &&
                              (fallbackNatId == null || fallbackNatId == 0)) {
                            return _kvLine(
                              context,
                              context.l10n.labelDriverNationality,
                              '—',
                            );
                          }

                          return FutureBuilder<List<Nationality>>(
                            future: _natsFuture,
                            builder: (context, natSnap) {
                              if (natSnap.connectionState ==
                                  ConnectionState.waiting) {
                                return _kvLine(
                                  context,
                                  context.l10n.labelDriverNationality,
                                  '—',
                                );
                              }
                              final nats =
                                  natSnap.data ?? const <Nationality>[];

                              // Build a lookup map for fast id → name
                              final nameById = <int, String>{
                                for (final n in nats)
                                  if (n.nationalityId != null)
                                    n.nationalityId!:
                                        (n.nationalityNameEnglish
                                                ?.trim()
                                                .isNotEmpty ??
                                            false)
                                        ? n.nationalityNameEnglish!.trim()
                                        : _safe(n.nationalityNameArabic),
                              };

                              // If we have multiple from RDLs, use those; else fallback single id
                              final idsToShow = natIds.isNotEmpty
                                  ? natIds
                                  : {
                                      if (fallbackNatId != null &&
                                          fallbackNatId > 0)
                                        fallbackNatId,
                                    };

                              final labels = idsToShow
                                  .map(
                                    (id) =>
                                        _safe(nameById[id] ?? id.toString()),
                                  )
                                  .toList();

                              // You can switch this to chips if you prefer:
                              // return _kvLineChips(context, context.l10n.labelDriverNationality,
                              //   labels.map((t) => _chip(t)).toList());

                              return _kvLineChips(
                                context,
                                context.l10n.labelDriverNationality,
                                labels.map((t) => _chip(t)).toList(),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ---------- Responsibilities & Acceptance ----------
              Glass(
                radius: 18,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.sectionResponsibilities,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      _kvLine(
                        context,
                        context.l10n.respFuel,
                        _domainLabel(
                          r.fuelResponsibilityDomain,
                          fallback: _safe(r.fuelResponsibility?.toString()),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _chipLine(context, [
                        _boolChip(
                          context,
                          label: context.l10n.respDriverFood,
                          v: r.isDriverFood,
                        ),
                        _boolChip(
                          context,
                          label: context.l10n.respDriverHousing,
                          v: r.isDriverHousing,
                        ),
                      ]),
                      const SizedBox(height: 10),
                      Text(
                        context.l10n.sectionStatusAcceptance,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 6),
                      _chipLine(context, [
                        _boolChip(
                          context,
                          label: context.l10n.flagVendorAccepted,
                          v: r.isVendorAccept,
                        ),
                        _boolChip(
                          context,
                          label: context.l10n.flagCustomerAccepted,
                          v: r.isCustomerAccept,
                        ),
                      ]),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ---------- Terms ----------
              if ((r.requestTerms?.isNotEmpty ?? false)) ...[
                Glass(
                  radius: 18,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.sectionTerms,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 10),
                        ...(() {
                          final terms =
                              (r.requestTerms ?? const <RequestTermModel>[])
                                  .toList()
                                ..sort(
                                  (a, b) => (a.orderBy ?? 0).compareTo(
                                    b.orderBy ?? 0,
                                  ),
                                );
                          return terms.map(
                            (t) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('• '),
                                  Expanded(
                                    child: Text(
                                      _safe(t.descEnglish ?? t.descArabic),
                                      softWrap: true,
                                      overflow: TextOverflow.fade,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        })(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // ---------- Files / Attachments ----------
              if ((r.requestFiles?.isNotEmpty ?? false)) ...[
                Glass(
                  radius: 18,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.sectionAttachments,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: r.requestFiles!
                              .map(
                                (f) => SizedBox(
                                  width: 360,
                                  child: _fileTile(context, f),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // ---------- Meta / Timestamps (no IDs) ----------
              Glass(
                radius: 18,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.sectionMeta,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      _kvLine(
                        context,
                        context.l10n.labelCreatedAt,
                        r.createDateTime != null
                            ? _dateFmt.format(r.createDateTime!)
                            : '—',
                      ),
                      _kvLine(
                        context,
                        context.l10n.labelUpdatedAt, // <- updated wording
                        r.modifyDateTime != null
                            ? _dateFmt.format(r.modifyDateTime!)
                            : '—',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ---------- Price breakdown ----------
              Glass(
                radius: 18,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.sectionPriceBreakdown,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 10),
                      _row(context.l10n.priceBase, _money(base)),
                      if (distance > 0)
                        _row(context.l10n.priceDistance, _money(distance)),
                      _row(context.l10n.priceVat, _money(vat)),
                      const Divider(height: 20),
                      _rowBold(context.l10n.priceTotal, _money(total)),
                      const SizedBox(height: 4),
                      _row(context.l10n.priceDownPayment, _money(dp)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ---------- Assign drivers (vendor) ----------
              if (canConfirm) ...[
                Glass(
                  radius: 18,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.sectionAssignDrivers,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),

                        FutureBuilder<List<RequestDriverLocation>>(
                          future: _rdlsFuture,
                          builder: (context, rdlSnap) {
                            if (rdlSnap.connectionState ==
                                ConnectionState.waiting) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: LinearProgressIndicator(),
                              );
                            }
                            if (rdlSnap.hasError) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    context.l10n.errorLoadDriverLocations,
                                    style: TextStyle(color: cs.error),
                                  ),
                                  const SizedBox(height: 6),
                                  OutlinedButton.icon(
                                    onPressed: _refreshRdl,
                                    icon: const Icon(Icons.refresh),
                                    label: Text(context.l10n.actionRetry),
                                  ),
                                ],
                              );
                            }
                            final rdls =
                                rdlSnap.data ?? const <RequestDriverLocation>[];
                            if (rdls.isEmpty) {
                              return Text(context.l10n.emptyNoDriverLocations);
                            }

                            return FutureBuilder<List<EquipmentDriver>>(
                              future: _driversFuture,
                              builder: (context, drvSnap) {
                                final drivers =
                                    drvSnap.data ?? const <EquipmentDriver>[];
                                final driversLoading =
                                    drvSnap.connectionState ==
                                    ConnectionState.waiting;

                                return FutureBuilder<List<Nationality>>(
                                  future: _natsFuture,
                                  builder: (context, natSnap) {
                                    final nats =
                                        natSnap.data ?? const <Nationality>[];
                                    final natNameById = <int, String>{
                                      for (final n in nats)
                                        if (n.nationalityId != null)
                                          n.nationalityId!:
                                              ((n.nationalityNameEnglish ?? '')
                                                  .trim()
                                                  .isNotEmpty
                                              ? n.nationalityNameEnglish!.trim()
                                              : ((n.nationalityNameArabic ?? '')
                                                        .trim()
                                                        .isNotEmpty
                                                    ? n.nationalityNameArabic!
                                                          .trim()
                                                    : '#${n.nationalityId}')),
                                    };

                                    final hasChoiceForEach =
                                        _everyRdlHasAtLeastOneChoice(
                                          rdls,
                                          drivers,
                                        );
                                    final allAssigned = _allAssignedValid(
                                      rdls,
                                      drivers,
                                    );
                                    final canCreateNow =
                                        hasChoiceForEach &&
                                        allAssigned &&
                                        !_confirmSubmitting;

                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (driversLoading ||
                                            natSnap.connectionState ==
                                                ConnectionState.waiting)
                                          const Padding(
                                            padding: EdgeInsets.only(bottom: 8),
                                            child: LinearProgressIndicator(),
                                          ),

                                        for (
                                          var i = 0;
                                          i < rdls.length;
                                          i++
                                        ) ...[
                                          _rdlTile(
                                            context,
                                            rdls[i],
                                            drivers,
                                            natNameById,
                                            cs,
                                            index: i,
                                          ),
                                          const SizedBox(height: 10),
                                        ],

                                        if (!hasChoiceForEach)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 6,
                                              bottom: 2,
                                            ),
                                            child: Text(
                                              context
                                                  .l10n
                                                  .errorNoDriversForNationality,
                                              style: TextStyle(color: cs.error),
                                            ),
                                          ),
                                        if (hasChoiceForEach && !allAssigned)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 6,
                                              bottom: 2,
                                            ),
                                            child: Text(
                                              context
                                                  .l10n
                                                  .errorAssignDriverEachUnit,
                                              style: TextStyle(color: cs.error),
                                            ),
                                          ),

                                        const SizedBox(height: 6),
                                        FilledButton.icon(
                                          onPressed: canCreateNow
                                              ? () => _confirmAndMakeContract(
                                                  r,
                                                  rdls,
                                                  drivers,
                                                )
                                              : null,
                                          icon: _confirmSubmitting
                                              ? const SizedBox(
                                                  height: 18,
                                                  width: 18,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor:
                                                        AlwaysStoppedAnimation(
                                                          Colors.white,
                                                        ),
                                                  ),
                                                )
                                              : const Icon(Icons.description),
                                          label: Text(
                                            _confirmSubmitting
                                                ? context.l10n.creatingEllipsis
                                                : context
                                                      .l10n
                                                      .actionCreateContract,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ---------- Cancel (pending only) ----------
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          (statusStr.isEmpty ||
                              statusStr.toLowerCase().contains('pending'))
                          ? () {
                              // TODO: cancel flow
                            }
                          : null,
                      child: Text(context.l10n.actionCancelRequest),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _rdlTile(
    BuildContext context,
    RequestDriverLocation u,
    List<EquipmentDriver> allDrivers,
    Map<int, String> natNameById,
    ColorScheme cs, {
    required int index,
  }) {
    final keyForTile = _tileKeyFor(u, index);
    final ridShown = u.requestDriverLocationId;

    final natId = u.driverNationalityId;
    final natName = natNameById[natId] ?? '#$natId';

    final drivers = _driversForNat(allDrivers, natId);

    int? sel = _assignDriverByTileKey[keyForTile];
    if (sel == null || sel == 0) {
      final uId = u.equipmentDriverId;
      sel = uId > 0 ? uId : null;
    }
    final validIds = drivers
        .map((d) => d.equipmentDriverId)
        .whereType<int>()
        .toSet();
    if (sel != null && !validIds.contains(sel)) sel = null;

    // Long addresses/coords can overflow; use Wrap and limit line lengths.
    final drop = u.dropoffAddress.trim();

    return Container(
      key: ValueKey('tile_$keyForTile'),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withOpacity(.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${context.l10n.unitLabel} #$ridShown',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),

          // Meta as wrap to avoid overflow
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              _metaChip(
                context,
                Icons.flag_outlined,
                '${context.l10n.requestedNationality}: $natName',
              ),
              if (drop.isNotEmpty)
                _metaChip(
                  context,
                  Icons.place_outlined,
                  '${context.l10n.dropoffLabel}: $drop',
                  maxWidthFraction: 0.65,
                ),
              _metaChip(
                context,
                Icons.gps_fixed,
                '${context.l10n.coordinatesLabel}: ${u.dLatitude}, ${u.dLongitude}',
              ),
            ],
          ),

          const SizedBox(height: 10),

          if (drivers.isEmpty)
            Text(
              context.l10n.emptyNoDriversForThisNationality,
              style: TextStyle(color: cs.error),
            )
          else
            DropdownButtonFormField<int>(
              key: ValueKey('dd_$keyForTile'),
              isExpanded: true,
              initialValue: sel,
              items: drivers.map((d) {
                final label = (d.driverNameEnglish?.trim().isNotEmpty ?? false)
                    ? d.driverNameEnglish!.trim()
                    : (d.driverNameArabic?.trim().isNotEmpty ?? false)
                    ? d.driverNameArabic!.trim()
                    : context.l10n.driverWithId(
                        (d.equipmentDriverId ?? 0).toString(),
                      );
                return DropdownMenuItem<int>(
                  value: d.equipmentDriverId,
                  child: Text(label, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (v) =>
                  setState(() => _assignDriverByTileKey[keyForTile] = v ?? 0),
              decoration: InputDecoration(
                labelText: context.l10n.labelAssignDriverFiltered,
                prefixIcon: const Icon(Icons.badge_outlined),
              ),
              hint: Text(context.l10n.hintSelectDriver),
            ),
        ],
      ),
    );
  }

  // ---------- File tile (localized) ----------
  Widget _fileTile(BuildContext ctx, RequestFileModel f) {
    final cs = Theme.of(ctx).colorScheme;
    final id = f.requestFileId ?? 0;
    final tp = f.typeId?.toString() ?? '—';
    final desc = _safe(f.fileDescription?.toString());
    final path = _safe(f.filePath?.toString());
    final approved =
        (f.isApprove == true) ||
        (f.isApprove?.toString() == 'true' || f.isApprove?.toString() == '1');

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withOpacity(.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  context.l10n.fileType1(tp),
                  style: Theme.of(ctx).textTheme.labelSmall?.copyWith(
                    color: cs.onPrimaryContainer,
                  ),
                ),
              ),
              const Spacer(),
              Icon(
                approved ? Icons.verified : Icons.help_outline,
                size: 18,
                color: approved ? cs.primary : cs.outline,
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (desc != '—')
            Text(desc, maxLines: 2, overflow: TextOverflow.ellipsis),
          if (path != '—') ...[
            const SizedBox(height: 6),
            InkWell(
              onTap: () {
                // TODO: open/download if available
                dev.log('Open file: $path (id=$id)');
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.attach_file, size: 16),
                  const SizedBox(width: 6),
                  Flexible(child: Text(path, overflow: TextOverflow.ellipsis)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---------- Small UI helpers ----------
  Widget _iconText(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16),
        const SizedBox(width: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 260),
          child: Text(text, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  Widget _metaChip(
    BuildContext context,
    IconData icon,
    String text, {
    double maxWidthFraction = 0.9,
  }) {
    final maxWidth = MediaQuery.of(context).size.width * maxWidthFraction;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(.6),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(.6),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String l, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Expanded(child: Text(l)),
        Text(v),
      ],
    ),
  );

  Widget _rowBold(String l, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Expanded(
          child: Text(l, style: const TextStyle(fontWeight: FontWeight.w800)),
        ),
        Text(v, style: const TextStyle(fontWeight: FontWeight.w800)),
      ],
    ),
  );
}

// --- label helpers (names only, no IDs) ---
String _orgNameOnly(OrganizationSummary? o) {
  if (o == null) return '—';
  // Try multiple likely keys safely
  return _safe(o.nameEnglish ?? o.nameEnglish ?? o.nameArabic ?? o.nameArabic);
}

String _equipDisplay(Equipment? e) {
  if (e == null) return '—';
  // Prefer user-facing names over IDs
  final name = _safe(e.title);
  final number = _safe(e.equipmentId.toString());
  // Show number only if we have a name and a distinct number
  return (name != '—' && number != '—') ? '$name • $number' : name;
}

String _safe(String? s, [String dash = '—']) {
  s = (s ?? '').trim();
  return s.isEmpty ? dash : s;
}

String _domainLabel(DomainDetailRef? d, {String fallback = '—'}) {
  if (d == null) return fallback;
  final en = (d.detailNameEnglish ?? '').trim();
  final ar = (d.detailNameArabic ?? '').trim();
  if (en.isNotEmpty) return en;
  if (ar.isNotEmpty) return ar;
  return fallback;
}

// chips / lines
Widget _boolChip(BuildContext ctx, {required String label, required bool? v}) {
  final cs = Theme.of(ctx).colorScheme;
  final on = v == true;
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: (on ? cs.primaryContainer : cs.surfaceVariant).withOpacity(.7),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: cs.outlineVariant.withOpacity(.5)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          on ? Icons.check_circle : Icons.cancel,
          size: 14,
          color: on ? cs.onPrimaryContainer : cs.onSurfaceVariant,
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(ctx).textTheme.labelMedium?.copyWith(
            color: on ? cs.onPrimaryContainer : cs.onSurfaceVariant,
          ),
        ),
      ],
    ),
  );
}

Widget _kvLine(BuildContext ctx, String k, String v) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 4),
  child: Row(
    children: [
      Expanded(child: Text(k, style: Theme.of(ctx).textTheme.bodyMedium)),
      const SizedBox(width: 12),
      Flexible(child: Text(v, overflow: TextOverflow.ellipsis)),
    ],
  ),
);

Widget _chipLine(BuildContext ctx, List<Widget> chips) =>
    Wrap(spacing: 8, runSpacing: 6, children: chips);

// long text with “expand”
class _ExpandableText extends StatefulWidget {
  // ignore: unused_element_parameter
  const _ExpandableText(this.text, {this.maxChars = 140});
  final String text;
  final int maxChars;
  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  bool _more = false;
  @override
  Widget build(BuildContext context) {
    final t = widget.text.trim();
    if (t.isEmpty) return const SizedBox.shrink();
    final over = t.length > widget.maxChars;
    final shown = (!over || _more)
        ? t
        : ('${t.substring(0, widget.maxChars)}…');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(shown),
        if (over)
          TextButton(
            onPressed: () => setState(() => _more = !_more),
            child: Text(_more ? context.l10n.showLess : context.l10n.showMore),
          ),
      ],
    );
  }
}

Widget _kvLineChips(BuildContext ctx, String k, List<Widget> chips) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 4),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        flex: 3,
        child: Text(k, style: Theme.of(ctx).textTheme.bodyMedium),
      ),
      const SizedBox(width: 12),
      Expanded(
        flex: 5,
        child: Wrap(spacing: 6, runSpacing: 6, children: chips),
      ),
    ],
  ),
);

Widget _chip(String text) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  decoration: BoxDecoration(
    color: Colors.black12.withOpacity(.06),
    borderRadius: BorderRadius.circular(999),
  ),
  child: Text(text, style: TextStyle(fontSize: 12)),
);

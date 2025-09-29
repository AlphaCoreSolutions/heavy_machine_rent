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

  // Domains / misc
  final _dateFmt = DateFormat('yyyy-MM-dd');
  static const _ccy = 'SAR';
  Map<int, String> _statusById = {};
  // ignore: unused_field
  bool _statusLoading = false;
  // ignore: unused_field
  String? _statusError;

  // Org (am I vendor?)
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
      setState(() => _statusError = 'Could not load status names.');
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
      AppSnack.error(context, 'Invalid request id.');
      return;
    }

    // Strict guards
    if (!_everyRdlHasAtLeastOneChoice(rdls, allDrivers)) {
      AppSnack.error(
        context,
        'At least one unit has no available drivers for its requested nationality.',
      );
      return;
    }
    if (!_allAssignedValid(rdls, allDrivers)) {
      AppSnack.error(context, 'Please assign a driver for every unit.');
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
        AppSnack.error(context, 'Update failed (flag=false)');
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
            : 'Contract creation failed.';
        AppSnack.error(context, msg);
        return;
      }

      if (!mounted) return;
      AppSnack.success(context, 'Contract created');

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

          final reqNo =
              r.requestNo?.toString() ?? r.requestId?.toString() ?? '—';
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
              // ---------- Header (wraps nicely on small screens) ----------
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
                            // Title gets all horizontal space, chips wrap beneath if needed
                            Text(
                              '${context.l10n.requestNumber} $reqNo',
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

              // ---------- Duration (uses Wrap so it never overflows) ----------
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
                    : 'Driver #${d.equipmentDriverId ?? 0}';
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

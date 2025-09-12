// lib/screens/request_details_screen.dart
import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:heavy_new/core/api/api_handler.dart' as api;
import 'package:heavy_new/core/auth/auth_store.dart';
import 'package:heavy_new/core/models/admin/request.dart';
import 'package:heavy_new/core/models/admin/request_driver_location.dart';
import 'package:heavy_new/core/models/equipment/equipment.dart';
import 'package:heavy_new/core/models/organization/organization_user.dart';
import 'package:heavy_new/core/models/user/nationality.dart';
import 'package:heavy_new/core/utils/model_utils.dart';

import 'package:heavy_new/foundation/ui/ui_extras.dart';
import 'package:heavy_new/foundation/ui/ui_kit.dart';

class RequestDetailsScreen extends StatefulWidget {
  const RequestDetailsScreen({super.key, required this.requestId});
  final int requestId;

  @override
  State<RequestDetailsScreen> createState() => _RequestDetailsScreenState();
}

class _RequestDetailsScreenState extends State<RequestDetailsScreen> {
  late Future<RequestModel> _future;
  final _dateFmt = DateFormat('yyyy-MM-dd');
  static const _ccy = 'SAR';

  // Status labels
  Map<int, String> _statusById = {};
  // ignore: unused_field
  bool _statusLoading = false;
  // ignore: unused_field
  String? _statusError;

  // My org to know if I’m vendor
  int? _myOrgId;
  // ignore: unused_field
  bool _orgLoading = false;

  // Data bundles
  Future<List<RequestDriverLocation>>? _rdlsFuture;
  int? _rdlsForReqId;

  Future<List<EquipmentDriver>>? _driversFuture;
  int? _driversForEqId;

  late Future<List<Nationality>> _natsFuture;

  // selections
  final Map<int, int> _assignDriverByRdlId = {};
  bool _confirmSubmitting = false;

  @override
  void initState() {
    super.initState();
    _future = api.Api.getRequestById(widget.requestId);
    _natsFuture = api.Api.getNationalities();
    _loadStatusDomain();
    _resolveMyOrg();
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
    // If already 37 and vendor accepted -> no need to confirm
    if (r.isVendorAccept == true && r.statusId == 37) return false;
    return true;
  }

  // ---- data loaders (no setState in build) ----
  Future<List<RequestDriverLocation>> _fetchRDLs(int requestId) async {
    final sql =
        'Select * From RequestDriverLocations Where RequestId = $requestId';
    return api.Api.advanceSearchRequestDriverLocations(sql);
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

  Future<void> _confirmAsVendor(
    RequestModel r,
    List<RequestDriverLocation> rdls,
  ) async {
    // validate selections
    for (final u in rdls) {
      final chosen = _assignDriverByRdlId[u.requestDriverLocationId] ?? 0;
      if (chosen == 0) {
        AppSnack.error(
          context,
          'Assign a driver for unit #${u.requestDriverLocationId}',
        );
        return;
      }
    }

    // merge driver IDs into copies
    final rdlsAssigned = rdls.map((u) {
      final chosen = _assignDriverByRdlId[u.requestDriverLocationId]!;
      return u.copyWith(equipmentDriverId: chosen);
    }).toList();

    setState(() => _confirmSubmitting = true);
    try {
      final ok = await api.Api.updateRequestWithRDLs(
        request: r,
        rdlsAssigned: rdlsAssigned,
      );
      if (!mounted) return;
      if (ok) {
        AppSnack.success(context, 'Request updated');
        setState(() => _future = api.Api.getRequestById(widget.requestId));
      } else {
        AppSnack.error(context, 'Update failed (flag=false)');
      }
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
      appBar: AppBar(title: const Text('Request details')),
      body: FutureBuilder<RequestModel>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return ListView(children: const [ShimmerTile(), ShimmerTile()]);
          }
          if (snap.hasError || !snap.hasData) {
            return const Center(child: Text('Failed to load request'));
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

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Glass(
                radius: 18,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Request #$reqNo',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      if (statusStr.isNotEmpty)
                        Container(
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
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(color: cs.onPrimaryContainer),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Glass(
                radius: 18,
                child: ListTile(
                  title: const Text('Duration'),
                  subtitle: Text('From $from  •  To $to  •  $days day(s)'),
                ),
              ),
              const SizedBox(height: 12),

              Glass(
                radius: 18,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Price breakdown',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 10),
                      _row('Base', _money(base)),
                      if (distance > 0) _row('Distance', _money(distance)),
                      _row('VAT', _money(vat)),
                      const Divider(height: 20),
                      _rowBold('Total', _money(total)),
                      const SizedBox(height: 4),
                      _row('Down payment', _money(dp)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              if (_vendorCanConfirm(r)) ...[
                Glass(
                  radius: 18,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: FutureBuilder<List<dynamic>>(
                      future: Future.wait([
                        _rdlsFuture ?? Future.value(<RequestDriverLocation>[]),
                        _driversFuture ?? Future.value(<EquipmentDriver>[]),
                        _natsFuture,
                      ]),
                      builder: (context, comboSnap) {
                        if (comboSnap.connectionState ==
                            ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: LinearProgressIndicator(),
                          );
                        }
                        if (comboSnap.hasError || !comboSnap.hasData) {
                          return Text(
                            'Could not load assignment data.',
                            style: TextStyle(color: cs.error),
                          );
                        }

                        final rdls =
                            comboSnap.data![0] as List<RequestDriverLocation>;
                        final drivers =
                            comboSnap.data![1] as List<EquipmentDriver>;
                        final nats = comboSnap.data![2] as List<Nationality>;

                        final natNameById = <int, String>{};
                        for (final n in nats) {
                          final id = n.nationalityId;
                          if (id == null) continue;
                          final en = (n.nationalityNameEnglish ?? '').trim();
                          final ar = (n.nationalityNameArabic ?? '').trim();
                          natNameById[id] = en.isNotEmpty
                              ? en
                              : (ar.isNotEmpty ? ar : '#$id');
                        }

                        if (rdls.isEmpty) {
                          return const Text(
                            'No driver locations for this request.',
                          );
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Assign drivers',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 8),
                            for (final u in rdls) ...[
                              _rdlTile(context, u, drivers, natNameById, cs),
                              const SizedBox(height: 10),
                            ],
                            const SizedBox(height: 6),
                            FilledButton.icon(
                              onPressed: _confirmSubmitting
                                  ? null
                                  : () => _confirmAsVendor(r, rdls),
                              icon: _confirmSubmitting
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : const Icon(Icons.check_circle),
                              label: Text(
                                _confirmSubmitting
                                    ? 'Confirming…'
                                    : 'Confirm as vendor',
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          (statusStr.isEmpty ||
                              statusStr.toLowerCase().contains('pending'))
                          ? () {
                              /* your cancel flow if still valid */
                            }
                          : null,
                      child: const Text('Cancel request'),
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
    ColorScheme cs,
  ) {
    final rid = u.requestDriverLocationId;
    final natId = u.driverNationalityId;
    final natName = natNameById[natId] ?? '#$natId';

    final drivers = allDrivers
        .where((d) => (d.driverNationalityId ?? -1) == natId)
        .toList();
    final selected =
        _assignDriverByRdlId[rid] == null || _assignDriverByRdlId[rid] == 0
        ? (u.equipmentDriverId > 0 ? u.equipmentDriverId : null)
        : _assignDriverByRdlId[rid];

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withOpacity(.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Unit #$rid',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text('Nationality: $natName'),
          if (u.dropoffAddress.trim().isNotEmpty)
            Text('Drop-off: ${u.dropoffAddress.trim()}'),
          Text('Coords: ${u.dLatitude}, ${u.dLongitude}'),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            value: selected,
            items: drivers.map((d) {
              final label = (d.driverNameEnglish?.trim().isNotEmpty ?? false)
                  ? d.driverNameEnglish!.trim()
                  : (d.driverNameArabic?.trim().isNotEmpty ?? false)
                  ? d.driverNameArabic!.trim()
                  : 'Driver #${d.equipmentDriverId ?? 0}';
              return DropdownMenuItem<int>(
                value: d.equipmentDriverId,
                child: Text(label),
              );
            }).toList(),
            onChanged: (v) =>
                setState(() => _assignDriverByRdlId[rid] = v ?? 0),
            decoration: const InputDecoration(
              labelText: 'Assign driver (filtered by nationality)',
              prefixIcon: Icon(Icons.badge_outlined),
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

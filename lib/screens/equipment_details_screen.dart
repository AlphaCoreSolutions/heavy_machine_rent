// =================================================================================
// EQUIPMENT DETAILS — Request first; then create RequestDriverLocation per unit.
// UI for Driver Location: nationality, drop-off address, lat, lon (no notes).
// Price shows Per-unit then × Quantity totals.
// =================================================================================

import 'dart:async';
import 'package:flutter/material.dart';

import 'package:heavy_new/core/api/api_handler.dart' as api;
import 'package:heavy_new/core/auth/auth_store.dart';
import 'package:heavy_new/core/models/admin/request.dart';
import 'package:heavy_new/core/models/admin/request_driver_location.dart';
import 'package:heavy_new/core/models/equipment/equipment.dart';
import 'package:heavy_new/core/models/organization/organization_user.dart';
import 'package:heavy_new/core/models/user/nationality.dart';
import 'package:heavy_new/core/utils/model_utils.dart';

import 'package:heavy_new/foundation/formatting/money.dart';
import 'package:heavy_new/foundation/ui/app_icons.dart';
import 'package:heavy_new/foundation/ui/ui_extras.dart';
import 'package:heavy_new/foundation/ui/ui_kit.dart';

import 'package:heavy_new/screens/request_confirmation_screen.dart';

// -------- Per-unit/total price helper --------
class _PriceBreakdown {
  final double base, distance, vat, total, downPayment;
  const _PriceBreakdown({
    required this.base,
    required this.distance,
    required this.vat,
    required this.total,
    required this.downPayment,
  });
}

// -------- Inline form state per unit --------

class _LocUnitForm {
  int? nationalityId;
  final TextEditingController dAddr = TextEditingController();
  final TextEditingController dLat = TextEditingController();
  final TextEditingController dLon = TextEditingController();
  final TextEditingController notes = TextEditingController();

  void dispose() {
    dAddr.dispose();
    dLat.dispose();
    dLon.dispose();
    notes.dispose();
  }

  RequestDriverLocation toEmbedded({required int equipmentId}) {
    return RequestDriverLocation(
      requestDriverLocationId: 0,
      requestId: 0, // embedded create
      equipmentId: equipmentId,
      equipmentNumber: "", // not shown; send empty
      driverNationalityId: nationalityId ?? 0,
      equipmentDriverId: 0, // fixed 0
      otherNotes: notes.text.trim(),
      pickupAddress: " ", // per requirement
      pLongitude: "0",
      pLatitude: "0",
      dropoffAddress: dAddr.text.trim(),
      dLongitude: dLon.text.trim(),
      dLatitude: dLat.text.trim(),
    );
  }
}

class EquipmentDetailsScreen extends StatefulWidget {
  const EquipmentDetailsScreen({super.key, required this.equipmentId});
  final int equipmentId;
  @override
  State<EquipmentDetailsScreen> createState() => _EquipmentDetailsScreenState();
}

class _EquipmentDetailsScreenState extends State<EquipmentDetailsScreen> {
  static const double _vatRate = 0.16;
  static const String _ccy = 'SAR';
  static const int _RESP_DOMAIN_ID = 7;

  late Future<Equipment> _future;
  bool _submitting = false;

  DateTime? _from;
  DateTime? _to;
  int _qty = 1;
  double _expectedKm = 0;

  final _fromCtrl = TextEditingController();
  final _toCtrl = TextEditingController();
  final _kmCtrl = TextEditingController(text: '0');
  final _qtyCtrl = TextEditingController(text: '1');

  bool _respMapLoading = false;
  String? _respMapError;
  final Map<int, String> _respNameById = {};

  List<Nationality> _nats = [];

  final List<_LocUnitForm> _locForms = [];

  @override
  void initState() {
    super.initState();
    _future = api.Api.getEquipmentById(widget.equipmentId);
    _loadResponsibilityNames();
    _loadNationalities();
    _ensureLocForms(1);
  }

  @override
  void dispose() {
    _fromCtrl.dispose();
    _toCtrl.dispose();
    _kmCtrl.dispose();
    _qtyCtrl.dispose();
    for (final f in _locForms) {
      f.dispose();
    }
    super.dispose();
  }

  // ---------- helpers ----------
  String _fmtYmd(DateTime d) => fmtDate(d);
  String _fmt(num? n) => (n ?? 0).toStringAsFixed(2);

  int get _days {
    if (_from == null || _to == null) return 0;
    final diff = _to!.difference(_from!).inDays;
    return diff < 0 ? 0 : (diff + 1);
  }

  int _availableQty(Equipment e) {
    final q = e.quantity ?? 0;
    final r = e.reservedQuantity ?? 0;
    final renting = e.rentQuantity ?? 0;
    final explicitAvail = e.availableQuantity;
    final derived = q - r - renting;
    final v = explicitAvail ?? derived;
    return v < 0 ? 0 : v;
  }

  void _ensureLocForms(int qty) {
    if (qty == _locForms.length) return;
    setState(() {
      if (qty > _locForms.length) {
        for (int i = _locForms.length; i < qty; i++) {
          _locForms.add(_LocUnitForm());
        }
      } else {
        for (int i = _locForms.length - 1; i >= qty; i--) {
          _locForms[i].dispose();
          _locForms.removeAt(i);
        }
      }
    });
  }

  Future<void> _loadNationalities() async {
    try {
      final list = await api.Api.getNationalities();
      if (!mounted) return;
      setState(() => _nats = list);
    } catch (_) {}
  }

  Future<void> _loadResponsibilityNames() async {
    if (_respMapLoading) return;
    setState(() {
      _respMapLoading = true;
      _respMapError = null;
    });
    try {
      final list = await api.Api.getDomainDetailsByDomainId(_RESP_DOMAIN_ID);
      _respNameById
        ..clear()
        ..addEntries(
          list.map((d) {
            final label = (d.detailNameEnglish?.trim().isNotEmpty ?? false)
                ? d.detailNameEnglish!.trim()
                : (d.detailNameArabic?.trim().isNotEmpty ?? false)
                ? d.detailNameArabic!.trim()
                : 'Detail #${d.domainDetailId ?? 0}';
            return MapEntry(d.domainDetailId ?? -1, label);
          }),
        );
      if (mounted) setState(() => _respMapLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _respMapError = 'Could not load responsibility names.';
        _respMapLoading = false;
      });
    }
  }

  // ---------- pricing ----------
  _PriceBreakdown _computePerUnit(Equipment e) {
    if (_days <= 0)
      return const _PriceBreakdown(
        base: 0,
        distance: 0,
        vat: 0,
        total: 0,
        downPayment: 0,
      );
    final perDay = (e.rentPerDayDouble ?? 0).toDouble();
    final base = perDay * _days;
    final perKm = (e.rentPerDistanceDouble ?? 0).toDouble();
    final distance = (e.isDistancePrice == true) ? (_expectedKm * perKm) : 0.0;
    final subtotal = base + distance;
    final vat = subtotal * _vatRate;
    final total = subtotal + vat;
    final dpPerc = (e.downPaymentPerc?.toDouble() ?? 0);
    final down = (dpPerc > 0) ? total * (dpPerc / 100.0) : total * 0.20;
    return _PriceBreakdown(
      base: base,
      distance: distance,
      vat: vat,
      total: total,
      downPayment: down,
    );
  }

  _PriceBreakdown _computeTotal(Equipment e) {
    final u = _computePerUnit(e);
    return _PriceBreakdown(
      base: u.base * _qty,
      distance: u.distance * _qty,
      vat: u.vat * _qty,
      total: u.total * _qty,
      downPayment: u.downPayment * _qty,
    );
  }

  // ---------- date pickers ----------
  void _pickFromDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _from ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (d != null) {
      setState(() {
        _from = d;
        _fromCtrl.text = _fmtYmd(d);
        if (_to != null && _to!.isBefore(_from!)) {
          _to = d;
          _toCtrl.text = _fmtYmd(d);
        }
      });
    }
  }

  void _pickToDate() async {
    final start = _from ?? DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _to ?? start,
      firstDate: start,
      lastDate: start.add(const Duration(days: 365)),
    );
    if (d != null) {
      setState(() {
        _to = d;
        _toCtrl.text = _fmtYmd(d);
      });
    }
  }

  Future<int?> _resolveMyOrganizationId() async {
    final u = AuthStore.instance.user.value;
    if (u == null) return null;
    try {
      final rows = await api.Api.getOrganizationUsers();
      final me = rows.firstWhere(
        (m) => (m.applicationUserId == u.id) && (m.isActive == true),
        orElse: () => OrganizationUser(),
      );
      return me.organizationId;
    } catch (_) {
      return null;
    }
  }

  // ---------- submit (single payload with embedded RDL) ----------
  Future<void> _submit(Equipment e) async {
    if (_from == null || _to == null) {
      AppSnack.error(context, 'Please choose dates');
      return;
    }
    if (!AuthStore.instance.isLoggedIn) {
      AppSnack.info(context, 'Please sign in first');
      return;
    }

    final avail = _availableQty(e);
    if (_qty < 1) {
      AppSnack.error(context, 'Quantity must be at least 1');
      return;
    }
    if (avail > 0 && _qty > avail) {
      AppSnack.error(context, 'Only $avail piece(s) available');
      return;
    }

    // validate forms
    for (int i = 0; i < _locForms.length; i++) {
      final f = _locForms[i];
      if ((f.nationalityId ?? 0) <= 0) {
        AppSnack.error(context, 'Unit ${i + 1}: Select a nationality');
        return;
      }
      if (f.dLat.text.trim().isEmpty || f.dLon.text.trim().isEmpty) {
        AppSnack.error(context, 'Unit ${i + 1}: Drop-off lat/long required');
        return;
      }
    }

    final vendorId = e.vendorId ?? e.organization?.organizationId ?? 0;
    if (vendorId == 0) {
      AppSnack.error(context, 'Vendor not found for this equipment.');
      return;
    }
    final eqId = e.equipmentId ?? 0;

    final meOrg = await _resolveMyOrganizationId();
    if (meOrg == null || meOrg == 0) {
      AppSnack.info(context, 'Please create/activate your Organization first.');
      return;
    }

    _computePerUnit(e);
    final total = _computeTotal(e);
    final subtotalAll = total.base + total.distance;

    // Build embedded RDLs
    final rdl = _locForms.map((f) => f.toEmbedded(equipmentId: eqId)).toList();

    final draft = RequestDraft(
      requestDate: DateTime.now(),
      vendorId: vendorId,
      customerId: meOrg,
      equipmentId: eqId,
      statusId: 36,
      isVendorAccept: false,
      isCustomerAccept: true,
      requestedQuantity: _qty,
      requiredDays: _days, // << exact key name per your spec
      fromDate: _from!,
      toDate: _to!,
      rentPricePerDay: e.rentPerDayDouble ?? 0,
      rentPricePerHour: e.rentPerHourDouble ?? 0,
      isDistancePrice: e.isDistancePrice ?? false,
      rentPricePerDistance: e.rentPerDistanceDouble ?? 0,
      fuelResponsibilityId: e.fuelResponsibilityId ?? 0,
      driverFoodResponsibilityId: e.driverFoodResponsibilityId ?? 0,
      driverHousingResponsibilityId: e.driverHousingResponsibilityId ?? 0,
      driverTransResponsibilityId: e.driverTransResponsibilityId ?? 0,
      equipmentWeight: e.equipmentWeight ?? 0,
      downPayment: total.downPayment,
      totalPrice: subtotalAll,
      vatPrice: total.vat,
      afterVatPrice: total.total,
      driverNationalityId: 0, // root-level remains 0
      driverId: 0,
      requestDriverLocations: rdl,
    );

    setState(() => _submitting = true);
    try {
      final created = await api.Api.addRequest(
        draft,
      ).timeout(const Duration(seconds: 20));
      if (!mounted) return;

      final reqId = created.requestId ?? 0;
      final reqNo = created.requestNo?.toString() ?? reqId.toString();
      final fromStr = created.fromDate ?? _fmtYmd(_from!);
      final toStr = created.toDate ?? _fmtYmd(_to!);

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => RequestConfirmationScreen(
            requestNo: reqNo,
            statusId: created.statusId,
            totalSar:
                (created.afterVatPrice ?? created.totalPrice ?? total.total)
                    .toDouble(),
            from: DateTime.parse(fromStr),
            to: DateTime.parse(toStr),
          ),
        ),
      );
    } catch (err) {
      AppSnack.error(context, '$err');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Equipment details')),
      body: FutureBuilder<Equipment>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return ListView(
              children: const [ShimmerTile(), ShimmerTile(), ShimmerTile()],
            );
          }
          if (snap.hasError || !snap.hasData) {
            return const Center(child: Text('Failed to load equipment'));
          }
          final e = snap.data!;
          final pxUnit = _computePerUnit(e);
          final pxAll = _computeTotal(e);
          final avail = _availableQty(e);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              // Gallery
              _Gallery(
                images: (e.equipmentImages ?? [])
                    .map((i) => i.equipmentPath ?? '')
                    .where((p) => p.isNotEmpty)
                    .toList(),
              ),
              const SizedBox(height: 14),

              // Header
              Glass(
                radius: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (e.category?.detailNameEnglish != null)
                          TonalIconChip(
                            label: e.category!.detailNameEnglish!,
                            icon: AIcon(
                              AppGlyph.truck,
                              color: cs.onPrimaryContainer,
                            ),
                          ),
                        if (e.organization?.nameEnglish != null)
                          TonalIconChip(
                            label: e.organization!.nameEnglish!,
                            icon: AIcon(
                              AppGlyph.organization,
                              color: cs.onPrimaryContainer,
                            ),
                          ),
                        TonalIconChip(
                          label: 'Available: $avail',
                          icon: AIcon(
                            AppGlyph.info,
                            color: cs.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Availability
              Glass(
                radius: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Availability',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: AInput(
                            controller: _fromCtrl,
                            label: 'Rent Date (From)',
                            hint: 'YYYY-MM-DD',
                            glyph: AppGlyph.calendar,
                            readOnly: true,
                            onTap: _pickFromDate,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: AInput(
                            controller: _toCtrl,
                            label: 'Return Date (To)',
                            hint: 'YYYY-MM-DD',
                            glyph: AppGlyph.calendar,
                            readOnly: true,
                            onTap: _pickToDate,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _DaysPill(daysText: '$_days day(s)', cs: cs),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Distance (if applicable)
              if (e.isDistancePrice == true) ...[
                Glass(
                  radius: 20,
                  child: Row(
                    children: [
                      Expanded(
                        child: AInput(
                          controller: _kmCtrl,
                          label: 'Expected distance (km)',
                          hint: 'e.g. 120',
                          glyph: AppGlyph.mapPin,
                          keyboardType: TextInputType.number,
                          onChanged: (v) {
                            final parsed =
                                double.tryParse(v.replaceAll(',', '.')) ?? 0;
                            setState(() => _expectedKm = parsed);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      _MiniPill(
                        text: '$_ccy ${_fmt(e.rentPerDistanceDouble)} / km',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Quantity
              Glass(
                radius: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quantity',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: AInput(
                            controller: _qtyCtrl,
                            label: 'Requested quantity',
                            hint: 'e.g. 1',
                            glyph: AppGlyph.info,
                            keyboardType: TextInputType.number,
                            onChanged: (v) {
                              final n =
                                  int.tryParse(
                                    v.replaceAll(RegExp(r'[^0-9]'), ''),
                                  ) ??
                                  1;
                              final q = n < 1 ? 1 : n;
                              setState(() {
                                _qty = q;
                                _ensureLocForms(q);
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        _MiniPill(text: 'Available: $avail'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Driver Locations (Nationality + dropoff + coords + notes)
              Glass(
                radius: 22,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Driver Locations',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),

                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 240),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      child: Column(
                        key: ValueKey(_locForms.length),
                        children: List.generate(_locForms.length, (i) {
                          final form = _locForms[i];
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: i == _locForms.length - 1 ? 0 : 12,
                            ),
                            child: _LocCard(
                              index: i + 1,
                              form: form,
                              nationalities: _nats,
                              onRemove: _locForms.length > 1
                                  ? () => setState(() {
                                      form.dispose();
                                      _locForms.removeAt(i);
                                      _qty = _locForms.length;
                                      _qtyCtrl.text = '$_qty';
                                    })
                                  : null,
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Price breakdown (per-unit then × qty)
              Glass(
                radius: 22,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Price breakdown',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 10),

                    _rowBold('Per unit', ''),
                    _row(
                      'Base (${Money.format(e.rentPerDayDouble)} × $_days day)',
                      Money.format(pxUnit.base, withCode: true),
                    ),
                    if (e.isDistancePrice == true)
                      _row(
                        'Distance (${_fmt(e.rentPerDistanceDouble)} × $_expectedKm km)',
                        Money.format(pxUnit.distance, withCode: true),
                      ),
                    _row(
                      'VAT ${(_vatRate * 100).toStringAsFixed(0)}%',
                      Money.format(pxUnit.vat),
                    ),
                    _rowBold('Per-unit total', Money.format(pxUnit.total)),

                    const SizedBox(height: 8),
                    _rowBold('× Quantity ($_qty)', ''),
                    _row(
                      'Subtotal',
                      Money.format(pxAll.base + pxAll.distance, withCode: true),
                    ),
                    _row('VAT', Money.format(pxAll.vat)),
                    _rowBold('Total', Money.format(pxAll.total)),
                    _row('Down payment', Money.format(pxAll.downPayment)),

                    const SizedBox(height: 14),
                    BrandButton(
                      onPressed: _submitting ? null : () => _submit(e),
                      icon: _submitting
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
                          : AIcon(
                              AppGlyph.contract,
                              color: Colors.white,
                              selected: true,
                            ),
                      child: Text(
                        _submitting ? 'Submitting…' : 'Submit request',
                      ),
                    ),

                    const SizedBox(height: 6),
                    Text(
                      'Fuel: ${_respNameById[e.fuelResponsibilityId ?? e.fuelResponsibility?.domainDetailId] ?? "—"}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withOpacity(0.7),
                      ),
                    ),
                    if (_respMapError != null) ...[
                      const SizedBox(height: 6),
                      Text(_respMapError!, style: TextStyle(color: cs.error)),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ------ small UI helpers (unchanged from your style) ------
  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(label, maxLines: 2, overflow: TextOverflow.ellipsis),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );

  Widget _rowBold(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    ),
  );
}

class _MiniPill extends StatelessWidget {
  const _MiniPill({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _LocCard extends StatelessWidget {
  const _LocCard({
    required this.index,
    required this.form,
    required this.nationalities,
    this.onRemove,
  });

  final int index;
  final _LocUnitForm form;
  final List<Nationality> nationalities;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '$index',
                  style: TextStyle(
                    color: cs.onPrimaryContainer,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Unit $index',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              if (onRemove != null)
                IconButton.filledTonal(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline),
                ),
            ],
          ),
          const SizedBox(height: 10),

          DropdownButtonFormField<int>(
            value: form.nationalityId,
            decoration: const InputDecoration(
              labelText: 'Driver nationality *',
            ),
            items: nationalities.map((n) {
              final label =
                  (n.nationalityNameEnglish?.trim().isNotEmpty ?? false)
                  ? n.nationalityNameEnglish!.trim()
                  : (n.nationalityNameArabic?.trim().isNotEmpty ?? false)
                  ? n.nationalityNameArabic!.trim()
                  : '#${n.nationalityId ?? 0}';
              return DropdownMenuItem<int>(
                value: n.nationalityId,
                child: Text(label),
              );
            }).toList(),
            onChanged: (v) => form.nationalityId = v,
          ),
          const SizedBox(height: 8),

          AInput(
            controller: form.dAddr,
            label: 'Drop-off address',
            glyph: AppGlyph.mapPin,
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: AInput(
                  controller: form.dLat,
                  label: 'Drop-off latitude *',
                  glyph: AppGlyph.pin,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AInput(
                  controller: form.dLon,
                  label: 'Drop-off longitude *',
                  glyph: AppGlyph.pin,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          AInput(controller: form.notes, label: 'Notes', glyph: AppGlyph.edit),
        ],
      ),
    );
  }
}

// -------- Gallery widget you already had --------
class _Gallery extends StatefulWidget {
  const _Gallery({required this.images});
  final List<String> images;
  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  static const _kMinH = 180.0;
  static const _kMaxH = 420.0;
  static const _kAspect = 16 / 9;

  late final PageController _pc;
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _pc = PageController(initialPage: 0);
    if (widget.images.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (!mounted || widget.images.isEmpty) return;
        final next = (_index + 1) % widget.images.length;
        _pc.animateToPage(
          next,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  @override
  void didUpdateWidget(covariant _Gallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.images.length != widget.images.length) {
      _timer?.cancel();
      if (widget.images.length > 1) {
        _timer = Timer.periodic(const Duration(seconds: 5), (_) {
          if (!mounted || widget.images.isEmpty) return;
          final next = (_index + 1) % widget.images.length;
          _pc.animateToPage(
            next,
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeInOut,
          );
        });
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (widget.images.isEmpty) {
      return Glass(
        radius: 22,
        child: AspectRatio(
          aspectRatio: _kAspect,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: cs.surfaceVariant,
            ),
            child: const Center(child: Text('No images')),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (_, bc) {
        final ideal = bc.maxWidth / _kAspect;
        final height = ideal.clamp(_kMinH, _kMaxH);

        return Column(
          children: [
            Glass(
              radius: 22,
              child: SizedBox(
                height: height,
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: PageView.builder(
                    controller: _pc,
                    itemCount: widget.images.length,
                    physics: const BouncingScrollPhysics(),
                    allowImplicitScrolling: true,
                    onPageChanged: (i) => setState(() => _index = i),
                    itemBuilder: (_, i) {
                      final name = widget.images[i];
                      final cands = api.Api.equipmentImageCandidates(name);
                      return FallbackNetworkImage(
                        candidates: cands,
                        placeholderColor: cs.surfaceVariant,
                        fit: BoxFit.cover,
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (widget.images.length > 1)
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (int i = 0; i < widget.images.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      width: i == _index ? 18 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _index
                            ? cs.primary
                            : cs.outline.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                ],
              ),
          ],
        );
      },
    );
  }
}

class _DaysPill extends StatelessWidget {
  const _DaysPill({required this.daysText, required this.cs});
  final String daysText;
  final ColorScheme cs;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        daysText,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: cs.onPrimaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class MiniPill extends StatelessWidget {
  const MiniPill({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

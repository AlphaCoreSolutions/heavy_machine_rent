// lib/screens/equipment_details_screen.dart
// Localized version (matches the style used in equipment_editor_screen.dart)

import 'dart:async';
import 'package:flutter/material.dart';

import 'package:heavy_new/core/api/api_handler.dart' as api;
import 'package:heavy_new/core/api/envelope.dart';
import 'package:heavy_new/core/auth/auth_store.dart';
import 'package:heavy_new/core/models/admin/request.dart';
import 'package:heavy_new/core/models/admin/request_driver_location.dart';
import 'package:heavy_new/core/models/equipment/equipment.dart';
import 'package:heavy_new/core/models/maps/maps_service.dart';
import 'package:heavy_new/core/models/organization/organization_user.dart';
import 'package:heavy_new/core/models/user/nationality.dart';
import 'package:heavy_new/core/utils/model_utils.dart';

import 'package:heavy_new/foundation/formatting/money.dart';
import 'package:heavy_new/foundation/ui/app_icons.dart';
import 'package:heavy_new/foundation/ui/ui_extras.dart';
import 'package:heavy_new/foundation/ui/ui_kit.dart';
import 'package:heavy_new/screens/auth_profile_screens/phone_auth_screen.dart';
import 'package:heavy_new/screens/auth_profile_screens/profile_screen.dart';
import 'package:heavy_new/screens/organization_screens/organization_hub_screen.dart';

import 'package:heavy_new/screens/request_screens/request_confirmation_screen.dart';
import 'package:heavy_new/l10n/app_localizations.dart';

extension _L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}

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
      equipmentNumber: "",
      driverNationalityId: nationalityId ?? 0,
      equipmentDriverId: 0,
      otherNotes: notes.text.trim(),
      pickupAddress: " ",
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
  // Add to _EquipmentDetailsScreenState:
  bool _sameDropoffForAll = false;
  bool _sameDropoffWired = false; // <— new: are we listening to unit #1?

  void _propagateFirstDropoff() {
    if (!_sameDropoffForAll) return;
    if (_locForms.isEmpty) return;
    final first = _locForms.first;
    final name = first.dAddr.text;
    final lat = first.dLat.text;
    final lon = first.dLon.text;
    if (name.isEmpty || lat.isEmpty || lon.isEmpty) return;

    // Update the rest (this will auto-move their InlineMapPicker via its listeners)
    for (var i = 1; i < _locForms.length; i++) {
      _locForms[i].dAddr.text = name;
      _locForms[i].dLat.text = lat;
      _locForms[i].dLon.text = lon;
    }
  }

  void _wireSameDropoffListeners() {
    if (_sameDropoffWired) return;
    if (_locForms.isEmpty) return;
    final first = _locForms.first;
    first.dAddr.addListener(_propagateFirstDropoff);
    first.dLat.addListener(_propagateFirstDropoff);
    first.dLon.addListener(_propagateFirstDropoff);
    _sameDropoffWired = true;
  }

  void _unwireSameDropoffListeners() {
    if (!_sameDropoffWired) return;
    if (_locForms.isEmpty) {
      _sameDropoffWired = false;
      return;
    }
    final first = _locForms.first;
    first.dAddr.removeListener(_propagateFirstDropoff);
    first.dLat.removeListener(_propagateFirstDropoff);
    first.dLon.removeListener(_propagateFirstDropoff);
    _sameDropoffWired = false;
  }

  void _applySameDropoffFromFirst() {
    if (_locForms.isEmpty) return;
    final first = _locForms.first;
    final name = first.dAddr.text.trim();
    final lat = first.dLat.text.trim();
    final lon = first.dLon.text.trim();
    if (name.isEmpty || lat.isEmpty || lon.isEmpty) return;
    setState(() {
      for (var i = 1; i < _locForms.length; i++) {
        _locForms[i].dAddr.text = name;
        _locForms[i].dLat.text = lat;
        _locForms[i].dLon.text = lon;
      }
    });
  }

  Future<RequestModel?> _hydrateByIdWithRetry(int id) async {
    const delays = <Duration>[
      Duration(milliseconds: 150),
      Duration(milliseconds: 300),
      Duration(milliseconds: 600),
      Duration(milliseconds: 1200),
      Duration(milliseconds: 2400),
    ];
    for (final d in delays) {
      try {
        final m = await api.Api.getRequestById(id);
        if (m.requestId != null && m.requestId! > 0) return m;
      } catch (_) {}
      await Future.delayed(d);
    }
    return null;
  }

  Map<String, dynamic>? _asMap(dynamic any) {
    if (any == null) return null;
    if (any is Map<String, dynamic>) return any;
    if (any is Map) return Map<String, dynamic>.from(any);
    return null;
  }

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

  final Set<int> _allowedNatIds = <int>{};
  bool _loadingAllowedNats = false;
  // ignore: unused_field
  String? _allowedNatError;

  Future<bool> _ensureLoggedInAndReady() async {
    // 1) Login if needed
    if (!AuthStore.instance.isLoggedIn) {
      final ok = await Navigator.of(
        context,
      ).push<bool>(MaterialPageRoute(builder: (_) => const PhoneAuthScreen()));
      if (ok != true || !AuthStore.instance.isLoggedIn) {
        AppSnack.info(context, context.l10n.infoSignInFirst);
        return false;
      }
    }

    // 2) Check “profile completed” (adapt to your real signal if different)
    final user = AuthStore.instance.user.value;
    final isProfileComplete =
        (user?.isCompleted == true) ||
        (user?.fullName?.trim().isNotEmpty ?? false);
    if (!isProfileComplete) {
      AppSnack.info(context, context.l10n.infoCompleteProfileFirst);
      // TODO: Navigate to your "Complete Profile" screen if you have one.
      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
      return false;
    }

    // 3) Check organization presence
    final meOrg = await _resolveMyOrganizationId();
    if (meOrg == null || meOrg == 0) {
      AppSnack.info(context, context.l10n.infoCreateOrgFirst);
      // TODO: push to organization creation if available
      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const OrganizationScreen()));
      return false;
    }

    return true;
  }

  Future<void> _loadAllowedNationalitiesForEquipment() async {
    if (_loadingAllowedNats) return;
    setState(() {
      _loadingAllowedNats = true;
      _allowedNatError = null;
    });
    try {
      final drivers = await api.Api.getEquipmentDriversByEquipmentId(
        widget.equipmentId,
      );
      final ids = drivers
          .map((d) => d.driverNationalityId ?? d.driverNationalityId)
          .where((id) => (id ?? 0) > 0)
          .cast<int>()
          .toSet();

      for (final f in _locForms) {
        if (f.nationalityId != null && !ids.contains(f.nationalityId)) {
          f.nationalityId = null;
        }
      }

      if (!mounted) return;
      setState(() {
        _allowedNatIds
          ..clear()
          ..addAll(ids);
        _loadingAllowedNats = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _allowedNatError = context.l10n.errLoadNatsFailed;
        _loadingAllowedNats = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _future = api.Api.getEquipmentById(widget.equipmentId);
    _loadResponsibilityNames();
    _loadNationalities();
    _loadAllowedNationalitiesForEquipment();
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
        _respMapError = context.l10n.errLoadRespFailed;
        _respMapLoading = false;
      });
    }
  }

  _PriceBreakdown _computePerUnit(Equipment e) {
    if (_days <= 0) {
      return const _PriceBreakdown(
        base: 0,
        distance: 0,
        vat: 0,
        total: 0,
        downPayment: 0,
      );
    }
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

  DateTime _dateOnly(DateTime d) => DateUtils.dateOnly(d);
  DateTime get _today => _dateOnly(DateTime.now());
  DateTime get _tomorrow => _today.add(const Duration(days: 1));

  void _pickFromDate() async {
    // User must start from tomorrow or later
    final first = _tomorrow;

    // If current _from is before 'first', use 'first' as initial
    final init = (_from != null && !_from!.isBefore(first)) ? _from! : first;

    final d = await showDatePicker(
      context: context,
      initialDate: init,
      firstDate: first,
      lastDate: first.add(const Duration(days: 365)),
    );

    if (d != null) {
      final picked = _dateOnly(d);
      setState(() {
        _from = picked;
        _fromCtrl.text = _fmtYmd(picked);

        // Ensure "to" stays valid and never before "from"
        if (_to == null || _to!.isBefore(picked)) {
          _to = picked;
          _toCtrl.text = _fmtYmd(picked);
        }
      });
    }
  }

  void _pickToDate() async {
    // Base lower-bound is tomorrow
    final baseFirst = _tomorrow;

    // If user already picked a "from", to-date cannot be before that
    final mustBeAfter = _from ?? baseFirst;
    final first = !mustBeAfter.isBefore(baseFirst) ? mustBeAfter : baseFirst;

    // Choose a safe initialDate inside bounds
    DateTime init;
    if (_to != null && !_to!.isBefore(first)) {
      init = _to!;
    } else if (_from != null && !_from!.isBefore(first)) {
      init = _from!;
    } else {
      init = first;
    }

    final d = await showDatePicker(
      context: context,
      initialDate: init,
      firstDate: first,
      lastDate: first.add(const Duration(days: 365)),
    );

    if (d != null) {
      final picked = _dateOnly(d);
      setState(() {
        _to = picked;
        _toCtrl.text = _fmtYmd(picked);
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

  Future<void> _submit(Equipment e) async {
    if (_from == null || _to == null) {
      AppSnack.error(context, context.l10n.errChooseDates);
      return;
    }
    if (!AuthStore.instance.isLoggedIn) {
      AppSnack.info(context, context.l10n.infoSignInFirst);
      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const PhoneAuthScreen()));
      return;
    }
    final okReady = await _ensureLoggedInAndReady();
    if (!okReady) return;

    if (_sameDropoffForAll) _applySameDropoffFromFirst();
    final avail = _availableQty(e);
    if (_qty < 1) {
      AppSnack.error(context, context.l10n.errQtyMin);
      return;
    }
    if (avail > 0 && _qty > avail) {
      AppSnack.error(context, context.l10n.errQtyAvail(avail));
      return;
    }

    for (int i = 0; i < _locForms.length; i++) {
      final f = _locForms[i];
      if ((f.nationalityId ?? 0) <= 0) {
        AppSnack.error(context, context.l10n.errUnitSelectNat(i + 1));
        return;
      }
      if (f.dAddr.text.trim().isEmpty) {
        AppSnack.error(
          context,
          context.l10n.errUnitAddress(i + 1),
        ); // add to ARB
        return;
      }
      if (f.dLat.text.trim().isEmpty || f.dLon.text.trim().isEmpty) {
        AppSnack.error(context, context.l10n.errUnitLatLng(i + 1));
        return;
      }
    }

    final vendorId = e.vendorId ?? e.organization?.organizationId ?? 0;
    if (vendorId == 0) {
      AppSnack.error(context, context.l10n.errVendorMissing);
      return;
    }
    final eqId = e.equipmentId ?? 0;

    final meOrg = await _resolveMyOrganizationId();
    if (meOrg == null || meOrg == 0) {
      AppSnack.info(context, context.l10n.infoCreateOrgFirst);
      return;
    }

    final totals = _computeTotal(e);
    final subtotalAll = totals.base + totals.distance;

    final rdl = _locForms.map((f) => f.toEmbedded(equipmentId: eqId)).toList();

    final draft = RequestDraft(
      requestDate: DateTime.now(),
      vendorId: vendorId,
      customerId: meOrg,
      equipmentId: eqId,
      isAgreeTerms: true,
      statusId: 36,
      isVendorAccept: false,
      isCustomerAccept: true,
      requestedQuantity: _qty,
      requiredDays: _days,
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
      downPayment: totals.downPayment,
      totalPrice: subtotalAll,
      vatPrice: totals.vat,
      afterVatPrice: totals.total,
      driverNationalityId: 0,
      driverId: 0,
      requestDriverLocations: rdl,
    );

    setState(() => _submitting = true);
    try {
      final raw = await api.Api.addRequest(
        draft,
      ).timeout(const Duration(seconds: 20));

      if (raw is RequestModel) {
        final created = raw;
        final reqNo =
            created.model?.requestNo?.toString() ??
            (created.model?.requestId != null
                ? '${created.model?.requestId}'
                : '—');
        final fromDt =
            (created.model?.fromDate != null &&
                created.model!.fromDate!.isNotEmpty)
            ? DateTime.tryParse(created.model!.fromDate!) ?? _from!
            : _from!;
        final toDt =
            (created.model?.toDate != null && created.model!.toDate!.isNotEmpty)
            ? DateTime.tryParse(created.model!.toDate!) ?? _to!
            : _to!;
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => RequestConfirmationScreen(
              requestNo: reqNo,
              statusId: created.model?.statusId ?? 36,
              totalSar:
                  (created.model?.afterVatPrice ??
                          created.model?.totalPrice ??
                          totals.total)
                      .toDouble(),
              from: fromDt,
              to: toDt,
            ),
          ),
        );
        return;
      }

      if (raw is! RequestModel && raw is! ApiEnvelope) {
        final maybeModel = (raw as dynamic).model;
        if (maybeModel is RequestModel) {
          final created = maybeModel;
          final reqNo =
              created.requestNo?.toString() ??
              (created.requestId != null ? '${created.requestId}' : '—');
          final fromDt =
              (created.fromDate != null && created.fromDate!.isNotEmpty)
              ? DateTime.tryParse(created.fromDate!) ?? _from!
              : _from!;
          final toDt = (created.toDate != null && created.toDate!.isNotEmpty)
              ? DateTime.tryParse(created.toDate!) ?? _to!
              : _to!;
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => RequestConfirmationScreen(
                requestNo: reqNo,
                statusId: created.statusId ?? 36,
                totalSar:
                    (created.afterVatPrice ??
                            created.totalPrice ??
                            totals.total)
                        .toDouble(),
                from: fromDt,
                to: toDt,
              ),
            ),
          );
          return;
        }
      }

      final env = (raw is ApiEnvelope) ? raw : ApiEnvelope.fromAny(raw);
      if ((env as ApiEnvelope).flag == false) {
        final msg = (env).message?.trim().isNotEmpty == true
            ? (env).message!.trim()
            : context.l10n.errRequestAddFailed;
        AppSnack.error(context, msg);
        return;
      }

      final mapData = _asMap(env.data);
      if (mapData != null && mapData.isNotEmpty) {
        final created = RequestModel.fromJson(mapData);
        final reqNo =
            created.requestNo?.toString() ??
            (created.requestId != null ? '${created.requestId}' : '—');
        final fromDt =
            (created.fromDate != null && created.fromDate!.isNotEmpty)
            ? DateTime.tryParse(created.fromDate!) ?? _from!
            : _from!;
        final toDt = (created.toDate != null && created.toDate!.isNotEmpty)
            ? DateTime.tryParse(created.toDate!) ?? _to!
            : _to!;
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => RequestConfirmationScreen(
              requestNo: reqNo,
              statusId: created.statusId ?? 36,
              totalSar:
                  (created.afterVatPrice ?? created.totalPrice ?? totals.total)
                      .toDouble(),
              from: fromDt,
              to: toDt,
            ),
          ),
        );
        return;
      }

      final id = env.modelId ?? 0;
      if (id > 0) {
        final created = await _hydrateByIdWithRetry(id);
        if (created != null) {
          final reqNo = created.requestNo?.toString() ?? '$id';
          final fromDt =
              (created.fromDate != null && created.fromDate!.isNotEmpty)
              ? DateTime.tryParse(created.fromDate!) ?? _from!
              : _from!;
          final toDt = (created.toDate != null && created.toDate!.isNotEmpty)
              ? DateTime.tryParse(created.toDate!) ?? _to!
              : _to!;
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => RequestConfirmationScreen(
                requestNo: reqNo,
                statusId: created.statusId ?? 36,
                totalSar:
                    (created.afterVatPrice ??
                            created.totalPrice ??
                            totals.total)
                        .toDouble(),
                from: fromDt,
                to: toDt,
              ),
            ),
          );
          return;
        }
      }

      AppSnack.success(
        context,
        env.message?.trim().isNotEmpty == true
            ? env.message!.trim()
            : context.l10n.requestCreated,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => RequestConfirmationScreen(
            requestNo: '—',
            statusId: 36,
            totalSar: totals.total,
            from: _from!,
            to: _to!,
          ),
        ),
      );
    } catch (err) {
      if (!mounted) return;
      AppSnack.error(context, '$err');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final baseTheme = Theme.of(context);
    final compactTextTheme = baseTheme.textTheme.apply(
      fontSizeFactor: 0.92,
    ); // ~8% smaller

    final cs = baseTheme.colorScheme;
    return Theme(
      data: baseTheme.copyWith(textTheme: compactTextTheme),
      child: Scaffold(
        appBar: AppBar(title: Text(context.l10n.equipDetailsTitle)),
        body: FutureBuilder<Equipment>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return ListView(
                children: const [ShimmerTile(), ShimmerTile(), ShimmerTile()],
              );
            }
            if (snap.hasError || !snap.hasData) {
              return Center(child: Text(context.l10n.msgFailedLoadEquipment));
            }
            final e = snap.data!;
            final pxUnit = _computePerUnit(e);
            final pxAll = _computeTotal(e);
            final avail = _availableQty(e);

            return ListView(
              padding: const EdgeInsets.fromLTRB(3, 12, 3, 28),
              children: [
                _Gallery(
                  images: (e.equipmentImages ?? [])
                      .map((i) => i.equipmentPath ?? '')
                      .where((p) => p.isNotEmpty)
                      .toList(),
                ),
                const SizedBox(height: 14),

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
                            label: context.l10n.miniAvailable(avail),
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

                Glass(
                  radius: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.labelAvailability,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: AInput(
                              controller: _fromCtrl,
                              label: context.l10n.labelRentFrom,
                              hint: context.l10n.hintYyyyMmDd,
                              glyph: AppGlyph.calendar,
                              readOnly: true,
                              onTap: _pickFromDate,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: AInput(
                              controller: _toCtrl,
                              label: context.l10n.labelReturnTo,
                              hint: context.l10n.hintYyyyMmDd,
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
                        child: _DaysPill(
                          daysText: context.l10n.pillDays(_days),
                          cs: cs,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                if (e.isDistancePrice == true) ...[
                  Glass(
                    radius: 20,
                    child: Row(
                      children: [
                        Expanded(
                          child: AInput(
                            controller: _kmCtrl,
                            label: context.l10n.labelExpectedKm,
                            hint: '120',
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
                          text: context.l10n.miniPricePerKm(
                            _ccy,
                            _fmt(e.rentPerDistanceDouble),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                Glass(
                  radius: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.labelQuantity,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: AInput(
                              controller: _qtyCtrl,
                              label: context.l10n.labelRequestedQty,
                              hint: '1',
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
                                  if (_sameDropoffForAll) {
                                    _unwireSameDropoffListeners(); // detach from old #1 (if any)
                                    _wireSameDropoffListeners(); // attach to new #1
                                    _applySameDropoffFromFirst(); // keep others in sync
                                  }
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          _MiniPill(text: context.l10n.miniAvailable(avail)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                Glass(
                  radius: 22,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.labelDriverLocations,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      // Inside the "Driver Locations" Glass, before AnimatedSwitcher:
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _sameDropoffForAll,
                        onChanged: (v) {
                          final enabled = v ?? false;
                          setState(() => _sameDropoffForAll = enabled);
                          if (enabled) {
                            _wireSameDropoffListeners();
                            _applySameDropoffFromFirst(); // one-shot sync now…
                            _propagateFirstDropoff(); // …and continue syncing live
                          } else {
                            _unwireSameDropoffListeners();
                          }
                        },

                        title: Text(
                          context.l10n.sameDropoffForAll,
                        ), // add to ARB
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      const SizedBox(height: 8),

                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 240),
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        child: Column(
                          key: ValueKey(_locForms.length),
                          children: [
                            if (_loadingAllowedNats) ...[
                              const SizedBox(height: 8),

                              Text(
                                context.l10n.msgLoadingNats,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ] else if (_allowedNatIds.isEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                context.l10n.msgNoNats,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                            ...List.generate(_locForms.length, (i) {
                              final form = _locForms[i];

                              final allowedNats = _nats.where((n) {
                                final id = n.nationalityId ?? 0;
                                return _allowedNatIds.contains(id);
                              }).toList();

                              return Padding(
                                padding: EdgeInsets.only(
                                  bottom: i == _locForms.length - 1 ? 0 : 12,
                                ),
                                child: _LocCard(
                                  index: i + 1,
                                  form: form,
                                  nationalities: allowedNats,
                                  onRemove: _locForms.length > 1
                                      ? () => setState(() {
                                          final removedWasFirst = (i == 0);
                                          _locForms[i].dispose();
                                          _locForms.removeAt(i);
                                          _qty = _locForms.length;
                                          _qtyCtrl.text = '$_qty';

                                          if (_sameDropoffForAll) {
                                            // If first changed, rewire to the new first.
                                            if (removedWasFirst) {
                                              _unwireSameDropoffListeners();
                                              _wireSameDropoffListeners();
                                            }
                                            _applySameDropoffFromFirst();
                                          }
                                        })
                                      : null,
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                Glass(
                  radius: 22,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.labelPriceBreakdown,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 10),

                      _rowBold(context.l10n.rowPerUnit, ''),
                      _row(
                        context.l10n.rowBase(
                          Money.format(e.rentPerDayDouble),
                          _days.toString(),
                        ),
                        Money.format(pxUnit.base, withCode: true),
                      ),
                      if (e.isDistancePrice == true)
                        _row(
                          context.l10n.rowDistance(
                            _fmt(e.rentPerDistanceDouble),
                            _expectedKm.toStringAsFixed(0),
                          ),
                          Money.format(pxUnit.distance, withCode: true),
                        ),
                      _row(
                        context.l10n.rowVat(
                          (_vatRate * 100).toStringAsFixed(0),
                        ),
                        Money.format(pxUnit.vat),
                      ),
                      _rowBold(
                        context.l10n.rowPerUnitTotal,
                        Money.format(pxUnit.total),
                      ),

                      const SizedBox(height: 8),
                      _rowBold(context.l10n.rowQtyTimes(_qty), ''),
                      _row(
                        context.l10n.rowSubtotal,
                        Money.format(
                          pxAll.base + pxAll.distance,
                          withCode: true,
                        ),
                      ),
                      _row(context.l10n.rowVatOnly, Money.format(pxAll.vat)),
                      _rowBold(
                        context.l10n.rowTotal,
                        Money.format(pxAll.total),
                      ),
                      _row(
                        context.l10n.rowDownPayment,
                        Money.format(pxAll.downPayment),
                      ),

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
                          _submitting
                              ? context.l10n.btnSubmitting
                              : context.l10n.btnSubmit,
                        ),
                      ),

                      const SizedBox(height: 6),
                      Text(
                        context.l10n.rowFuel(
                          _respNameById[e.fuelResponsibilityId ??
                                  e.fuelResponsibility?.domainDetailId] ??
                              "—",
                        ),
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
      ),
    );
  }

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
  _LocCard({
    required this.index,
    required this.form,
    required this.nationalities,
    this.onRemove,
  });

  final int index;
  final _LocUnitForm form;
  final List<Nationality> nationalities;
  final VoidCallback? onRemove;
  bool get hasOptions => nationalities.isNotEmpty;

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
                context.l10n.unitIndex(index), // e.g., "Unit {index}"
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
            value: hasOptions ? form.nationalityId : null,
            decoration: InputDecoration(
              labelText: context.l10n.labelDriverNationality,
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
            onChanged: hasOptions ? (v) => form.nationalityId = v : null,
          ),

          const SizedBox(height: 12),

          // Address input (shows the chosen place name, not coordinates)
          AInput(
            controller: form.dAddr,
            label: context.l10n.labelDropoffAddress,
            glyph: AppGlyph.mapPin,
          ),

          const SizedBox(height: 10),

          // Inline map + search with autocomplete
          InlineMapPicker(
            latCtrl: form.dLat,
            lonCtrl: form.dLon,
            addrCtrl: form.dAddr,
            googleApiKey: 'AIzaSyDNIu49-9h5zA8KrVrJpTdTe42MZJwlrbw',
            height: 240,
            onChanged: () {},
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: form.dLat,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: context.l10n.labelDropoffLat,
                    suffixIcon: const Icon(Icons.pin_drop_outlined),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: form.dLon,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: context.l10n.labelDropoffLon,
                    suffixIcon: const Icon(Icons.pin_drop_outlined),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          AInput(
            controller: form.notes,
            label: context.l10n.labelNotes,
            glyph: AppGlyph.edit,
          ),
        ],
      ),
    );
  }
}

// -------- Gallery widget (unchanged except strings already neutral) --------
class _Gallery extends StatefulWidget {
  const _Gallery({required this.images});
  final List<String> images;
  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  static const _kMinH = 170.0; // ↓ a bit
  static const _kMaxH = 400.0; // ↓ a bit
  static const _kAspect = 12 / 9.6; // slightly wider look
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
            child: Center(child: Text(context.l10n.noImages)),
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

// lib/screens/contract_details_screen.dart
import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:Ajjara/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

import 'package:Ajjara/core/api/api_handler.dart' as api;
import 'package:Ajjara/foundation/ui/ui_extras.dart';
import 'package:Ajjara/foundation/ui/ui_kit.dart';

import 'package:Ajjara/core/models/contracts/contract.dart';
import 'package:Ajjara/core/models/contracts/contract_slice.dart';
import 'package:Ajjara/core/models/contracts/contract_slice_sheet.dart';
import 'package:Ajjara/core/models/admin/request.dart';
import 'package:Ajjara/core/models/equipment/equipment.dart';
import 'package:Ajjara/core/models/organization/organization_summary.dart';
import 'package:Ajjara/core/models/admin/request_driver_location.dart';
import 'package:Ajjara/core/models/user/nationality.dart';

import 'contract_sheet_screen.dart';

extension _L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}

class ContractDetailsScreen extends StatefulWidget {
  const ContractDetailsScreen({super.key, required this.contractId});
  final int contractId;

  @override
  State<ContractDetailsScreen> createState() => _ContractDetailsScreenState();
}

class _ContractDetailsScreenState extends State<ContractDetailsScreen> {
  late Future<_Bundle> _future;
  final _money = NumberFormat.currency(symbol: 'SAR ', decimalDigits: 2);

  bool _seeding = false;

  // Domain 7 responsibilities map (DomainDetailId -> Label)
  final Map<int, String> _respNameById = {};
  bool _respLoading = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
    _loadResponsibilities(); // domain 7 once
  }

  Future<void> _loadResponsibilities() async {
    if (_respLoading) return;
    setState(() => _respLoading = true);
    try {
      final list = await api.Api.getDomainDetailsByDomainId(7);
      _respNameById
        ..clear()
        ..addEntries(
          list.map((d) {
            final label = (d.detailNameEnglish?.trim().isNotEmpty ?? false)
                ? d.detailNameEnglish!.trim()
                : (d.detailNameArabic?.trim().isNotEmpty ?? false)
                ? d.detailNameArabic!.trim()
                : context.l10n.detailHash('${d.domainDetailId ?? 0}');
            return MapEntry(d.domainDetailId ?? -1, label);
          }),
        );
    } finally {
      if (mounted) setState(() => _respLoading = false);
    }
  }

  Future<_Bundle> _load() async {
    // Core Models
    final contract = await api.Api.getContractById(widget.contractId);
    final req = await api.Api.getRequestById(contract.requestId ?? 0);
    final eq = await api.Api.getEquipmentById(contract.equipmentId ?? 0);

    // Organizations: explicit API fetch by id (as requested)
    final vendorId =
        req.vendorId ?? req.vendor?.organizationId ?? contract.vendorId ?? 0;
    final customerId =
        req.customerId ??
        req.customer?.organizationId ??
        contract.customerId ??
        0;

    final vendorOrg = vendorId > 0
        ? await api.Api.getOrganizationById(vendorId)
        : null;
    final customerOrg = customerId > 0
        ? await api.Api.getOrganizationById(customerId)
        : null;

    // Aux data for rich view
    final drivers = await api.Api.getEquipmentDriversByEquipmentId(
      contract.equipmentId ?? 0,
    );
    final nats = await api.Api.getNationalities();
    final terms = await api.Api.getEquipmentTermsByEquipmentId(
      eq.equipmentId ?? 0,
    );

    // RDLs (units) via AdvanceSearch (split load)
    final rdlQuery =
        'select * from RequestDriverLocations where RequestId = ${req.requestId ?? 0}';
    final rdls = await api.Api.searchRequestDriverLocation(rdlQuery);

    // Seed slices/sheets once if absent
    await _seedIfNeeded(contract, req);

    return _Bundle(
      contract: contract,
      request: req,
      equipment: eq,
      vendorOrg: vendorOrg,
      customerOrg: customerOrg,
      drivers: drivers,
      rdls: rdls,
      nationalities: nats,
      terms: terms,
    );
  }

  Future<void> _seedIfNeeded(ContractModel c, RequestModel r) async {
    setState(() => _seeding = true);
    try {
      final existing = await api.Api.getSlicesForContract(c.contractId ?? 0);
      if (existing.isNotEmpty) return;

      // Build range
      final from = (c.fromDate?.isNotEmpty == true)
          ? c.fromDate!
          : (r.fromDate ?? '');
      final to = (c.toDate?.isNotEmpty == true) ? c.toDate! : (r.toDate ?? '');

      final startIso = (from.isNotEmpty)
          ? '${from.split('T').first}T00:00:00.000Z'
          : DateTime.now().toUtc().toIso8601String();
      final endIso = (to.isNotEmpty)
          ? '${to.split('T').first}T23:59:59.000Z'
          : DateTime.now().toUtc().toIso8601String();

      // Base slice
      final slice = await api.Api.addContractSlice(
        ContractSlice(
          contractSliceId: 0,
          contractId: c.contractId,
          requestId: c.requestId,
          equipmentId: c.equipmentId,
          requestDriverLocationId: 0,
          driverNationalityId: r.driverNationalityId ?? 0,
          driverId: c.driverId ?? r.driverId ?? 0,
          isCompleted: false,
          startDateTime: startIso,
          endDateTime: endIso,
          isRecived: false,
        ),
      );

      // Seed one sheet (the Contract Sheet screen will expand per-day × qty)
      final firstDate = (from.isNotEmpty)
          ? from.split('T').first
          : DateTime.now().toUtc().toIso8601String().split('T').first;
      await api.Api.addContractSliceSheet(
        ContractSliceSheet(
          contractSliceSheetId: 0,
          contractSliceId: slice.contractSliceId,
          sliceDate: firstDate,
          dailyHours: 0,
          actualHours: 0,
          overHours: 0,
          totalHours: 0,
          customerUserId: 0,
          vendorUserId: 0,
          isCustomerAccept: false,
          isVendorAccept: false,
          customerNote: '',
          vendorNote: '',
        ),
      );
    } catch (e) {
      dev.log('Slice seed skipped: $e', name: 'ContractDetails');
    } finally {
      if (mounted) setState(() => _seeding = false);
    }
  }

  // Helpers
  String _ymd(String? iso) =>
      (iso == null || iso.isEmpty) ? '—' : iso.split('T').first;
  String _currency(num? n) => _money.format((n ?? 0).toDouble());

  // Resolve a responsibility row using Domain 7
  // IDs-only mapping via Domain 7; no fallbacks from equipment model
  (String, String) _respRow(String title, int? id) {
    if (id == null || id == 0) return (title, '—');
    final label = _respNameById[id] ?? '—';
    return (title, context.l10n.responsibilityValue(label, '$id'));
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withOpacity(.25),
      appBar: AppBar(
        title: Text(context.l10n.contractTitle),
        actions: [
          IconButton(
            tooltip: context.l10n.actionOpenContractSheet,
            onPressed: () async {
              final b = await _future;
              final slices = await api.Api.getSlicesForContract(
                b.contract.contractId ?? 0,
              );
              final slice = slices.isNotEmpty ? slices.first : null;
              if (!mounted) return;
              if (slice == null) {
                AppSnack.error(context, context.l10n.errorNoContractSlice);
                return;
              }
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ContractSheetScreen(
                    contract: b.contract,
                    request: b.request,
                    equipment: b.equipment,
                    slice: slice,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.description),
          ),
          IconButton(
            tooltip: context.l10n.actionPrint,
            onPressed: () {
              AppSnack.info(context, context.l10n.printingStubMessage);
            },
            icon: const Icon(Icons.print),
          ),
          IconButton(
            tooltip: context.l10n.actionRefresh,
            onPressed: () => setState(() => _future = _load()),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<_Bundle>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: const [ShimmerTile(), ShimmerTile(), ShimmerTile()],
            );
          }
          if (snap.hasError || !snap.hasData) {
            return Center(
              child: Text(context.l10n.errorFailedToLoadContractDetails),
            );
          }

          final b = snap.data!;
          final c = b.contract;
          final r = b.request;
          final e = b.equipment;

          // map nationalities and drivers
          final natNameById = <int, String>{
            for (final n in b.nationalities)
              if (n.nationalityId != null)
                n.nationalityId!:
                    ((n.nationalityNameEnglish ?? '').trim().isNotEmpty)
                    ? n.nationalityNameEnglish!.trim()
                    : ((n.nationalityNameArabic ?? '').trim().isNotEmpty
                          ? n.nationalityNameArabic!.trim()
                          : '#${n.nationalityId}'),
          };
          final driverNameById = <int, String>{
            for (final d in b.drivers)
              if (d.equipmentDriverId != null)
                d.equipmentDriverId!:
                    ((d.driverNameEnglish ?? '').trim().isNotEmpty)
                    ? d.driverNameEnglish!.trim()
                    : ((d.driverNameArabic ?? '').trim().isNotEmpty
                          ? d.driverNameArabic!.trim()
                          : 'Driver #${d.equipmentDriverId}'),
          };

          // Organization names (from Organization/<id>)
          String partyName(OrganizationSummary? o) {
            final en = (o?.nameEnglish ?? '').trim();
            final ar = (o?.nameArabic ?? '').trim();
            return en.isNotEmpty ? en : (ar.isNotEmpty ? ar : '—');
          }

          final vendorName = partyName(b.vendorOrg);
          final customerName = partyName(b.customerOrg);

          final pageTextColor = Colors.black87;

          return LayoutBuilder(
            builder: (context, bc) {
              final pageWidth = (bc.maxWidth < 900) ? bc.maxWidth : 900.0;

              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                  child: Container(
                    width: pageWidth,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                          color: Colors.black.withOpacity(0.08),
                        ),
                      ],
                      border: Border.all(color: cs.outlineVariant),
                    ),
                    child: DefaultTextStyle(
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: pageTextColor,
                        height: 1.25,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(28, 28, 28, 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_seeding)
                              const Padding(
                                padding: EdgeInsets.only(bottom: 8),
                                child: LinearProgressIndicator(),
                              ),

                            // Header with centered local logo
                            Column(
                              children: [
                                _LogoBox(),
                                const SizedBox(height: 12),
                                Text(
                                  context.l10n.rentalAgreementHeader,
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(
                                        color: pageTextColor,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${c.contractNo ?? c.contractId ?? '—'}',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        color: pageTextColor.withOpacity(.75),
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            const Divider(height: 24),

                            // Parties
                            _SectionHeader(
                              context.l10n.sectionParties,
                              color: pageTextColor,
                            ),
                            _KeyValueGrid(
                              color: pageTextColor,
                              rows: [
                                (
                                  context.l10n.vendorLabel,
                                  partyName(b.vendorOrg),
                                ),
                                (
                                  context.l10n.customerLabel,
                                  partyName(b.customerOrg),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            _KeyValueGrid(
                              color: pageTextColor,
                              rows: [
                                (
                                  context.l10n.fromDate,
                                  _ymd(c.fromDate) == '—'
                                      ? _ymd(r.fromDate)
                                      : _ymd(c.fromDate),
                                ),
                                (
                                  context.l10n.toDate,
                                  _ymd(c.toDate) == '—'
                                      ? _ymd(r.toDate)
                                      : _ymd(c.toDate),
                                ),
                              ],
                            ),

                            const SizedBox(height: 22),
                            _SectionHeader(
                              context.l10n.sectionRequestSummary,
                              color: pageTextColor,
                            ),
                            _KeyValueGrid(
                              color: pageTextColor,
                              rows: [
                                (
                                  context.l10n.requestNumberLabel,
                                  '${r.requestNo ?? r.requestId ?? '—'}',
                                ),
                                (
                                  context.l10n.quantityLabel,
                                  '${r.requestedQuantity ?? 0}',
                                ), // ← requestedQuantity from request
                                (
                                  context.l10n.daysLabel,
                                  '${r.numberDays ?? 0}',
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _KeyValueGrid(
                              color: pageTextColor,
                              rows: [
                                (
                                  context.l10n.rentPerDayLabel,
                                  _currency(r.rentPricePerDay),
                                ),
                                // (Removed distance pricing & rent/km as requested)
                                (
                                  context.l10n.subtotalLabel,
                                  _currency(r.totalPrice ?? 0),
                                ),
                                (
                                  context.l10n.vatLabel,
                                  _currency(r.vatPrice ?? 0),
                                ),
                                (
                                  context.l10n.totalLabel,
                                  _currency(r.afterVatPrice ?? r.totalPrice),
                                ),
                                (
                                  context.l10n.downPaymentLabel,
                                  _currency(r.downPayment),
                                ),
                              ],
                            ),

                            const SizedBox(height: 22),
                            _SectionHeader(
                              context.l10n.sectionEquipment,
                              color: pageTextColor,
                            ),
                            _KeyValueGrid(
                              color: pageTextColor,
                              rows: [
                                (context.l10n.titleLabel, e.title),
                                (
                                  context.l10n.categoryLabel,
                                  e.category?.detailNameEnglish ??
                                      e.category?.detailNameArabic ??
                                      '—',
                                ),
                                // (Removed weight as requested)
                              ],
                            ),

                            const SizedBox(height: 22),
                            _SectionHeader(
                              context.l10n.sectionResponsibilities,
                              color: pageTextColor,
                            ),
                            if (_respLoading)
                              const Padding(
                                padding: EdgeInsets.only(bottom: 8),
                                child: LinearProgressIndicator(),
                              )
                            else
                              _KeyValueGrid(
                                color: pageTextColor,
                                rows: [
                                  _respRow(
                                    context.l10n.fuelResponsibilityLabel,
                                    e.fuelResponsibilityId,
                                  ),
                                  _respRow(
                                    context.l10n.driverFoodLabel,
                                    e.driverFoodResponsibilityId,
                                  ),
                                  _respRow(
                                    context.l10n.driverHousingLabel,
                                    e.driverHousingResponsibilityId,
                                  ),
                                  _respRow(
                                    context.l10n.driverTransportLabel,
                                    e.driverTransResponsibilityId,
                                  ),
                                ],
                              ),

                            const SizedBox(height: 22),
                            _SectionHeader(
                              context.l10n.sectionTerms,
                              color: pageTextColor,
                            ),
                            _BulletBox(
                              color: pageTextColor,
                              items: [
                                context.l10n.termDownPayment,
                                context.l10n.termManufacturerGuidelines,
                                context.l10n.termCustomerSiteAccess,
                                context.l10n.termLiability,
                              ],
                            ),
                            if (b.terms.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text(
                                context.l10n.sectionTerms,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: pageTextColor,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              const SizedBox(height: 6),
                              _BulletBox(
                                color: pageTextColor,
                                items: (() {
                                  final list = [...b.terms];
                                  list.sort(
                                    (a, b) => (a.orderBy ?? 0).compareTo(
                                      b.orderBy ?? 0,
                                    ),
                                  );
                                  return list
                                      .map((t) {
                                        final en = (t.descEnglish ?? '').trim();
                                        final ar = (t.descArabic ?? '').trim();
                                        return en.isNotEmpty
                                            ? en
                                            : (ar.isNotEmpty ? ar : '');
                                      })
                                      .where((s) => s.isNotEmpty)
                                      .toList();
                                })(),
                              ),
                            ],

                            const SizedBox(height: 22),
                            _SectionHeader(
                              context.l10n.sectionDriverAssignments,
                              color: pageTextColor,
                            ),
                            if (b.rdls.isEmpty)
                              Text(
                                context.l10n.noDriverLocations,
                                style: TextStyle(color: Colors.red.shade700),
                              )
                            else
                              Column(
                                children: [
                                  for (final u in b.rdls)
                                    _DriverUnitCard(
                                      color: pageTextColor,
                                      unitId: u.requestDriverLocationId,
                                      nationality:
                                          natNameById[u.driverNationalityId] ??
                                          '—',
                                      dropoff: (u.dropoffAddress).trim().isEmpty
                                          ? '—'
                                          : u.dropoffAddress.trim(),
                                      coords:
                                          '${u.dLatitude}${(u.dLatitude.isNotEmpty) ? ', ' : ''}${u.dLongitude}',
                                      assignedDriver:
                                          driverNameById[u.equipmentDriverId] ??
                                          '—',
                                    ),
                                ],
                              ),

                            const SizedBox(height: 26),
                            _SectionHeader(
                              context.l10n.sectionSignatures,
                              color: pageTextColor,
                            ),
                            const SizedBox(height: 10),
                            _SignatureLines(
                              color: pageTextColor,
                              vendorName: vendorName,
                              customerName: customerName,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ----------------- Presentational widgets -----------------

class _LogoBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        SizedBox(
          height: 150,
          child: Image.asset(
            'lib/assets/alogo.png',
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Container(
              height: 70,
              width: 120,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                context.l10n.companyLogo,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color color;
  const _SectionHeader(this.title, {required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }
}

class _KeyValueGrid extends StatelessWidget {
  final List<(String, String)> rows;
  final Color color;
  const _KeyValueGrid({required this.rows, required this.color});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Table(
      columnWidths: const {
        0: FractionColumnWidth(0.35),
        1: FractionColumnWidth(0.65),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: rows
          .map(
            (e) => TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    e.$1,
                    style: t.textTheme.bodyMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    e.$2,
                    style: t.textTheme.bodyMedium?.copyWith(color: color),
                  ),
                ),
              ],
            ),
          )
          .toList(),
    );
  }
}

class _BulletBox extends StatelessWidget {
  final List<String> items;
  final Color color;
  const _BulletBox({required this.items, required this.color});
  @override
  Widget build(BuildContext context) {
    final border = Theme.of(context).colorScheme.outlineVariant;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items
            .map(
              (s) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('•  ', style: TextStyle(color: color)),
                    Expanded(
                      child: Text(s, style: TextStyle(color: color)),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _DriverUnitCard extends StatelessWidget {
  final int unitId;
  final String nationality;
  final String dropoff;
  final String coords;
  final String assignedDriver;
  final Color color;

  const _DriverUnitCard({
    required this.unitId,
    required this.nationality,
    required this.dropoff,
    required this.coords,
    required this.assignedDriver,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withOpacity(.5)),
      ),
      padding: const EdgeInsets.all(12),
      child: DefaultTextStyle(
        style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: color),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${context.l10n.unitLabel} #$unitId',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            _kv(context.l10n.requestedNationalityLabel, nationality, color),
            if (dropoff.isNotEmpty && dropoff != '—')
              _kv(context.l10n.dropoffLabel, dropoff, color),
            if (coords.trim().isNotEmpty)
              _kv(context.l10n.coordsLabel, coords, color),
            _kv(context.l10n.assignedDriverLabel, assignedDriver, color),
          ],
        ),
      ),
    );
  }

  Widget _kv(String k, String v, Color color) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        SizedBox(
          width: 170,
          child: Text(
            k,
            style: TextStyle(fontWeight: FontWeight.w700, color: color),
          ),
        ),
        Expanded(
          child: Text(v, style: TextStyle(color: color)),
        ),
      ],
    ),
  );
}

class _SignatureLines extends StatelessWidget {
  final String vendorName;
  final String customerName;
  final Color color;
  const _SignatureLines({
    required this.vendorName,
    required this.customerName,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              const SizedBox(height: 36),
              Container(height: 1.2, color: cs.outline),
              const SizedBox(height: 6),
              Text(
                '${context.l10n.vendorLabel}: $vendorName',
                style: TextStyle(color: color),
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            children: [
              const SizedBox(height: 36),
              Container(height: 1.2, color: cs.outline),
              const SizedBox(height: 6),
              Text(
                '${context.l10n.customerLabel}: $customerName',
                style: TextStyle(color: color),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Bundle {
  final ContractModel contract;
  final RequestModel request;
  final Equipment equipment;
  final OrganizationSummary? vendorOrg;
  final OrganizationSummary? customerOrg;
  final List<EquipmentDriver> drivers;
  final List<RequestDriverLocation> rdls;
  final List<Nationality> nationalities;
  final List<EquipmentTerm> terms;

  _Bundle({
    required this.contract,
    required this.request,
    required this.equipment,
    required this.vendorOrg,
    required this.customerOrg,
    required this.drivers,
    required this.rdls,
    required this.nationalities,
    required this.terms,
  });
}

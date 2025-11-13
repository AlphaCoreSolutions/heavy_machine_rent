// lib/screens/contract_sheet_screen.dart
import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:Ajjara/core/api/api_handler.dart' as api;
import 'package:Ajjara/core/models/contracts/contract.dart';
import 'package:Ajjara/core/models/contracts/contract_slice.dart';
import 'package:Ajjara/core/models/contracts/contract_slice_sheet.dart';
import 'package:Ajjara/core/models/admin/request.dart';
import 'package:Ajjara/core/models/equipment/equipment.dart';
import 'package:Ajjara/foundation/ui/ui_kit.dart';

// ▶ for role detection
import 'package:Ajjara/core/auth/auth_store.dart';
import 'package:Ajjara/core/models/organization/organization_user.dart';

// l10n
import 'package:Ajjara/l10n/app_localizations.dart';

extension _L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}

class ContractSheetScreen extends StatefulWidget {
  const ContractSheetScreen({
    super.key,
    required this.contract,
    required this.request,
    required this.equipment,
    required this.slice,
  });

  final ContractModel contract;
  final RequestModel request;
  final Equipment equipment;
  final ContractSlice slice;

  @override
  State<ContractSheetScreen> createState() => _ContractSheetScreenState();
}

class _ContractSheetScreenState extends State<ContractSheetScreen> {
  final _df = DateFormat('yyyy-MM-dd');

  // We compute days from request/contract dates and render a grid by quantity.
  late final List<String> _days;
  int _qty = 1;

  // ▶ role flags
  bool _isVendor = false;
  bool _isCustomer = false;

  // Pending edits per-unit & per-day: key = "u{unit}#d{dayIdx}"
  final Map<String, ContractSliceSheet> _pending = {};
  // Saved (finalized) values to render in read-only rows
  final Map<String, ContractSliceSheet> _saved = {};
  // Which keys are finalized (saved once; no more edits)
  final Set<String> _finalized = {};
  // Per-row saving flags (same keys)
  final Set<String> _saving = {};

  @override
  void initState() {
    super.initState();
    _days = _buildDays();
    _loadQty();
    _resolveRole();
  }

  // ---------- role detection ----------
  Future<void> _resolveRole() async {
    try {
      final me = AuthStore.instance.user.value;
      if (me == null) return;
      final orgUsers = await api.Api.getOrganizationUsers();
      final mine = orgUsers.firstWhere(
        (m) => (m.applicationUserId == me.id) && (m.isActive == true),
        orElse: () => OrganizationUser(),
      );
      final myOrgId = mine.organizationId ?? 0;

      // Vendor/Customer on the contract/request
      final vendorOrgId =
          widget.contract.vendorId ??
          widget.request.vendorId ??
          widget.request.vendor?.organizationId ??
          0;
      final customerOrgId =
          widget.contract.customerId ??
          widget.request.customerId ??
          widget.request.customer?.organizationId ??
          0;

      if (!mounted) return;
      setState(() {
        _isVendor = (myOrgId != 0 && myOrgId == vendorOrgId);
        _isCustomer = (myOrgId != 0 && myOrgId == customerOrgId);
      });
    } catch (e) {
      dev.log('Role resolve failed: $e', name: 'ContractSheet');
    }
  }

  // ---------- qty/dates helpers ----------
  Future<void> _loadQty() async {
    try {
      final rid =
          widget.request.requestId ??
          widget.contract.requestId ??
          widget.slice.requestId ??
          0;
      if (rid <= 0) return;
      final freshReq = await api.Api.getRequestById(rid);
      final q = (freshReq.requestedQuantity ?? 1);
      if (!mounted) return;
      setState(() => _qty = q < 1 ? 1 : q);
    } catch (_) {
      // keep default 1
    }
  }

  DateTime? _parseIsoOrYmd(String? isoOrYmd) {
    if (isoOrYmd == null || isoOrYmd.isEmpty) return null;
    try {
      return DateTime.parse(
        isoOrYmd.contains('T') ? isoOrYmd : '${isoOrYmd}T00:00:00.000Z',
      );
    } catch (_) {
      return null;
    }
  }

  List<String> _buildDays() {
    final from =
        _parseIsoOrYmd(widget.request.fromDate) ??
        _parseIsoOrYmd(widget.contract.fromDate) ??
        DateTime.now();
    final to =
        _parseIsoOrYmd(widget.request.toDate) ??
        _parseIsoOrYmd(widget.contract.toDate) ??
        from;
    final n = to.difference(from).inDays + 1;
    return List<String>.generate(
      n < 1 ? 1 : n,
      (i) => _df.format(from.add(Duration(days: i))),
    );
  }

  num _num(String v) => num.tryParse(v.replaceAll(',', '.')) ?? 0;

  // Stable id in 1..60 so it doesn’t jump every rebuild
  int _idForUpdate({required int unitIndex, required int dayIndex}) {
    final seed = (unitIndex * 37 + dayIndex * 13);
    return (seed % 60) + 1; // 1..60
  }

  String _key(int unitIndex, int dayIndex) => 'u$unitIndex#d$dayIndex';

  ContractSliceSheet _mergedRow(int unitIndex, int dayIndex) {
    final k = _key(unitIndex, dayIndex);
    final base = _saved[k] ?? _pending[k]; // prefer saved for display
    final id = _idForUpdate(unitIndex: unitIndex, dayIndex: dayIndex);
    final sliceId = widget.slice.contractSliceId;

    if (base == null) {
      // defaults (zeros/empty)
      return ContractSliceSheet(
        contractSliceSheetId: id,
        contractSliceId: sliceId,
        sliceDate: _days[dayIndex],
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
      );
    }
    return base.copyWith(
      contractSliceSheetId: id,
      contractSliceId: sliceId,
      sliceDate: _days[dayIndex],
    );
  }

  void _markPending(
    int unitIndex,
    int dayIndex, {
    String? customerNote,
    String? vendorNote,
    num? daily,
    num? actual,
    num? over,
    num? total,
  }) {
    final k = _key(unitIndex, dayIndex);

    // If finalized, ignore changes
    if (_finalized.contains(k)) return;

    final cur = _pending[k];
    final next = (cur == null)
        ? ContractSliceSheet(
            contractSliceSheetId: null, // will be filled in _mergedRow
            contractSliceId: widget.slice.contractSliceId,
            sliceDate: _days[dayIndex],
            dailyHours: daily ?? 0,
            actualHours: actual ?? 0,
            overHours: over ?? 0,
            totalHours: total ?? 0,
            customerUserId: 0,
            vendorUserId: 0,
            isCustomerAccept: false,
            isVendorAccept: false,
            customerNote: customerNote ?? '',
            vendorNote: vendorNote ?? '',
          )
        : cur.copyWith(
            contractSliceSheetId: cur.contractSliceSheetId!,
            contractSliceId: cur.contractSliceId,
            sliceDate: cur.sliceDate!,
            dailyHours: daily ?? cur.dailyHours,
            actualHours: actual ?? cur.actualHours,
            overHours: over ?? cur.overHours,
            totalHours: total ?? cur.totalHours,
            customerNote: customerNote ?? cur.customerNote,
            vendorNote: vendorNote ?? cur.vendorNote,
          );

    setState(() => _pending[k] = next);
  }

  Future<void> _saveOne({required int unitIndex, required int dayIndex}) async {
    final k = _key(unitIndex, dayIndex);
    if (_finalized.contains(k)) return;

    // Enforce role-based locks before sending
    final editableFields = _editableForRole();
    final merged = _mergedRow(unitIndex, dayIndex);

    // If nothing entered and everything locked → noop with hint
    if (!_pending.containsKey(k) && !_saved.containsKey(k)) {
      AppSnack.info(context, context.l10n.rowNothingToSave);
      return;
    }

    // Build the payload limited to the fields the role may edit
    final p = _pending[k] ?? merged;
    final payload = ContractSliceSheet(
      contractSliceSheetId: merged.contractSliceSheetId,
      contractSliceId: merged.contractSliceId,
      sliceDate: merged.sliceDate,
      dailyHours: editableFields.canEditNumbers
          ? (p.dailyHours ?? 0)
          : (merged.dailyHours ?? 0),
      actualHours: editableFields.canEditNumbers
          ? (p.actualHours ?? 0)
          : (merged.actualHours ?? 0),
      overHours: editableFields.canEditNumbers
          ? (p.overHours ?? 0)
          : (merged.overHours ?? 0),
      totalHours: editableFields.canEditNumbers
          ? (p.totalHours ?? 0)
          : (merged.totalHours ?? 0),
      customerUserId: 0,
      vendorUserId: 0,
      isCustomerAccept: merged.isCustomerAccept ?? false,
      isVendorAccept: merged.isVendorAccept ?? false,
      customerNote: editableFields.canEditCustomerNote
          ? (p.customerNote ?? '')
          : (merged.customerNote ?? ''),
      vendorNote: editableFields.canEditVendorNote
          ? (p.vendorNote ?? '')
          : (merged.vendorNote ?? ''),
    );

    final label = context.l10n.rowLabel(
      unitIndex.toString(),
      merged.sliceDate ?? '',
    );
    setState(() => _saving.add(k));
    try {
      final ok = await api.Api.updateContractSliceSheet(payload);
      if (!mounted) return;

      if (ok == true) {
        // Persist the saved values, mark finalized, remove "pending"
        _saved[k] = payload;
        _finalized.add(k);
        _pending.remove(k);
        setState(() {});
        AppSnack.success(context, context.l10n.rowSaved(label));
      } else {
        AppSnack.error(context, context.l10n.rowSaveFailed(label));
      }
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('405')) {
        AppSnack.info(context, context.l10n.endpoint405Noop);
      } else {
        AppSnack.error(context, msg);
      }
    } finally {
      if (!mounted) return;
      setState(() => _saving.remove(k));
    }
  }

  // ▶ role rules
  _EditRules _editableForRole() {
    if (_isVendor) {
      return const _EditRules(
        canEditNumbers: false,
        canEditCustomerNote: false,
        canEditVendorNote: true,
      );
    }
    if (_isCustomer) {
      return const _EditRules(
        canEditNumbers: true,
        canEditCustomerNote: true,
        canEditVendorNote: false, // vendor note is locked for customer
      );
    }
    // fallback: allow everything (unknown role)
    return const _EditRules(
      canEditNumbers: true,
      canEditCustomerNote: true,
      canEditVendorNote: true,
    );
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final qty = _qty;
    final crossAxisCount = (qty == 1) ? 1 : 2;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.contractSheetTitle)),
      body: LayoutBuilder(
        builder: (context, bc) {
          final rules = _editableForRole();

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _chip(
                      cs,
                      context.l10n.contractChip(
                        '${widget.contract.contractNo ?? widget.contract.contractId ?? ''}',
                      ),
                      Icons.assignment,
                    ),
                    _chip(
                      cs,
                      context.l10n.requestChip(
                        '${widget.request.requestNo ?? widget.request.requestId ?? ''}',
                      ),
                      Icons.request_page_outlined,
                    ),
                    _chip(cs, context.l10n.qtyChip(qty), Icons.numbers),
                    _chip(
                      cs,
                      context.l10n.dateRangeChip(_days.first, _days.last),
                      Icons.calendar_month,
                    ),
                    if (_isVendor)
                      _chip(cs, context.l10n.roleVendor, Icons.badge),
                    if (_isCustomer)
                      _chip(
                        cs,
                        context.l10n.roleCustomer,
                        Icons.badge_outlined,
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: qty,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: (bc.maxWidth < 700) ? 0.78 : 0.95,
                  ),
                  itemBuilder: (_, unitIdxZero) {
                    final unitIndex = unitIdxZero + 1;
                    return _UnitColumn(
                      cs: cs,
                      unitIndex: unitIndex,
                      days: _days,
                      rules: rules,
                      // row state per day
                      isDirty: (dayIdx) =>
                          _pending.containsKey(_key(unitIndex, dayIdx)),
                      isSaved: (dayIdx) =>
                          _finalized.contains(_key(unitIndex, dayIdx)),
                      isSaving: (dayIdx) =>
                          _saving.contains(_key(unitIndex, dayIdx)),
                      // values to display (pending or saved)
                      valueFor: (dayIdx) => _mergedRow(unitIndex, dayIdx),
                      onChangedNumber: (dayIdx, field, value) {
                        if (_finalized.contains(_key(unitIndex, dayIdx))) {
                          return;
                        }
                        switch (field) {
                          case 'daily':
                            if (rules.canEditNumbers) {
                              _markPending(
                                unitIndex,
                                dayIdx,
                                daily: _num(value),
                              );
                            }
                            break;
                          case 'actual':
                            if (rules.canEditNumbers) {
                              _markPending(
                                unitIndex,
                                dayIdx,
                                actual: _num(value),
                              );
                            }
                            break;
                          case 'over':
                            if (rules.canEditNumbers) {
                              _markPending(
                                unitIndex,
                                dayIdx,
                                over: _num(value),
                              );
                            }
                            break;
                          case 'total':
                            if (rules.canEditNumbers) {
                              _markPending(
                                unitIndex,
                                dayIdx,
                                total: _num(value),
                              );
                            }
                            break;
                        }
                      },
                      onChangedText: (dayIdx, which, value) {
                        if (_finalized.contains(_key(unitIndex, dayIdx))) {
                          return;
                        }
                        if (which == 'cust') {
                          if (rules.canEditCustomerNote) {
                            _markPending(
                              unitIndex,
                              dayIdx,
                              customerNote: value,
                            );
                          }
                        } else {
                          if (rules.canEditVendorNote) {
                            _markPending(unitIndex, dayIdx, vendorNote: value);
                          }
                        }
                      },
                      onSaveRow: (dayIdx) =>
                          _saveOne(unitIndex: unitIndex, dayIndex: dayIdx),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _chip(ColorScheme cs, String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: cs.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(color: cs.onSurface)),
        ],
      ),
    );
  }
}

class _UnitColumn extends StatelessWidget {
  const _UnitColumn({
    required this.cs,
    required this.unitIndex,
    required this.days,
    required this.rules,
    required this.isDirty,
    required this.isSaved,
    required this.isSaving,
    required this.valueFor,
    required this.onChangedNumber,
    required this.onChangedText,
    required this.onSaveRow,
  });

  final ColorScheme cs;
  final int unitIndex;
  final List<String> days;
  final _EditRules rules;

  final bool Function(int dayIdx) isDirty;
  final bool Function(int dayIdx) isSaved;
  final bool Function(int dayIdx) isSaving;

  final ContractSliceSheet Function(int dayIdx) valueFor;

  final void Function(int dayIdx, String field, String value) onChangedNumber;
  final void Function(int dayIdx, String which, String value) onChangedText;
  final void Function(int dayIdx) onSaveRow;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withOpacity(.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            decoration: BoxDecoration(
              color: cs.primaryContainer.withOpacity(.85),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: cs.onPrimaryContainer.withOpacity(.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    '$unitIndex',
                    style: TextStyle(
                      color: cs.onPrimaryContainer,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${context.l10n.unitLabel} #$unitIndex',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: cs.onPrimaryContainer,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              itemCount: days.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final saved = isSaved(i);
                final dirty = isDirty(i);
                final saving = isSaving(i);
                final v = valueFor(i);

                return saved
                    ? _RowSavedCard(
                        cs: cs,
                        date: days[i],
                        planned: '${v.dailyHours ?? 0}',
                        actual: '${v.actualHours ?? 0}',
                        overtime: '${v.overHours ?? 0}',
                        total: '${v.totalHours ?? 0}',
                        customerNote: v.customerNote ?? '',
                        vendorNote: v.vendorNote ?? '',
                      )
                    : _RowCard(
                        cs: cs,
                        date: days[i],
                        // Seed fields with pending/known values
                        planned: '${v.dailyHours ?? 0}',
                        actual: '${v.actualHours ?? 0}',
                        overtime: '${v.overHours ?? 0}',
                        total: '${v.totalHours ?? 0}',
                        custNote: v.customerNote ?? '',
                        vendNote: v.vendorNote ?? '',
                        // locks
                        lockNumbers: !rules.canEditNumbers,
                        lockCustomerNote: !rules.canEditCustomerNote,
                        lockVendorNote: !rules.canEditVendorNote,
                        // state
                        dirty: dirty,
                        saving: saving,
                        onChangedNumber: (field, val) =>
                            onChangedNumber(i, field, val),
                        onChangedText: (field, val) =>
                            onChangedText(i, field, val),
                        onSave: () => onSaveRow(i),
                      );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RowSavedCard extends StatelessWidget {
  const _RowSavedCard({
    required this.cs,
    required this.date,
    required this.planned,
    required this.actual,
    required this.overtime,
    required this.total,
    required this.customerNote,
    required this.vendorNote,
  });

  final ColorScheme cs;
  final String date, planned, actual, overtime, total, customerNote, vendorNote;

  @override
  Widget build(BuildContext context) {
    final headerBg = cs.secondaryContainer.withOpacity(.75);
    final headerFg = cs.onSecondaryContainer;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withOpacity(.6)),
      ),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: headerBg,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Text(
                  date,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: headerFg,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: headerFg.withOpacity(.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    context.l10n.savedChip,
                    style: TextStyle(
                      color: headerFg,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Column(
              children: [
                _kv(context.l10n.plannedLabel, planned),
                _kv(context.l10n.actualLabel, actual),
                _kv(context.l10n.overtimeLabel, overtime),
                _kv(context.l10n.totalLabel, total),
                if (customerNote.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _kv(context.l10n.customerNoteLabel, customerNote),
                ],
                if (vendorNote.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  _kv(context.l10n.vendorNoteLabel, vendorNote),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        SizedBox(
          width: 130,
          child: Text(k, style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
        Expanded(child: Text(v)),
      ],
    ),
  );
}

class _RowCard extends StatelessWidget {
  const _RowCard({
    required this.cs,
    required this.date,
    required this.planned,
    required this.actual,
    required this.overtime,
    required this.total,
    required this.custNote,
    required this.vendNote,
    required this.lockNumbers,
    required this.lockCustomerNote,
    required this.lockVendorNote,
    required this.dirty,
    required this.saving,
    required this.onChangedNumber,
    required this.onChangedText,
    required this.onSave,
  });

  final ColorScheme cs;
  final String date;
  final String planned, actual, overtime, total, custNote, vendNote;
  final bool lockNumbers, lockCustomerNote, lockVendorNote;
  final bool dirty, saving;

  final void Function(String field, String value) onChangedNumber;
  final void Function(String which, String value) onChangedText;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final headerBg = cs.secondaryContainer.withOpacity(.75);
    final headerFg = cs.onSecondaryContainer;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withOpacity(.6)),
      ),
      child: Column(
        children: [
          // Row header
          Container(
            decoration: BoxDecoration(
              color: headerBg,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Text(
                  date,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: headerFg,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                if (dirty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: headerFg.withOpacity(.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      context.l10n.unsavedChip,
                      style: TextStyle(
                        color: headerFg,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Inputs
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Column(
              children: [
                Row(
                  children: [
                    _NumField(
                      label: context.l10n.plannedLabel,
                      initial: planned,
                      enabled: !lockNumbers,
                      onChanged: (v) => onChangedNumber('daily', v),
                    ),
                    const SizedBox(width: 8),
                    _NumField(
                      label: context.l10n.actualLabel,
                      initial: actual,
                      enabled: !lockNumbers,
                      onChanged: (v) => onChangedNumber('actual', v),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _NumField(
                      label: context.l10n.overtimeLabel,
                      initial: overtime,
                      enabled: !lockNumbers,
                      onChanged: (v) => onChangedNumber('over', v),
                    ),
                    const SizedBox(width: 8),
                    _NumField(
                      label: context.l10n.totalLabel,
                      initial: total,
                      enabled: !lockNumbers,
                      onChanged: (v) => onChangedNumber('total', v),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _TextField(
                  label: context.l10n.customerNoteLabel,
                  initial: custNote,
                  enabled: !lockCustomerNote,
                  onChanged: (v) => onChangedText('cust', v),
                ),
                const SizedBox(height: 8),
                _TextField(
                  label: context.l10n.vendorNoteLabel,
                  initial: vendNote,
                  enabled: !lockVendorNote,
                  onChanged: (v) => onChangedText('vend', v),
                ),

                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: saving ? null : onSave,
                    icon: saving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: Text(
                      saving
                          ? context.l10n.savingEllipsis
                          : context.l10n.actionSave,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NumField extends StatelessWidget {
  const _NumField({
    required this.label,
    required this.initial,
    required this.enabled,
    required this.onChanged,
  });
  final String label;
  final String initial;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: TextFormField(
        initialValue: initial,
        enabled: enabled,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          filled: true,
          isDense: true,
        ).copyWith(labelText: label),
        onChanged: onChanged,
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  const _TextField({
    required this.label,
    required this.initial,
    required this.enabled,
    required this.onChanged,
  });
  final String label;
  final String initial;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initial,
      enabled: enabled,
      minLines: 1,
      maxLines: 3,
      decoration: const InputDecoration(
        filled: true,
      ).copyWith(labelText: label),
      onChanged: onChanged,
    );
  }
}

// small value object for edit permissions
class _EditRules {
  final bool canEditNumbers;
  final bool canEditCustomerNote;
  final bool canEditVendorNote;
  const _EditRules({
    required this.canEditNumbers,
    required this.canEditCustomerNote,
    required this.canEditVendorNote,
  });
}

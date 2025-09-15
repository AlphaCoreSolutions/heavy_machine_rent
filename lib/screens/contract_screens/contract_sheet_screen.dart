// lib/screens/contract_sheet_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:heavy_new/core/api/api_handler.dart' as api;
import 'package:heavy_new/core/models/contracts/contract.dart';
import 'package:heavy_new/core/models/contracts/contract_slice.dart';
import 'package:heavy_new/core/models/contracts/contract_slice_sheet.dart';
import 'package:heavy_new/core/models/admin/request.dart';
import 'package:heavy_new/core/models/equipment/equipment.dart';
import 'package:heavy_new/foundation/ui/ui_kit.dart';

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

  // Pending edits per-unit & per-day: key = "u{unit}#d{dayIdx}"
  final Map<String, ContractSliceSheet> _pending = {};
  // Per-row saving flags (same keys)
  final Set<String> _saving = {};

  @override
  void initState() {
    super.initState();
    _days = _buildDays();
    _loadQty();
  }

  // ---- helpers ----

  // 3) Add a helper to load the fresh quantity from the server
  Future<void> _loadQty() async {
    try {
      // Prefer the request id from the widget; fall back to contract/slice if needed
      final rid =
          widget.request.requestId ??
          widget.contract.requestId ??
          widget.slice.requestId ??
          0;
      if (rid <= 0) return; // keep default 1

      final freshReq = await api.Api.getRequestById(rid);
      final q = (freshReq.requestedQuantity ?? 1);
      if (!mounted) return;
      setState(() => _qty = q < 1 ? 1 : q);
    } catch (_) {
      // leave _qty as-is (1) on failure
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

  // “Random” (but stable) id in 1..60 so it doesn’t jump every rebuild
  // (unit + day -> id). This matches your “random 1..60” constraint.
  int _idForUpdate({required int unitIndex, required int dayIndex}) {
    final seed = (unitIndex * 37 + dayIndex * 13);
    return (seed % 60) + 1; // 1..60
  }

  String _key(int unitIndex, int dayIndex) => 'u$unitIndex#d$dayIndex';

  ContractSliceSheet _mergedRow(int unitIndex, int dayIndex) {
    final k = _key(unitIndex, dayIndex);
    final base = _pending[k];

    // Always send these three:
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
    final cur = _pending[k];

    final next = (cur == null)
        ? ContractSliceSheet(
            contractSliceSheetId: null, // will be filled on _mergedRow
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
    final payload = _mergedRow(unitIndex, dayIndex);

    setState(() => _saving.add(k));
    try {
      final ok = await api.Api.updateContractSliceSheet(payload);
      if (!mounted) return;

      if (ok == true) {
        // Mark this key as clean (keep the values, drop “unsaved”)
        setState(() {});
        AppSnack.success(context, 'Saved.');
      } else {
        AppSnack.error(context, 'Save failed.');
      }
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('405')) {
        AppSnack.info(
          context,
          'Update endpoint not enabled (405). Nothing changed on the server.',
        );
      } else {
        AppSnack.error(context, msg);
      }
    } finally {
      if (!mounted) return;
      setState(() => _saving.remove(k));
    }
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final qty = _qty;
    final crossAxisCount = (qty == 1) ? 1 : 2;

    return Scaffold(
      appBar: AppBar(title: const Text('Contract Sheet')),
      body: LayoutBuilder(
        builder: (context, bc) {
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
                      'Contract #${widget.contract.contractNo ?? widget.contract.contractId ?? ''}',
                      Icons.assignment,
                    ),
                    _chip(
                      cs,
                      'Req #${widget.request.requestNo ?? widget.request.requestId ?? ''}',
                      Icons.request_page_outlined,
                    ),
                    _chip(cs, 'Qty: $qty', Icons.numbers),
                    _chip(
                      cs,
                      '${_days.first} → ${_days.last}',
                      Icons.calendar_month,
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
                      isDirty: (dayIdx) =>
                          _pending.containsKey(_key(unitIndex, dayIdx)),
                      isSaving: (dayIdx) =>
                          _saving.contains(_key(unitIndex, dayIdx)),
                      onChangedNumber: (dayIdx, field, value) {
                        switch (field) {
                          case 'daily':
                            _markPending(unitIndex, dayIdx, daily: _num(value));
                            break;
                          case 'actual':
                            _markPending(
                              unitIndex,
                              dayIdx,
                              actual: _num(value),
                            );
                            break;
                          case 'over':
                            _markPending(unitIndex, dayIdx, over: _num(value));
                            break;
                          case 'total':
                            _markPending(unitIndex, dayIdx, total: _num(value));
                            break;
                        }
                      },
                      onChangedText: (dayIdx, which, value) {
                        if (which == 'cust') {
                          _markPending(unitIndex, dayIdx, customerNote: value);
                        } else {
                          _markPending(unitIndex, dayIdx, vendorNote: value);
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
        color: cs.surfaceVariant,
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
    required this.isDirty,
    required this.isSaving,
    required this.onChangedNumber,
    required this.onChangedText,
    required this.onSaveRow,
  });

  final ColorScheme cs;
  final int unitIndex;
  final List<String> days;

  final bool Function(int dayIdx) isDirty;
  final bool Function(int dayIdx) isSaving;
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
                  'Unit #$unitIndex',
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
                final dirty = isDirty(i);
                final saving = isSaving(i);
                return _RowCard(
                  cs: cs,
                  date: days[i],
                  dirty: dirty,
                  saving: saving,
                  onChangedNumber: (field, v) => onChangedNumber(i, field, v),
                  onChangedText: (which, v) => onChangedText(i, which, v),
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

class _RowCard extends StatelessWidget {
  const _RowCard({
    required this.cs,
    required this.date,
    required this.dirty,
    required this.saving,
    required this.onChangedNumber,
    required this.onChangedText,
    required this.onSave,
  });

  final ColorScheme cs;
  final String date;
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
                      'Unsaved',
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
                      label: 'Planned',
                      onChanged: (v) => onChangedNumber('daily', v),
                    ),
                    const SizedBox(width: 8),
                    _NumField(
                      label: 'Actual',
                      onChanged: (v) => onChangedNumber('actual', v),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _NumField(
                      label: 'Overtime',
                      onChanged: (v) => onChangedNumber('over', v),
                    ),
                    const SizedBox(width: 8),
                    _NumField(
                      label: 'Total',
                      onChanged: (v) => onChangedNumber('total', v),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _TextField(
                  label: 'Customer note',
                  onChanged: (v) => onChangedText('cust', v),
                ),
                const SizedBox(height: 8),
                _TextField(
                  label: 'Vendor note',
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
                    label: Text(saving ? 'Saving…' : 'Save'),
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
  const _NumField({required this.label, required this.onChanged});
  final String label;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: TextFormField(
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
  const _TextField({required this.label, required this.onChanged});
  final String label;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      minLines: 1,
      maxLines: 3,
      decoration: const InputDecoration(
        filled: true,
      ).copyWith(labelText: label),
      onChanged: onChanged,
    );
  }
}

extension on ContractSliceSheet {
  ContractSliceSheet copyWith({
    int? contractSliceSheetId,
    int? contractSliceId,
    String? sliceDate,
    num? dailyHours,
    num? actualHours,
    num? overHours,
    num? totalHours,
    int? customerUserId,
    bool? isCustomerAccept,
    int? vendorUserId,
    bool? isVendorAccept,
    String? customerNote,
    String? vendorNote,
  }) => ContractSliceSheet(
    contractSliceSheetId: contractSliceSheetId ?? this.contractSliceSheetId,
    contractSliceId: contractSliceId ?? this.contractSliceId,
    sliceDate: sliceDate ?? this.sliceDate,
    dailyHours: dailyHours ?? this.dailyHours,
    actualHours: actualHours ?? this.actualHours,
    overHours: overHours ?? this.overHours,
    totalHours: totalHours ?? this.totalHours,
    customerUserId: customerUserId ?? this.customerUserId,
    isCustomerAccept: isCustomerAccept ?? this.isCustomerAccept,
    vendorUserId: vendorUserId ?? this.vendorUserId,
    isVendorAccept: isVendorAccept ?? this.isVendorAccept,
    customerNote: customerNote ?? this.customerNote,
    vendorNote: vendorNote ?? this.vendorNote,
  );
}

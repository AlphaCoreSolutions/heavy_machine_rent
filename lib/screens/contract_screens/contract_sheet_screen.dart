// lib/screens/contract_sheet_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:heavy_new/core/api/api_handler.dart' as api;
import 'package:heavy_new/core/models/contracts/contract.dart';
import 'package:heavy_new/core/models/contracts/contract_slice.dart';
import 'package:heavy_new/core/models/contracts/contract_slice_sheet.dart';
import 'package:heavy_new/core/models/admin/request.dart';
import 'package:heavy_new/core/models/equipment/equipment.dart';
import 'package:heavy_new/foundation/ui/ui_extras.dart';
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
  bool _loading = true;
  bool _generating = false;

  // The rows we render
  List<ContractSliceSheet> _rows = [];

  // Per-row pending edits (only what changed)
  // Keyed by contractSliceSheetId; for new rows (shouldn’t happen here) we fallback to index key.
  final Map<int, ContractSliceSheet> _pending = {};

  // Which rows are currently saving
  final Set<int> _saving = {};

  @override
  void initState() {
    super.initState();
    _load(); // no async setState inside
  }

  DateTime? _d(String? isoOrYmd) {
    if (isoOrYmd == null || isoOrYmd.isEmpty) return null;
    try {
      if (isoOrYmd.contains('T')) return DateTime.parse(isoOrYmd);
      return DateTime.parse('${isoOrYmd}T00:00:00.000Z');
    } catch (_) {
      return null;
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
    });

    try {
      // Ensure sheets exist once
      final existing = await api.Api.getSheetsForSlice(
        widget.slice.contractSliceId ?? 0,
      );
      if (existing.isNotEmpty) {
        _rows = existing;
      } else {
        // Generate (days × requestedQuantity)
        final from =
            _d(widget.request.fromDate) ??
            _d(widget.contract.fromDate) ??
            DateTime.now();
        final to =
            _d(widget.request.toDate) ?? _d(widget.contract.toDate) ?? from;
        final days = to.difference(from).inDays + 1;
        final qty = widget.request.requestedQuantity ?? 1;

        _generating = true;
        final created = <ContractSliceSheet>[];
        for (int i = 0; i < days; i++) {
          final date = _df.format(from.add(Duration(days: i)));
          for (int q = 0; q < qty; q++) {
            final sheet = await api.Api.addContractSliceSheet(
              ContractSliceSheet(
                contractSliceSheetId: 0,
                contractSliceId: widget.slice.contractSliceId,
                sliceDate: date,
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
            created.add(sheet);
          }
        }
        _rows = created;
      }
    } finally {
      if (!mounted) return;
      setState(() {
        _generating = false;
        _loading = false;
      });
    }
  }

  // Merge base row with pending edits (if any)
  ContractSliceSheet _mergedRow(ContractSliceSheet base) {
    final id = base.contractSliceSheetId ?? -1;
    final p = _pending[id];
    if (p == null) return base;
    return base.copyWith(
      sliceDate: p.sliceDate,
      dailyHours: p.dailyHours,
      actualHours: p.actualHours,
      overHours: p.overHours,
      totalHours: p.totalHours,
      customerUserId: p.customerUserId,
      isCustomerAccept: p.isCustomerAccept,
      vendorUserId: p.vendorUserId,
      isVendorAccept: p.isVendorAccept,
      customerNote: p.customerNote,
      vendorNote: p.vendorNote,
    );
  }

  void _markPending(int id, ContractSliceSheet patch) {
    final cur = _pending[id];
    if (cur == null) {
      _pending[id] = patch;
    } else {
      _pending[id] = cur.copyWith(
        sliceDate: patch.sliceDate ?? cur.sliceDate,
        dailyHours: patch.dailyHours ?? cur.dailyHours,
        actualHours: patch.actualHours ?? cur.actualHours,
        overHours: patch.overHours ?? cur.overHours,
        totalHours: patch.totalHours ?? cur.totalHours,
        customerUserId: patch.customerUserId ?? cur.customerUserId,
        isCustomerAccept: patch.isCustomerAccept ?? cur.isCustomerAccept,
        vendorUserId: patch.vendorUserId ?? cur.vendorUserId,
        isVendorAccept: patch.isVendorAccept ?? cur.isVendorAccept,
        customerNote: patch.customerNote ?? cur.customerNote,
        vendorNote: patch.vendorNote ?? cur.vendorNote,
      );
    }
    setState(() {}); // only sync UI flags (dirty chip)
  }

  num _numParse(String v) => num.tryParse(v.replaceAll(',', '.')) ?? 0;

  Future<void> _saveOne(ContractSliceSheet base) async {
    final id = base.contractSliceSheetId ?? -1;
    final updated = _mergedRow(base);

    setState(() {
      _saving.add(id);
    });

    try {
      final ok = await api.Api.updateContractSliceSheet(updated);
      if (!mounted) return;

      if (ok) {
        // Replace the base row in _rows with updated values
        final idx = _rows.indexWhere(
          (r) => (r.contractSliceSheetId ?? -1) == id,
        );
        if (idx >= 0) _rows[idx] = updated;
        _pending.remove(id);
        setState(() {});
        AppSnack.success(context, 'Saved.');
      } else {
        AppSnack.error(context, 'Save failed.');
      }
    } catch (e) {
      // 405 is backend (Method Not Allowed) — do not alter local state
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
      setState(() {
        _saving.remove(id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contract Sheet'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? ListView(
              children: const [ShimmerTile(), ShimmerTile(), ShimmerTile()],
            )
          : (_generating
                ? const Center(child: CircularProgressIndicator())
                : (_rows.isEmpty
                      ? const Center(child: Text('No rows.'))
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                          itemCount: _rows.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (_, i) {
                            final base = _rows[i];
                            final id = base.contractSliceSheetId ?? -1;
                            final merged = _mergedRow(base);
                            final dirty = _pending.containsKey(id);
                            final saving = _saving.contains(id);

                            return _ModernSheetCard(
                              cs: cs,
                              index: i + 1,
                              row: merged,
                              dirty: dirty,
                              saving: saving,
                              onChangedNumber: (field, value) {
                                // store only the changed field
                                switch (field) {
                                  case 'daily':
                                    _markPending(
                                      id,
                                      base.copyWith(
                                        dailyHours: _numParse(value),
                                      ),
                                    );
                                    break;
                                  case 'actual':
                                    _markPending(
                                      id,
                                      base.copyWith(
                                        actualHours: _numParse(value),
                                      ),
                                    );
                                    break;
                                  case 'over':
                                    _markPending(
                                      id,
                                      base.copyWith(
                                        overHours: _numParse(value),
                                      ),
                                    );
                                    break;
                                  case 'total':
                                    _markPending(
                                      id,
                                      base.copyWith(
                                        totalHours: _numParse(value),
                                      ),
                                    );
                                    break;
                                }
                              },
                              onChangedText: (field, value) {
                                if (field == 'cust') {
                                  _markPending(
                                    id,
                                    base.copyWith(customerNote: value),
                                  );
                                } else if (field == 'vend') {
                                  _markPending(
                                    id,
                                    base.copyWith(vendorNote: value),
                                  );
                                }
                              },
                            );
                          },
                        ))),
    );
  }
}

// --------- Presentational modern card ---------
class _ModernSheetCard extends StatelessWidget {
  const _ModernSheetCard({
    required this.cs,
    required this.index,
    required this.row,
    required this.dirty,
    required this.saving,
    required this.onChangedNumber,
    required this.onChangedText,

    required this.onSave,
  });

  final ColorScheme cs;
  final int index;
  final ContractSliceSheet row;
  final bool dirty;
  final bool saving;

  final void Function(String field, String value) onChangedNumber;
  final void Function(String field, String value) onChangedText;

  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final headerBg = cs.primaryContainer.withOpacity(.75);
    final headerFg = cs.onPrimaryContainer;

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
              color: headerBg,
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
                    color: headerFg.withOpacity(.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    '$index',
                    style: TextStyle(
                      color: headerFg,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    row.sliceDate ?? '—',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: headerFg,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
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

          // Body
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Column(
              children: [
                Row(
                  children: [
                    _NumField(
                      label: 'Planned',
                      initial: '${row.dailyHours ?? 0}',
                      onChanged: (v) => onChangedNumber('daily', v),
                    ),
                    const SizedBox(width: 8),
                    _NumField(
                      label: 'Actual',
                      initial: '${row.actualHours ?? 0}',
                      onChanged: (v) => onChangedNumber('actual', v),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _NumField(
                      label: 'Overtime',
                      initial: '${row.overHours ?? 0}',
                      onChanged: (v) => onChangedNumber('over', v),
                    ),
                    const SizedBox(width: 8),
                    _NumField(
                      label: 'Total',
                      initial: '${row.totalHours ?? 0}',
                      onChanged: (v) => onChangedNumber('total', v),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Accept toggles
                Row(
                  children: [
                    Expanded(
                      child: _SwitchPill(
                        label: 'Customer accepted',
                        value: row.isCustomerAccept ?? false,
                        onChanged: onToggleCustomerAccept,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _SwitchPill(
                        label: 'Vendor accepted',
                        value: row.isVendorAccept ?? false,
                        onChanged: onToggleVendorAccept,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Notes
                _TextField(
                  label: 'Customer note',
                  initial: row.customerNote ?? '',
                  onChanged: (v) => onChangedText('cust', v),
                ),
                const SizedBox(height: 8),
                _TextField(
                  label: 'Vendor note',
                  initial: row.vendorNote ?? '',
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
  const _NumField({
    required this.label,
    required this.initial,
    required this.onChanged,
  });
  final String label;
  final String initial;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: TextFormField(
        initialValue: initial,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          isDense: true,
        ),
        onChanged: onChanged,
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  const _TextField({
    required this.label,
    required this.initial,
    required this.onChanged,
  });
  final String label;
  final String initial;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initial,
      minLines: 1,
      maxLines: 3,
      decoration: InputDecoration(labelText: label, filled: true),
      onChanged: onChanged,
    );
  }
}

class _SwitchPill extends StatelessWidget {
  const _SwitchPill({
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withOpacity(.6)),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
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

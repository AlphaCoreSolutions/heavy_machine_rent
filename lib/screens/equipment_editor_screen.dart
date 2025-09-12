// lib/screens/equipment_editor_screen.dart
import 'package:flutter/material.dart';
import 'package:heavy_new/core/api/api_handler.dart' as api;

// Models
import 'package:heavy_new/core/models/equipment/equipment.dart';
import 'package:heavy_new/core/models/equipment/equipment_list.dart' as elist;
import 'package:heavy_new/core/models/admin/factory.dart' as fmodels;
import 'package:heavy_new/core/models/admin/domain.dart'; // DomainDetail

// UI bits
import 'package:heavy_new/foundation/ui/app_icons.dart';
import 'package:heavy_new/foundation/ui/ui_extras.dart';
import 'package:heavy_new/foundation/ui/ui_kit.dart';

class EquipmentEditorScreen extends StatefulWidget {
  const EquipmentEditorScreen({super.key, this.forceShowPanels = false});
  final bool forceShowPanels;

  @override
  State<EquipmentEditorScreen> createState() => _EquipmentEditorScreenState();
}

// ---- Data bundle for FutureBuilder
class _EditorData {
  final List<elist.EquipmentListModel> lists;
  final List<fmodels.FactoryModel> factories;
  final List<DomainDetail> statusD11;
  final List<DomainDetail> categoryD9;
  final List<DomainDetail> fuelD7;
  final List<DomainDetail> transferTypeD8;
  final List<DomainDetail> transferRespD7;
  final List<DomainDetail> driverRespD7;

  _EditorData({
    required this.lists,
    required this.factories,
    required this.statusD11,
    required this.categoryD9,
    required this.fuelD7,
    required this.transferTypeD8,
    required this.transferRespD7,
    required this.driverRespD7,
  });
}

class _EquipmentEditorScreenState extends State<EquipmentEditorScreen> {
  // ===== Controllers / focus
  final _descEn = TextEditingController();
  final _descAr = TextEditingController();
  final _priceDay = TextEditingController();
  final _priceHour = TextEditingController();
  final _qtyCtrl = TextEditingController(text: '1');

  final _dayFocus = FocusNode();
  final _hourFocus = FocusNode();

  // ===== Selected objects (object-typed to avoid dropdown “lock”)
  elist.EquipmentListModel? _selList;
  fmodels.FactoryModel? _selFactory;

  DomainDetail? _selStatus; // domain 11
  DomainDetail? _selCategory; // domain 9
  DomainDetail? _selFuel; // domain 7
  DomainDetail? _selTransferType; // domain 8
  DomainDetail? _selTransferResp; // domain 7
  DomainDetail? _selDriverTrans; // domain 7
  DomainDetail? _selDriverFood; // domain 7
  DomainDetail? _selDriverHousing; // domain 7

  // ===== Backing IDs for the draft
  int? _equipmentListId;

  List<fmodels.FactoryModel> _factories = [];
  bool _loadingFactories = false;
  int? _factoryId;

  int? _statusId;
  int? _categoryId;
  int? _fuelRespId;
  int? _transferTypeId;
  int? _transferRespId;
  int? _driverTransRespId;
  int? _driverFoodRespId;
  int? _driverHousingRespId;

  // ===== Pricing rules
  static const double kHoursPerDay = 10.0;
  static const num kDownPaymentPercent = 20; // percent (amount is derived)
  bool _priceSyncGuard = false;

  late Future<_EditorData> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadAll();
    _loadFactories();

    // Day -> Hour
    _priceDay.addListener(() {
      if (_priceSyncGuard || !_dayFocus.hasFocus) return;
      final d = _toD(_priceDay.text);
      _priceSyncGuard = true;
      if (d != null) _priceHour.text = _fmt(d / kHoursPerDay);
      _priceSyncGuard = false;
      setState(() {}); // refresh down-payment preview
    });

    // Hour -> Day
    _priceHour.addListener(() {
      if (_priceSyncGuard || !_hourFocus.hasFocus) return;
      final h = _toD(_priceHour.text);
      _priceSyncGuard = true;
      if (h != null) _priceDay.text = _fmt(h * kHoursPerDay);
      _priceSyncGuard = false;
      setState(() {}); // refresh down-payment preview
    });
  }

  @override
  void dispose() {
    _descEn.dispose();
    _descAr.dispose();
    _priceDay.dispose();
    _priceHour.dispose();
    _qtyCtrl.dispose();
    _dayFocus.dispose();
    _hourFocus.dispose();
    super.dispose();
  }

  // ===== Load lists/factories/domains
  Future<_EditorData> _loadAll() async {
    final lists = await api.Api.getEquipmentLists();
    final factories = await api.Api.getFactories();
    final statusD11 = await api.Api.getDomainDetailsByDomainId(11);
    final categoryD9 = await api.Api.getDomainDetailsByDomainId(9);
    final fuelD7 = await api.Api.getDomainDetailsByDomainId(7);
    final transferTypeD8 = await api.Api.getDomainDetailsByDomainId(8);
    final transferRespD7 = fuelD7;
    final driverRespD7 = fuelD7;

    debugPrint(
      '[EquipEditor] lists=${lists.length} '
      'factories=${factories.length} '
      'D11=${statusD11.length} D9=${categoryD9.length} '
      'D7=${fuelD7.length} D8=${transferTypeD8.length}',
    );

    return _EditorData(
      lists: lists.where((e) => (e.isActive ?? true)).toList(),
      factories: factories.where((e) => (e.isActive ?? true)).toList(),
      statusD11: statusD11,
      categoryD9: categoryD9,
      fuelD7: fuelD7,
      transferTypeD8: transferTypeD8,
      transferRespD7: transferRespD7,
      driverRespD7: driverRespD7,
    );
  }

  Future<void> _loadFactories() async {
    setState(() => _loadingFactories = true);
    try {
      final list = await api.Api.getFactories();
      debugPrint('[EquipEditor] fetched factories: ${list.length}');
      for (final f in list) {
        debugPrint('[EquipEditor] · id=${f.factoryId} en=${f.nameEnglish}');
      }

      // Keep everything the server returned; don't filter by id
      final next = List<fmodels.FactoryModel>.from(list);

      // Optional: stable sort by English name
      next.sort((a, b) => (a.nameEnglish ?? '').compareTo(b.nameEnglish ?? ''));

      setState(() {
        _factories = next;

        // Reconcile selection
        if (_factoryId != null &&
            !_factories.any((m) => m.factoryId == _factoryId)) {
          _factoryId = null;
          _selFactory = null;
        } else if (_factoryId != null) {
          _selFactory = _factories.firstWhere(
            (m) => m.factoryId == _factoryId,
            orElse: () => _factories.first,
          );
        }
      });
    } catch (e, st) {
      debugPrint('[EquipEditor] getFactories failed: $e\n$st');
      if (mounted) AppSnack.error(context, 'Could not load factories');
    } finally {
      if (mounted) setState(() => _loadingFactories = false);
    }
  }

  // ===== Helpers
  String _fmt(num n) {
    final d = n.toDouble();
    return (d.truncateToDouble() == d)
        ? d.toStringAsFixed(0)
        : d.toStringAsFixed(2);
  }

  double? _toD(String s) => double.tryParse(s.trim());
  int _toI(String s, [int def = 1]) => int.tryParse(s.trim()) ?? def;

  String _factoryLabel(fmodels.FactoryModel m) {
    final en = (m.nameEnglish ?? '').trim();
    final ar = (m.nameArabic ?? '').trim();
    if (en.isNotEmpty && ar.isNotEmpty) return '$en — $ar';
    return en.isNotEmpty ? en : (ar.isNotEmpty ? ar : 'Unnamed factory');
  }

  String _labelDomain(DomainDetail d) =>
      (d.detailNameEnglish?.trim().isNotEmpty ?? false)
      ? d.detailNameEnglish!.trim()
      : (d.detailNameArabic ?? '—');

  DropdownMenuItem<T> _dd<T>(T value, String label) => DropdownMenuItem<T>(
    value: value,
    child: Text(label, overflow: TextOverflow.ellipsis),
  );

  num _downPaymentAmount() {
    final perDay = _toD(_priceDay.text) ?? 0.0;
    return (perDay * (kDownPaymentPercent / 100.0));
  }

  // ===== Save (returns draft to caller)
  Future<void> _save() async {
    if (_selList == null || _equipmentListId == null) {
      AppSnack.error(context, 'Choose an equipment type');
      return;
    }
    if (_selFactory == null || _factoryId == null) {
      AppSnack.error(context, 'Choose a factory');
      return;
    }
    if (_factoryId == null) {
      AppSnack.error(context, 'Choose a factory');
      return;
    }

    if (_descEn.text.trim().isEmpty && _descAr.text.trim().isEmpty) {
      AppSnack.error(context, 'Enter a description (EN or AR)');
      return;
    }

    final perDay = _toD(_priceDay.text) ?? 0.0;
    final perHour = _toD(_priceHour.text) ?? (perDay / kHoursPerDay);
    final qty = _toI(_qtyCtrl.text, 1);

    final draft = Equipment(
      // Required/type
      equipmentListId: _equipmentListId,
      factoryId: _factoryId,
      descEnglish: _descEn.text.trim().isNotEmpty ? _descEn.text.trim() : null,
      descArabic: _descAr.text.trim().isNotEmpty ? _descAr.text.trim() : null,
      isActive: true,

      // Domains (IDs only)
      statusId: _statusId,
      categoryId: _categoryId,
      fuelResponsibilityId: _fuelRespId,
      transferTypeId: _transferTypeId,
      transferResponsibilityId: _transferRespId,
      driverTransResponsibilityId: _driverTransRespId,
      driverFoodResponsibilityId: _driverFoodRespId,
      driverHousingResponsibilityId: _driverHousingRespId,

      // Pricing
      rentPricePerDay: perDay,
      rentPricePerHour: perHour,
      downPaymentPerc: kDownPaymentPercent, // percent
      // Quantities (available mirrors quantity, reserved=0)
      quantity: qty,
      availableQuantity: qty,
      reservedQuantity: 0,
    );

    debugPrint('[EquipEditor] SAVE draft => ${draft.toJson()}');
    if (!mounted) return;
    Navigator.of(context).pop({'equipment': draft});
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('New equipment')),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: BrandButton(
            onPressed: _save,
            icon: AIcon(AppGlyph.check, color: Colors.white, selected: true),
            child: const Text('Continue'),
          ),
        ),
      ),
      body: FutureBuilder<_EditorData>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError || !snap.hasData) {
            return Center(
              child: Glass(
                radius: 18,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Failed to load options'),
                      const SizedBox(height: 8),
                      Text(
                        '${snap.error}',
                        textAlign: TextAlign.center,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: cs.error),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () => setState(() => _future = _loadAll()),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          final data = snap.data!;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              // ===== Type (Equipment list) =====
              Glass(
                radius: 20,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Type',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<elist.EquipmentListModel>(
                        value: _selList,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Equipment list',
                          isDense: true,
                        ),
                        isExpanded: true,
                        items: data.lists
                            .map(
                              (m) => _dd<elist.EquipmentListModel>(
                                m,
                                [
                                  if ((m.nameEnglish ?? '').trim().isNotEmpty)
                                    m.nameEnglish!.trim(),
                                  if ((m.primaryUseEnglish ?? '')
                                      .trim()
                                      .isNotEmpty)
                                    '· ${m.primaryUseEnglish!.trim()}',
                                ].join(' '),
                              ),
                            )
                            .toList(),
                        onChanged: (m) {
                          setState(() {
                            _selList = m;
                            _equipmentListId = m?.equipmentListId;
                          });
                          // Prefill desc if empty (editable)
                          if ((_descEn.text.trim().isEmpty) &&
                              (m?.nameEnglish?.trim().isNotEmpty ?? false)) {
                            _descEn.text = m!.nameEnglish!.trim();
                          }
                          if ((_descAr.text.trim().isEmpty) &&
                              (m?.nameArabic?.trim().isNotEmpty ?? false)) {
                            _descAr.text = m!.nameArabic!.trim();
                          }
                          debugPrint(
                            '[EquipEditor] selected listId=$_equipmentListId',
                          );
                        },
                      ),
                      if (_selList != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Selected: ${_selList!.nameEnglish ?? _selList!.nameArabic ?? '—'}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // ===== Ownership & Status =====
              Glass(
                radius: 20,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ownership & Status',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      _TwoCol(
                        // Factory (object-typed dropdown so it never “locks”)
                        left: // ===== Factory (UNLOCKED) =====
                            // ===== Factory (UNLOCKED, backed by _factories) =====
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<int>(
                                    value:
                                        _factoryId, // may be null (that’s fine)
                                    isExpanded: true,
                                    menuMaxHeight: 360,
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      labelText: 'Factory',
                                      isDense: true,
                                    ),
                                    hint: const Text('Select a factory'),
                                    // IMPORTANT: build from _factories, not from data.factories
                                    items: _factories.map((m) {
                                      return DropdownMenuItem<int>(
                                        value: m
                                            .factoryId, // can be null; dropdown still opens
                                        child: Text(
                                          _factoryLabel(m),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (_factories.isEmpty)
                                        ? null
                                        : (int? v) {
                                            setState(() {
                                              _factoryId = v;
                                              _selFactory = (v == null)
                                                  ? null
                                                  : _factories.firstWhere(
                                                      (m) => m.factoryId == v,
                                                      orElse: () =>
                                                          _factories.first,
                                                    );
                                            });
                                            debugPrint(
                                              '[EquipEditor] selected factoryId=$_factoryId',
                                            );
                                          },
                                    onTap: () => debugPrint(
                                      '[EquipEditor] factory dropdown tapped',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Small refresh button to re-pull factories if needed
                                IconButton(
                                  tooltip: 'Refresh factories',
                                  onPressed: _loadFactories,
                                  icon: _loadingFactories
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.refresh),
                                ),
                              ],
                            ),

                        right: DropdownButtonFormField<DomainDetail>(
                          value: _selStatus,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Status (Domain 11)',
                            isDense: true,
                          ),
                          isExpanded: true,
                          items: data.statusD11
                              .map((d) => _dd<DomainDetail>(d, _labelDomain(d)))
                              .toList(),
                          onChanged: (d) => setState(() {
                            _selStatus = d;
                            _statusId = d?.domainDetailId;
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // ===== Logistics =====
              Glass(
                radius: 20,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Logistics',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      _TwoCol(
                        left: DropdownButtonFormField<DomainDetail>(
                          value: _selCategory,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Category (Domain 9)',
                            isDense: true,
                          ),
                          isExpanded: true,
                          items: data.categoryD9
                              .map((d) => _dd<DomainDetail>(d, _labelDomain(d)))
                              .toList(),
                          onChanged: (d) => setState(() {
                            _selCategory = d;
                            _categoryId = d?.domainDetailId;
                          }),
                        ),
                        right: DropdownButtonFormField<DomainDetail>(
                          value: _selFuel,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Fuel responsibility (Domain 7)',
                            isDense: true,
                          ),
                          isExpanded: true,
                          items: data.fuelD7
                              .map((d) => _dd<DomainDetail>(d, _labelDomain(d)))
                              .toList(),
                          onChanged: (d) => setState(() {
                            _selFuel = d;
                            _fuelRespId = d?.domainDetailId;
                          }),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _TwoCol(
                        left: DropdownButtonFormField<DomainDetail>(
                          value: _selTransferType,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Transfer type (Domain 8)',
                            isDense: true,
                          ),
                          isExpanded: true,
                          items: data.transferTypeD8
                              .map((d) => _dd<DomainDetail>(d, _labelDomain(d)))
                              .toList(),
                          onChanged: (d) => setState(() {
                            _selTransferType = d;
                            _transferTypeId = d?.domainDetailId;
                          }),
                        ),
                        right: DropdownButtonFormField<DomainDetail>(
                          value: _selTransferResp,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Transfer responsibility (Domain 7)',
                            isDense: true,
                          ),
                          isExpanded: true,
                          items: data.transferRespD7
                              .map((d) => _dd<DomainDetail>(d, _labelDomain(d)))
                              .toList(),
                          onChanged: (d) => setState(() {
                            _selTransferResp = d;
                            _transferRespId = d?.domainDetailId;
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // ===== Driver responsibilities =====
              Glass(
                radius: 20,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Driver responsibilities (Domain 7)',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      _TwoCol(
                        left: DropdownButtonFormField<DomainDetail>(
                          value: _selDriverTrans,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Transport',
                            isDense: true,
                          ),
                          isExpanded: true,
                          items: data.driverRespD7
                              .map((d) => _dd<DomainDetail>(d, _labelDomain(d)))
                              .toList(),
                          onChanged: (d) => setState(() {
                            _selDriverTrans = d;
                            _driverTransRespId = d?.domainDetailId;
                          }),
                        ),
                        right: DropdownButtonFormField<DomainDetail>(
                          value: _selDriverFood,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Food',
                            isDense: true,
                          ),
                          isExpanded: true,
                          items: data.driverRespD7
                              .map((d) => _dd<DomainDetail>(d, _labelDomain(d)))
                              .toList(),
                          onChanged: (d) => setState(() {
                            _selDriverFood = d;
                            _driverFoodRespId = d?.domainDetailId;
                          }),
                        ),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<DomainDetail>(
                        value: _selDriverHousing,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Housing',
                          isDense: true,
                        ),
                        isExpanded: true,
                        items: data.driverRespD7
                            .map((d) => _dd<DomainDetail>(d, _labelDomain(d)))
                            .toList(),
                        onChanged: (d) => setState(() {
                          _selDriverHousing = d;
                          _driverHousingRespId = d?.domainDetailId;
                        }),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // ===== Descriptions =====
              Glass(
                radius: 20,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Descriptions',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      AInput(
                        controller: _descEn,
                        label: 'Description (English)',
                        hint: 'e.g. Excavator 22T',
                        glyph: AppGlyph.edit,
                      ),
                      const SizedBox(height: 10),
                      AInput(
                        controller: _descAr,
                        label: 'الوصف (عربي)',
                        hint: 'مثال: حفّار ٢٢ طن',
                        glyph: AppGlyph.edit,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // ===== Pricing (two-way) + down payment preview
              Glass(
                radius: 20,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pricing',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      _TwoCol(
                        left: AInput(
                          controller: _priceDay,
                          label: 'Price per day',
                          hint: 'e.g. 1600',
                          glyph: AppGlyph.money,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setState(() {}),
                        ),
                        right: AInput(
                          controller: _priceHour,
                          label: 'Price per hour',
                          hint: 'e.g. 160',
                          glyph: AppGlyph.money,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Rule: 1 day = ${kHoursPerDay.toStringAsFixed(0)} hours. '
                        'Down payment = $kDownPaymentPercent%.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Down payment (auto): ${_fmt(_downPaymentAmount())}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // ===== Quantity
              Glass(
                radius: 20,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quantity',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      AInput(
                        controller: _qtyCtrl,
                        label: 'Quantity (also used as Available)',
                        hint: 'e.g. 1',
                        glyph: AppGlyph.info,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Available = Quantity, Reserved starts at 0 (both updated later).',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// Responsive helper
class _TwoCol extends StatelessWidget {
  const _TwoCol({required this.left, required this.right});
  final Widget left, right;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, c) {
        final two = c.maxWidth >= 700;
        if (!two)
          return Column(children: [left, const SizedBox(height: 10), right]);
        return Row(
          children: [
            Expanded(child: left),
            const SizedBox(width: 12),
            Expanded(child: right),
          ],
        );
      },
    );
  }
}

// lib/screens/equipment_editor_screen.dart
import 'package:flutter/material.dart';
import 'package:Ajjara/core/api/api_handler.dart' as api;

// Models
import 'package:Ajjara/core/models/equipment/equipment.dart';
import 'package:Ajjara/core/models/equipment/equipment_list.dart' as elist;
import 'package:Ajjara/core/models/admin/factory.dart' as fmodels;
import 'package:Ajjara/core/models/admin/domain.dart'; // DomainDetail

// UI bits
import 'package:Ajjara/foundation/ui/app_icons.dart';
import 'package:Ajjara/foundation/ui/ui_extras.dart';
import 'package:Ajjara/foundation/ui/ui_kit.dart';
import 'package:Ajjara/l10n/app_localizations.dart';
import 'package:intl/intl.dart' show Bidi;

extension _L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}

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
  final List<DomainDetail> categoryD9;
  final List<DomainDetail> fuelD7;
  final List<DomainDetail> transferTypeD8;
  final List<DomainDetail> transferRespD7;
  final List<DomainDetail> driverRespD7;

  _EditorData({
    required this.lists,
    required this.factories,
    required this.categoryD9,
    required this.fuelD7,
    required this.transferTypeD8,
    required this.transferRespD7,
    required this.driverRespD7,
  });
}

TextDirection _dirFor(String text, BuildContext ctx) {
  if (text.trim().isEmpty) {
    // default when empty: follow locale (so Arabic UI starts RTL)
    return Directionality.of(ctx);
  }
  final isRtl = Bidi.detectRtlDirectionality(text);
  return isRtl ? TextDirection.rtl : TextDirection.ltr;
}

Widget _dirWrap({
  required BuildContext context,
  required TextEditingController controller,
  required Widget child,
}) {
  return ValueListenableBuilder<TextEditingValue>(
    valueListenable: controller,
    builder: (_, v, __) =>
        Directionality(textDirection: _dirFor(v.text, context), child: child),
  );
}

class _EquipmentEditorScreenState extends State<EquipmentEditorScreen> {
  // ===== Controllers / focus
  final _descEn = TextEditingController();
  final _descAr = TextEditingController();
  final _priceDay = TextEditingController();
  final _priceHour = TextEditingController();
  final _qtyCtrl = TextEditingController(text: '1');
  final _dpCtrl = TextEditingController(); // optional down payment %

  final _dayFocus = FocusNode();
  final _hourFocus = FocusNode();
  // Add near your other state:
  bool _autoFromDay = false; // we just set hour from day
  bool _autoFromHour = false; // we just set day from hour

  double _dpPercent() => double.tryParse(_dpCtrl.text.trim()) ?? 0.0;
  double _perDay() => double.tryParse(_priceDay.text.trim()) ?? 0.0;
  double _perHour() => double.tryParse(_priceHour.text.trim()) ?? 0.0;

  void _setHourFromDay() {
    final d = _perDay();
    _priceSyncGuard = true;
    _priceHour.text = _fmt(d / kHoursPerDay);
    _priceSyncGuard = false;
    _autoFromDay = true;
    _autoFromHour = false;
  }

  void _setDayFromHour() {
    final h = _perHour();
    _priceSyncGuard = true;
    _priceDay.text = _fmt(h * kHoursPerDay);
    _priceSyncGuard = false;
    _autoFromHour = true;
    _autoFromDay = false;
  }

  // Inputs
  // ignore: unused_field
  String? _errDescEn, _errDescAr, _errPriceDay, _errPriceHour, _errQty;

  // Dropdowns
  bool _errType = false;
  bool _errList = false;
  bool _errFactory = false;
  bool _errFuel = false;
  bool _errTransferType = false;
  bool _errTransferResp = false;
  bool _errDriverTrans = false;
  bool _errDriverFood = false;
  bool _errDriverHousing = false;

  void _clearErrors() {
    _errDescEn = _errDescAr = _errPriceDay = _errPriceHour = _errQty = null;
    _errType = _errList = _errFactory = false;
    _errFuel = _errTransferType = _errTransferResp = false;
    _errDriverTrans = _errDriverFood = _errDriverHousing = false;
  }

  bool _isBlank(TextEditingController c) => c.text.trim().isEmpty;
  int _safeQty() => int.tryParse(_qtyCtrl.text.trim()) ?? 0;
  double? _safeD(TextEditingController c) => double.tryParse(c.text.trim());

  bool _validateAndWarn() {
    final errs = <String>[];

    // Required picks
    if (_selType == null) errs.add('Select an equipment type.');
    if (_selList == null) errs.add('Select an equipment from the list.');
    if (_factoryId == null) errs.add('Select a factory.');

    // Descriptions: require at least one
    if (_isBlank(_descEn) && _isBlank(_descAr)) {
      errs.add('Enter a description (English or Arabic).');
    }

    // Domain dropdowns
    if (_fuelRespId == null) errs.add('Select fuel responsibility.');
    if (_transferTypeId == null) errs.add('Select transfer type.');
    if (_transferRespId == null) errs.add('Select transfer responsibility.');
    if (_driverTransRespId == null) {
      errs.add('Select driver transport responsibility.');
    }
    if (_driverFoodRespId == null) {
      errs.add('Select driver food responsibility.');
    }
    if (_driverHousingRespId == null) {
      errs.add('Select driver housing responsibility.');
    }

    // Pricing & quantity
    final perDay = _safeD(_priceDay);
    final perHour = _safeD(_priceHour);
    final qty = _safeQty();

    if (perDay == null || perDay <= 0) errs.add('Enter price per day (> 0).');
    if (perHour == null || perHour <= 0) {
      errs.add('Enter price per hour (> 0).');
    }
    if (qty <= 0) errs.add('Enter quantity (≥ 1).');

    if (errs.isEmpty) return true;

    // Show all issues at once
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Please complete the form'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: errs
              .map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• '),
                      Expanded(child: Text(e)),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    return false;
  }

  bool _canSaveNow() {
    return _selType != null &&
        _selList != null &&
        _factoryId != null &&
        !(_isBlank(_descEn) && _isBlank(_descAr)) &&
        _fuelRespId != null &&
        _transferTypeId != null &&
        _transferRespId != null &&
        _driverTransRespId != null &&
        _driverFoodRespId != null &&
        _driverHousingRespId != null &&
        (_safeD(_priceDay) ?? 0) > 0 &&
        (_safeD(_priceHour) ?? 0) > 0 &&
        _safeQty() > 0;
  }

  void _onContinuePressed() {
    if (_canSaveNow()) {
      _clearErrors();
      _save();
      return;
    }

    // mark errors
    _errType = _selType == null;
    _errList = _selList == null;
    _errFactory = _factoryId == null;

    final hasDesc =
        _descEn.text.trim().isNotEmpty || _descAr.text.trim().isNotEmpty;
    if (!hasDesc) {
      // show error on both so user sees red wherever they choose to type
      _errDescEn = context.l10n.errDescRequiredEnOrAr;
      _errDescAr = context.l10n.errDescRequiredEnOrAr;
    }

    _errFuel = _fuelRespId == null;
    _errTransferType = _transferTypeId == null;
    _errTransferResp = _transferRespId == null;
    _errDriverTrans = _driverTransRespId == null;
    _errDriverFood = _driverFoodRespId == null;
    _errDriverHousing = _driverHousingRespId == null;

    final d = double.tryParse(_priceDay.text.trim());
    final h = double.tryParse(_priceHour.text.trim());
    final q = int.tryParse(_qtyCtrl.text.trim());
    if (d == null || d <= 0) _errPriceDay = context.l10n.errPricePerDayGtZero;
    if (h == null || h <= 0) _errPriceHour = context.l10n.errPricePerHourGtZero;
    if (q == null || q <= 0) _errQty = context.l10n.errQuantityGteOne;

    // choose the first missing thing for the SnackBar
    final l10n = context.l10n;

    final String msg = _errType
        ? l10n.errSelectEquipmentType
        : _errList
        ? l10n.errSelectEquipmentFromList
        : _errFactory
        ? l10n.errSelectFactory
        : !hasDesc
        ? l10n.errEnterDescriptionEnOrAr
        : _errFuel
        ? l10n.errSelectFuelResponsibility
        : _errTransferType
        ? l10n.errSelectTransferType
        : _errTransferResp
        ? l10n.errSelectTransferResponsibility
        : _errDriverTrans
        ? l10n.errSelectDriverTransport
        : _errDriverFood
        ? l10n.errSelectDriverFood
        : _errDriverHousing
        ? l10n.errSelectDriverHousing
        : _errPriceDay != null
        ? l10n.errPricePerDayGtZero
        : _errPriceHour != null
        ? l10n.errPricePerHourGtZero
        : _errQty != null
        ? l10n.errQuantityGteOne
        : l10n.errPleaseCompleteForm;

    setState(() {}); // apply red states

    // SnackBar
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ===== Selected objects
  DomainDetail? _selType; // 1st dropdown (type pick)
  elist.EquipmentListModel? _selList; // 2nd dropdown (final pick sent)
  fmodels.FactoryModel? _selFactory;

  // Backing IDs
  int? _equipmentListId; // derived from _selList (final pick)
  int? _factoryId;

  List<fmodels.FactoryModel> _factories = [];
  bool _loadingFactories = false;

  bool _descLocked = false;

  void _applyListDescriptions(elist.EquipmentListModel? m) {
    if (m == null) {
      setState(() {
        _descEn.clear();
        _descAr.clear();
        _descLocked = false;
      });
      return;
    }

    // Try common description fields; fall back to name/primaryUse if needed.
    final en = [
      (m.primaryUseArabic ?? '').trim(),
      (m.primaryUseEnglish ?? '').trim(),
      (m.primaryUseEnglish ?? '').trim(),
    ].firstWhere((s) => s.isNotEmpty, orElse: () => '');

    final ar = [
      (m.primaryUseArabic ?? '').trim(),
      (m.primaryUseArabic ?? '').trim(),
      (m.primaryUseArabic ?? '').trim(),
    ].firstWhere((s) => s.isNotEmpty, orElse: () => '');

    setState(() {
      _descEn.text = en;
      _descAr.text = ar;
      _descLocked = en.isNotEmpty || ar.isNotEmpty; // lock only if we have text
    });
  }

  // Domains (IDs only)
  int? _categoryId;
  int? _fuelRespId;
  int? _transferTypeId;
  int? _transferRespId;
  int? _driverTransRespId;
  int? _driverFoodRespId;
  int? _driverHousingRespId;

  // ===== Pricing rules
  static const double kHoursPerDay = 10.0;
  bool _priceSyncGuard = false;

  late Future<_EditorData> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadAll();
    _loadFactories();

    _descEn.addListener(() => setState(() => _errDescEn = null));
    _descAr.addListener(() => setState(() => _errDescAr = null));
    _priceDay.addListener(() => setState(() => _errPriceDay = null));
    _priceHour.addListener(() => setState(() => _errPriceHour = null));
    _qtyCtrl.addListener(() => setState(() => _errQty = null));

    // Day -> Hour
    _priceDay.addListener(() {
      if (_priceSyncGuard || !_dayFocus.hasFocus) return;
      final d = _toD(_priceDay.text);
      _priceSyncGuard = true;
      if (d != null) {
        _priceHour.text = _fmt(d / kHoursPerDay);
        _autoFromDay = true; // ← show hint next to hour
        _autoFromHour = false;
      }
      _priceSyncGuard = false;
      setState(() {});
    });

    // Hour -> Day
    _priceHour.addListener(() {
      if (_priceSyncGuard || !_hourFocus.hasFocus) return;
      final h = _toD(_priceHour.text);
      _priceSyncGuard = true;
      if (h != null) {
        _priceDay.text = _fmt(h * kHoursPerDay);
        _autoFromHour = true; // ← show hint next to day
        _autoFromDay = false;
      }
      _priceSyncGuard = false;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _descEn.dispose();
    _descAr.dispose();
    _priceDay.dispose();
    _priceHour.dispose();
    _qtyCtrl.dispose();
    _dpCtrl.dispose();
    _dayFocus.dispose();
    _hourFocus.dispose();
    super.dispose();
  }

  // ===== Load lists/factories/domains
  Future<_EditorData> _loadAll() async {
    final lists = await api.Api.getEquipmentLists();
    final factories = await api.Api.getFactories();
    final categoryD9 = await api.Api.getDomainDetailsByDomainId(9);
    final fuelD7 = await api.Api.getDomainDetailsByDomainId(7);
    final transferTypeD8 = await api.Api.getDomainDetailsByDomainId(8);
    final transferRespD7 = fuelD7;
    final driverRespD7 = fuelD7;

    debugPrint(
      '[EquipEditor] lists=${lists.length} '
      'factories=${factories.length} '
      'D9=${categoryD9.length} D7=${fuelD7.length} D8=${transferTypeD8.length}',
    );

    return _EditorData(
      lists: lists.where((e) => (e.isActive ?? true)).toList(),
      factories: factories.where((e) => (e.isActive ?? true)).toList(),
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

      final next = List<fmodels.FactoryModel>.from(list);
      next.sort((a, b) => (a.nameEnglish ?? '').compareTo(b.nameEnglish ?? ''));

      setState(() {
        _factories = next;

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
    return en.isNotEmpty
        ? en
        : (ar.isNotEmpty ? ar : context.l10n.unnamedFactory);
  }

  String _labelDomain(DomainDetail d) =>
      (d.detailNameEnglish?.trim().isNotEmpty ?? false)
      ? d.detailNameEnglish!.trim()
      : (d.detailNameArabic ?? '—');

  DropdownMenuItem<T> _dd<T>(T value, String label) => DropdownMenuItem<T>(
    value: value,
    child: Text(label, overflow: TextOverflow.ellipsis),
  );

  // ===== Save (returns draft to caller)
  Future<void> _save() async {
    if (!_validateAndWarn()) return;
    // final Equipment List ID comes from the second dropdown if chosen, else from the first.
    final effectiveListId = _selList?.equipmentListId;
    if (effectiveListId == null) {
      AppSnack.error(context, 'Choose an equipment list');
      return;
    }
    // Ensure category from type:
    _categoryId = _selType?.domainDetailId;
    if (_selFactory == null || _factoryId == null) {
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
    final downPerc = _toD(_dpCtrl.text) ?? 0; // 0 if not provided

    final draft = Equipment(
      // Required/type
      equipmentListId: effectiveListId,
      factoryId: _factoryId,
      descEnglish: _descEn.text.trim().isNotEmpty ? _descEn.text.trim() : null,
      descArabic: _descAr.text.trim().isNotEmpty ? _descAr.text.trim() : null,

      // Always send INACTIVE (domain detail id 27)
      statusId: 27,
      isActive: false,

      // Domains (IDs only)
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
      downPaymentPerc: downPerc, // user-provided or 0
      // Quantities
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

    EdgeInsets sectionPad() => const EdgeInsets.fromLTRB(0, 12, 0, 12);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.equipEditorTitleNew)),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: BrandButton(
            onPressed: _onContinuePressed,
            icon: AIcon(AppGlyph.check, color: Colors.white, selected: true),
            child: Text(context.l10n.actionContinue),
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
                      Text(context.l10n.errorFailedToLoadOptions),
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
                        child: Text(context.l10n.actionRetry),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          final data = snap.data!;
          return ListView(
            padding: const EdgeInsets.fromLTRB(7, 12, 7, 24),
            children: [
              // ===== Type (Equipment Type from Domain 9 + Equipment List) =====
              Glass(
                radius: 20,
                child: Padding(
                  padding: sectionPad(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.sectionType,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),

                      // 1) Equipment Type (Domain 9)
                      DropdownButtonFormField<DomainDetail>(
                        initialValue: _selType,
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          labelText:
                              context.l10n.labelCategoryD9, // “Equipment Type”
                          isDense: true,
                        ),
                        isExpanded: true,
                        items: data.categoryD9
                            .map((d) => _dd<DomainDetail>(d, _labelDomain(d)))
                            .toList(),
                        onChanged: (d) {
                          setState(() {
                            _selType = d;
                            _categoryId =
                                d?.domainDetailId; // bind type -> categoryId
                          });
                        },
                      ),

                      const SizedBox(height: 10),

                      // 2) Equipment List (final pick sent to API)
                      DropdownButtonFormField<elist.EquipmentListModel>(
                        initialValue: _selList,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: context.l10n.equipmentTitle,
                          isDense: true,
                        ),
                        isExpanded: true,
                        items: data.lists.map((m) {
                          final label = [
                            if ((m.nameEnglish ?? '').trim().isNotEmpty)
                              m.nameEnglish!.trim(),
                            if ((m.primaryUseEnglish ?? '').trim().isNotEmpty)
                              '· ${m.primaryUseEnglish!.trim()}',
                          ].join(' ');
                          return _dd<elist.EquipmentListModel>(m, label);
                        }).toList(),
                        onChanged: (m) {
                          setState(() {
                            _selList = m;
                            _equipmentListId = m?.equipmentListId;
                          });
                          _applyListDescriptions(m);
                          debugPrint(
                            '[EquipEditor] FINAL listId=$_equipmentListId',
                          );
                        },
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
                  padding: sectionPad(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.sectionDescriptions,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      _dirWrap(
                        context: context,
                        controller: _descEn,
                        child: AInput(
                          controller: _descEn,
                          label: context.l10n.labelDescEnglish,
                          hint: context.l10n.hintDescEnglish,
                          glyph: AppGlyph.edit,
                          readOnly: _descLocked,
                          maxLines: 2,
                          // If AInput exposes textAlign, you can also set:
                          // textAlign: Bidi.detectRtlDirectionality(_descEn.text) ? TextAlign.right : TextAlign.left,
                        ),
                      ),

                      const SizedBox(height: 10),

                      _dirWrap(
                        context: context,
                        controller: _descAr,
                        child: AInput(
                          controller: _descAr,
                          label: context.l10n.labelDescArabic,
                          hint: context.l10n.hintDescArabic,
                          glyph: AppGlyph.edit,
                          readOnly: _descLocked,
                          maxLines: 2,
                          // textAlign: Bidi.detectRtlDirectionality(_descAr.text) ? TextAlign.right : TextAlign.left,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // ===== Ownership (Factory) — Status removed
              Glass(
                radius: 20,
                child: Padding(
                  padding: sectionPad(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.sectionOwnershipStatus,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      _TwoCol(
                        left: Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                initialValue: _factoryId,
                                isExpanded: true,
                                menuMaxHeight: 360,
                                decoration: InputDecoration(
                                  border: const OutlineInputBorder(),
                                  labelText: context.l10n.labelFactory,
                                  isDense: true,
                                ),
                                hint: Text(context.l10n.hintSelectFactory),
                                items: _factories.map((m) {
                                  return DropdownMenuItem<int>(
                                    value: m.factoryId,
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
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              tooltip: context.l10n.tooltipRefreshFactories,
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
                        right: const SizedBox.shrink(), // status removed
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
                  padding: sectionPad(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.sectionLogistics,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      _TwoCol(
                        left: SizedBox(),
                        right: DropdownButtonFormField<DomainDetail>(
                          initialValue: data.fuelD7.firstWhere(
                            (d) => d.domainDetailId == _fuelRespId,
                            orElse: () =>
                                (null as DomainDetail?) ?? data.fuelD7.first,
                          ),
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            labelText: context.l10n.labelFuelRespD7,
                            isDense: true,
                          ),
                          isExpanded: true,
                          items: data.fuelD7
                              .map((d) => _dd<DomainDetail>(d, _labelDomain(d)))
                              .toList(),
                          onChanged: (d) => setState(() {
                            _fuelRespId = d?.domainDetailId;
                          }),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _TwoCol(
                        left: DropdownButtonFormField<DomainDetail>(
                          initialValue: data.transferTypeD8.firstWhere(
                            (d) => d.domainDetailId == _transferTypeId,
                            orElse: () =>
                                (null as DomainDetail?) ??
                                data.transferTypeD8.first,
                          ),
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            labelText: context.l10n.labelTransferTypeD8,
                            isDense: true,
                          ),
                          isExpanded: true,
                          items: data.transferTypeD8
                              .map((d) => _dd<DomainDetail>(d, _labelDomain(d)))
                              .toList(),
                          onChanged: (d) => setState(() {
                            _transferTypeId = d?.domainDetailId;
                          }),
                        ),
                        right: DropdownButtonFormField<DomainDetail>(
                          initialValue: data.transferRespD7.firstWhere(
                            (d) => d.domainDetailId == _transferRespId,
                            orElse: () =>
                                (null as DomainDetail?) ??
                                data.transferRespD7.first,
                          ),
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            labelText: context.l10n.labelTransferRespD7,
                            isDense: true,
                          ),
                          isExpanded: true,
                          items: data.transferRespD7
                              .map((d) => _dd<DomainDetail>(d, _labelDomain(d)))
                              .toList(),
                          onChanged: (d) => setState(() {
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
                  padding: sectionPad(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.sectionDriverRespD7,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      _TwoCol(
                        left: DropdownButtonFormField<DomainDetail>(
                          initialValue: data.driverRespD7.firstWhere(
                            (d) => d.domainDetailId == _driverTransRespId,
                            orElse: () =>
                                (null as DomainDetail?) ??
                                data.driverRespD7.first,
                          ),
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            labelText: context.l10n.labelTransport,
                            isDense: true,
                          ),
                          isExpanded: true,
                          items: data.driverRespD7
                              .map((d) => _dd<DomainDetail>(d, _labelDomain(d)))
                              .toList(),
                          onChanged: (d) => setState(() {
                            _driverTransRespId = d?.domainDetailId;
                          }),
                        ),
                        right: DropdownButtonFormField<DomainDetail>(
                          initialValue: data.driverRespD7.firstWhere(
                            (d) => d.domainDetailId == _driverFoodRespId,
                            orElse: () =>
                                (null as DomainDetail?) ??
                                data.driverRespD7.first,
                          ),
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            labelText: context.l10n.labelFood,
                            isDense: true,
                          ),
                          isExpanded: true,
                          items: data.driverRespD7
                              .map((d) => _dd<DomainDetail>(d, _labelDomain(d)))
                              .toList(),
                          onChanged: (d) => setState(() {
                            _driverFoodRespId = d?.domainDetailId;
                          }),
                        ),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<DomainDetail>(
                        initialValue: data.driverRespD7.firstWhere(
                          (d) => d.domainDetailId == _driverHousingRespId,
                          orElse: () =>
                              (null as DomainDetail?) ??
                              data.driverRespD7.first,
                        ),
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          labelText: context.l10n.labelHousing,
                          isDense: true,
                        ),
                        isExpanded: true,
                        items: data.driverRespD7
                            .map((d) => _dd<DomainDetail>(d, _labelDomain(d)))
                            .toList(),
                        onChanged: (d) => setState(() {
                          _driverHousingRespId = d?.domainDetailId;
                        }),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // ===== Pricing (two-way) + optional down payment %, with "Calculated" hints
              Glass(
                radius: 20,
                child: Padding(
                  padding: sectionPad(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.sectionPricing,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),

                      _TwoCol(
                        left: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AInput(
                              controller: _priceDay,
                              label: context.l10n.labelPricePerDay,
                              hint: context.l10n.hintPricePerDay,
                              glyph: AppGlyph.money,
                              keyboardType: TextInputType.number,
                              onChanged: (_) {
                                if (_priceSyncGuard) return;
                                _setHourFromDay(); // ← fill hour immediately
                                setState(() {});
                              },
                            ),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 180),
                              child: _autoFromHour
                                  ? Padding(
                                      key: const ValueKey('calc_day'),
                                      padding: const EdgeInsets.only(top: 4),
                                      child: _CalculatedHint(
                                        text:
                                            'Calculated from price/hour × ${kHoursPerDay.toStringAsFixed(0)}',
                                      ),
                                    )
                                  : const SizedBox.shrink(
                                      key: ValueKey('no_calc_day'),
                                    ),
                            ),
                          ],
                        ),
                        right: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AInput(
                              controller: _priceHour,
                              label: context.l10n.labelPricePerHour,
                              hint: context.l10n.hintPricePerHour,
                              glyph: AppGlyph.money,
                              keyboardType: TextInputType.number,
                              onChanged: (_) {
                                if (_priceSyncGuard) return;
                                _setDayFromHour(); // ← fill day immediately
                                setState(() {});
                              },
                            ),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 180),
                              child: _autoFromDay
                                  ? Padding(
                                      key: const ValueKey('calc_hour'),
                                      padding: const EdgeInsets.only(top: 4),
                                      child: _CalculatedHint(
                                        text:
                                            'Calculated from price/day ÷ ${kHoursPerDay.toStringAsFixed(0)}',
                                      ),
                                    )
                                  : const SizedBox.shrink(
                                      key: ValueKey('no_calc_hour'),
                                    ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),

                      AInput(
                        controller: _dpCtrl,
                        label: context.l10n.downPaymentLabel,
                        hint: context.l10n.leaveEmpty,
                        glyph: AppGlyph.money,
                        keyboardType: TextInputType.number,
                        onChanged: (_) =>
                            setState(() {}), // ← live recompute in the text
                      ),

                      const SizedBox(height: 10),
                      // Use the actual DP % the user typed, and show computed amount too.
                      Builder(
                        builder: (_) {
                          final dp = _dpPercent().clamp(0, 100);
                          final perDay = _perDay();
                          final dpAmount = perDay * (dp / 100.0);

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                // first line: rule with the user's DP %
                                context.l10n.ruleHoursPerDayAndDp(
                                  kHoursPerDay.toStringAsFixed(0),
                                  dp.toStringAsFixed(
                                    0,
                                  ), // show the live % instead of '—'
                                ),
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                              const SizedBox(height: 6),
                              // second line: computed amount based on price/day
                              Text(
                                // If you have a localization like downPaymentAuto, use it:
                                // context.l10n.downPaymentAuto(_fmt(dpAmount)),
                                // fallback:
                                '${context.l10n.downPaymentLabel}: ${_fmt(dpAmount)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          );
                        },
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
                  padding: sectionPad(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.sectionQuantity,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      AInput(
                        controller: _qtyCtrl,
                        label: context.l10n.labelQuantityAlsoAvailable,
                        hint: context.l10n.hintQuantity,
                        glyph: AppGlyph.info,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        context.l10n.noteAvailableReserved,
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
        if (!two) {
          return Column(children: [left, const SizedBox(height: 10), right]);
        }
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

class _CalculatedHint extends StatelessWidget {
  const _CalculatedHint({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
      ),
    );
  }
}

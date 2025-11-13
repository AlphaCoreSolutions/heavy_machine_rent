import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:Ajjara/core/auth/auth_store.dart';
import 'package:Ajjara/core/api/api_handler.dart' as api;
import 'package:Ajjara/core/models/admin/domain.dart';
import 'package:Ajjara/core/models/equipment/equipment.dart';

import 'package:Ajjara/core/models/user/nationality.dart';
import 'package:Ajjara/foundation/ui/app_icons.dart';
import 'package:Ajjara/foundation/ui/ui_extras.dart';
import 'package:Ajjara/foundation/ui/ui_kit.dart';
import 'package:Ajjara/l10n/app_localizations.dart';

extension _L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}

class EquipmentSettingsScreen extends StatefulWidget {
  const EquipmentSettingsScreen({super.key, required this.equipmentId});
  final int equipmentId;

  @override
  State<EquipmentSettingsScreen> createState() =>
      _EquipmentSettingsScreenState();
}

class _EquipmentSettingsScreenState extends State<EquipmentSettingsScreen>
    with SingleTickerProviderStateMixin {
  // ---------- auth gate ----------
  bool get _loggedIn => AuthStore.instance.isLoggedIn;

  // ---------- data ----------
  late Future<Equipment> _future;
  Equipment? _original; // authoritative GET snapshot
  bool _seeded = false;

  // ---------- tabs / nav guard ----------
  late TabController _tabs;
  int _tabIndex = 0;
  bool _dirtyOverview = false;
  bool get _anyDirty => _dirtyOverview;

  // ---------- consts / rules ----------
  static const double _kHoursPerDay = 10.0;
  static const int _kDownPaymentPercent = 20;

  // ---------- overview controllers ----------
  final _enCtrl = TextEditingController();
  final _arCtrl = TextEditingController();
  final _priceDayCtrl = TextEditingController();
  final _priceHourCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  bool _isActive = true;

  bool _syncGuard = false;

  @override
  void initState() {
    super.initState();
    if (!_loggedIn) return;
    _future = api.Api.getEquipmentById(widget.equipmentId);
    _tabs = TabController(length: 5, vsync: this)
      ..addListener(() {
        if (!_tabs.indexIsChanging) return;
        _handleTabChange(_tabs.index);
      });

    // price sync (no setState during build)
    _priceDayCtrl.addListener(() {
      if (_hydrating || _syncGuard) return;
      final d = _toD(_priceDayCtrl.text);
      if (d == null) return;
      _syncGuard = true;
      final newHour = _fmt(d / _kHoursPerDay);
      if (_priceHourCtrl.text != newHour) _priceHourCtrl.text = newHour;
      _syncGuard = false;
      _markDirty();
    });

    _priceHourCtrl.addListener(() {
      if (_hydrating || _syncGuard) return;
      final h = _toD(_priceHourCtrl.text);
      if (h == null) return;
      _syncGuard = true;
      final newDay = _fmt(h * _kHoursPerDay);
      if (_priceDayCtrl.text != newDay) _priceDayCtrl.text = newDay;
      _syncGuard = false;
      _markDirty();
    });

    for (final c in [_enCtrl, _arCtrl, _qtyCtrl, _weightCtrl]) {
      c.addListener(_markDirty);
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    _enCtrl.dispose();
    _arCtrl.dispose();
    _priceDayCtrl.dispose();
    _priceHourCtrl.dispose();
    _qtyCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  // ---------- helpers ----------
  bool _hydrating = false;

  void _markDirty() {
    if (_hydrating) return;
    if (!_dirtyOverview) {
      setState(() {
        _dirtyOverview = true;
      });
    }
  }

  int? _toInt(String s) => int.tryParse(s.trim());
  double? _toD(String s) => double.tryParse(s.trim().replaceAll(',', '.'));
  String _fmt(num n) {
    final d = n.toDouble();
    return (d.truncateToDouble() == d)
        ? d.toStringAsFixed(0)
        : d.toStringAsFixed(2);
  }

  Future<void> _reload() async {
    setState(() {
      _seeded = false;
      _future = api.Api.getEquipmentById(widget.equipmentId);
    });
  }

  // ---------- nav guard ----------
  Future<bool> _confirmLoseChanges() async {
    if (!_anyDirty) return true;
    final choice = await showDialog<_LeaveChoice>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Unsaved changes'),
        content: const Text(
          'You have unsaved changes. Save them before leaving?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(
              dialogCtx,
              rootNavigator: true,
            ).pop(_LeaveChoice.cancel),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(
              dialogCtx,
              rootNavigator: true,
            ).pop(_LeaveChoice.discard),
            child: const Text('Discard'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(
              dialogCtx,
              rootNavigator: true,
            ).pop(_LeaveChoice.save),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (choice == _LeaveChoice.cancel || choice == null) return false;
    if (choice == _LeaveChoice.save) {
      final ok = await _saveOverviewInternal();
      return ok;
    }
    return true; // discard
  }

  void _handleTabChange(int nextIndex) async {
    if (!_anyDirty) {
      setState(() {
        _tabIndex = nextIndex;
      });
      return;
    }
    final ok = await _confirmLoseChanges();
    if (!mounted) return;
    if (ok) {
      setState(() {
        _dirtyOverview = false;
        _tabIndex = nextIndex;
        _tabs.index = nextIndex;
      });
    } else {
      setState(() {
        _tabs.index = _tabIndex;
      });
    }
  }

  // ---------- overview save ----------
  Future<bool> _saveOverviewInternal() async {
    final e = _original;
    if (e == null) return false;

    // derive edited values
    final perDay = _toD(_priceDayCtrl.text) ?? 0;
    final perHour = _toD(_priceHourCtrl.text) ?? (perDay / _kHoursPerDay);
    final qty = _toInt(_qtyCtrl.text) ?? 0;
    final weight = _toD(_weightCtrl.text) ?? 0;

    // Build a full-object PUT *without* nested lists/objects
    final put = Equipment(
      equipmentId: e.equipmentId,
      // names / flags
      descEnglish: _enCtrl.text.trim().isNotEmpty ? _enCtrl.text.trim() : null,
      descArabic: _arCtrl.text.trim().isNotEmpty ? _arCtrl.text.trim() : null,
      isActive: _isActive,
      // identity / ownership
      vendorId: e.vendorId,
      // scalar IDs (keep originals)
      equipmentListId: e.equipmentListId,
      factoryId: e.factoryId,
      statusId: e.statusId,
      mileage: e.mileage ?? 0,
      categoryId: e.categoryId,
      fuelResponsibilityId: e.fuelResponsibilityId,
      transferTypeId: e.transferTypeId,
      transferResponsibilityId: e.transferResponsibilityId,
      driverTransResponsibilityId: e.driverTransResponsibilityId,
      driverFoodResponsibilityId: e.driverFoodResponsibilityId,
      driverHousingResponsibilityId: e.driverHousingResponsibilityId,
      rentOutRegion: e.rentOutRegion ?? true,

      // pricing
      rentPricePerDay: perDay,
      rentPricePerHour: perHour,
      isDistancePrice: e.isDistancePrice ?? false,
      rentPricePerDistance: e.rentPricePerDistance ?? 0,
      distanceKilo: e.distanceKilo ?? 0,
      downPaymentPerc: _kDownPaymentPercent,
      haveCertificates: e.haveCertificates ?? false,

      // quantities
      quantity: qty,
      availableQuantity: qty, // mirrors quantity
      reservedQuantity: e.reservedQuantity ?? 0,
      rentQuantity: e.rentQuantity ?? 0,

      // misc
      equipmentWeight: weight,
      equipmentPath: e.equipmentPath ?? '',
      // EXPLICITLY OMIT nested
      organization: null,
      status: null,
      category: null,
      fuelResponsibility: null,
      transferType: null,
      transferResponsibility: null,
      drivers: null,
      equipmentTerms: null,
      equipmentImages: null,
      equipmentCertificates: null,
    );

    try {
      await api.Api.updateEquipment(put);
      if (!mounted) return false;
      AppSnack.success(context, context.l10n.saved);
      setState(() {
        _dirtyOverview = false;
      });
      await _reload();
      return true;
    } catch (e) {
      if (!mounted) return false;
      AppSnack.error(context, context.l10n.saveFailedWithMsg('$e'));
      return false;
    }
  }

  Future<void> _saveOverview() async {
    await _saveOverviewInternal();
  }

  // ---------- seed controllers once ----------
  void _seedOnce(Equipment e) {
    if (_seeded) return;
    _seeded = true;
    _original = e;

    _hydrating = true;

    _enCtrl.text = e.descEnglish ?? '';
    _arCtrl.text = e.descArabic ?? '';
    final day = e.rentPerDayDouble ?? 0;
    final hour = e.rentPerHourDouble ?? (day / _kHoursPerDay);
    _priceDayCtrl.text = _fmt(day);
    _priceHourCtrl.text = _fmt(hour);
    _qtyCtrl.text = (e.quantity ?? 0).toString();
    _weightCtrl.text = (e.equipmentWeight ?? 0).toString();
    _isActive = e.isActive ?? true;

    _dirtyOverview = false;

    WidgetsBinding.instance.addPostFrameCallback((_) => _hydrating = false);
  }

  // ---------- build ----------
  @override
  Widget build(BuildContext context) {
    if (!_loggedIn) {
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.equipSettingsTitle)),
        body: Center(child: Text(context.l10n.signInRequired)),
      );
    }

    final cs = Theme.of(context).colorScheme;
    return WillPopScope(
      onWillPop: () async => await _confirmLoseChanges(),
      child: ScrollConfiguration(
        behavior: const _DesktopScrollBehavior(),
        child: Scaffold(
          appBar: AppBar(
            title: Text(context.l10n.equipSettingsTitle),
            bottom: TabBar(
              controller: _tabs,
              isScrollable: true,
              onTap: (i) {
                if (_anyDirty) _handleTabChange(i);
              },
              tabs: [
                Tab(text: context.l10n.tabOverview),
                Tab(text: context.l10n.tabImages),
                Tab(text: context.l10n.tabTerms),
                Tab(text: context.l10n.tabDrivers),
                Tab(text: context.l10n.tabCertificates),
              ],
            ),
          ),

          body: FutureBuilder<Equipment>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError || !snap.hasData) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Failed to load equipment'),
                        const SizedBox(height: 8),
                        Text(
                          '${snap.error}',
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(color: cs.error),
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _reload,
                          child: Text(context.l10n.actionRetry),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final e = snap.data!;
              _seedOnce(e);

              return TabBarView(
                controller: _tabs,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _OverviewTab(
                    enCtrl: _enCtrl,
                    arCtrl: _arCtrl,
                    priceDayCtrl: _priceDayCtrl,
                    priceHourCtrl: _priceHourCtrl,
                    qtyCtrl: _qtyCtrl,
                    weightCtrl: _weightCtrl,
                    dpPercent: _kDownPaymentPercent.toDouble(),
                    isActive: _isActive,
                    onToggleActive: (v) => setState(() {
                      _isActive = v;
                      _dirtyOverview = true;
                    }),
                    onSave: _saveOverview,
                  ),
                  _ImagesTab(equipmentId: e.equipmentId!, onChanged: _reload),
                  _TermsTab(equipmentId: e.equipmentId!, onChanged: _reload),
                  _DriversTab(equipmentId: e.equipmentId!, onChanged: _reload),
                  _CertificatesTab(
                    equipmentId: e.equipmentId!,
                    certs: e.equipmentCertificates ?? const [],
                    folderName: api.Api.equipCertsFolder,
                    onChanged: _reload,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

enum _LeaveChoice { save, discard, cancel }

// ---------------- Overview ----------------

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({
    required this.enCtrl,
    required this.arCtrl,
    required this.priceDayCtrl,
    required this.priceHourCtrl,
    required this.qtyCtrl,
    required this.weightCtrl,
    required this.dpPercent,
    required this.isActive,
    required this.onToggleActive,
    required this.onSave,
  });

  final TextEditingController enCtrl,
      arCtrl,
      priceDayCtrl,
      priceHourCtrl,
      qtyCtrl,
      weightCtrl;
  final double dpPercent;
  final bool isActive;
  final ValueChanged<bool> onToggleActive;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    Widget title(String t) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(t, style: Theme.of(context).textTheme.headlineSmall),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Glass(
          radius: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              title(context.l10n.basicInfo),
              _TwoCol(
                left: AInput(
                  controller: enCtrl,
                  label: context.l10n.nameEn,
                  glyph: AppGlyph.edit,
                  hint: context.l10n.exampleExcavator,
                ),
                right: AInput(
                  controller: arCtrl,
                  label: context.l10n.nameAr,
                  glyph: AppGlyph.edit,
                  hint: context.l10n.exampleExcavatorAr,
                ),
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
              title(context.l10n.pricing),
              _TwoCol(
                left: AInput(
                  controller: priceDayCtrl,
                  label: context.l10n.filterPriceDay,
                  glyph: AppGlyph.money,
                  keyboardType: TextInputType.number,
                ),
                right: AInput(
                  controller: priceHourCtrl,
                  label: context.l10n.pricePerHour,
                  glyph: AppGlyph.money,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
                child: AnimatedBuilder(
                  animation: Listenable.merge([priceDayCtrl]),
                  builder: (_, __) {
                    final day =
                        double.tryParse(priceDayCtrl.text.trim()) ?? 0.0;
                    final amt = day * (dpPercent / 100.0);
                    return Text(
                      context.l10n.downPaymentPct(
                        dpPercent.toStringAsFixed(0),
                        amt.toStringAsFixed(2),
                      ),
                      style: Theme.of(context).textTheme.bodyMedium,
                    );
                  },
                ),
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
              title(context.l10n.quantityAndStatus),
              _TwoCol(
                left: AInput(
                  controller: qtyCtrl,
                  label: context.l10n.quantity,
                  glyph: AppGlyph.info,
                  keyboardType: TextInputType.number,
                ),
                right: AInput(
                  controller: weightCtrl,
                  label: context.l10n.equipmentWeight,
                  glyph: AppGlyph.info,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Switch.adaptive(value: isActive, onChanged: onToggleActive),
                  const SizedBox(width: 8),
                  Text(
                    isActive
                        ? context.l10n.activeVisible
                        : context.l10n.inactiveHidden,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: BrandButton(
                onPressed: onSave,
                icon: AIcon(
                  AppGlyph.check,
                  color: Colors.white,
                  selected: true,
                ),
                child: Text(context.l10n.saveChanges),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

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

// ---------- image filename rules (strict) ----------

String _toYmd(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime _now() => DateTime.now();

// ---------------- Images (strict URL only) ----------------

class _ImagesTab extends StatefulWidget {
  const _ImagesTab({required this.equipmentId, required this.onChanged});

  final int equipmentId;
  final VoidCallback onChanged;

  @override
  State<_ImagesTab> createState() => _ImagesTabState();
}

class _ImagesTabState extends State<_ImagesTab> {
  late Future<List<EquipmentImage>> _future;
  final _sc = ScrollController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _future = api.Api.getEquipmentImagesByEquipmentId(widget.equipmentId);
  }

  @override
  void dispose() {
    _sc.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    setState(() {
      _future = api.Api.getEquipmentImagesByEquipmentId(widget.equipmentId);
    });
    widget.onChanged();
  }

  Future<void> _addImage() async {
    if (_busy) return;

    final picked = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) return;

    setState(() => _busy = true);
    try {
      final f = picked.files.single;

      // Capture result (for debugging/logs); then reload list
      final up = (f.bytes != null)
          ? await api.Api.uploadEquipmentImage(
              equipmentId: widget.equipmentId,
              fileBytes: f.bytes!,
              originalFileName: f.name,
            )
          : await api.Api.uploadEquipmentImageFromPath(
              equipmentId: widget.equipmentId,
              path: f.path!,
            );

      debugPrint('[images] uploaded -> ${up.publicUrl}');
      if (!mounted) return;
      AppSnack.success(context, context.l10n.imageUploaded);
      await _reload();
    } catch (e) {
      if (!mounted) return;
      AppSnack.error(context, context.l10n.uploadFailedWithMsg('$e'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteImage(EquipmentImage img) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete image'),
        content: const Text('Remove this image from the listing?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _busy = true);
    try {
      await api.Api.deleteEquipmentImage(img.equipmentImageId ?? 0);
      if (!mounted) return;
      AppSnack.success(context, context.l10n.imageDeleted);
      await _reload();
    } catch (e) {
      if (!mounted) return;
      AppSnack.error(context, context.l10n.deleteFailedWithMsg('$e'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // -------- URL + preview helpers ----------
  String _publicUrlFromStoredPath(
    String? storedPath, {
    required String defaultFolder, // e.g. 'equipimageFiles'
  }) {
    final raw = (storedPath ?? '').trim();
    if (raw.isEmpty) return '';

    var p = raw.replaceAll('\\', '/');

    final lower = p.toLowerCase();
    if (lower.startsWith('http://') || lower.startsWith('https://')) return p;
    if (p.startsWith('/')) p = p.substring(1);

    if (p.toLowerCase().startsWith('staticfiles/')) {
      return 'https://sr.visioncit.com/$p';
    }

    final name = p.substring(p.lastIndexOf('/') + 1);
    return 'https://sr.visioncit.com/StaticFiles/$defaultFolder/${Uri.encodeComponent(name)}';
  }

  String _basenameSafe(String? p) {
    final s = (p ?? '').trim();
    if (s.isEmpty) return '';
    final norm = s.replaceAll('\\', '/');
    final name = norm.substring(norm.lastIndexOf('/') + 1);
    if (name.isEmpty ||
        name == '#' ||
        name.contains('\n') ||
        name.contains('/')) {
      return '';
    }
    return name;
  }

  void _previewImageUrl(BuildContext context, String url) {
    showDialog<void>(
      context: context,
      builder: (dCtx) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 5,
          child: AspectRatio(
            aspectRatio: 3 / 4,
            child: CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.contain,
              placeholder: (_, __) => const SizedBox(
                height: 240,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              errorWidget: (_, __, ___) => const SizedBox(
                height: 240,
                child: Center(child: Icon(Icons.broken_image_outlined)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return FutureBuilder<List<EquipmentImage>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final rows = snap.data ?? const <EquipmentImage>[];

        return Scrollbar(
          controller: _sc,
          thumbVisibility: true,
          child: ListView(
            controller: _sc,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Row(
                children: [
                  FilledButton.icon(
                    onPressed: _busy ? null : _addImage,
                    icon: const Icon(Icons.add),
                    label: Text(
                      _busy
                          ? context.l10n.uploading
                          : context.l10n.actionAddImage,
                    ),
                  ),
                  const Spacer(),
                  IconButton.filledTonal(
                    tooltip: context.l10n.actionRefresh,
                    onPressed: _busy ? null : _reload,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (rows.isEmpty)
                Glass(
                  radius: 16,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      context.l10n.noImagesYet,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                )
              else
                LayoutBuilder(
                  builder: (_, c) {
                    final w = c.maxWidth;
                    final cross = w >= 1100
                        ? 4
                        : (w >= 800 ? 3 : (w >= 560 ? 2 : 1));
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: rows.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cross,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.4,
                      ),
                      itemBuilder: (_, i) {
                        final row = rows[i];

                        final baseUrl = _publicUrlFromStoredPath(
                          row.equipmentPath,
                          defaultFolder: 'equipimageFiles',
                        );

                        // cache-bust once per record using its timestamps
                        final ts = (row.modifyDateTime ?? row.createDateTime)
                            ?.millisecondsSinceEpoch;
                        final url = ts != null ? '$baseUrl?v=$ts' : baseUrl;

                        final name = _basenameSafe(row.equipmentPath);

                        debugPrint(
                          '[images] url=$url path=${row.equipmentPath}',
                        );

                        return Glass(
                          radius: 18,
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: InkWell(
                                  onTap: url.isEmpty
                                      ? null
                                      : () => _previewImageUrl(context, url),
                                  child: CachedNetworkImage(
                                    imageUrl: url,
                                    fit: BoxFit.cover,
                                    placeholderFadeInDuration: const Duration(
                                      milliseconds: 120,
                                    ),
                                    fadeInDuration: const Duration(
                                      milliseconds: 150,
                                    ),
                                    placeholder: (c, u) => Container(
                                      color: cs.surfaceContainerHighest,
                                      child: const Center(
                                        child: SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      ),
                                    ),
                                    errorWidget: (c, u, e) => Container(
                                      color: cs.surfaceContainerHighest,
                                      child: const Center(
                                        child: Icon(
                                          Icons.broken_image_outlined,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 8,
                                top: 8,
                                child: IconButton.filledTonal(
                                  tooltip: context.l10n.actionDelete,
                                  onPressed: _busy
                                      ? null
                                      : () => _deleteImage(row),
                                  icon: const Icon(Icons.delete_outline),
                                ),
                              ),
                              Positioned(
                                left: 8,
                                bottom: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: cs.surface.withOpacity(0.85),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    name.isEmpty
                                        ? (row.equipmentPath ?? '')
                                        : name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelMedium,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------- Terms ----------------

class _TermsTab extends StatefulWidget {
  const _TermsTab({required this.equipmentId, required this.onChanged});
  final int equipmentId;
  final VoidCallback onChanged;

  @override
  State<_TermsTab> createState() => _TermsTabState();
}

class _TermsTabState extends State<_TermsTab> {
  bool _busy = true;
  List<EquipmentTerm> _items = [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _busy = true);
    try {
      final data = await api.Api.getEquipmentTermsByEquipmentId(
        widget.equipmentId,
      );
      // Always sort safely
      data.sort((a, b) => (a.orderBy ?? 0).compareTo(b.orderBy ?? 0));
      if (!mounted) return;
      setState(() {
        _items = data;
        _busy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      AppSnack.error(context, 'Load failed: $e');
    }
  }

  Future<void> _reload() async {
    await _fetch();
    widget.onChanged();
  }

  Future<void> _edit([EquipmentTerm? t]) async {
    final en = TextEditingController(text: t?.descEnglish ?? '');
    final ar = TextEditingController(text: t?.descArabic ?? '');
    final order = TextEditingController(
      text: '${t?.orderBy ?? (_items.length)}',
    );

    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        title: Text(t == null ? 'Add term' : 'Edit term'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AInput(controller: en, label: 'English', glyph: AppGlyph.edit),
              const SizedBox(height: 8),
              AInput(controller: ar, label: 'Arabic', glyph: AppGlyph.edit),
              const SizedBox(height: 8),
              AInput(
                controller: order,
                label: 'Order',
                glyph: AppGlyph.info,
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(dialogCtx, rootNavigator: true).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogCtx, rootNavigator: true).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (ok == true) {
      try {
        final now = DateTime.now();
        final payload = EquipmentTerm(
          equipmentTermId: t?.equipmentTermId,
          equipmentId: widget.equipmentId,
          descEnglish: en.text.trim(),
          descArabic: ar.text.trim(),
          orderBy: int.tryParse(order.text.trim()) ?? (_items.length),
          isActive: true,
          createDateTime: t?.createDateTime ?? now,
          modifyDateTime: now,
        );

        if (t == null) {
          await api.Api.addEquipmentTerm(payload);
        } else {
          await api.Api.updateEquipmentTerm(payload);
        }
        if (!mounted) return;
        AppSnack.success(context, 'Saved');
        _reload();
      } catch (e) {
        if (!mounted) return;
        AppSnack.error(context, 'Save failed: $e');
      }
    }
  }

  Future<void> _delete(EquipmentTerm t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete term?'),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(dialogCtx, rootNavigator: true).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogCtx, rootNavigator: true).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await api.Api.deleteEquipmentTerm(t.equipmentTermId ?? 0);
      if (!mounted) return;
      AppSnack.success(context, 'Deleted');
      _reload();
    } catch (e) {
      if (!mounted) return;
      AppSnack.error(context, 'Delete failed: $e');
    }
  }

  Future<void> _saveOrder() async {
    // Persist current visual order (top-to-bottom)
    try {
      for (int i = 0; i < _items.length; i++) {
        final t = _items[i];
        await api.Api.updateEquipmentTerm(
          EquipmentTerm(
            equipmentTermId: t.equipmentTermId,
            equipmentId: widget.equipmentId,
            descEnglish: t.descEnglish,
            descArabic: t.descArabic,
            orderBy: i, // ← index is the new order
            isActive: t.isActive ?? true,
            createDateTime: t.createDateTime,
            modifyDateTime: DateTime.now(),
          ),
        );
      }
      if (!mounted) return;
      AppSnack.success(context, 'Order saved');
      _reload();
    } catch (e) {
      if (!mounted) return;
      AppSnack.error(context, 'Order save failed: $e');
    }
  }

  // --- Modern term card --------------------------------------------------------
  Widget _termCard(BuildContext context, EquipmentTerm t, int index) {
    final cs = Theme.of(context).colorScheme;
    final en = (t.descEnglish ?? '').trim();
    final ar = (t.descArabic ?? '').trim();
    final active = t.isActive ?? true;

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cs.surface.withOpacity(0.95),
              cs.surfaceContainerHighest.withOpacity(0.35),
            ],
          ),
          border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _edit(t),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // compact grip
                ReorderableDragStartListener(
                  index: index,
                  child: _GripDots(color: cs.onSurfaceVariant),
                ),
                const SizedBox(width: 10),

                // index avatar
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [cs.primary, cs.primary.withOpacity(0.75)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: cs.primary.withOpacity(0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: cs.onPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // text block
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        en.isEmpty ? '—' : en,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.1,
                            ),
                      ),
                      if (ar.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Directionality(
                          textDirection: TextDirection.rtl,
                          child: Text(
                            ar,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: cs.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                // status + actions
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Column(
                      children: [
                        _StatusChip(active: active),
                        SizedBox(height: 5),
                        _ActionsPill(onDelete: () => _delete(t)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ignore: unused_element
  void _showPreview() {
    final sorted = List<EquipmentTerm>.from(_items)
      ..sort((a, b) => (a.orderBy ?? 0).compareTo(b.orderBy ?? 0));

    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        final cs = Theme.of(dialogCtx).colorScheme;
        final enStyle = Theme.of(dialogCtx).textTheme.bodyLarge;
        final arStyle = Theme.of(
          dialogCtx,
        ).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant);

        return AlertDialog(
          title: Text(context.l10n.tabTerms),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640, maxHeight: 500),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (sorted.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(context.l10n.noTermsYetCreateFirst),
                    )
                  else
                    ...List.generate(sorted.length, (i) {
                      final t = sorted[i];
                      final en = (t.descEnglish ?? '').trim();
                      final ar = (t.descArabic ?? '').trim();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                                '${i + 1}',
                                style: TextStyle(
                                  color: cs.onPrimaryContainer,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (en.isNotEmpty) Text(en, style: enStyle),
                                  if (ar.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Directionality(
                                      textDirection: TextDirection.rtl,
                                      child: Text(ar, style: arStyle),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(dialogCtx, rootNavigator: true).pop(),
              child: Text(context.l10n.actionClose),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_busy) {
      return const Center(child: CircularProgressIndicator());
    }

    final items = _items;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              IconButton.filledTonal(
                tooltip: context.l10n.actionRefresh,
                onPressed: _reload,
                icon: const Icon(Icons.refresh),
              ),
              const SizedBox(width: 3),
              FilledButton.icon(
                onPressed: () => _edit(null),
                icon: const Icon(Icons.add),
                label: Text(context.l10n.actionAddTerm),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: _saveOrder,
                icon: const Icon(Icons.save),
                label: Text(context.l10n.actionSaveOrder),
              ),
            ],
          ),
        ),

        // Empty state
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Glass(
              radius: 16,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.list_alt_outlined, color: cs.onSurfaceVariant),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        context.l10n.noTermsYetCreateFirst,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              buildDefaultDragHandles: false, // ← only our custom grip remains
              proxyDecorator: (child, index, anim) => Transform.scale(
                scale: 1.02,
                child: Material(
                  elevation: 8,
                  shadowColor: Colors.black26,
                  borderRadius: BorderRadius.circular(16),
                  child: child,
                ),
              ),
              itemCount: items.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex -= 1;
                  final item = _items.removeAt(oldIndex);
                  _items.insert(newIndex, item);
                });
              },
              itemBuilder: (ctx, i) {
                final t = items[i];
                return Padding(
                  key: ValueKey(t.equipmentTermId ?? i),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: _termCard(ctx, t, i),
                );
              },
            ),
          ),
      ],
    );
  }
}

// ---------------- Drivers (+ files) ----------------

class _DriversTab extends StatefulWidget {
  const _DriversTab({required this.equipmentId, required this.onChanged});
  final int equipmentId;
  final VoidCallback onChanged;

  @override
  State<_DriversTab> createState() => _DriversTabState();
}

class _DriversTabState extends State<_DriversTab> {
  late Future<List<EquipmentDriver>> _future;
  List<Nationality>? _nats;

  // ---- domain(10) file types for driver files ----
  List<DomainDetail> _fileTypes = [];
  bool _loadingFileTypes = true;

  // ------------ logging helpers ------------
  static const JsonEncoder _pretty = JsonEncoder.withIndent('  ');
  void _log(String msg, [Object? data]) {
    if (data == null) {
      dev.log(msg, name: 'DriversTab');
    } else {
      dev.log(
        '$msg: ${data is String ? data : _pretty.convert(data)}',
        name: 'DriversTab',
      );
    }
  }
  // -----------------------------------------

  @override
  void initState() {
    super.initState();
    _future = api.Api.getEquipmentDriversByEquipmentId(widget.equipmentId);
    _loadNats();
    _loadFileTypes();
  }

  Future<void> _loadNats() async {
    try {
      final n = await api.Api.getNationalities();
      if (!mounted) return;
      setState(() => _nats = n);
    } catch (_) {}
  }

  Future<void> _loadFileTypes() async {
    try {
      final list = await api.Api.getDomainDetailsByDomainId(10);
      if (!mounted) return;
      setState(() {
        _fileTypes = list;
        _loadingFileTypes = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingFileTypes = false);
    }
  }

  Future<void> _reload() async {
    if (!mounted) return;
    setState(() {
      _future = api.Api.getEquipmentDriversByEquipmentId(widget.equipmentId);
    });
    // do not await here; FutureBuilder will handle it
    widget.onChanged();
  }

  Future<void> _editDriver([EquipmentDriver? d]) async {
    final en = TextEditingController(text: d?.driverNameEnglish ?? '');
    final ar = TextEditingController(text: d?.driverNameArabic ?? '');
    int? natId = d?.driverNationalityId;

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setSB) {
          return AlertDialog(
            title: Text(
              d == null ? context.l10n.addDriver : context.l10n.editDriver,
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AInput(
                    controller: en,
                    label: context.l10n.nameEnRequired,
                    glyph: AppGlyph.edit,
                  ),
                  const SizedBox(height: 8),
                  AInput(
                    controller: ar,
                    label: context.l10n.nameArRequired,
                    glyph: AppGlyph.edit,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: DropdownButtonFormField<int>(
                      initialValue: natId,
                      isExpanded: true,
                      alignment: AlignmentDirectional.centerStart,
                      items: (_nats ?? const <Nationality>[])
                          .map(
                            (n) => DropdownMenuItem<int>(
                              value: n.nationalityId,
                              child: Text(
                                n.nationalityNameEnglish ?? '—',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                textAlign: TextAlign.start,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setSB(() => natId = v),
                      menuMaxHeight: 360,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.of(dialogCtx, rootNavigator: true).pop(false),
                child: Text(context.l10n.actionCancel),
              ),
              FilledButton(
                onPressed: () =>
                    Navigator.of(dialogCtx, rootNavigator: true).pop(true),
                child: Text(context.l10n.actionSave),
              ),
            ],
          );
        },
      ),
    );

    if (ok == true) {
      if (en.text.trim().isEmpty || ar.text.trim().isEmpty || natId == null) {
        AppSnack.error(context, context.l10n.allFieldsRequired);
        return;
      }
      try {
        final payload = EquipmentDriver(
          equipmentDriverId: d?.equipmentDriverId,
          equipmentId: widget.equipmentId,
          driverNameEnglish: en.text.trim(),
          driverNameArabic: ar.text.trim(),
          driverNationalityId: natId,
          isActive: true,
        );
        if (d == null) {
          await api.Api.addEquipmentDriver(payload);
        } else {
          await api.Api.updateEquipmentDriver(payload);
        }
        if (!mounted) return;
        AppSnack.success(context, context.l10n.saved);
        _reload();
      } catch (e) {
        if (!mounted) return;
        AppSnack.error(context, context.l10n.saveFailedWithMsg('$e'));
      }
    }
  }

  /// Always return "driverdocFiles/&lt;basename&gt;" for storage.
  String _driverDocStorableFromName(String filename) {
    final base = filename.replaceAll('\\', '/').split('/').last.trim();
    return base.isEmpty ? '' : '${api.Api.driverDocsFolder}/$base';
  }

  // ---- date helpers (expiry is true only if endDate < today) ----
  DateTime? _parseYmd(String? ymd) {
    if (ymd == null || ymd.trim().isEmpty) return null;
    try {
      final p = ymd.split('-');
      if (p.length != 3) return null;
      return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
    } catch (_) {
      return null;
    }
  }

  bool _isExpiredYmd(String? endYmd) {
    final end = _parseYmd(endYmd);
    if (end == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return end.isBefore(today); // inclusive end date
  }

  Future<void> _addDriverFile(EquipmentDriver d) async {
    final formKey = GlobalKey<FormState>();

    int? typeId;
    DateTime? startDt;
    DateTime? endDt;

    final descENCtrl = TextEditingController();
    final descARCtrl = TextEditingController();

    PlatformFile? picked; // NOT uploaded; only used to derive name & preview
    bool isImage = false; // auto from extension; user can toggle

    bool saving = false;
    String? errorText;

    bool looksLikeImage(String name) {
      final n = name.toLowerCase();
      return n.endsWith('.png') ||
          n.endsWith('.jpg') ||
          n.endsWith('.jpeg') ||
          n.endsWith('.webp');
    }

    Future<void> pickFile(StateSetter setSB) async {
      final result = await FilePicker.platform.pickFiles(
        withData: true,
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
      );
      if (result == null || result.files.isEmpty) {
        _log('File picker: user cancelled');
        return;
      }
      picked = result.files.single;
      isImage = looksLikeImage(picked!.name);
      _log('Picked file', {
        'name': picked!.name,
        'bytes': picked!.bytes?.lengthInBytes ?? 0,
        'path': picked!.path,
        'guessedIsImage': isImage,
      });
      setSB(() {});
    }

    Future<void> pickDate(StateSetter setSB, {required bool isStart}) async {
      final base = isStart
          ? (startDt ?? DateTime.now())
          : (endDt ?? DateTime.now());
      final chosen = await showDatePicker(
        context: context,
        initialDate: base,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );
      if (chosen != null) {
        if (isStart) {
          startDt = chosen;
        } else {
          endDt = chosen;
        }
        setSB(() {});
      }
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setSB) {
          Widget preview() {
            if (picked == null) return const SizedBox.shrink();
            if (isImage && picked!.bytes != null) {
              return Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    picked!.bytes!,
                    width: 220,
                    height: 150,
                    fit: BoxFit.cover,
                  ),
                ),
              );
            }
            return Center(
              child: Container(
                width: 220,
                height: 150,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Theme.of(
                    dialogCtx,
                  ).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isImage
                      ? Icons.broken_image_outlined
                      : Icons.picture_as_pdf_outlined,
                  size: 36,
                ),
              ),
            );
          }

          Future<void> handleSave() async {
            if (typeId == null) {
              errorText = context.l10n.fileTypeIdRequired;
              (dialogCtx as Element).markNeedsBuild();
              return;
            }
            if (picked == null) {
              errorText = context.l10n.chooseDocumentFile;
              (dialogCtx as Element).markNeedsBuild();
              return;
            }
            if (!(formKey.currentState?.validate() ?? true)) return;

            saving = true;
            errorText = null;
            (dialogCtx as Element).markNeedsBuild();

            // Capture count before, to detect success via reload if the API throws on parse.
            int beforeCount = d.equipmentDriverFiles?.length ?? 0;

            // Build payload
            final storable = _driverDocStorableFromName(picked!.name);
            final isImageFinal = looksLikeImage(storable);
            final startYmd = startDt == null ? null : _toYmd(startDt!);
            final endYmd = endDt == null ? null : _toYmd(endDt!);

            final payload = EquipmentDriverFile(
              equipmentDriverFileId: 0,
              equipmentDriverId: d.equipmentDriverId,
              filePath: storable,
              fileTypeId: typeId,
              fileDescriptionEnglish: descENCtrl.text.trim().isEmpty
                  ? ' '
                  : descENCtrl.text.trim(),
              fileDescriptionArabic: descARCtrl.text.trim().isEmpty
                  ? ' '
                  : descARCtrl.text.trim(),
              startDate: startYmd,
              endDate: endYmd,
              isImage: isImageFinal,
              isActive: true,
              isExpire: _isExpiredYmd(endYmd),
              createDateTime: DateTime.now(),
              modifyDateTime: DateTime.now(),
            );

            _log('addEquipmentDriverFile.payload', payload.toJson());

            bool committed = false;

            // 1) Try the call, but NEVER let a parsing error crash the UI
            try {
              await api.Api.addEquipmentDriverFile(payload);
              committed = true; // if we get here, no exception thrown
            } catch (e, st) {
              _log(
                'addEquipmentDriverFile.throw (ignored—for envelope-only backend)',
                {'error': e.toString(), 'stack': st.toString()},
              );
              // We’ll confirm by reload below.
            }

            // 2) Close the dialog FIRST so we never call markNeedsBuild on a dead context.
            if (mounted) {
              Navigator.of(dialogCtx, rootNavigator: true).pop();
            }

            // 3) Reload quietly and infer success (even if the call threw)
            try {
              await _reload();
            } catch (e) {
              _log('_reload.throw (ignored)', e.toString());
            }

            // 4) Best-effort success toast: check if count increased
            try {
              final latest =
                  await _future; // safe: FutureBuilder will drive it too
              final me = latest.firstWhere(
                (x) => x.equipmentDriverId == d.equipmentDriverId,
                orElse: () => d,
              );
              final after = me.equipmentDriverFiles?.length ?? beforeCount;
              if (committed || after > beforeCount) {
                if (mounted) AppSnack.success(context, context.l10n.fileAdded);
              } else {
                if (mounted) {
                  AppSnack.error(
                    context,
                    context.l10n.addFailedWithMsg(context.l10n.tryAgain),
                  );
                }
              }
            } catch (e) {
              // Even if this fails, the UI won’t crash.
              _log('post-reload verification failed', e.toString());
              if (mounted) {
                AppSnack.success(context, context.l10n.saved); // optimistic
              }
            }
          }

          return AlertDialog(
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 24,
            ),
            title: Text(context.l10n.addDriverFile),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900, maxHeight: 680),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          FilledButton.icon(
                            onPressed: saving ? null : () => pickFile(setSB),
                            icon: const Icon(Icons.upload_file),
                            label: Text(context.l10n.chooseFile),
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: saving || picked == null
                                ? null
                                : () {
                                    _log('Clear pressed');
                                    picked = null;
                                    isImage = false;
                                    setSB(() {});
                                  },
                            icon: const Icon(Icons.close_rounded),
                            label: const Text('Clear'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      preview(),
                      const SizedBox(height: 12),

                      // File type (Domain 10)
                      DropdownButtonFormField<int>(
                        initialValue: typeId,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: context.l10n.fileTypeIdRequired,
                        ),
                        items: (!_loadingFileTypes && _fileTypes.isNotEmpty)
                            ? _fileTypes.map((d) {
                                final label =
                                    (d.detailNameEnglish?.trim().isNotEmpty ??
                                        false)
                                    ? d.detailNameEnglish!.trim()
                                    : (d.detailNameArabic?.trim().isNotEmpty ??
                                          false)
                                    ? d.detailNameArabic!.trim()
                                    : '#${d.domainDetailId ?? 0}';
                                return DropdownMenuItem<int>(
                                  value: d.domainDetailId,
                                  child: Text(label),
                                );
                              }).toList()
                            : const [],
                        onChanged: saving
                            ? null
                            : (v) => setSB(() => typeId = v),
                        validator: (_) => (typeId == null) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),

                      // Dates
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              readOnly: true,
                              controller: TextEditingController(
                                text: startDt != null ? _toYmd(startDt!) : '',
                              ),
                              decoration: InputDecoration(
                                labelText: context.l10n.startDateYmd,
                              ),
                              onTap: saving
                                  ? null
                                  : () => pickDate(setSB, isStart: true),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              readOnly: true,
                              controller: TextEditingController(
                                text: endDt != null ? _toYmd(endDt!) : '',
                              ),
                              decoration: InputDecoration(
                                labelText: context.l10n.endDateYmd,
                              ),
                              onTap: saving
                                  ? null
                                  : () => pickDate(setSB, isStart: false),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Optional descriptions
                      AInput(
                        controller: descENCtrl,
                        label: context.l10n.fileDescriptionOptionalEn,
                        glyph: AppGlyph.edit,
                      ),
                      const SizedBox(height: 8),
                      AInput(
                        controller: descARCtrl,
                        label: context.l10n.fileDescriptionOptionalAr,
                        glyph: AppGlyph.edit,
                      ),
                      const SizedBox(height: 12),

                      // Is image (auto; user can still toggle)
                      Row(
                        children: [
                          Switch.adaptive(
                            value: isImage,
                            onChanged: saving
                                ? null
                                : (v) {
                                    isImage = v;
                                    (dialogCtx as Element).markNeedsBuild();
                                  },
                          ),
                          const SizedBox(width: 8),
                          Text(context.l10n.isImage),
                        ],
                      ),

                      if (errorText != null) ...[
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            errorText!,
                            style: TextStyle(
                              color: Theme.of(dialogCtx).colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving
                    ? null
                    : () => Navigator.of(dialogCtx, rootNavigator: true).pop(),
                child: Text(context.l10n.actionCancel),
              ),
              FilledButton(
                onPressed: saving ? null : handleSave,
                child: Text(
                  saving ? context.l10n.savingEllipsis : context.l10n.actionAdd,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return FutureBuilder<List<EquipmentDriver>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final drivers = snap.data ?? const <EquipmentDriver>[];

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Row(
              children: [
                FilledButton.icon(
                  onPressed: () => _editDriver(null),
                  icon: const Icon(Icons.add),
                  label: Text(context.l10n.actionAddDriver),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (drivers.isEmpty)
              Glass(
                radius: 16,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    context.l10n.noDriversYet,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              )
            else
              ...drivers.map((d) {
                final files = d.equipmentDriverFiles ?? const [];

                _log('Rendering driver row', {
                  'driverId': d.equipmentDriverId,
                  'filesCount': files.length,
                  'files': files.map((f) => f.toJson()).toList(),
                });

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Glass(
                    radius: 18,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header row
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 2),
                                child: Icon(Icons.person_outline),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      d.driverNameEnglish ??
                                          d.driverNameArabic ??
                                          context.l10n.driver,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${context.l10n.nationalityIdLabel}: ${d.driverNationalityId ?? '—'}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: cs.onSurfaceVariant,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),
                          const Divider(height: 1),

                          // Files list
                          if (files.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                context.l10n.noFiles,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: cs.onSurfaceVariant),
                              ),
                            )
                          else
                            ...files.map((f) {
                              final expired = _isExpiredYmd(f.endDate);

                              final displayTitle =
                                  (f.fileDescriptionEnglish
                                          ?.trim()
                                          .isNotEmpty ??
                                      false)
                                  ? f.fileDescriptionEnglish!.trim()
                                  : (f.fileDescriptionArabic
                                            ?.trim()
                                            .isNotEmpty ??
                                        false)
                                  ? f.fileDescriptionArabic!.trim()
                                  : (f.filePath ?? '—');

                              return ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(
                                  Icons.insert_drive_file_outlined,
                                ),
                                title: Text(
                                  displayTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  [
                                    if (f.startDate?.isNotEmpty == true)
                                      '${context.l10n.fromDate} ${f.startDate}',
                                    if (f.endDate?.isNotEmpty == true)
                                      '${context.l10n.toDate} ${f.endDate}',
                                    if (expired) context.l10n.expired,
                                  ].join(' • '),
                                ),
                                trailing: IconButton.filledTonal(
                                  tooltip: context.l10n.actionDelete,
                                  onPressed: () => _deleteDriverFile(
                                    f.equipmentDriverFileId,
                                  ),
                                  icon: const Icon(Icons.delete_outline),
                                ),
                              );
                            }),

                          const SizedBox(height: 8),

                          // Bottom actions
                          Row(
                            children: [
                              FilledButton.icon(
                                onPressed: () => _addDriverFile(d),
                                icon: const Icon(Icons.add),
                                label: Text(context.l10n.actionAddFile),
                              ),
                              const Spacer(),
                              Wrap(
                                spacing: 6,
                                children: [
                                  IconButton.filledTonal(
                                    onPressed: () => _editDriver(d),
                                    icon: const Icon(Icons.edit),
                                    tooltip: context.l10n.actionEdit,
                                  ),
                                  IconButton.filledTonal(
                                    onPressed: () => _deleteDriver(d),
                                    icon: const Icon(Icons.delete_outline),
                                    tooltip: context.l10n.actionDelete,
                                    style: ButtonStyle(
                                      foregroundColor: WidgetStateProperty.all(
                                        Theme.of(context).colorScheme.error,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
          ],
        );
      },
    );
  }

  Future<void> _deleteDriver(EquipmentDriver d) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(context.l10n.deleteDriverQ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(dialogCtx, rootNavigator: true).pop(false),
            child: Text(context.l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogCtx, rootNavigator: true).pop(true),
            child: Text(context.l10n.actionDelete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await api.Api.deleteEquipmentDriver(d.equipmentDriverId ?? 0);
      if (!mounted) return;
      AppSnack.success(context, context.l10n.deleted);
      _reload();
    } catch (e) {
      if (!mounted) return;
      AppSnack.error(context, context.l10n.deleteFailedWithMsg('$e'));
    }
  }

  Future<void> _deleteDriverFile(int? id) async {
    if (id == null) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(context.l10n.deleteFileQ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(dialogCtx, rootNavigator: true).pop(false),
            child: Text(context.l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogCtx, rootNavigator: true).pop(true),
            child: Text(context.l10n.actionDelete),
          ),
        ],
      ),
    );
    if (ok != true) return;

    // snapshot counts to infer success after reload
    int beforeCount = 0;
    try {
      final current = await _future;
      final allFiles = current
          .expand(
            (ed) => ed.equipmentDriverFiles ?? const <EquipmentDriverFile>[],
          )
          .toList(growable: false);
      beforeCount = allFiles.length;
    } catch (_) {}

    bool committed = false;
    try {
      await api.Api.deleteEquipmentDriverFile(id);
      committed = true;
    } catch (e, st) {
      _log('deleteDriverFile.throw (ignored—for envelope-only backend)', {
        'error': e.toString(),
        'stack': st.toString(),
      });
    }

    try {
      await _reload();
    } catch (e) {
      _log('_reload.throw (ignored)', e.toString());
    }

    try {
      final latest = await _future;
      final afterCount = latest
          .expand(
            (ed) => ed.equipmentDriverFiles ?? const <EquipmentDriverFile>[],
          )
          .length;
      if (committed || afterCount < beforeCount) {
        if (mounted) AppSnack.success(context, context.l10n.deleted);
      } else {
        if (mounted) {
          AppSnack.error(
            context,
            context.l10n.deleteFailedWithMsg(context.l10n.tryAgain),
          );
        }
      }
    } catch (e) {
      _log('post-reload verification failed', e.toString());
      if (mounted) {
        AppSnack.success(context, context.l10n.deleted); // optimistic
      }
    }
  }

  // ---- simple Y-M-D helper for UI inputs ----
  String _toYmd(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}

// ---------------- Certificates ----------------

class _CertificatesTab extends StatefulWidget {
  const _CertificatesTab({
    required this.equipmentId,
    required this.certs,
    required this.folderName,
    required this.onChanged,
  });

  final int equipmentId;
  final List<EquipmentCertificate> certs;
  final String folderName;
  final VoidCallback onChanged;

  @override
  State<_CertificatesTab> createState() => _CertificatesTabState();
}

class _CertificatesTabState extends State<_CertificatesTab> {
  Future<void> _edit([EquipmentCertificate? c]) async {
    final formKey = GlobalKey<FormState>();

    // local state
    String nameEn = c?.nameEnglish ?? '';
    String nameAr = c?.nameArabic ?? '';
    int? typeId = c?.typeId;
    DateTime? issueDt = (c?.issueDate != null && c!.issueDate!.isNotEmpty)
        ? DateTime.tryParse('${c.issueDate}T00:00:00')
        : null;
    DateTime? expireDt = (c?.expireDate != null && c!.expireDate!.isNotEmpty)
        ? DateTime.tryParse('${c.expireDate}T00:00:00')
        : null;
    String? docServerName = c?.documentPath; // existing file name (basename)
    bool isImage = c?.isImage ?? false;

    // local picked file (not uploaded yet)
    PlatformFile? picked;

    bool saving = false;
    String? errorText;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        final cs = Theme.of(dialogCtx).colorScheme;

        Future<void> pickFile() async {
          final result = await FilePicker.platform.pickFiles(
            withData: true,
            type: FileType.custom,
            allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
          );
          if (result == null || result.files.isEmpty) return;
          picked = result.files.single;

          // guess image flag from extension; user can still toggle
          final n = picked!.name.toLowerCase();
          final looksImg =
              n.endsWith('.png') ||
              n.endsWith('.jpg') ||
              n.endsWith('.jpeg') ||
              n.endsWith('.webp');
          isImage = looksImg;
          (dialogCtx as Element).markNeedsBuild();
        }

        Future<void> pickDate({required bool isIssue}) async {
          final base = isIssue
              ? (issueDt ?? DateTime.now())
              : (expireDt ?? DateTime.now());
          final chosen = await showDatePicker(
            context: dialogCtx,
            initialDate: base,
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          );
          if (chosen != null) {
            if (isIssue) {
              issueDt = chosen;
            } else {
              expireDt = chosen;
            }
            (dialogCtx as Element).markNeedsBuild();
          }
        }

        Future<void> handleSave() async {
          if (!formKey.currentState!.validate()) return;
          if (issueDt == null || expireDt == null) {
            errorText = context.l10n.pickIssueAndExpire;
            (dialogCtx as Element).markNeedsBuild();
            return;
          }
          if (typeId == null) {
            errorText = context.l10n.chooseType;
            (dialogCtx as Element).markNeedsBuild();
            return;
          }
          if (docServerName == null && picked == null) {
            errorText = context.l10n.chooseDocumentFile;
            (dialogCtx as Element).markNeedsBuild();
            return;
          }

          saving = true;
          errorText = null;
          (dialogCtx as Element).markNeedsBuild();

          try {
            // CASE A: New file selected => two-step save (DB row + SaveUploadFile)
            if (picked != null) {
              if (picked!.bytes != null) {
                await api.Api.uploadEquipmentCertificate(
                  equipmentId: widget.equipmentId,
                  equipmentCertificateId: c?.equipmentCertificateId,
                  typeId: typeId!,
                  nameEnglish: nameEn,
                  nameArabic: nameAr,
                  issueDate: issueDt!,
                  expireDate: expireDt!,
                  fileBytes: picked!.bytes!,
                  originalFileName: picked!.name,
                  isImage: isImage,
                );
              } else if ((picked!.path ?? '').isNotEmpty) {
                await api.Api.uploadEquipmentCertificateFromPath(
                  equipmentId: widget.equipmentId,
                  equipmentCertificateId: c?.equipmentCertificateId,
                  typeId: typeId!,
                  nameEnglish: nameEn,
                  nameArabic: nameAr,
                  issueDate: issueDt!,
                  expireDate: expireDt!,
                  path: picked!.path!, // <- fall back to path
                  originalFileName: picked!.name,
                  isImage: isImage,
                );
              } else {
                throw Exception(
                  'Unable to read file bytes for the selected file.',
                );
              }
            } else {
              // CASE B: No new file picked => just add/update row with existing docServerName
              final now = _now();
              final payload = EquipmentCertificate(
                equipmentCertificateId: c?.equipmentCertificateId,
                equipmentId: widget.equipmentId,
                typeId: typeId,
                nameArabic: nameAr.trim(),
                nameEnglish: nameEn.trim(),
                issueDate: _toYmd(issueDt!),
                expireDate: _toYmd(expireDt!),
                isExpire: expireDt!.isBefore(DateTime.now()),
                isActive: true,
                createDateTime: c?.createDateTime ?? now,
                modifyDateTime: now,
                documentPath: docServerName,
                documentType: null,
                isImage: isImage,
              );

              if (c == null) {
                await api.Api.addEquipmentCertificate(payload);
              } else {
                await api.Api.updateEquipmentCertificate(payload);
              }
            }

            if (!mounted) return;
            AppSnack.success(context, context.l10n.saved);
            Navigator.of(dialogCtx, rootNavigator: true).pop();
            widget.onChanged();
          } catch (e) {
            saving = false;
            errorText = context.l10n.saveFailedWithMsg('$e');
            (dialogCtx).markNeedsBuild();
          }
        }

        final typesReady = !_loadingTypes && _types.isNotEmpty;

        return AlertDialog(
          title: Text(
            c == null
                ? context.l10n.addCertificate
                : context.l10n.editCertificate,
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760, maxHeight: 620),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // A) Replace the current Row(..) that contains Choose file + preview with:
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FilledButton.icon(
                          onPressed: saving ? null : pickFile,
                          icon: const Icon(Icons.upload_file),
                          label: Text(context.l10n.chooseFile),
                        ),
                        const SizedBox(height: 12),

                        if (picked != null ||
                            ((docServerName ?? '').isNotEmpty && isImage)) ...[
                          Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxWidth: 220,
                                maxHeight: 160,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Builder(
                                  builder: (_) {
                                    if (picked != null &&
                                        isImage &&
                                        picked!.bytes != null) {
                                      return Image.memory(
                                        picked!.bytes!,
                                        fit: BoxFit.cover,
                                      );
                                    }
                                    if ((docServerName ?? '').isNotEmpty &&
                                        isImage) {
                                      return CachedNetworkImage(
                                        imageUrl: _publicUrlFromStoredPath(
                                          docServerName,
                                          defaultFolder: 'equipcertFiles',
                                        ),
                                        fit: BoxFit.cover,
                                        placeholder: (_, __) => const SizedBox(
                                          height: 160,
                                          child: Center(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        ),
                                        errorWidget: (_, __, ___) => Container(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.surfaceContainerHighest,
                                          child: const Icon(
                                            Icons.broken_image_outlined,
                                          ),
                                        ),
                                      );
                                    }
                                    return Container(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.surfaceContainerHighest,
                                      child: Center(
                                        child: Text(context.l10n.pdfSelected),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ],
                    ),

                    if (errorText != null) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          errorText!,
                          style: TextStyle(color: cs.error),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),

                    TextFormField(
                      initialValue: nameEn,
                      decoration: InputDecoration(
                        labelText: context.l10n.nameEnRequired,
                      ),
                      onChanged: (v) => nameEn = v,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      initialValue: nameAr,
                      decoration: InputDecoration(
                        labelText: context.l10n.nameArRequired,
                      ),
                      onChanged: (v) => nameAr = v,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<int>(
                      initialValue: typeId,
                      decoration: InputDecoration(
                        labelText: context.l10n.typeDomain10Required,
                      ),
                      items: typesReady
                          ? _types.map((d) {
                              final label =
                                  (d.detailNameEnglish?.trim().isNotEmpty ??
                                      false)
                                  ? d.detailNameEnglish!.trim()
                                  : (d.detailNameArabic?.trim().isNotEmpty ??
                                        false)
                                  ? d.detailNameArabic!.trim()
                                  : '#${d.domainDetailId ?? 0}';
                              return DropdownMenuItem<int>(
                                value: d.domainDetailId,
                                child: Text(label),
                              );
                            }).toList()
                          : const [],
                      onChanged: saving ? null : (v) => typeId = v,
                      validator: (_) => (typeId == null) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            readOnly: true,
                            controller: TextEditingController(
                              text: issueDt != null ? _toYmd(issueDt!) : '',
                            ),
                            decoration: InputDecoration(
                              labelText: context.l10n.issueDateRequired,
                            ),
                            onTap: saving
                                ? null
                                : () => pickDate(isIssue: true),
                            validator: (_) =>
                                (issueDt == null) ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            readOnly: true,
                            controller: TextEditingController(
                              text: expireDt != null ? _toYmd(expireDt!) : '',
                            ),
                            decoration: InputDecoration(
                              labelText: context.l10n.expireDateRequired,
                            ),
                            onTap: saving
                                ? null
                                : () => pickDate(isIssue: false),
                            validator: (_) =>
                                (expireDt == null) ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (expireDt != null && expireDt!.isBefore(DateTime.now()))
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).colorScheme.onErrorContainer.withOpacity(.25),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                size: 16,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onErrorContainer,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                context.l10n.expired,
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onErrorContainer,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Switch.adaptive(
                          value: isImage,
                          onChanged: saving
                              ? null
                              : (v) {
                                  isImage = v;
                                  (dialogCtx as Element).markNeedsBuild();
                                },
                        ),
                        const SizedBox(width: 8),
                        Text(context.l10n.isImage),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving
                  ? null
                  : () => Navigator.of(dialogCtx, rootNavigator: true).pop(),
              child: Text(context.l10n.actionCancel),
            ),
            FilledButton(
              onPressed: saving ? null : handleSave,
              child: Text(
                saving ? context.l10n.savingEllipsis : context.l10n.actionSave,
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _delete(EquipmentCertificate c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(context.l10n.deleteCertificateQ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(dialogCtx, rootNavigator: true).pop(false),
            child: Text(context.l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogCtx, rootNavigator: true).pop(true),
            child: Text(context.l10n.actionDelete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await api.Api.deleteEquipmentCertificate(c.equipmentCertificateId ?? 0);
      if (!mounted) return;
      AppSnack.success(context, context.l10n.deleted);
      widget.onChanged();
    } catch (e) {
      if (!mounted) return;
      AppSnack.error(context, context.l10n.deleteFailedWithMsg('$e'));
    }
  }

  List<DomainDetail> _types = [];
  bool _loadingTypes = true;

  @override
  void initState() {
    super.initState();
    _loadTypes();
  }

  void _previewImageUrl(BuildContext context, String url) {
    showDialog<void>(
      context: context,
      builder: (dCtx) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 5,
          child: AspectRatio(
            aspectRatio: 3 / 4,
            child: CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.contain,
              placeholder: (_, __) => const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              errorWidget: (_, __, ___) => const SizedBox(
                height: 200,
                child: Center(child: Icon(Icons.broken_image_outlined)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _publicUrlFromStoredPath(
    String? storedPath, {
    required String defaultFolder, // e.g. 'equipimageFiles' or 'equipcertFiles'
  }) {
    final raw = (storedPath ?? '').trim();
    if (raw.isEmpty) return '';

    // Normalize
    var p = raw.replaceAll('\\', '/');

    // Already absolute http(s)?
    final lower = p.toLowerCase();
    if (lower.startsWith('http://') || lower.startsWith('https://')) return p;

    // Strip leading slash if any
    if (p.startsWith('/')) p = p.substring(1);

    // If it already includes StaticFiles/... use it as-is
    if (p.toLowerCase().startsWith('staticfiles/')) {
      return 'https://sr.visioncit.com/$p';
    }

    // Otherwise treat it as a bare filename (what our image flow stores)
    final name = p.substring(p.lastIndexOf('/') + 1);
    return 'https://sr.visioncit.com/StaticFiles/$defaultFolder/${Uri.encodeComponent(name)}';
  }

  Future<void> _loadTypes() async {
    try {
      final list = await api.Api.getDomainDetailsByDomainId(10);
      if (!mounted) return;
      setState(() {
        _types = list;
        _loadingTypes = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingTypes = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.certs;
    final cs = Theme.of(context).colorScheme;

    Widget statusChip(bool expired) {
      final bg = expired ? cs.errorContainer : cs.secondaryContainer;
      final fg = expired ? cs.onErrorContainer : cs.onSecondaryContainer;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: fg.withOpacity(.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              expired ? Icons.warning_amber_rounded : Icons.verified_outlined,
              size: 16,
              color: fg,
            ),
            const SizedBox(width: 6),
            Text(
              expired ? context.l10n.expired : context.l10n.active,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: fg),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        FilledButton.icon(
          onPressed: () => _edit(null),
          icon: const Icon(Icons.add),
          label: Text(context.l10n.actionAddCertificate),
        ),
        const SizedBox(height: 12),

        if (items.isEmpty)
          Glass(
            radius: 16,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                context.l10n.noCertificatesYet,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          )
        else
          ...items.map((c) {
            final url = _publicUrlFromStoredPath(
              c.documentPath,
              defaultFolder: 'equipcertFiles',
            );
            final showImg = (c.isImage == true) && url.isNotEmpty;

            final expired =
                (c.expireDate?.isNotEmpty == true) &&
                DateTime.tryParse('${c.expireDate}T00:00:00') != null &&
                DateTime.parse(
                  '${c.expireDate}T00:00:00',
                ).isBefore(DateTime.now());

            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Glass(
                radius: 16,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Thumbnail
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: SizedBox(
                              width: 72,
                              height: 72,
                              child: showImg
                                  ? InkWell(
                                      onTap: () =>
                                          _previewImageUrl(context, url),
                                      child: CachedNetworkImage(
                                        imageUrl: url,
                                        fit: BoxFit.cover,
                                        placeholder: (_, __) => Container(
                                          color: cs.surfaceContainerHighest,
                                          child: const Center(
                                            child: SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            ),
                                          ),
                                        ),
                                        errorWidget: (_, __, ___) => Container(
                                          color: cs.surfaceContainerHighest,
                                          child: const Icon(
                                            Icons.broken_image_outlined,
                                          ),
                                        ),
                                      ),
                                    )
                                  : Container(
                                      color: cs.surfaceContainerHighest,
                                      child: const Center(
                                        child: Icon(Icons.verified_outlined),
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Text + meta
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title
                                Text(
                                  c.nameEnglish ?? c.nameArabic ?? '—',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 6),

                                // Dates
                                Row(
                                  children: [
                                    const Icon(Icons.event_outlined, size: 16),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        '${context.l10n.issueDate} ${c.issueDate ?? '—'}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: cs.onSurfaceVariant,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.schedule_outlined,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        '${context.l10n.expireDate} ${c.expireDate ?? '—'}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: cs.onSurfaceVariant,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 8),
                                statusChip(expired),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),
                      const Divider(height: 1),

                      // Bottom actions (right aligned)
                      Align(
                        alignment: Alignment.centerRight,
                        child: Wrap(
                          spacing: 6,
                          children: [
                            IconButton.filledTonal(
                              onPressed: () => _edit(c),
                              icon: const Icon(Icons.edit),
                              tooltip: context.l10n.actionEdit,
                            ),
                            IconButton.filledTonal(
                              onPressed: () => _delete(c),
                              icon: const Icon(Icons.delete_outline),
                              tooltip: context.l10n.actionDelete,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}

// -------------- common --------------

class _DesktopScrollBehavior extends MaterialScrollBehavior {
  const _DesktopScrollBehavior();
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.mouse,
    PointerDeviceKind.touch,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
  };
}

class _GripDots extends StatelessWidget {
  const _GripDots({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    Widget dot() => Container(
      width: 4,
      height: 4,
      margin: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.8),
        borderRadius: BorderRadius.circular(2),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        children: [
          Row(children: [dot(), dot(), dot()]),
          Row(children: [dot(), dot(), dot()]),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = active ? cs.secondaryContainer : cs.surfaceContainerHighest;
    final fg = active ? cs.onSecondaryContainer : cs.onSurfaceVariant;
    final label = active ? 'Active' : 'Hidden';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: active ? Colors.greenAccent.shade400 : cs.onSurfaceVariant,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(color: fg),
          ),
        ],
      ),
    );
  }
}

class _ActionsPill extends StatelessWidget {
  const _ActionsPill({required this.onDelete});
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surface.withOpacity(0.7),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton.filledTonal(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, size: 18),
            tooltip: 'Delete',
            style: ButtonStyle(
              minimumSize: WidgetStateProperty.all(const Size(36, 36)),
              padding: WidgetStateProperty.all(EdgeInsets.zero),
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              // slight danger tint
              foregroundColor: WidgetStateProperty.resolveWith((_) => cs.error),
            ),
          ),
        ],
      ),
    );
  }
}

// lib/features/organization/organization_screen.dart

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Auth & API
import 'package:heavy_new/core/auth/auth_store.dart';
import 'package:heavy_new/core/api/api_handler.dart' as api;

// Models
import 'package:heavy_new/core/models/admin/domain.dart';
import 'package:heavy_new/core/models/organization/organization_summary.dart';
import 'package:heavy_new/core/models/organization/organization_file.dart';
import 'package:heavy_new/core/models/organization/organization_user.dart';
import 'package:heavy_new/core/models/user/city.dart';

// UI kit
import 'package:heavy_new/foundation/ui/ui_extras.dart';
import 'package:heavy_new/foundation/ui/ui_kit.dart';
import 'package:heavy_new/foundation/ui/app_icons.dart';

const _ORG_FILE_BASE = 'https://sr.visioncit.com/StaticFiles/orgfileFiles/';

class OrganizationScreen extends StatefulWidget {
  const OrganizationScreen({super.key, this.organizationId});
  final int? organizationId;

  @override
  State<OrganizationScreen> createState() => _OrganizationScreenState();
}

class _OrganizationScreenState extends State<OrganizationScreen> {
  bool _busy = false;

  // Resolved after boot
  int? _orgId;
  OrganizationSummary? _orgSummary;

  // Lists
  List<City> _cities = [];
  List<DomainDetail> _statusOpts = []; // Domain 11
  List<DomainDetail> _typeOpts = []; // Domain 13
  final List<DomainDetail> _fileTypeOpts = []; // Domain 10 – file types
  List<OrganizationFileModel> _files = [];
  // ignore: unused_field
  List<OrganizationUser> _members = [];

  // Cache for on-server image existence checks
  final Map<String, Future<bool>> _existsCache = {};

  // Selected (form)
  City? _selCity;
  DomainDetail? _selStatus;
  DomainDetail? _selType;

  // Basic form fields
  final _nameAr = TextEditingController();
  final _nameEn = TextEditingController();
  final _briefAr = TextEditingController();
  final _briefEn = TextEditingController();
  final _address = TextEditingController();
  final _cr = TextEditingController();
  final _vat = TextEditingController();
  final _mainMobile = TextEditingController();
  final _secondMobile = TextEditingController();
  final _mainEmail = TextEditingController();
  final _secondEmail = TextEditingController();
  final _countryRO = TextEditingController();

  @override
  void initState() {
    super.initState();
    _boot();
  }

  @override
  void dispose() {
    _nameAr.dispose();
    _nameEn.dispose();
    _briefAr.dispose();
    _briefEn.dispose();
    _address.dispose();
    _cr.dispose();
    _vat.dispose();
    _mainMobile.dispose();
    _secondMobile.dispose();
    _mainEmail.dispose();
    _secondEmail.dispose();
    _countryRO.dispose();

    super.dispose();
  }

  // ---------- helpers ----------
  void _log(String msg) => debugPrint('[OrgScreen] $msg');

  DomainDetail? _optById(List<DomainDetail> list, int? id) {
    if (id == null) return null;
    for (final d in list) {
      if (d.domainDetailId == id) return d;
    }
    return null;
  }

  T? _firstOrNull<T>(Iterable<T> list, bool Function(T) test) {
    for (final e in list) {
      if (test(e)) return e;
    }
    return null;
  }

  String? _nz(String? s) {
    final t = (s ?? '').trim();
    return t.isEmpty ? null : t;
  }

  // ---------- boot ----------
  Future<void> _boot() async {
    if (!mounted) return;
    setState(() => _busy = true);
    try {
      await Future.wait([_loadCities(), _loadDomains()]);
      _orgId = widget.organizationId ?? await _resolveMyOrgId();
      _log('resolved orgId=${_orgId ?? 'null'}');

      if (_orgId != null) {
        await Future.wait([
          _loadOrgSummary(_orgId!),
          _loadFiles(),
          _loadMembers(),
        ]);

        // Selections from summary (defensive)
        if (_orgSummary?.cityId != null) {
          _selCity =
              _firstOrNull(_cities, (c) => c.cityId == _orgSummary!.cityId) ??
              _selCity ??
              (_cities.isNotEmpty ? _cities.first : null);
        }
        if (_orgSummary?.statusId != null) {
          _selStatus =
              _optById(_statusOpts, _orgSummary!.statusId!) ??
              _selStatus ??
              (_statusOpts.isNotEmpty ? _statusOpts.first : null);
        } else if (_statusOpts.isNotEmpty) {
          _selStatus = _statusOpts.first;
        }
        if (_orgSummary?.typeId != null) {
          _selType =
              _optById(_typeOpts, _orgSummary!.typeId!) ??
              _selType ??
              (_typeOpts.isNotEmpty ? _typeOpts.first : null);
        } else if (_typeOpts.isNotEmpty) {
          _selType = _typeOpts.first;
        }
      } else {
        // New org defaults
        if (_statusOpts.isNotEmpty) _selStatus = _statusOpts.first;
        if (_typeOpts.isNotEmpty) _selType = _typeOpts.first;

        // Prefill from user
        final u = AuthStore.instance.user.value;
        if ((u?.mobile ?? '').isNotEmpty) _mainMobile.text = u!.mobile!;
        if ((u?.email ?? '').isNotEmpty) _mainEmail.text = u!.email!;
      }
    } catch (e, st) {
      _log('boot error: $e\n$st');
      if (mounted) AppSnack.error(context, 'Failed to load organization');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _loadCities() async {
    final list = await api.Api.getCities();
    _cities = list;
    // Default: Riyadh if present, else first
    _selCity =
        _firstOrNull(
          _cities,
          (c) => (c.nameEnglish ?? '').toLowerCase() == 'riyadh',
        ) ??
        (_cities.isNotEmpty ? _cities.first : null);
  }

  String _countryLabel() {
    // Prefer the selected city's Country name
    final c = _selCity?.country;
    if ((c?.nationalityNameEnglish ?? '').trim().isNotEmpty) {
      return c!.nationalityNameEnglish!;
    }
    if ((c?.nationalityNameArabic ?? '').trim().isNotEmpty) {
      return c!.nationalityNameArabic!;
    }

    // Fallback: if OrganizationSummary.country is a map with names
    final dyn = _orgSummary?.country;
    if (dyn is Map) {
      final en =
          (dyn['nationalityNameEnglish'] ?? dyn['NationalityNameEnglish'])
              ?.toString();
      final ar = (dyn['nationalityNameArabic'] ?? dyn['NationalityNameArabic'])
          ?.toString();
      if ((en ?? '').trim().isNotEmpty) return en!;
      if ((ar ?? '').trim().isNotEmpty) return ar!;
    }

    // Last resort: if we know the countryId, show it (better than "—")
    if ((_orgSummary?.countryId ?? 0) > 0)
      return 'Country #${_orgSummary!.countryId}';
    return '—';
  }

  /// Apply all OrganizationSummary fields to inputs & selects in one place.
  void _applySummaryToForm(OrganizationSummary org) {
    // Text fields
    _nameAr.text = org.nameArabic ?? '';
    _nameEn.text = org.nameEnglish ?? '';
    _briefAr.text = org.briefArabic ?? '';
    _briefEn.text = org.briefEnglish ?? '';
    _address.text = org.fullAddress ?? '';
    _cr.text = org.crNumber ?? '';
    _vat.text = org.vatNumber ?? '';
    _mainMobile.text = org.mainMobile ?? '';
    _secondMobile.text = org.secondMobile ?? '';
    _mainEmail.text = org.mainEmail ?? '';
    _secondEmail.text = org.secondEmail ?? '';

    // Selects (defensive if options exist)
    _selStatus =
        _optById(_statusOpts, org.statusId ?? -1) ??
        _selStatus ??
        (_statusOpts.isNotEmpty ? _statusOpts.first : null);
    _selType =
        _optById(_typeOpts, org.typeId ?? -1) ??
        _selType ??
        (_typeOpts.isNotEmpty ? _typeOpts.first : null);
    _selCity =
        _firstOrNull(_cities, (c) => c.cityId == org.cityId) ??
        _selCity ??
        (_cities.isNotEmpty ? _cities.first : null);

    // Country read-only label
    _countryRO.text = _countryLabel();
  }

  Future<void> _loadDomains() async {
    _statusOpts = await api.Api.getDomainDetailsByDomainId(11);
    _typeOpts = await api.Api.getDomainDetailsByDomainId(13);
    final fTypes = await api.Api.getDomainDetailsByDomainId(10);
    _fileTypeOpts
      ..clear()
      ..addAll(fTypes);
    // bind if summary is already here
    if (_orgSummary != null) {
      _selStatus =
          _optById(_statusOpts, _orgSummary!.statusId ?? -1) ?? _selStatus;
      _selType = _optById(_typeOpts, _orgSummary!.typeId ?? -1) ?? _selType;
    }
  }

  Future<void> _loadFiles() async {
    final all = await api.Api.getOrganizationFiles();
    _files = (_orgId == null)
        ? []
        : all.where((f) => f.organizationId == _orgId).toList();
  }

  Future<void> _loadMembers() async {
    final all = await api.Api.getOrganizationUsers();
    _members = (_orgId == null)
        ? []
        : all.where((u) => u.organizationId == _orgId).toList();
  }

  Future<void> _loadOrgSummary(int id) async {
    try {
      final org = await api.Api.getOrganizationById(id);
      _log(
        'org loaded -> id=${org.organizationId} statusId=${org.statusId} cityId=${org.cityId}',
      );
      _orgSummary = org;

      _applySummaryToForm(org);
      if (mounted) setState(() {}); // reflect selects/country text
    } catch (e) {
      _log('getOrganizationById failed: $e');
    }
  }

  Future<int?> _resolveMyOrgId() async {
    final meId = AuthStore.instance.user.value?.id;
    if (meId == null) return null;
    final links = await api.Api.getOrganizationUsers();
    final link = _firstOrNull(links, (x) => x.applicationUserId == meId);
    return link?.organizationId;
  }

  // ---------- save/create ----------
  Future<void> _saveOrg() async {
    final nameOk =
        (_nameEn.text.trim().length >= 3) || (_nameAr.text.trim().length >= 3);
    if (!nameOk) {
      AppSnack.error(context, 'Please enter a name (≥ 3 chars)');
      return;
    }
    if (_selType == null || _selStatus == null || _selCity == null) {
      AppSnack.error(context, 'Please choose Status, Type and City');
      return;
    }

    // API expects countryId to be nationalityId
    final int? countryId =
        _selCity?.country?.nationalityId ?? _selCity?.nationalityId;

    final payload = <String, dynamic>{
      if (_orgId != null) 'organizationId': _orgId,
      'nameArabic': _nz(_nameAr.text),
      'nameEnglish': _nz(_nameEn.text),
      'briefArabic': _nz(_briefAr.text),
      'briefEnglish': _nz(_briefEn.text),
      'statusId': _selStatus?.domainDetailId,
      'typeId': _selType!.domainDetailId,
      'countryId': countryId,
      'cityId': _selCity!.cityId,
      'fullAddress': _nz(_address.text),
      'crNumber': _nz(_cr.text),
      'vatNumber': _nz(_vat.text),
      'mainMobile': _nz(_mainMobile.text),
      'mainEmail': _nz(_mainEmail.text),
      'secondMobile': _nz(_secondMobile.text),
      'secondEmail': _nz(_secondEmail.text),
    };

    if (!mounted) return;
    setState(() => _busy = true);
    try {
      if (_orgId == null) {
        // CREATE (envelope path)
        final env = await api.Api.addOrganizationEnvelope(payload);
        if (env.flag != true) {
          AppSnack.error(context, env.message ?? 'Create failed');
          return;
        }
        // resolve id
        final newId = env.modelId ?? await _resolveMyOrgId();
        if (newId == null) {
          AppSnack.error(
            context,
            env.message ?? 'Created, but id not resolved',
          );
          return;
        }
        _orgId = newId;

        // link current user if not already linked (non-fatal)
        final meId = AuthStore.instance.user.value?.id;
        if (meId != null) {
          try {
            await api.Api.addOrganizationUser(
              OrganizationUser(
                organizationId: _orgId,
                applicationUserId: meId,
                statusId: _selStatus?.domainDetailId,
                isActive: true,
              ),
            );
          } catch (_) {}
        }

        await _loadOrgSummary(_orgId!);
        await Future.wait([_loadFiles(), _loadMembers()]);
        AppSnack.success(context, env.message ?? 'Organization created');
        if (mounted) setState(() {});
      } else {
        final env = await api.Api.updateOrganizationEnvelope(payload);
        if (env.flag == false) {
          AppSnack.error(context, env.message ?? 'Update failed');
          return;
        }
        await _loadOrgSummary(_orgId!);
        await Future.wait([_loadFiles(), _loadMembers()]);
        AppSnack.success(context, env.message ?? 'Organization updated');
        if (mounted) setState(() {});
      }
    } catch (e, st) {
      _log('save error: $e\n$st');
      AppSnack.error(context, 'Could not save organization');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ---------- files CRUD ----------
  Future<void> _addOrEditFile({OrganizationFileModel? existing}) async {
    if (_orgId == null) {
      AppSnack.info(context, 'Create organization first');
      return;
    }
    if (_fileTypeOpts.isEmpty) {
      await _loadDomains();
    }

    DomainDetail? selType = (() {
      final id = existing?.fileTypeId ?? existing?.fileType?.domainDetailId;
      return id == null ? null : _optById(_fileTypeOpts, id);
    })();

    final desc = TextEditingController(text: existing?.descFileType ?? '');
    final fileName = TextEditingController(text: existing?.fileName ?? '');
    final issue = TextEditingController(text: existing?.issueDate ?? '');
    final expire = TextEditingController(text: existing?.enDate ?? '');

    Future<void> pickDate(TextEditingController ctrl) async {
      final now = DateTime.now();
      final d = await showDatePicker(
        context: context,
        initialDate: _parseYMD(ctrl.text) ?? now,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );
      if (d != null) {
        ctrl.text = DateFormat('yyyy-MM-dd').format(d);
      }
    }

    Future<void> pickFile() async {
      final res = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        withData: false, // we don't need bytes anymore
        allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'pdf'],
      );
      if (res == null || res.files.isEmpty) return;

      final f = res.files.first;
      // Use local filename only for metadata; server must already host it (or be handled out of band)
      final localName = (f.name).trim();
      if (localName.isEmpty) return;

      // Set filename (used for server-side lookup/preview) and recompute derived props
      fileName.text = localName;
    }

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        DomainDetail? _localSel = selType;
        return StatefulBuilder(
          builder: (context, setModal) {
            final cs = Theme.of(context).colorScheme;
            final isImage = _isImageByName(fileName.text);
            final isExpired = _computeExpired(expire.text);
            final isActive = _computeActive(issue.text, expire.text);
            return Glass(
              radius: 20,
              child: Padding(
                padding: EdgeInsets.only(
                  left: 12,
                  right: 12,
                  top: 12,
                  bottom: 12 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Attachment',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            DropdownButtonFormField<DomainDetail>(
                              value: _localSel,
                              items: _fileTypeOpts
                                  .map(
                                    (d) => DropdownMenuItem(
                                      value: d,
                                      child: Text(
                                        d.detailNameEnglish ??
                                            d.detailNameArabic ??
                                            '—',
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) => setModal(() => _localSel = v),
                              decoration: const InputDecoration(
                                labelText: 'File type',
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: AInput(
                                    controller: fileName,
                                    label: 'add file name *',
                                    hint: 'e.g. cr_2025.pdf',
                                    glyph: AppGlyph.attachment,
                                    readOnly: true,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                FilledButton.icon(
                                  onPressed: pickFile,
                                  icon: const Icon(Icons.upload_file),
                                  label: const Text('Pick file *'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            AInput(
                              controller: desc,
                              label: 'Description (optional)',
                              glyph: AppGlyph.note,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: AInput(
                                    controller: issue,
                                    label: 'Issue date',
                                    glyph: AppGlyph.calendar,
                                    readOnly: true,
                                    onTap: () => pickDate(issue),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: AInput(
                                    controller: expire,
                                    label: 'Expire date',
                                    glyph: AppGlyph.calendar,
                                    readOnly: true,
                                    onTap: () => pickDate(expire),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _chipComputed('Image', isImage, cs),
                                _chipComputed('Active', isActive, cs),
                                _chipComputed(
                                  'Expired',
                                  isExpired,
                                  cs,
                                  danger: isExpired,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: GhostButton(
                            onPressed: () => Navigator.pop(context, false),
                            icon: AIcon(
                              AppGlyph.close,
                              color: cs.primary,
                              selected: true,
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: BrandButton(
                            onPressed: () {
                              if (_localSel == null) {
                                AppSnack.error(context, 'Choose a file type');
                                return;
                              }
                              if (fileName.text.trim().isEmpty) {
                                AppSnack.error(
                                  context,
                                  'Pick a file — name is required',
                                );
                                return;
                              }
                              selType = _localSel;
                              Navigator.pop(context, true);
                            },

                            icon: AIcon(
                              AppGlyph.save,
                              color: Colors.white,
                              selected: true,
                            ),
                            child: const Text('Save'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    final isExpiredFinal = _computeExpired(expire.text);
    final isActiveFinal = _computeActive(issue.text, expire.text);
    if (ok == true) {
      final model = OrganizationFileModel(
        organizationFileId: existing?.organizationFileId,
        organizationId: _orgId,
        fileTypeId: selType?.domainDetailId, // Domain 10 detail id
        fileTypeExt: _extFrom(fileName.text), // <-- NEW: set extension
        isImage: _isImageByName(fileName.text),
        descFileType: desc.text,
        fileName: fileName.text, // stored/display name only
        isExpired: isExpiredFinal,
        isActive: isActiveFinal,
        issueDate: issue.text, // "yyyy-MM-dd"
        enDate: expire.text, // "yyyy-MM-dd"
      );

      try {
        if (!mounted) return;
        setState(() => _busy = true);
        if (existing == null) {
          await api.Api.addOrganizationFile(model);
          AppSnack.success(context, 'File added');
        } else {
          await api.Api.updateOrganizationFile(model);
          AppSnack.success(context, 'File updated');
        }
        await _loadFiles();
        if (mounted) setState(() {});
      } catch (e, st) {
        _log('file save error: $e\n$st');
        AppSnack.error(context, 'Could not save file');
      } finally {
        if (mounted) setState(() => _busy = false);
      }
    }
  }

  Future<void> _deleteFile(OrganizationFileModel f) async {
    // 1) Confirm
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete file'),
        content: const Text('Are you sure you want to delete this file?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    // 2) Validate id (avoid crash on null `!`)
    final id = f.organizationFileId;
    if (id == null || id <= 0) {
      AppSnack.error(context, 'Could not delete: missing file id');
      return;
    }

    // 3) Optimistic UI: remove immediately, rollback on failure
    final idx = _files.indexWhere((x) => x.organizationFileId == id);
    OrganizationFileModel? removed;
    if (idx >= 0) {
      removed = _files.removeAt(idx);
      if (mounted) setState(() {}); // shrink list right away
    }

    // Clear any cached existence/thumbnail (prevents ghost thumb)
    final nameKey = (f.fileName ?? '').trim();
    if (nameKey.isNotEmpty) {
      _existsCache.remove(nameKey);
    }

    // 4) Network call with busy overlay
    try {
      if (!mounted) return;
      setState(() => _busy = true);

      await api.Api.deleteOrganizationFile(id);

      // Re-fetch to be authoritative in case server applied side-effects
      await _loadFiles();
      if (mounted) setState(() {});
      AppSnack.success(context, 'File deleted');
    } catch (e, st) {
      _log('file delete error: $e\n$st');

      // Roll back optimistic removal if call failed
      if (removed != null && idx >= 0 && idx <= _files.length) {
        _files.insert(idx, removed);
        if (mounted) setState(() {});
      }
      AppSnack.error(context, 'Could not delete file');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ---------- utils: dates & thumbs ----------
  DateTime? _parseYMD(String s) {
    final t = s.trim();
    if (t.isEmpty) return null;
    try {
      return DateTime.parse(t);
    } catch (_) {
      return null;
    }
  }

  bool _isImageByName(String name) {
    final n = name.toLowerCase();
    return n.endsWith('.jpg') ||
        n.endsWith('.jpeg') ||
        n.endsWith('.png') ||
        n.endsWith('.gif') ||
        n.endsWith('.webp') ||
        n.endsWith('.bmp');
  }

  // Expired ⇢ end < today (date-only)
  bool _computeExpired(String endYmd) {
    final end = _parseYMD(endYmd);
    if (end == null) return false;
    final today = DateTime.now();
    final endD = DateTime(end.year, end.month, end.day);
    final todayD = DateTime(today.year, today.month, today.day);
    return endD.isBefore(todayD);
  }

  // Active = today in [issue, end] inclusive (date-only)
  // If start missing -> -∞, if end missing -> +∞
  bool _computeActive(String startYmd, String endYmd) {
    final now = DateTime.now();
    final todayD = DateTime(now.year, now.month, now.day);

    final s = _parseYMD(startYmd) ?? DateTime(1900, 1, 1);
    final e = _parseYMD(endYmd) ?? DateTime(9999, 12, 31);

    final sD = DateTime(s.year, s.month, s.day);
    final eD = DateTime(e.year, e.month, e.day);

    final notBeforeStart = !todayD.isBefore(sD); // today >= start
    final notAfterEnd = !todayD.isAfter(eD); // today <= end
    return notBeforeStart && notAfterEnd;
  }

  Future<bool> _ensureExists(String name) {
    return _existsCache[name] ??= api.Api.orgStaticFileExists(name);
  }

  Widget _buildFileThumb(OrganizationFileModel f) {
    final name = (f.fileName ?? '').trim();
    final isImg = _isImageByName(name);
    if (!isImg || name.isEmpty) return _fileThumbPlaceholder(context);

    _existsCache[name] ??= _ensureExists(name);

    return FutureBuilder<bool>(
      future: _existsCache[name],
      builder: (_, snap) {
        final ok = snap.data == true;
        if (!ok) return _fileThumbPlaceholder(context);
        final url = '$_ORG_FILE_BASE${Uri.encodeComponent(name)}';
        return Image.network(
          url,
          fit: BoxFit.cover,
          loadingBuilder: (_, child, progress) =>
              progress == null ? child : _fileThumbPlaceholder(context),
          errorBuilder: (_, __, ___) => _fileThumbPlaceholder(context),
        );
      },
    );
  }

  Widget _fileThumbPlaceholder(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: cs.surface,
      child: Center(
        child: Icon(Icons.insert_drive_file_outlined, color: cs.outline),
      ),
    );
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Organization')),
      body: AbsorbPointer(
        absorbing: _busy,
        child: Stack(
          children: [
            if (_busy) const LinearProgressIndicator(minHeight: 2),
            LayoutBuilder(
              builder: (context, bc) {
                final w = bc.maxWidth;
                final twoCol = w >= 960;
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ——— Organization form ———
                      Glass(
                        radius: 18,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _orgId == null
                                    ? 'Create organization'
                                    : 'Organization',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 12),
                              _row2(
                                twoCol,
                                left: DropdownButtonFormField<DomainDetail>(
                                  value: _selType,
                                  items: _typeOpts
                                      .map(
                                        (d) => DropdownMenuItem(
                                          value: d,
                                          child: Text(
                                            d.detailNameEnglish ??
                                                d.detailNameArabic ??
                                                '—',
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (v) =>
                                      setState(() => _selType = v),
                                  decoration: const InputDecoration(
                                    labelText: 'Type',
                                  ),
                                ),
                                right: DropdownButtonFormField<DomainDetail>(
                                  value: _selStatus,
                                  items: _statusOpts
                                      .map(
                                        (d) => DropdownMenuItem(
                                          value: d,
                                          child: Text(
                                            d.detailNameEnglish ??
                                                d.detailNameArabic ??
                                                '—',
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (v) =>
                                      setState(() => _selStatus = v),
                                  decoration: const InputDecoration(
                                    labelText: 'Status',
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              _row2(
                                twoCol,
                                left: AInput(
                                  controller: _nameAr,
                                  label: 'Name arabic',
                                  glyph: AppGlyph.edit,
                                ),
                                right: AInput(
                                  controller: _nameEn,
                                  label: 'Name english',
                                  glyph: AppGlyph.edit,
                                ),
                              ),
                              const SizedBox(height: 10),
                              _row2(
                                twoCol,
                                left: AInput(
                                  controller: _briefAr,
                                  label: 'Brief arabic',
                                  glyph: AppGlyph.note,
                                  maxLines: 3,
                                ),
                                right: AInput(
                                  controller: _briefEn,
                                  label: 'Brief english',
                                  glyph: AppGlyph.note,
                                  maxLines: 3,
                                ),
                              ),
                              const SizedBox(height: 10),
                              _row2(
                                twoCol,
                                left: AInput(
                                  label: 'Country',
                                  glyph: AppGlyph.globe,
                                  readOnly: true,
                                  controller: _countryRO,
                                ),

                                right: DropdownButtonFormField<City>(
                                  value: _selCity,
                                  items: _cities
                                      .map(
                                        (c) => DropdownMenuItem(
                                          value: c,
                                          child: Text(
                                            c.nameEnglish ??
                                                c.nameArabic ??
                                                '—',
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (v) => setState(() {
                                    _selCity = v;
                                    _countryRO.text = _countryLabel();
                                  }),

                                  decoration: const InputDecoration(
                                    labelText: 'City',
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              AInput(
                                controller: _address,
                                label: 'Address',
                                glyph: AppGlyph.mapPin,
                              ),
                              const SizedBox(height: 10),
                              _row2(
                                twoCol,
                                left: AInput(
                                  controller: _cr,
                                  label: 'C.R. Number',
                                  glyph: AppGlyph.info,
                                ),
                                right: AInput(
                                  controller: _vat,
                                  label: 'VAT Number',
                                  glyph: AppGlyph.info,
                                ),
                              ),
                              const SizedBox(height: 10),
                              _row2(
                                twoCol,
                                left: AInput(
                                  controller: _mainMobile,
                                  label: 'Main mobile',
                                  glyph: AppGlyph.phone,
                                ),
                                right: AInput(
                                  controller: _secondMobile,
                                  label: 'Second mobile',
                                  glyph: AppGlyph.phone,
                                ),
                              ),
                              const SizedBox(height: 10),
                              _row2(
                                twoCol,
                                left: AInput(
                                  controller: _mainEmail,
                                  label: 'Main email',
                                  glyph: AppGlyph.mail,
                                ),
                                right: AInput(
                                  controller: _secondEmail,
                                  label: 'Second email',
                                  glyph: AppGlyph.mail,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: GhostButton(
                                      onPressed: _boot,
                                      icon: AIcon(
                                        AppGlyph.refresh,
                                        color: cs.primary,
                                      ),
                                      child: const Text('Reset'),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: BrandButton(
                                      onPressed: _saveOrg,
                                      icon: AIcon(
                                        AppGlyph.save,
                                        color: Colors.white,
                                        selected: true,
                                      ),
                                      child: Text(
                                        _orgId == null ? 'Create' : 'Save',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ——— Files ———
                      Glass(
                        radius: 18,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(0, 10, 0, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Files • Attachments',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                  SizedBox(width: 35),
                                  TextButton.icon(
                                    onPressed: _orgId == null
                                        ? null
                                        : () => _addOrEditFile(),
                                    icon: const Icon(Icons.add),
                                    label: const Text('Add file'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (_orgId == null)
                                Text(
                                  'Create organization to manage files.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                )
                              else if (_files.isEmpty)
                                Text(
                                  'No files yet.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                )
                              else
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _files.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 8),
                                  itemBuilder: (_, i) {
                                    final f = _files[i];
                                    final isImg = _isImageByName(
                                      f.fileName ?? '',
                                    );
                                    return Container(
                                      padding: const EdgeInsets.all(9),
                                      decoration: BoxDecoration(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.surfaceVariant,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 1,
                                            child: Text(
                                              '${i + 1}',
                                              style: Theme.of(
                                                context,
                                              ).textTheme.labelLarge,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: SizedBox(
                                              width: 40,
                                              height: 54,
                                              child: isImg
                                                  ? _buildFileThumb(f)
                                                  : _fileThumbPlaceholder(
                                                      context,
                                                    ),
                                            ),
                                          ),
                                          const SizedBox(width: 5),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  f
                                                          .fileType
                                                          ?.detailNameEnglish ??
                                                      f.descFileType ??
                                                      '—',
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleSmall
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                ),
                                                const SizedBox(height: 2),
                                                Row(
                                                  children: [
                                                    Text(
                                                      'Issue: ${f.issueDate ?? '—'}',
                                                      style: Theme.of(
                                                        context,
                                                      ).textTheme.labelMedium,
                                                    ),
                                                    const SizedBox(width: 10),
                                                  ],
                                                ),
                                                Row(
                                                  children: [
                                                    Text(
                                                      'Expire: ${f.enDate ?? '—'}',
                                                      style: Theme.of(
                                                        context,
                                                      ).textTheme.labelMedium,
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            tooltip: 'Edit',
                                            icon: const Icon(Icons.edit),
                                            onPressed: () =>
                                                _addOrEditFile(existing: f),
                                          ),
                                          IconButton(
                                            tooltip: 'Delete',
                                            icon: const Icon(
                                              Icons.delete_outline,
                                            ),
                                            onPressed: () => _deleteFile(f),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ——— Users ———
                      /*
                      Glass(
                        radius: 18,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Users',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 10),
                              if (_orgId == null)
                                Text(
                                  'Create organization to see members.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                )
                              else if (_members.isEmpty)
                                Text(
                                  'No users linked.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                )
                              else
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _members.length,
                                  separatorBuilder: (_, __) =>
                                      const Divider(height: 14),
                                  itemBuilder: (_, i) {
                                    final m = _members[i];
                                    final u = m.applicationUser;
                                    final name =
                                        (u?.fullName?.trim().isNotEmpty ??
                                            false)
                                        ? u!.fullName!
                                        : 'User #${m.applicationUserId ?? '—'}';
                                    return ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: CircleAvatar(
                                        child: AIcon(
                                          AppGlyph.user,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                        ),
                                      ),
                                      title: Text(
                                        name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      subtitle: Text(
                                        u?.email ?? u?.mobile ?? '—',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                    */
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- small UI helpers ---
  Widget _row2(bool twoCol, {required Widget left, required Widget right}) {
    if (!twoCol) {
      return Column(children: [left, const SizedBox(height: 8), right]);
    }
    return Row(
      children: [
        Expanded(child: left),
        const SizedBox(width: 10),
        Expanded(child: right),
      ],
    );
  }

  Widget _chipComputed(
    String label,
    bool value,
    ColorScheme cs, {
    bool danger = false,
  }) {
    final color = danger ? cs.error : cs.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: value ? color.withOpacity(0.10) : cs.surfaceVariant,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: value ? color : cs.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            value ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: value ? color : cs.outline,
          ),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: cs.onSurface)),
        ],
      ),
    );
  }
}

String? _extFrom(String name) {
  final n = name.trim().toLowerCase();
  final i = n.lastIndexOf('.');
  if (i <= 0 || i == n.length - 1) return null;
  return n.substring(i + 1); // e.g. "pdf", "jpg"
}

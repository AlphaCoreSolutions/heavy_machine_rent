import 'dart:io';
import 'package:flutter/material.dart';
import 'package:Ajjara/core/models/admin/employee.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:Ajjara/foundation/ui/app_icons.dart';
import 'package:Ajjara/foundation/ui/ui_extras.dart'; // Glass, PressableScale, AppSnack
import 'package:Ajjara/foundation/ui/ui_kit.dart'; // AInput, BrandButton, GhostButton
import 'package:Ajjara/core/api/api_handler.dart' as api;
import 'package:Ajjara/l10n/l10n.dart';

/// Minimal employee model (adjust to your real model)
class EmployeeModel {
  final int? employeeId;
  String fullName;
  String? phone;
  String? email;
  String? title; // role
  String? avatarPath; // file name / URL
  bool isActive;

  EmployeeModel({
    this.employeeId,
    required this.fullName,
    this.phone,
    this.email,
    this.title,
    this.avatarPath,
    this.isActive = true,
  });

  factory EmployeeModel.fromJson(Map<String, dynamic> j) => EmployeeModel(
    employeeId: j['employeeId'] as int?,
    fullName: (j['fullName'] ?? j['name'] ?? '') as String,
    phone: j['phone'] as String?,
    email: j['email'] as String?,
    title: j['title'] as String?,
    avatarPath: j['avatarPath'] as String?,
    isActive: (j['isActive'] as bool?) ?? true,
  );

  Map<String, dynamic> toJson() => {
    'employeeId': employeeId,
    'fullName': fullName,
    'phone': phone,
    'email': email,
    'title': title,
    'avatarPath': avatarPath,
    'isActive': isActive,
  };
}

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key});
  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  final _searchCtrl = TextEditingController();
  Future<List<EmployeeModel>>? _future;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _load() {
    setState(() {
      // TODO: Implement these endpoints in Api.* (names are suggested)
      _future = api.Api.getEmployees().then(
        (list) => list.map((e) => EmployeeModel.fromJson(e.toJson())).toList(),
      );
      // If you already have a typed model: just return that directly.
    });
  }

  void _doSearch() {
    final q = _searchCtrl.text.trim();
    setState(() {
      _future = q.isEmpty
          ? api.Api.getEmployees().then(
              (list) =>
                  list.map((e) => EmployeeModel.fromJson(e.toJson())).toList(),
            )
          : api.Api.searchEmployees(q).then(
              (list) =>
                  list.map((e) => EmployeeModel.fromJson(e.toJson())).toList(),
            );
    });
  }

  Future<void> _addOrEdit([EmployeeModel? existing]) async {
    final result = await showModalBottomSheet<EmployeeModel>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _EmployeeFormSheet(model: existing),
    );
    if (result == null) return;

    try {
      setState(() => _busy = true);
      if (existing == null) {
        // Add
        // If you have a typed model in your Api, convert accordingly
        await api.Api.addEmployee(result.toJson() as Employee);
        AppSnack.success(context, context.l10n.employeeAdded);
      } else {
        // Update
        await api.Api.updateEmployee(result.toJson() as Employee);
        AppSnack.success(context, context.l10n.employeeUpdated);
      }
      _load();
    } catch (_) {
      AppSnack.error(context, context.l10n.couldNotSaveEmployee);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(EmployeeModel m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.l10n.deleteEmployeeTitle),
        content: Text(context.l10n.deleteEmployeeBody(m.fullName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.actionDelete),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      setState(() => _busy = true);
      await api.Api.deleteEmployee(m.employeeId ?? 0);
      AppSnack.success(context, context.l10n.employeeDeleted);
      _load();
    } catch (_) {
      AppSnack.error(context, context.l10n.couldNotDeleteEmployee);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.employeesTitle)),
      body: Stack(
        children: [
          if (_busy) const LinearProgressIndicator(minHeight: 2),
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: AInput(
                  controller: _searchCtrl,
                  label: context.l10n.searchEmployeesHint,
                  hint: context.l10n.searchHintEmployees,
                  glyph: AppGlyph.search,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _doSearch(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                child: Row(
                  children: [
                    BrandButton(
                      onPressed: _doSearch,
                      icon: AIcon(
                        AppGlyph.search,
                        color: Colors.white,
                        selected: true,
                      ),
                      child: Text(context.l10n.common_search),
                    ),
                    const SizedBox(width: 10),
                    GhostButton(
                      onPressed: _load,
                      icon: AIcon(AppGlyph.refresh, color: cs.primary),
                      child: Text(context.l10n.actionClear),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => _load(),
                  child: FutureBuilder<List<EmployeeModel>>(
                    future: _future,
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return ListView(
                          children: const [
                            ShimmerTile(),
                            ShimmerTile(),
                            ShimmerTile(),
                          ],
                        );
                      }
                      if (snap.hasError) {
                        return ListView(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                'Failed to load employees',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ),
                          ],
                        );
                      }
                      final items = snap.data ?? [];
                      if (items.isEmpty) {
                        return ListView(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                'No employees yet.',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ),
                          ],
                        );
                      }
                      return ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (_, i) {
                          final m = items[i];
                          return _EmployeeTile(
                            model: m,
                            onEdit: () => _addOrEdit(m),
                            onDelete: () => _delete(m),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addOrEdit(),
        icon: const Icon(Icons.add),
        label: Text(context.l10n.actionAdd),
      ),
    );
  }
}

class _EmployeeTile extends StatelessWidget {
  const _EmployeeTile({
    required this.model,
    required this.onEdit,
    required this.onDelete,
  });

  final EmployeeModel model;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimateIn(
      child: Glass(
        margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        radius: 14,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          leading: _Avatar(pathOrUrl: model.avatarPath, name: model.fullName),
          title: Text(
            model.fullName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            [
              if ((model.title ?? '').trim().isNotEmpty) model.title,
              if ((model.email ?? '').trim().isNotEmpty) model.email,
              if ((model.phone ?? '').trim().isNotEmpty) model.phone,
            ].whereType<String>().join(' • '),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: context.l10n.actionEdit,
                onPressed: onEdit,
                icon: Icon(Icons.edit, color: cs.primary),
              ),
              IconButton(
                tooltip: context.l10n.actionDelete,
                onPressed: onDelete,
                icon: Icon(Icons.delete_outline, color: cs.error),
              ),
            ],
          ),
          onTap: onEdit,
        ),
      ),
    );
  }
}

class _EmployeeFormSheet extends StatefulWidget {
  const _EmployeeFormSheet({required this.model});
  final EmployeeModel? model;

  @override
  State<_EmployeeFormSheet> createState() => _EmployeeFormSheetState();
}

class _EmployeeFormSheetState extends State<_EmployeeFormSheet> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _title = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  File? _pickedAvatar;
  String? _avatarPath; // keep original

  @override
  void initState() {
    super.initState();
    final m = widget.model;
    _name.text = m?.fullName ?? '';
    _title.text = m?.title ?? '';
    _email.text = m?.email ?? '';
    _phone.text = m?.phone ?? '';
    _avatarPath = m?.avatarPath;
  }

  @override
  void dispose() {
    _name.dispose();
    _title.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final x = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
    );
    if (x != null) setState(() => _pickedAvatar = File(x.path));
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    final m = EmployeeModel(
      employeeId: widget.model?.employeeId,
      fullName: _name.text.trim(),
      title: _title.text.trim(),
      email: _email.text.trim(),
      phone: _phone.text.trim(),
      avatarPath: _avatarPath, // TODO: upload and set returned path if needed
      isActive: true,
    );
    Navigator.pop(context, m);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.model == null
                ? context.l10n.addEmployeeTitle
                : context.l10n.editEmployeeTitle,
          ),
          actions: [
            IconButton(
              tooltip: context.l10n.actionSave,
              onPressed: _save,
              icon: const Icon(Icons.check),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          children: [
            Glass(
              radius: 16,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 34,
                          backgroundColor: cs.surfaceContainerHighest,
                          backgroundImage: _pickedAvatar != null
                              ? FileImage(_pickedAvatar!)
                              : null,
                          child: _pickedAvatar == null
                              ? _Avatar(
                                  pathOrUrl: _avatarPath,
                                  name: _name.text,
                                  radius: 34,
                                  asChild: true,
                                )
                              : null,
                        ),
                        Positioned(
                          right: -4,
                          bottom: -4,
                          child: PressableScale(
                            onTap: _pickAvatar,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: cs.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.edit,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _name.text.isEmpty
                            ? context.l10n.newEmployee
                            : _name.text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Glass(
              radius: 16,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Form(
                  key: _form,
                  child: Column(
                    children: [
                      AInput(
                        controller: _name,
                        label: context.l10n.fullName,
                        glyph: AppGlyph.user,
                        textInputAction: TextInputAction.next,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? context.l10n.requiredField
                            : null,
                      ),
                      const SizedBox(height: 8),
                      AInput(
                        controller: _title,
                        label: context.l10n.roleTitleLabel,
                        glyph: AppGlyph.info,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 8),
                      AInput(
                        controller: _email,
                        label: context.l10n.email,
                        glyph: AppGlyph.mail,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: (v) =>
                            (v == null || v.isEmpty || !v.contains('@'))
                            ? context.l10n.validationEmail
                            : null,
                      ),
                      const SizedBox(height: 8),
                      AInput(
                        controller: _phone,
                        label: context.l10n.mobileLabel,
                        glyph: AppGlyph.phone,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.done,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: BrandButton(
                              onPressed: _save,
                              icon: AIcon(
                                AppGlyph.save,
                                color: Colors.white,
                                selected: true,
                              ),
                              child: Text(context.l10n.actionSave),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: GhostButton(
                              onPressed: () => Navigator.pop(context),
                              icon: AIcon(
                                AppGlyph.close,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              child: Text(context.l10n.actionCancel),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small avatar that tries server paths, otherwise shows initials.
/// Uses your Api.fileCandidates + auth headers if available.
class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.pathOrUrl,
    required this.name,
    this.radius = 24,
    this.asChild = false,
  });

  final String? pathOrUrl;
  final String name;
  final double radius;
  final bool asChild;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final initials = _initials(name);

    if ((pathOrUrl ?? '').trim().isEmpty) {
      return _fallback(initials, cs);
    }

    // Build candidates from your Api helper (works with file names or full URLs)
    final cands = api.Api.fileCandidates(pathOrUrl);

    return ClipOval(
      child: SizedBox(
        width: radius * 2,
        height: radius * 2,
        child: CachedNetworkImage(
          imageUrl: cands.first,
          httpHeaders: api.Api.imageAuthHeaders(),
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) {
            // try next candidate if possible
            if (cands.length > 1) {
              return CachedNetworkImage(
                imageUrl: cands[1],
                httpHeaders: api.Api.imageAuthHeaders(),
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => _fallback(initials, cs),
              );
            }
            return _fallback(initials, cs);
          },
          placeholder: (_, __) => Container(color: cs.surfaceContainerHighest),
        ),
      ),
    );
  }

  Widget _fallback(String initials, ColorScheme cs) {
    final base = CircleAvatar(
      radius: radius,
      backgroundColor: cs.surfaceContainerHighest,
      child: Text(
        initials,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          color: cs.onSurfaceVariant,
        ),
      ),
    );
    return asChild ? base : base;
  }

  String _initials(String s) {
    final parts = s
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '—';
    if (parts.length == 1) {
      return parts.first.characters.take(2).toString().toUpperCase();
    }
    return (parts.first.characters.take(1).toString() +
            parts.last.characters.take(1).toString())
        .toUpperCase();
  }
}

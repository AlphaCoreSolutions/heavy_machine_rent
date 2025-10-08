// lib/screens/super_admin_hub_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:heavy_new/core/auth/auth_store.dart';
import 'package:heavy_new/core/api/api_handler.dart' as api;

import 'package:heavy_new/core/models/admin/request.dart';
import 'package:heavy_new/core/models/organization/organization_file.dart';
import 'package:heavy_new/core/models/organization/organization_user.dart';
// ⬇️ Add these imports (adjust paths if needed)
import 'package:heavy_new/core/models/equipment/equipment.dart';
import 'package:heavy_new/core/models/organization/organization_summary.dart';

import 'package:heavy_new/foundation/ui/ui_extras.dart';
import 'package:heavy_new/foundation/ui/ui_kit.dart';
import 'package:heavy_new/foundation/ui/app_icons.dart';
import 'package:heavy_new/screens/organization_screens/organization_hub_screen.dart';
import 'package:heavy_new/screens/auth_profile_screens/phone_auth_screen.dart';

// ⬇️ Localization
import 'package:heavy_new/l10n/app_localizations.dart';

extension _L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}

class SuperAdminHubScreen extends StatelessWidget {
  const SuperAdminHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthStore.instance;

    // Gate: only super admin (userTypeId == 17)
    if (!auth.isLoggedIn) {
      return _GateScreen(
        title: context.l10n.superAdmin_gate_signIn_title,
        message: context.l10n.superAdmin_gate_signIn_message,
        primary: () async {
          final ok = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const PhoneAuthScreen()),
          );
          if (ok == true && context.mounted) {
            AppSnack.success(context, context.l10n.common_signedIn);
          }
        },
        primaryLabel: context.l10n.action_signIn,
      );
    }
    /*
    if (u?.userTypeId != 17) {
      return _GateScreen(
        title: context.l10n.superAdmin_gate_notAvailable_title,
        message: context.l10n.superAdmin_gate_notAvailable_message,
        primary: () => Navigator.of(context).maybePop(),
        primaryLabel: context.l10n.action_back,
      );
    }
    */

    return DefaultTabController(
      length: 5, // ⬅️ now 5 tabs
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.superAdmin_title),
          bottom: TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: context.l10n.superAdmin_tab_orgFiles),
              Tab(text: context.l10n.superAdmin_tab_orgUsers),
              Tab(text: context.l10n.superAdmin_tab_requestsOrders),
              Tab(text: context.l10n.superAdmin_tab_inactiveEquipments),
              Tab(text: context.l10n.superAdmin_tab_inactiveOrgs),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _OrgFilesTab(),
            _OrgUsersTab(),
            _RequestsOrdersTab(),
            _InactiveEquipmentsTab(),
            _InactiveOrganizationsTab(),
          ],
        ),
      ),
    );
  }
}

class _GateScreen extends StatelessWidget {
  const _GateScreen({
    required this.title,
    required this.message,
    required this.primary,
    required this.primaryLabel,
  });
  final String title;
  final String message;
  final VoidCallback primary;
  final String primaryLabel;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.superAdmin_title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Glass(
            radius: 18,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: cs.surfaceContainerHighest,
                      child: AIcon(AppGlyph.info, color: cs.primary),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(onPressed: primary, child: Text(primaryLabel)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ========================== ORG FILES TAB ==========================
class _OrgFilesTab extends StatefulWidget {
  const _OrgFilesTab();

  @override
  State<_OrgFilesTab> createState() => _OrgFilesTabState();
}

class _OrgFilesTabState extends State<_OrgFilesTab> {
  late Future<List<OrganizationFileModel>> _future;
  final _qCtrl = TextEditingController();
  Timer? _deb;

  @override
  void initState() {
    super.initState();
    _future = api.Api.getOrganizationFiles();
    _qCtrl.addListener(_onQ);
  }

  @override
  void dispose() {
    _qCtrl.removeListener(_onQ);
    _qCtrl.dispose();
    _deb?.cancel();
    super.dispose();
  }

  void _onQ() {
    _deb?.cancel();
    _deb = Timer(const Duration(milliseconds: 350), () {
      final q = _qCtrl.text.trim();
      setState(() {
        _future = q.isEmpty
            ? api.Api.getOrganizationFiles()
            : api.Api.advanceSearchOrganizationFiles(q);
      });
    });
  }

  String _fileUrl(String? name) =>
      'https://sr.visioncit.com/StaticFiles/orgfileFiles/${name ?? ''}';

  Future<void> _toggleActive(OrganizationFileModel f) async {
    try {
      final updated = f.copyWith(isActive: !(f.isActive ?? false));
      await api.Api.updateOrganizationFile(updated);
      AppSnack.success(context, context.l10n.common_updated);
      setState(() {
        _future = api.Api.getOrganizationFiles();
      });
    } catch (_) {
      AppSnack.error(context, context.l10n.common_updateFailed);
    }
  }

  Future<void> _delete(OrganizationFileModel f) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.l10n.orgFiles_delete_title),
        content: Text(
          context.l10n.orgFiles_delete_message(
            f.fileName ?? context.l10n.common_file,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.action_cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.action_delete),
          ),
        ],
      ),
    );
    if (yes != true) return;
    try {
      await api.Api.deleteOrganizationFile(f.organizationFileId ?? 0);
      AppSnack.success(context, context.l10n.common_deleted);
      setState(() {
        _future = api.Api.getOrganizationFiles();
      });
    } catch (_) {
      AppSnack.error(context, context.l10n.common_deleteFailed);
    }
  }

  void _preview(OrganizationFileModel f) {
    final url = _fileUrl(f.fileName);
    showDialog(
      context: context,
      builder: (_) {
        final cs = Theme.of(context).colorScheme;
        return Dialog(
          child: Glass(
            radius: 12,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text(
                    f.descFileType ?? f.fileName ?? context.l10n.common_file,
                  ),
                  subtitle: Text(
                    context.l10n.common_orgNumber(
                      (f.organizationId ?? '—').toString(),
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                if (f.isImage == true)
                  AspectRatio(
                    aspectRatio: 16 / 10,
                    child: FallbackNetworkImage(
                      candidates: [url],
                      placeholderColor: cs.surfaceContainerHighest,
                      fit: BoxFit.contain,
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SelectableText(url),
                  ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
          child: AInput(
            controller: _qCtrl,
            label: context.l10n.orgFiles_search_label,
            hint: context.l10n.common_typeToSearch,
            glyph: AppGlyph.search,
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => setState(() {
              _future = api.Api.getOrganizationFiles();
            }),
            child: FutureBuilder<List<OrganizationFileModel>>(
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
                final items = snap.data ?? [];
                if (items.isEmpty) {
                  return ListView(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(context.l10n.orgFiles_empty),
                      ),
                    ],
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 24),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final f = items[i];
                    return Glass(
                      radius: 14,
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: CircleAvatar(
                          backgroundColor: cs.surfaceContainerHighest,
                          child: AIcon(
                            f.isImage == true ? AppGlyph.image : AppGlyph.file,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        title: Text(
                          f.descFileType ?? f.fileName ?? '—',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          '${context.l10n.common_orgNumber((f.organizationId ?? '—').toString())}'
                          '  •  ${(f.fileType?.detailNameEnglish ?? f.fileType?.detailNameArabic ?? '')}'
                          '  •  ${(f.isActive ?? false) ? context.l10n.common_active : context.l10n.common_inactive}'
                          '${(f.isExpired ?? false) ? '  •  ${context.l10n.common_expired}' : ''}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (v) {
                            if (v == 'preview') _preview(f);
                            if (v == 'toggle') _toggleActive(f);
                            if (v == 'delete') _delete(f);
                          },
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              value: 'preview',
                              child: Text(context.l10n.action_previewOpen),
                            ),
                            PopupMenuItem(
                              value: 'toggle',
                              child: Text(
                                (f.isActive ?? false)
                                    ? context.l10n.action_deactivate
                                    : context.l10n.action_activate,
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text(context.l10n.action_delete),
                            ),
                          ],
                        ),
                        onTap: () => _preview(f),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

// ========================== ORG USERS TAB ==========================
class _OrgUsersTab extends StatefulWidget {
  const _OrgUsersTab();

  @override
  State<_OrgUsersTab> createState() => _OrgUsersTabState();
}

class _OrgUsersTabState extends State<_OrgUsersTab> {
  late Future<List<OrganizationUser>> _future;
  final _qCtrl = TextEditingController();
  Timer? _deb;

  @override
  void initState() {
    super.initState();
    _future = api.Api.getOrganizationUsers();
    _qCtrl.addListener(_onQ);
  }

  @override
  void dispose() {
    _qCtrl.removeListener(_onQ);
    _qCtrl.dispose();
    _deb?.cancel();
    super.dispose();
  }

  void _onQ() {
    _deb?.cancel();
    _deb = Timer(const Duration(milliseconds: 350), () {
      final q = _qCtrl.text.trim();
      setState(() {
        _future = q.isEmpty
            ? api.Api.getOrganizationUsers()
            : api.Api.advanceSearchOrganizationUsers(q);
      });
    });
  }

  Future<void> _toggleActive(OrganizationUser u) async {
    try {
      final updated = OrganizationUser(
        organizationUserId: u.organizationUserId,
        organizationId: u.organizationId,
        applicationUserId: u.applicationUserId,
        statusId: u.statusId,
        isActive: !(u.isActive ?? false),
        createDateTime: u.createDateTime,
        modifyDateTime: DateTime.now(),
        applicationUser: u.applicationUser,
      );
      await api.Api.updateOrganizationUser(updated);
      AppSnack.success(context, context.l10n.common_updated);
      setState(() {
        _future = api.Api.getOrganizationUsers();
      });
    } catch (_) {
      AppSnack.error(context, context.l10n.common_updateFailed);
    }
  }

  Future<void> _delete(OrganizationUser u) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.l10n.orgUsers_remove_title),
        content: Text(
          context.l10n.orgUsers_remove_message(
            (u.applicationUserId ?? '').toString(),
            (u.organizationId ?? '').toString(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.action_cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.action_remove),
          ),
        ],
      ),
    );
    if (yes != true) return;
    try {
      await api.Api.deleteOrganizationUser(u.organizationUserId ?? 0);
      AppSnack.success(context, context.l10n.common_removed);
      setState(() {
        _future = api.Api.getOrganizationUsers();
      });
    } catch (_) {
      AppSnack.error(context, context.l10n.common_removeFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
          child: AInput(
            controller: _qCtrl,
            label: context.l10n.orgUsers_search_label,
            hint: context.l10n.common_typeToSearch,
            glyph: AppGlyph.search,
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => setState(() {
              _future = api.Api.getOrganizationUsers();
            }),
            child: FutureBuilder<List<OrganizationUser>>(
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
                final items = snap.data ?? [];
                if (items.isEmpty) {
                  return ListView(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(context.l10n.orgUsers_empty),
                      ),
                    ],
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 24),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final u = items[i];
                    final person = u.applicationUser;
                    final name =
                        person?.fullName ??
                        '${context.l10n.common_user} ${person?.id ?? ''}';
                    final emailOrMobile = (person?.email?.isNotEmpty ?? false)
                        ? person!.email!
                        : (person?.mobile ?? '—');

                    return Glass(
                      radius: 14,
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: CircleAvatar(
                          backgroundColor: cs.surfaceContainerHighest,
                          child: AIcon(
                            AppGlyph.user,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        title: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          '${context.l10n.common_orgNumber((u.organizationId ?? '—').toString())}'
                          '  •  $emailOrMobile'
                          '  •  ${(u.isActive ?? false) ? context.l10n.common_active : context.l10n.common_inactive}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (v) {
                            if (v == 'toggle') _toggleActive(u);
                            if (v == 'open-org') {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => OrganizationScreen(),
                                ),
                              );
                            }
                            if (v == 'delete') _delete(u);
                          },
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              value: 'toggle',
                              child: Text(
                                (u.isActive ?? false)
                                    ? context.l10n.action_deactivate
                                    : context.l10n.action_activate,
                              ),
                            ),
                            PopupMenuItem(
                              value: 'open-org',
                              child: Text(context.l10n.action_openOrganization),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text(context.l10n.action_removeFromOrg),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

// ====================== REQUESTS / ORDERS TAB ======================
class _RequestsOrdersTab extends StatefulWidget {
  const _RequestsOrdersTab();

  @override
  State<_RequestsOrdersTab> createState() => _RequestsOrdersTabState();
}

class _RequestsOrdersTabState extends State<_RequestsOrdersTab> {
  late Future<List<RequestModel>> _future;
  final _qCtrl = TextEditingController();
  Timer? _deb;

  @override
  void initState() {
    super.initState();
    _future = api.Api.getRequests();
    _qCtrl.addListener(_onQ);
  }

  @override
  void dispose() {
    _qCtrl.removeListener(_onQ);
    _qCtrl.dispose();
    _deb?.cancel();
    super.dispose();
  }

  void _onQ() {
    _deb?.cancel();
    _deb = Timer(const Duration(milliseconds: 350), () {
      final q = _qCtrl.text.trim();
      setState(() {
        _future = q.isEmpty
            ? api.Api.getRequests()
            : api.Api.advanceSearchRequests(q);
      });
    });
  }

  String _status(RequestModel r) =>
      r.status?.detailNameEnglish ??
      r.status?.detailNameArabic ??
      r.status?.toString() ??
      '';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
          child: AInput(
            controller: _qCtrl,
            label: context.l10n.requests_search_label,
            hint: context.l10n.common_typeToSearch,
            glyph: AppGlyph.search,
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async =>
                setState(() => _future = api.Api.getRequests()),
            child: FutureBuilder<List<RequestModel>>(
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
                final items = (snap.data ?? [])
                  ..sort((a, b) {
                    final at = a.createDateTime ?? DateTime(0);
                    final bt = b.createDateTime ?? DateTime(0);
                    return bt.compareTo(at);
                  });
                if (items.isEmpty) {
                  return ListView(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(context.l10n.requests_empty),
                      ),
                    ],
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 24),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final r = items[i];
                    final s = _status(r);
                    final idText =
                        r.requestNo?.toString() ??
                        r.requestId?.toString() ??
                        '—';
                    final dateRange =
                        '${(r.fromDate ?? '').toString().split(' ').first} → ${(r.toDate ?? '').toString().split(' ').first}';

                    return Glass(
                      radius: 14,
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: CircleAvatar(
                          backgroundColor: cs.surfaceContainerHighest,
                          child: AIcon(
                            AppGlyph.invoice,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        title: Text(
                          context.l10n.requests_item_title(idText),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text('$dateRange  •  ${s.isEmpty ? '—' : s}'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          // Hook up to a global RequestDetailsScreen if you want
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

// ====================== INACTIVE EQUIPMENTS TAB ======================
class _InactiveEquipmentsTab extends StatefulWidget {
  const _InactiveEquipmentsTab();

  @override
  State<_InactiveEquipmentsTab> createState() => _InactiveEquipmentsTabState();
}

class _InactiveEquipmentsTabState extends State<_InactiveEquipmentsTab> {
  static const String _kEquipmentsSQL =
      'select * from Equipments where isActive = 0';

  late Future<List<Equipment>> _future;
  final _qCtrl = TextEditingController();
  Timer? _deb;

  @override
  void initState() {
    super.initState();
    _future = api.Api.advanceSearchEquipments(_kEquipmentsSQL);
    _qCtrl.addListener(_onQ);
  }

  @override
  void dispose() {
    _qCtrl.removeListener(_onQ);
    _qCtrl.dispose();
    _deb?.cancel();
    super.dispose();
  }

  void _onQ() {
    // You asked to send the exact SQL; ignore user text.
    _deb?.cancel();
    _deb = Timer(const Duration(milliseconds: 350), () {
      setState(() {
        _future = api.Api.advanceSearchEquipments(_kEquipmentsSQL);
      });
    });
  }

  Future<void> _activate(Equipment e) async {
    try {
      final updated = e.copyWith(isActive: true);
      await api.Api.updateEquipment(updated);
      AppSnack.success(context, context.l10n.common_activated);
      setState(() {
        _future = api.Api.advanceSearchEquipments(_kEquipmentsSQL);
      });
    } catch (_) {
      AppSnack.error(context, context.l10n.common_updateFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
          child: AInput(
            controller: _qCtrl,
            label: context.l10n.inactiveEquipments_search_label,
            hint: context.l10n.common_typeToSearch,
            glyph: AppGlyph.search,
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => setState(() {
              _future = api.Api.advanceSearchEquipments(_kEquipmentsSQL);
            }),
            child: FutureBuilder<List<Equipment>>(
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
                final items = snap.data ?? [];
                if (items.isEmpty) {
                  return ListView(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(context.l10n.inactiveEquipments_empty),
                      ),
                    ],
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 24),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final e = items[i];
                    final name = (e.descEnglish ?? '').isNotEmpty
                        ? e.descEnglish!
                        : (e.descArabic ?? context.l10n.common_equipment);

                    return Glass(
                      radius: 14,
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: CircleAvatar(
                          backgroundColor: cs.surfaceContainerHighest,
                          child: AIcon(
                            AppGlyph.tools,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        title: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          '${context.l10n.common_status}: ${context.l10n.common_inactive}',
                        ),
                        trailing: FilledButton(
                          onPressed: () => _activate(e),
                          child: Text(context.l10n.action_activate),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

// ====================== INACTIVE ORGANIZATIONS TAB ======================
class _InactiveOrganizationsTab extends StatefulWidget {
  const _InactiveOrganizationsTab();

  @override
  State<_InactiveOrganizationsTab> createState() =>
      _InactiveOrganizationsTabState();
}

class _InactiveOrganizationsTabState extends State<_InactiveOrganizationsTab> {
  static const String _kOrganizationsSQL =
      'select * from Organizations where isActive = 0';

  late Future<List<OrganizationSummary>> _future;
  final _qCtrl = TextEditingController();
  Timer? _deb;

  @override
  void initState() {
    super.initState();
    _future = api.Api.advanceSearchOrganization(_kOrganizationsSQL);
    _qCtrl.addListener(_onQ);
  }

  @override
  void dispose() {
    _qCtrl.removeListener(_onQ);
    _qCtrl.dispose();
    _deb?.cancel();
    super.dispose();
  }

  void _onQ() {
    // You asked to send the exact SQL; ignore user text.
    _deb?.cancel();
    _deb = Timer(const Duration(milliseconds: 350), () {
      setState(() {
        _future = api.Api.advanceSearchOrganization(_kOrganizationsSQL);
      });
    });
  }

  Future<void> _activate(OrganizationSummary o) async {
    try {
      // Ensure this matches your backend’s activation contract.
      final body = {'organizationId': o.organizationId, 'isActive': 1};
      await api.Api.updateOrganizationEnvelope(body);
      AppSnack.success(context, context.l10n.common_activated);
      setState(() {
        _future = api.Api.advanceSearchOrganization(_kOrganizationsSQL);
      });
    } catch (_) {
      AppSnack.error(context, context.l10n.common_updateFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
          child: AInput(
            controller: _qCtrl,
            label: context.l10n.inactiveOrgs_search_label,
            hint: context.l10n.common_typeToSearch,
            glyph: AppGlyph.search,
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => setState(() {
              _future = api.Api.advanceSearchOrganization(_kOrganizationsSQL);
            }),
            child: FutureBuilder<List<OrganizationSummary>>(
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
                final items = snap.data ?? [];
                if (items.isEmpty) {
                  return ListView(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(context.l10n.inactiveOrgs_empty),
                      ),
                    ],
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 24),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final o = items[i];
                    final name = (o.nameEnglish ?? '').isNotEmpty
                        ? o.nameEnglish!
                        : (o.nameArabic ?? context.l10n.common_organization);

                    return Glass(
                      radius: 14,
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: CircleAvatar(
                          backgroundColor: cs.surfaceContainerHighest,
                          child: AIcon(
                            AppGlyph.building,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        title: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          '${context.l10n.common_status}: ${context.l10n.common_inactive}',
                        ),
                        trailing: FilledButton(
                          onPressed: () => _activate(o),
                          child: Text(context.l10n.action_activate),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

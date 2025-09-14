// lib/screens/super_admin_hub_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:heavy_new/core/auth/auth_store.dart';
import 'package:heavy_new/core/api/api_handler.dart' as api;

import 'package:heavy_new/core/models/admin/request.dart';
import 'package:heavy_new/core/models/organization/organization_file.dart';
import 'package:heavy_new/core/models/organization/organization_user.dart';

import 'package:heavy_new/foundation/ui/ui_extras.dart';
import 'package:heavy_new/foundation/ui/ui_kit.dart';
import 'package:heavy_new/foundation/ui/app_icons.dart';
import 'package:heavy_new/screens/organization_screens/organization_hub_screen.dart';
import 'package:heavy_new/screens/auth_profile_screens/phone_auth_screen.dart';

class SuperAdminHubScreen extends StatelessWidget {
  const SuperAdminHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthStore.instance;
    final u = auth.user.value;

    // Gate: only super admin (userTypeId == 17)
    if (!auth.isLoggedIn) {
      return _GateScreen(
        title: 'Sign in required',
        message: 'This page is for Super Admin accounts.',
        primary: () async {
          final ok = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const PhoneAuthScreen()),
          );
          if (ok == true && context.mounted) {
            AppSnack.success(context, 'Signed in');
          }
        },
        primaryLabel: 'Sign in',
      );
    }
    if (u?.userTypeId != 17) {
      return _GateScreen(
        title: 'Not available',
        message: 'Your account does not have Super Admin permission.',
        primary: () => Navigator.of(context).maybePop(),
        primaryLabel: 'Back',
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Super Admin'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Org Files'),
              Tab(text: 'Org Users'),
              Tab(text: 'Requests / Orders'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_OrgFilesTab(), _OrgUsersTab(), _RequestsOrdersTab()],
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
      appBar: AppBar(title: const Text('Super Admin')),
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
                      backgroundColor: cs.surfaceVariant,
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
      AppSnack.success(context, 'File updated');
      setState(() {
        _future = api.Api.getOrganizationFiles();
      });
    } catch (_) {
      AppSnack.error(context, 'Update failed');
    }
  }

  Future<void> _delete(OrganizationFileModel f) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete file?'),
        content: Text('This will remove “${f.fileName ?? 'file'}”.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (yes != true) return;
    try {
      await api.Api.deleteOrganizationFile(f.organizationFileId ?? 0);
      AppSnack.success(context, 'Deleted');
      setState(() {
        _future = api.Api.getOrganizationFiles();
      });
    } catch (_) {
      AppSnack.error(context, 'Delete failed');
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
                  title: Text(f.descFileType ?? f.fileName ?? 'File'),
                  subtitle: Text('Org #${f.organizationId ?? '—'}'),
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
                      placeholderColor: cs.surfaceVariant,
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
            label: 'Search org files',
            hint: 'Type to search',
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
                    children: const [
                      Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('No organization files.'),
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
                          backgroundColor: cs.surfaceVariant,
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
                          'Org #${f.organizationId ?? '—'}'
                          '  •  ${f.fileType?.detailNameEnglish ?? f.fileType?.detailNameArabic ?? ''}'
                          '  •  ${(f.isActive ?? false) ? 'Active' : 'Inactive'}'
                          '${(f.isExpired ?? false) ? '  •  Expired' : ''}',
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
                            const PopupMenuItem(
                              value: 'preview',
                              child: Text('Preview / Open'),
                            ),
                            PopupMenuItem(
                              value: 'toggle',
                              child: Text(
                                (f.isActive ?? false)
                                    ? 'Deactivate'
                                    : 'Activate',
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete'),
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
      AppSnack.success(context, 'User updated');
      setState(() {
        _future = api.Api.getOrganizationUsers();
      });
    } catch (_) {
      AppSnack.error(context, 'Update failed');
    }
  }

  Future<void> _delete(OrganizationUser u) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove org user?'),
        content: Text(
          'This will unlink user #${u.applicationUserId ?? ''} from organization #${u.organizationId ?? ''}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (yes != true) return;
    try {
      await api.Api.deleteOrganizationUser(u.organizationUserId ?? 0);
      AppSnack.success(context, 'Removed');
      setState(() {
        _future = api.Api.getOrganizationUsers();
      });
    } catch (_) {
      AppSnack.error(context, 'Remove failed');
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
            label: 'Search org users',
            hint: 'Type to search',
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
                    children: const [
                      Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('No organization users.'),
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
                    final name = person?.fullName ?? 'User ${person?.id ?? ''}';
                    final emailOrMobile = (person?.email?.isNotEmpty ?? false)
                        ? person!.email!
                        : (person?.mobile ?? '—');

                    return Glass(
                      radius: 14,
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: CircleAvatar(
                          backgroundColor: cs.surfaceVariant,
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
                          'Org #${u.organizationId ?? '—'}  •  ${emailOrMobile}  •  ${(u.isActive ?? false) ? 'Active' : 'Inactive'}',
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
                                    ? 'Deactivate'
                                    : 'Activate',
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'open-org',
                              child: Text('Open organization'),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Remove from org'),
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
            label: 'Search requests / orders',
            hint: 'Type to search',
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
                    children: const [
                      Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('No requests found.'),
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
                          backgroundColor: cs.surfaceVariant,
                          child: AIcon(
                            AppGlyph.invoice,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        title: Text(
                          'Request #$idText',
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

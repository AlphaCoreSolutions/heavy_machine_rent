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
import 'package:heavy_new/screens/app/app_settings_screen.dart'
    show AppSettingsScreen;
import 'package:heavy_new/screens/organization_screens/organization_hub_screen.dart';
import 'package:heavy_new/screens/auth_profile_screens/phone_auth_screen.dart';

// ⬇️ Localization
import 'package:heavy_new/l10n/app_localizations.dart';

// --- Feature flags for backend-less mode ---
const bool kEnableSettingsTab = false; // set true when backend is ready
const bool kEnableAuditLogsTab = false; // set true when backend is ready

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

    final tabs = <Tab>[
      Tab(text: context.l10n.superAdmin_tab_overview),
      Tab(text: context.l10n.superAdmin_tab_orgFiles),
      Tab(text: context.l10n.superAdmin_tab_orgUsers),
      Tab(text: context.l10n.superAdmin_tab_requestsOrders),
      Tab(text: context.l10n.superAdmin_tab_inactiveEquipments),
      Tab(text: context.l10n.superAdmin_tab_inactiveOrgs),
      if (kEnableSettingsTab) Tab(text: context.l10n.superAdmin_tab_settings),
      if (kEnableAuditLogsTab) Tab(text: context.l10n.superAdmin_tab_auditLogs),
    ];

    final views = <Widget>[
      const _OverviewTab(),
      const _OrgFilesTab(),
      const _OrgUsersTab(),
      const _RequestsOrdersTab(),
      const _InactiveEquipmentsTab(),
      const _InactiveOrganizationsTab(),
      if (kEnableSettingsTab) const _SettingsTab(),
      if (kEnableAuditLogsTab) const _AuditLogsTab(),
    ];

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.superAdmin_title),
          actions: [
            IconButton(
              tooltip: context.l10n.common_search,
              icon: const Icon(Icons.search),
              onPressed: () => showSearch(
                context: context,
                delegate: _GlobalAdminSearchDelegate(),
              ),
            ),
          ],
          bottom: TabBar(isScrollable: true, tabs: tabs),
        ),
        body: TabBarView(children: views),
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

// ========================== OVERVIEW TAB ==========================
// ========================== OVERVIEW TAB (client-computed) ==========================
class _OverviewTab extends StatefulWidget {
  const _OverviewTab();
  @override
  State<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<_OverviewTab> {
  late Future<_DashboardBundle> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_DashboardBundle> _load() async {
    // 1) Fetch everything we need via your existing AdvanceSearch endpoints.
    //    Use '1=1' to fetch all rows.
    final orgs = await api.Api.advanceSearchOrganization(
      'select * from Organizations',
    );
    final eqs = await api.Api.advanceSearchEquipments(
      'select * from Equipments',
    );

    // Requests with statusId in (34,35,36)
    // If your backend supports IN, this is best:
    List<RequestModel> reqs;
    try {
      reqs = await api.Api.advanceSearchRequests(
        'select * from Requests where statusId IN (34, 35, 36)',
      );
    } catch (_) {
      // Fallback if IN is not supported: sum separate queries
      final r34 = await api.Api.advanceSearchRequests(
        'select * from Requests where statusId = 34',
      );
      final r35 = await api.Api.advanceSearchRequests(
        'select * from Requests where statusId = 35',
      );
      final r36 = await api.Api.advanceSearchRequests(
        'select * from Requests where statusId = 36',
      );
      reqs = [...r34, ...r35, ...r36];
    }

    // Users: count all accounts
    final users = await api.Api.getUserAccounts();

    // 2) Build client-side stats (totals + tiny placeholder trends).
    final stats = DashboardStats(
      totalOrgs: orgs.length,
      totalEquipments: eqs.length,
      totalUsers: users.length,
      openRequests: reqs.length, // requests with status 34/35/36
      orgsWeekly: _fakeTrend(orgs.length),
      equipWeekly: _fakeTrend(eqs.length),
      usersWeekly: _fakeTrend(users.length),
      reqWeekly: _fakeTrend(reqs.length),
    );

    // 3) Build a recent activity list using whatever timestamps exist.
    final recent = <RecentActivity>[
      ...orgs.map(
        (o) => RecentActivity(
          kind: 'org',
          title: (o.nameEnglish ?? o.nameArabic ?? '—'),
          subtitle: (o.isActive ?? false) ? 'Active' : 'Inactive',
          at:
              _tryParse(o.modifyDateTime?.toString()) ??
              _tryParse(o.createDateTime?.toString()),
        ),
      ),
      ...eqs.map(
        (e) => RecentActivity(
          kind: 'equipment',
          title: (e.descEnglish?.isNotEmpty ?? false)
              ? e.descEnglish!
              : (e.descArabic ?? '—'),
          subtitle: 'Status: ${(e.isActive ?? false) ? 'Active' : 'Inactive'}',
          at:
              _tryParse(e.modifyDateTime?.toString()) ??
              _tryParse(e.createDateTime?.toString()),
        ),
      ),
      ...users.map(
        (u) => RecentActivity(
          kind: 'user',
          title: u.fullName ?? u.email ?? u.mobile ?? '—',
          subtitle: 'User',
          at:
              _tryParse(u.modifyDateTime?.toString()) ??
              _tryParse(u.createDateTime?.toString()),
        ),
      ),
      ...reqs.map(
        (r) => RecentActivity(
          kind: 'request',
          title: 'Request #${(r.requestNo ?? r.requestId ?? '—')}',
          subtitle:
              '${(r.fromDate ?? '').toString().split(" ").first} → ${(r.toDate ?? '').toString().split(" ").first}',
          at: _tryParse(r.createDateTime?.toString()),
        ),
      ),
    ]..sort((a, b) => (b.at ?? DateTime(0)).compareTo(a.at ?? DateTime(0)));

    return _DashboardBundle(stats: stats, recent: recent.take(20).toList());
  }

  // --- helpers (keep these exactly) ---
  List<double> _fakeTrend(int total) {
    final base = (total / 7).clamp(0, 100000).toDouble();
    final raw = <double>[
      base,
      base + 1.0,
      base - 0.5,
      base + 1.5,
      base + 0.8,
      base + 1.2,
      base + 1.6,
    ];
    return raw.map((e) => e < 0.0 ? 0.0 : e).toList();
  }

  DateTime? _tryParse(String? s) =>
      (s == null || s.isEmpty) ? null : DateTime.tryParse(s);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return RefreshIndicator(
      onRefresh: () async => setState(() => _future = _load()),
      child: FutureBuilder<_DashboardBundle>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return ListView(
              children: const [ShimmerTile(), ShimmerTile(), ShimmerTile()],
            );
          }
          if (snap.hasError) {
            return ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Failed to load dashboard: ${snap.error}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: cs.error),
                  ),
                ),
              ],
            );
          }
          final data = snap.data!;
          final s = data.stats;

          return ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  StatCard(
                    icon: AppGlyph.building,
                    label: context.l10n.overview_totalOrgs,
                    value: s.totalOrgs.toString(),
                    trend: s.orgsWeekly,
                  ),
                  StatCard(
                    icon: AppGlyph.tools,
                    label: context.l10n.overview_totalEquipments,
                    value: s.totalEquipments.toString(),
                    trend: s.equipWeekly,
                  ),
                  StatCard(
                    icon: AppGlyph.user,
                    label: context.l10n.overview_totalUsers,
                    value: s.totalUsers.toString(),
                    trend: s.usersWeekly,
                  ),
                  StatCard(
                    icon: AppGlyph.invoice,
                    label: context.l10n.overview_openRequests,
                    value: s.openRequests.toString(),
                    trend: s.reqWeekly,
                    accent: cs.tertiary,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Glass(
                radius: 16,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        icon: const Icon(Icons.apartment),
                        label: Text(context.l10n.overview_quick_createOrg),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (BuildContext context) =>
                                  const OrganizationScreen(),
                            ),
                          );
                        },
                      ),
                      FilledButton.icon(
                        icon: const Icon(Icons.people),
                        label: Text(context.l10n.overview_quick_inviteUser),
                        onPressed: () {
                          // TODO: invite user flow
                        },
                      ),
                      FilledButton.icon(
                        icon: const Icon(Icons.settings),
                        label: Text(context.l10n.overview_quick_settings),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (BuildContext context) =>
                                  const AppSettingsScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                context.l10n.overview_recentActivity,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Glass(
                radius: 14,
                child: Column(
                  children: [
                    for (final a in data.recent.take(8))
                      ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          backgroundColor: cs.surfaceContainerHighest,
                          child: AIcon(
                            _iconForActivity(a),
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        title: Text(
                          a.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          a.subtitle ?? '—',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Text(_fmtTime(a.at)),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  AppGlyph _iconForActivity(RecentActivity a) {
    switch (a.kind) {
      case 'org':
        return AppGlyph.building;
      case 'equipment':
        return AppGlyph.tools;
      case 'user':
        return AppGlyph.user;
      case 'request':
        return AppGlyph.invoice;
      default:
        return AppGlyph.info;
    }
  }

  String _fmtTime(DateTime? dt) => (dt == null)
      ? '—'
      : '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}

// Local bundle + DTOs (client side)
class _DashboardBundle {
  final DashboardStats stats;
  final List<RecentActivity> recent;
  _DashboardBundle({required this.stats, required this.recent});
}

class DashboardStats {
  final int totalOrgs;
  final int totalEquipments;
  final int totalUsers;
  final int openRequests;
  final List<double> orgsWeekly;
  final List<double> equipWeekly;
  final List<double> usersWeekly;
  final List<double> reqWeekly;

  DashboardStats({
    required this.totalOrgs,
    required this.totalEquipments,
    required this.totalUsers,
    required this.openRequests,
    required this.orgsWeekly,
    required this.equipWeekly,
    required this.usersWeekly,
    required this.reqWeekly,
  });
}

class RecentActivity {
  final String kind; // org|equipment|user|request|other
  final String title;
  final String? subtitle;
  final DateTime? at;
  RecentActivity({
    required this.kind,
    required this.title,
    this.subtitle,
    this.at,
  });
}

// =========================== SETTINGS TAB ===========================
class _SettingsTab extends StatelessWidget {
  const _SettingsTab();
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Glass(
          radius: 16,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Settings are not connected yet.\n\n'
              'Expose endpoints like:\n'
              '- Admin/GetSettings (GET/POST)\n'
              '- Admin/UpdateSettings (POST)\n\n'
              'Then replace this stub with the real form.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      ],
    );
  }
}

// =========================== AUDIT LOGS (STUB) ===========================
class _AuditLogsTab extends StatelessWidget {
  const _AuditLogsTab();
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Glass(
          radius: 16,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Audit logs are not connected yet.\n\n'
              'Expose endpoints like:\n'
              '- Admin/AuditLogs { level, q }\n\n'
              'Then replace this stub with the real list.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      ],
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
  static const String _kEquipmentsFILTER =
      'select * from Equipments where isActive = 0';

  late Future<List<Equipment>> _future;
  final _qCtrl = TextEditingController();
  Timer? _deb;

  @override
  void initState() {
    super.initState();
    _future = api.Api.advanceSearchEquipments(_kEquipmentsFILTER);
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
    // Same as org: ignore user text and always send the exact SQL.
    _deb?.cancel();
    _deb = Timer(const Duration(milliseconds: 350), () {
      setState(() {
        _future = api.Api.advanceSearchEquipments(_kEquipmentsFILTER);
      });
    });
  }

  Future<void> _activate(Equipment e) async {
    try {
      // ✅ Uses equipmentId (not equipmentListId)
      await api.Api.updateEquipmentActive(e.equipmentId!, true);
      AppSnack.success(context, context.l10n.common_activated);
      setState(() {
        _future = api.Api.advanceSearchEquipments(_kEquipmentsFILTER);
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
              _future = api.Api.advanceSearchEquipments(_kEquipmentsFILTER);
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

                // Mirror org: use data as-is (no extra client-side filter).
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

class _EquipmentTileTrailing extends StatefulWidget {
  const _EquipmentTileTrailing({
    required this.e,
    required this.onActivate,
    required this.onDeactivate,
    // ignore: unused_element_parameter
    super.key,
  });

  final Equipment e;
  final Future<void> Function(Equipment) onActivate;
  final Future<void> Function(Equipment) onDeactivate;

  @override
  State<_EquipmentTileTrailing> createState() => _EquipmentTileTrailingState();
}

class _EquipmentTileTrailingState extends State<_EquipmentTileTrailing> {
  bool _busy = false;

  Future<void> _handle() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      if (widget.e.isActive == true) {
        await widget.onDeactivate(widget.e);
      } else {
        await widget.onActivate(widget.e);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isActive = widget.e.isActive == true;

    return FilledButton(
      onPressed: _busy ? null : _handle,
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return null;
          return isActive ? Colors.red : null; // red for deactivate
        }),
      ),
      child: _busy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(
              isActive
                  ? context.l10n.action_deactivate
                  : context.l10n.action_activate,
            ),
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
  static const String _kOrganizationsFILTER =
      'select * from Organizations where isActive = 0';

  late Future<List<OrganizationSummary>> _future;
  final _qCtrl = TextEditingController();
  Timer? _deb;

  @override
  void initState() {
    super.initState();
    _future = api.Api.advanceSearchOrganization(_kOrganizationsFILTER);
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
        _future = api.Api.advanceSearchOrganization(_kOrganizationsFILTER);
      });
    });
  }

  Future<void> _activate(OrganizationSummary o) async {
    try {
      await api.Api.updateOrganizationActive(o.organizationId!, true);
      AppSnack.success(context, context.l10n.common_activated);
      setState(() {
        _future = api.Api.advanceSearchOrganization(_kOrganizationsFILTER);
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
              _future = api.Api.advanceSearchOrganization(
                _kOrganizationsFILTER,
              );
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

class StatCard extends StatelessWidget {
  const StatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.trend = const <double>[],
    this.accent,
    super.key,
  });

  final AppGlyph icon;
  final String label;
  final String value;
  final List<double> trend;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: 260,
      child: Glass(
        radius: 16,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: cs.surfaceContainerHighest,
                child: AIcon(icon, color: accent ?? cs.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 28,
                      child: Sparkline(
                        values: trend,
                        color: accent ?? cs.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Sparkline extends StatelessWidget {
  const Sparkline({super.key, required this.values, required this.color});
  final List<double> values;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SparklinePainter(values: values, color: color.withOpacity(0.9)),
      size: const Size(double.infinity, 28), // width expands by parent
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({required this.values, required this.color});
  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final path = Path();
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = color;

    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final span = (maxV - minV).abs() < 1e-6 ? 1.0 : (maxV - minV);

    final dx = size.width / (values.length - 1).clamp(1, 9999);
    for (int i = 0; i < values.length; i++) {
      final x = i * dx;
      // y inverted because canvas origin is top-left
      final y = size.height - ((values[i] - minV) / span) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.color != color;
}

class _GlobalAdminSearchDelegate extends SearchDelegate<String?> {
  @override
  List<Widget>? buildActions(BuildContext context) => [
    IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
  ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () => close(context, null),
  );

  @override
  Widget buildResults(BuildContext context) {
    return _SearchResultsView(query: query);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.trim().isEmpty) {
      return Center(child: Text(AppLocalizations.of(context)!.search_hint));
    }
    return _SearchResultsView(query: query);
  }
}

class _SearchResultsView extends StatefulWidget {
  const _SearchResultsView({required this.query});
  final String query;

  @override
  State<_SearchResultsView> createState() => _SearchResultsViewState();
}

class _SearchResultsViewState extends State<_SearchResultsView> {
  late Future<_SearchBundle> _future;

  @override
  void initState() {
    super.initState();
    _future = _load(widget.query);
  }

  @override
  void didUpdateWidget(covariant _SearchResultsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) {
      _future = _load(widget.query);
    }
  }

  Future<_SearchBundle> _load(String q) async {
    // For now: always fetch full tables (ignore q). We'll add WHERE later.
    const orgSql = 'select * from Organizations';
    const userSql = 'select * from OrganizationUsers';
    const eqSql = 'select * from Equipments';
    const reqSql = 'select * from Requests';

    final orgs = await api.Api.advanceSearchOrganization(orgSql);
    final users = await api.Api.advanceSearchOrganizationUsers(userSql);
    final eqs = await api.Api.advanceSearchEquipments(eqSql);
    final reqs = await api.Api.advanceSearchRequests(reqSql);

    return _SearchBundle(orgs: orgs, users: users, eqs: eqs, reqs: reqs);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return FutureBuilder<_SearchBundle>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return ListView(
            children: const [ShimmerTile(), ShimmerTile(), ShimmerTile()],
          );
        }
        if (!snap.hasData) {
          return Center(
            child: Text(AppLocalizations.of(context)!.search_noResults),
          );
        }
        final b = snap.data!;
        return ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
          children: [
            if (b.orgs.isNotEmpty) _header(context.l10n.common_organizations),
            ...b.orgs
                .take(5)
                .map(
                  (o) => Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Glass(
                      radius: 12,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: cs.surfaceContainerHighest,
                          child: AIcon(
                            AppGlyph.building,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        title: Text(
                          o.nameEnglish ?? o.nameArabic ?? '—',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          context.l10n.common_statusLabel(
                            (o.isActive ?? false)
                                ? context.l10n.common_active
                                : context.l10n.common_inactive,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            if (b.users.isNotEmpty) _header(context.l10n.common_users),
            ...b.users
                .take(5)
                .map(
                  (u) => Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Glass(
                      radius: 12,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: cs.surfaceContainerHighest,
                          child: AIcon(
                            AppGlyph.user,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        title: Text(
                          u.applicationUser?.fullName ?? '—',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${context.l10n.common_orgNumber((u.organizationId ?? '').toString())}',
                        ),
                      ),
                    ),
                  ),
                ),
            if (b.eqs.isNotEmpty) _header(context.l10n.common_equipments),
            ...b.eqs
                .take(5)
                .map(
                  (e) => Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Glass(
                      radius: 12,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: cs.surfaceContainerHighest,
                          child: AIcon(
                            AppGlyph.tools,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        title: Text(
                          (e.descEnglish?.isNotEmpty ?? false)
                              ? e.descEnglish!
                              : (e.descArabic ?? '—'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${context.l10n.common_status}: ${(e.isActive ?? false) ? context.l10n.common_active : context.l10n.common_inactive}',
                        ),
                      ),
                    ),
                  ),
                ),
            if (b.reqs.isNotEmpty) _header(context.l10n.common_requests),
            ...b.reqs
                .take(5)
                .map(
                  (r) => Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Glass(
                      radius: 12,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: cs.surfaceContainerHighest,
                          child: AIcon(
                            AppGlyph.invoice,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        title: Text(
                          context.l10n.requests_item_title(
                            (r.requestNo ?? r.requestId ?? '—').toString(),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${(r.fromDate ?? '').toString().split(" ").first} → ${(r.toDate ?? '').toString().split(" ").first}',
                        ),
                      ),
                    ),
                  ),
                ),
          ],
        );
      },
    );
  }

  Widget _header(String text) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.w800)),
  );
}

class _SearchBundle {
  final List<OrganizationSummary> orgs;
  final List<OrganizationUser> users;
  final List<Equipment> eqs;
  final List<RequestModel> reqs;
  _SearchBundle({
    required this.orgs,
    required this.users,
    required this.eqs,
    required this.reqs,
  });
}

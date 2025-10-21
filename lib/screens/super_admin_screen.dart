// lib/screens/super_admin_hub_screen.dart
// ignore_for_file: unused_local_variable

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:heavy_new/core/auth/auth_store.dart';
import 'package:heavy_new/core/api/api_handler.dart' as api;
import 'package:heavy_new/core/models/admin/domain.dart';
import 'package:heavy_new/core/models/admin/factory.dart';

import 'package:heavy_new/core/models/admin/request.dart';
import 'package:heavy_new/core/models/organization/organization_file.dart';
import 'package:heavy_new/core/models/organization/organization_user.dart';
// ⬇️ Add these imports (adjust paths if needed)
import 'package:heavy_new/core/models/equipment/equipment.dart';
import 'package:heavy_new/core/models/organization/organization_summary.dart';

import 'package:heavy_new/foundation/ui/ui_extras.dart';
import 'package:url_launcher/url_launcher.dart';
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
        if (q.isEmpty) {
          _future = api.Api.getOrganizationFiles();
        } else {
          // Using LIKE for partial matching and making it case-insensitive (optional)
          final sql =
              "select * from OrganizationFiles where descFileType LIKE '%$q%'";
          _future = api.Api.advanceSearchOrganizationFiles(sql);
        }
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
      builder: (dialogContext) {
        // 🛑 Use dialogContext so closing only affects dialog
        final cs = Theme.of(dialogContext).colorScheme;

        final isPdf = (f.fileName?.toLowerCase().endsWith('.pdf') ?? false);

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
                    onPressed: () => Navigator.of(dialogContext).pop(), // ✅ FIX
                  ),
                ),

                // ✅ Show PDF Viewer or Image
                if (isPdf)
                  SizedBox(
                    height: 400,
                    child: Center(
                      child: FilledButton.icon(
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text("Open PDF"),
                        onPressed: () async {
                          // open in in-app browser
                          await launchUrl(
                            Uri.parse(url),
                            mode: LaunchMode.inAppBrowserView,
                          );
                        },
                      ),
                    ),
                  )
                else if (f.isImage == true)
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
    // Guard: no id, no delete
    final id = u.organizationUserId;
    if (id == null) {
      AppSnack.error(context, context.l10n.common_deleteFailed);
      return;
    }

    // Show confirm dialog; IMPORTANT: use the dialog's context to pop
    final yes = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) => AlertDialog(
        title: Row(
          children: [
            Expanded(child: Text(context.l10n.orgUsers_remove_title)),
            IconButton(
              tooltip: context.l10n.action_cancel,
              icon: const Icon(Icons.close),
              onPressed: () =>
                  Navigator.of(dialogCtx).pop(false), // ✅ closes only dialog
            ),
          ],
        ),
        content: Text(
          context.l10n.orgUsers_remove_message(
            (u.applicationUserId ?? '').toString(),
            (u.organizationId ?? '').toString(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false), // ✅
            child: Text(context.l10n.action_cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true), // ✅
            child: Text(context.l10n.action_remove),
          ),
        ],
      ),
    );

    if (yes != true) return;

    try {
      await api.Api.deleteOrganizationUser(id);
      if (!mounted) return;
      AppSnack.success(context, context.l10n.common_removed);
      setState(() {
        _future = api.Api.getOrganizationUsers();
      });
    } catch (_) {
      if (!mounted) return;
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
                              if (u.organizationId == null) return;
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      OrganizationDetailsActivationScreen(
                                        organizationId: u.organizationId!,
                                        initial: null,
                                        readOnly: true,
                                      ),
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
        if (q.isEmpty) {
          _future = api.Api.getRequests();
        } else {
          // ✅ Partial match using LIKE
          final sql = "select * from Requests where requestId like '%$q%'";
          _future = api.Api.advanceSearchRequests(sql);
        }
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
    _deb?.cancel();
    _deb = Timer(const Duration(milliseconds: 350), () {
      final q = _qCtrl.text.trim();

      setState(() {
        if (q.isEmpty) {
          // Default filter
          _future = api.Api.advanceSearchEquipments(_kEquipmentsFILTER);
        } else {
          // ✅ Search with partial match + inactive filter
          final sql =
              """
          select * from Equipments
          where isActive = 0 
          and (
            descEnglish like '%$q%' 
            or descArabic like '%$q%'
            or equipmentId like '%$q%'
          )
        """;
          _future = api.Api.advanceSearchEquipments(sql);
        }
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
                        // ⬇️ Add this onTap
                        onTap: () async {
                          if (e.equipmentId == null) return;
                          final changed = await Navigator.of(context)
                              .push<bool>(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      EquipmentDetailsActivationScreen(
                                        equipmentId: e.equipmentId!,
                                        initial: e,
                                      ),
                                ),
                              );
                          if (changed == true && mounted) {
                            setState(() {
                              _future = api.Api.advanceSearchEquipments(
                                _kEquipmentsFILTER,
                              );
                            });
                          }
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
    _deb?.cancel();
    _deb = Timer(const Duration(milliseconds: 350), () {
      final q = _qCtrl.text.trim();

      setState(() {
        if (q.isEmpty) {
          // Default inactive filter
          _future = api.Api.advanceSearchOrganization(_kOrganizationsFILTER);
        } else {
          // ✅ Search across fields while still filtering inactive organizations
          final sql =
              """
          select * from Organizations
          where isActive = 0
          and (
            nameEnglish like '%$q%' 
            or nameArabic like '%$q%'
            or organizationCode like '%$q%'
            or cast(organizationId as nvarchar) like '%$q%'
          )
        """;
          _future = api.Api.advanceSearchOrganization(sql);
        }
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
                        // ⬇️ Add this onTap
                        onTap: () async {
                          if (o.organizationId == null) return;
                          final changed = await Navigator.of(context)
                              .push<bool>(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      OrganizationDetailsActivationScreen(
                                        organizationId: o.organizationId!,
                                        initial: o,
                                      ),
                                ),
                              );
                          if (changed == true && mounted) {
                            setState(() {
                              _future = api.Api.advanceSearchOrganization(
                                _kOrganizationsFILTER,
                              );
                            });
                          }
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

// ====================== ORGANIZATION DETAILS SCREEN ======================
class OrganizationDetailsActivationScreen extends StatefulWidget {
  final int organizationId;
  final OrganizationSummary? initial;
  final bool readOnly; // ✅ Add this

  const OrganizationDetailsActivationScreen({
    super.key,
    required this.organizationId,
    this.initial,
    this.readOnly = false, // ✅ default false
  });

  @override
  State<OrganizationDetailsActivationScreen> createState() =>
      _OrganizationDetailsActivationScreenState();
}

class _OrgResolvedRefs {
  final Map<int, String> typeNameById; // Domain 13
  final Map<int, String> statusNameById; // Domain 10
  const _OrgResolvedRefs({
    this.typeNameById = const {},
    this.statusNameById = const {},
  });

  String typeName(int? id) =>
      (id == null) ? '—' : (typeNameById[id] ?? id.toString());
  String statusName(int? id) =>
      (id == null) ? '—' : (statusNameById[id] ?? id.toString());
}

class _OrgBundle {
  final OrganizationSummary? org;
  final _OrgResolvedRefs refs;
  const _OrgBundle({required this.org, required this.refs});
}

class _OrganizationDetailsActivationScreenState
    extends State<OrganizationDetailsActivationScreen> {
  late Future<_OrgBundle> _future;

  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_OrgBundle> _load() async {
    final sql =
        'select * from Organizations where organizationId = ${widget.organizationId}';
    final list = await api.Api.advanceSearchOrganization(sql);

    // Start with SQL result or initial
    OrganizationSummary? org = list.isNotEmpty ? list.first : widget.initial;

    // 🔹 Hydrate with full endpoint so nested city/country/status are present
    if (org?.organizationId != null) {
      try {
        final full = await api.Api.getOrganizationById(org!.organizationId!);
        org = full;
        if (org.city == null && org.cityId != null) {
          try {
            final c = await api.Api.getCityById(org.cityId!);
            org = OrganizationSummary(
              // carry forward existing fields; or if you have a copyWith, use that
              organizationId: org.organizationId,
              organizationCode: org.organizationCode,
              nameArabic: org.nameArabic,
              nameEnglish: org.nameEnglish,
              briefArabic: org.briefArabic,
              briefEnglish: org.briefEnglish,
              crNumber: org.crNumber,
              vatNumber: org.vatNumber,
              mainMobile: org.mainMobile,
              secondMobile: org.secondMobile,
              mainEmail: org.mainEmail,
              secondEmail: org.secondEmail,
              iban: org.iban,
              bankName: org.bankName,
              statusId: org.statusId,
              countryId: org.countryId,
              cityId: org.cityId,
              fullAddress: org.fullAddress,
              tradeNameArabic: org.tradeNameArabic,
              tradeNameEnglish: org.tradeNameEnglish,
              logoPath: org.logoPath,
              isActive: org.isActive,
              typeId: org.typeId,
              createDateTime: org.createDateTime,
              modifyDateTime: org.modifyDateTime,
              status: org.status,
              country: org.country, // keep whatever was there
              city: c, // <-- hydrated city
              organizationUsers: org.organizationUsers,
              organizationFiles: org.organizationFiles,
            );

            // If country still null, prefer the one attached to City
            if (org.country == null && c.country?.nationalityId != null) {
              final cref = await api.Api.getNationalityById(
                c.country!.nationalityId!,
              );
              org = OrganizationSummary(
                organizationId: org.organizationId,
                organizationCode: org.organizationCode,
                nameArabic: org.nameArabic,
                nameEnglish: org.nameEnglish,
                briefArabic: org.briefArabic,
                briefEnglish: org.briefEnglish,
                crNumber: org.crNumber,
                vatNumber: org.vatNumber,
                mainMobile: org.mainMobile,
                secondMobile: org.secondMobile,
                mainEmail: org.mainEmail,
                secondEmail: org.secondEmail,
                iban: org.iban,
                bankName: org.bankName,
                statusId: org.statusId,
                countryId: org.countryId,
                cityId: org.cityId,
                fullAddress: org.fullAddress,
                tradeNameArabic: org.tradeNameArabic,
                tradeNameEnglish: org.tradeNameEnglish,
                logoPath: org.logoPath,
                isActive: org.isActive,
                typeId: org.typeId,
                createDateTime: org.createDateTime,
                modifyDateTime: org.modifyDateTime,
                status: org.status,
                country: cref, // <-- hydrated country
                city: org.city,
                organizationUsers: org.organizationUsers,
                organizationFiles: org.organizationFiles,
              );
            }
          } catch (_) {
            // ignore; fallbacks will show ids
          }
        }
      } catch (_) {
        // keep the partial 'org' if full fetch fails
      }
    }

    Map<int, String> typeNames = const {};
    Map<int, String> statusNames = const {};

    // Fetch Domain 13 (Type) and Domain 10 (Status) details in parallel
    List<DomainDetail>? d13, d10;
    await Future.wait([
      api.Api.getDomainDetailsByDomainId(13).then((v) => d13 = v),
      api.Api.getDomainDetailsByDomainId(10).then((v) => d10 = v),
    ]);

    if (d13 != null) {
      typeNames = {
        for (final dd in d13!)
          if (dd.domainDetailId != null)
            dd.domainDetailId!:
                (dd.detailNameEnglish ??
                dd.detailNameArabic ??
                dd.domainDetailId!.toString()),
      };
    }
    if (d10 != null) {
      statusNames = {
        for (final dd in d10!)
          if (dd.domainDetailId != null)
            dd.domainDetailId!:
                (dd.detailNameEnglish ??
                dd.detailNameArabic ??
                dd.domainDetailId!.toString()),
      };
    }

    return _OrgBundle(
      org: org,
      refs: _OrgResolvedRefs(
        typeNameById: typeNames,
        statusNameById: statusNames,
      ),
    );
  }

  Future<void> _activate(OrganizationSummary o) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await api.Api.updateOrganizationActive(o.organizationId!, true);
      if (!mounted) return;
      AppSnack.success(context, context.l10n.common_activated);
      Navigator.of(context).pop(true); // signal parent to refresh
    } catch (_) {
      if (!mounted) return;
      AppSnack.error(context, context.l10n.common_updateFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.common_organization)),
      body: RefreshIndicator(
        onRefresh: () async => setState(() => _future = _load()),
        child: FutureBuilder<_OrgBundle>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return ListView(
                children: const [ShimmerTile(), ShimmerTile(), ShimmerTile()],
              );
            }
            final bundle = snap.data;
            final o = bundle?.org;
            final refs = bundle?.refs ?? const _OrgResolvedRefs();
            if (o == null) {
              return ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      context.l10n.inactiveOrgs_empty,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              );
            }

            final isActive = o.isActive == true;
            final name = (o.nameEnglish ?? '').isNotEmpty
                ? o.nameEnglish!
                : (o.nameArabic ?? context.l10n.common_organization);

            return ListView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
              children: [
                // Header
                Glass(
                  radius: 18,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      radius: 26,
                      backgroundColor: cs.surfaceContainerHighest,
                      child: AIcon(AppGlyph.building, color: cs.primary),
                    ),
                    title: Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    subtitle: Text(
                      '${context.l10n.common_status}: ${isActive ? context.l10n.common_active : context.l10n.common_inactive}',
                    ),
                    trailing: (o.logoPath ?? '').isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: 48,
                              height: 48,
                              child: FallbackNetworkImage(
                                candidates: [o.logoPath!],
                                fit: BoxFit.cover,
                                placeholderColor: cs.surfaceContainerHighest,
                              ),
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 12),

                // Identity
                Glass(
                  radius: 16,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _DetailsSection(
                      title: context.l10n.common_details,
                      rows: [
                        _kv(
                          context.l10n.common_id,
                          (o.organizationId ?? '—').toString(),
                        ),
                        _kv(context.l10n.common_english, o.nameEnglish ?? '—'),
                        _kv(context.l10n.common_arabic, o.nameArabic ?? '—'),

                        _kv('Brief (EN)', o.briefEnglish ?? '—'),
                        _kv('Brief (AR)', o.briefArabic ?? '—'),
                        _kv(
                          'Created',
                          o.createDateTime?.toIso8601String() ?? '—',
                        ),
                        _kv(
                          'Modified',
                          o.modifyDateTime?.toIso8601String() ?? '—',
                        ),
                        _kv('Type', refs.typeName(o.typeId)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Contact & Address
                Glass(
                  radius: 16,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _DetailsSection(
                      title: 'Contact & Address',
                      rows: [
                        _kv('Main mobile', o.mainMobile ?? '—'),
                        _kv('Second mobile', o.secondMobile ?? '—'),
                        _kv('Main email', o.mainEmail ?? '—'),
                        _kv('Second email', o.secondEmail ?? '—'),

                        _kv(
                          'City',
                          o.city?.nameEnglish ??
                              o.city?.nameArabic ??
                              _fmtInt(o.cityId),
                        ),
                        _kv('Address', o.fullAddress ?? '—'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Legal & Banking
                Glass(
                  radius: 16,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _DetailsSection(
                      title: 'Legal & Banking',
                      rows: [
                        _kv('CR Number', o.crNumber ?? '—'),
                        _kv('VAT Number', o.vatNumber ?? '—'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Users
                Glass(
                  radius: 16,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle(context.l10n.common_users),
                        const SizedBox(height: 8),
                        if (o.organizationUsers.isEmpty)
                          Text(
                            context.l10n.orgUsers_empty,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: cs.onSurfaceVariant),
                          )
                        else
                          ...o.organizationUsers.map(
                            (u) => ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
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
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Files
                Glass(
                  radius: 16,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle(context.l10n.superAdmin_tab_orgFiles),
                        const SizedBox(height: 8),
                        if (o.organizationFiles.isEmpty)
                          Text(
                            context.l10n.orgFiles_empty,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: cs.onSurfaceVariant),
                          )
                        else
                          ...o.organizationFiles.map(
                            (f) => ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor: cs.surfaceContainerHighest,
                                child: AIcon(
                                  (f.isImage == true)
                                      ? AppGlyph.image
                                      : AppGlyph.file,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                              title: Text(
                                f.descFileType ?? f.fileName ?? '—',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                '${context.l10n.common_orgNumber((f.organizationId ?? '—').toString())}'
                                ' • ${(f.fileType?.detailNameEnglish ?? f.fileType?.detailNameArabic ?? '')}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                if (!widget.readOnly && !isActive)
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: _busy ? null : () => _activate(o),
                      icon: _busy
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check_circle),
                      label: Text(context.l10n.action_activate),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  _KV _kv(String k, String v) => _KV(k: k, v: v);
}

// ======================== EQUIPMENT DETAILS SCREEN ========================
class _ResolvedRefs {
  final String? vendorName; // from getOrganizationById(vendorId)
  final String? factoryName; // from getFactoryById(factoryId)
  // Domain Detail id -> display name (from Domain 9)
  final Map<int, String> ddNameById;

  const _ResolvedRefs({
    this.vendorName,
    this.factoryName,
    this.ddNameById = const {},
  });

  String nameFor(int? id) =>
      (id == null) ? '—' : (ddNameById[id] ?? id.toString());
}

class _EquipmentBundle {
  final Equipment? equipment;
  final List<EquipmentTerm> terms;
  final List<EquipmentCertificate> certs;
  final _ResolvedRefs refs;

  _EquipmentBundle({
    required this.equipment,
    required this.terms,
    required this.certs,
    required this.refs,
  });
}

class EquipmentDetailsActivationScreen extends StatefulWidget {
  const EquipmentDetailsActivationScreen({
    required this.equipmentId,
    this.initial,
    super.key,
  });

  final int equipmentId;
  final Equipment? initial;

  @override
  State<EquipmentDetailsActivationScreen> createState() =>
      _EquipmentDetailsActivationScreenState();
}

class _EquipmentDetailsActivationScreenState
    extends State<EquipmentDetailsActivationScreen> {
  late Future<_EquipmentBundle> _future;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<void> _openCertDoc(BuildContext context, String? rawPath) async {
    if (rawPath == null || rawPath.trim().isEmpty) return;

    // Some APIs return leading slashes or backslashes; normalize and encode the filename.
    final cleaned = rawPath.replaceAll('\\', '/').replaceAll(RegExp('^/+'), '');
    // If API ever returns an absolute URL, just open it.
    final isAbsolute =
        cleaned.startsWith('http://') || cleaned.startsWith('https://');

    final url = isAbsolute
        ? cleaned
        : 'https://sr.visioncit.com/staticFiles/equipcertFiles/${Uri.encodeComponent(cleaned.split('/').last)}';

    final ok = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!ok) {
      // Fallback: try in-app webview
      await launchUrl(Uri.parse(url), mode: LaunchMode.inAppBrowserView);
    }
  }

  Future<_EquipmentBundle> _load() async {
    // 1) Equipment
    final where = 'equipmentId = ${widget.equipmentId}';
    final list = await api.Api.advanceSearchEquipments(where);
    final equipment = list.isNotEmpty ? list.first : widget.initial;

    // Defaults
    List<EquipmentTerm> terms = const [];
    List<EquipmentCertificate> certs = const [];
    String? vendorName;
    String? factoryName;
    Map<int, String> ddNameById = const {};

    if (equipment?.equipmentId != null) {
      final id = equipment!.equipmentId!;

      // 2) Related lists
      terms = await api.Api.getEquipmentTermsByEquipmentId(id);

      final embedded = equipment.equipmentCertificates ?? const [];
      if (embedded.isNotEmpty) {
        final needFetch = embedded.any(
          (c) =>
              c.nameEnglish == null &&
              c.nameArabic == null &&
              c.documentPath == null,
        );
        certs = needFetch
            ? await Future.wait(
                embedded
                    .map((c) => c.equipmentCertificateId)
                    .whereType<int>()
                    .map(api.Api.getEquipmentCertificateById),
              )
            : embedded;
      }

      // 3) Resolve vendor (org) and factory, plus Domain 7 details
      final futures = <Future>[];
      OrganizationSummary? vendor;
      FactoryModel? factory;
      Domain? domain7; // (not strictly needed for names)
      List<DomainDetail>? domain7Details; // <-- we use these for the names

      if (equipment.vendorId != null) {
        futures.add(
          api.Api.getOrganizationById(
            equipment.vendorId!,
          ).then((v) => vendor = v),
        );
      }
      if (equipment.factoryId != null) {
        futures.add(
          api.Api.getFactoryById(equipment.factoryId!).then((f) => factory = f),
        );
      }
      futures.add(api.Api.getDomainById(7).then((d) => domain7 = d));
      futures.add(
        api.Api.getDomainDetailsByDomainId(7).then((ds) => domain7Details = ds),
      );

      await Future.wait(futures);

      // Prefer EN then AR
      vendorName = vendor?.nameEnglish ?? vendor?.nameArabic;

      // Factory model field names vary; try both EN/AR possibilities
      factoryName =
          (factory?.nameEnglish ??
          factory?.nameArabic ??
          factory?.nameEnglish ??
          factory?.nameArabic);

      // Build quick lookup from Domain 7 details
      if (domain7Details != null) {
        ddNameById = {
          for (final dd in domain7Details!)
            if (dd.domainDetailId != null)
              dd.domainDetailId!:
                  (dd.detailNameEnglish ??
                  dd.detailNameArabic ??
                  dd.domainDetailId!.toString()),
        };
      }
    }

    // Sorts
    terms = [...terms]
      ..sort((a, b) => (a.orderBy ?? 0).compareTo(b.orderBy ?? 0));
    certs = [...certs]
      ..sort((a, b) => (b.expireDate ?? '').compareTo(a.expireDate ?? ''));

    return _EquipmentBundle(
      equipment: equipment,
      terms: terms,
      certs: certs,
      refs: _ResolvedRefs(
        vendorName: vendorName,
        factoryName: factoryName,
        ddNameById: ddNameById,
      ),
    );
  }

  Future<void> _activate(Equipment e) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await api.Api.updateEquipmentActive(e.equipmentId!, true);
      if (!mounted) return;
      AppSnack.success(context, context.l10n.common_activated);
      Navigator.of(context).pop(true); // signal parent to refresh
    } catch (_) {
      if (!mounted) return;
      AppSnack.error(context, context.l10n.common_updateFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.common_equipment)),
      body: RefreshIndicator(
        onRefresh: () async => setState(() => _future = _load()),
        child: FutureBuilder<_EquipmentBundle>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return ListView(
                children: const [ShimmerTile(), ShimmerTile(), ShimmerTile()],
              );
            }

            final bundle = snap.data;
            final e = bundle?.equipment;
            final terms = bundle?.terms ?? const [];
            final certs = bundle?.certs ?? const [];
            final refs = bundle?.refs ?? const _ResolvedRefs();

            if (e == null) {
              return ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      context.l10n.inactiveEquipments_empty,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              );
            }

            final isActive = e.isActive == true;
            final name = (e.descEnglish ?? '').isNotEmpty
                ? e.descEnglish!
                : (e.descArabic ?? context.l10n.common_equipment);

            // ⬇️ keep your existing “Header / Media / Basics / Pricing / Inventory / Relations” sections...
            // Then replace the old "Drivers / Terms / Certificates" blocks with the upgraded ones below.

            return ListView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
              children: [
                // Header
                Glass(
                  radius: 18,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      radius: 26,
                      backgroundColor: cs.surfaceContainerHighest,
                      child: AIcon(AppGlyph.tools, color: cs.primary),
                    ),
                    title: Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    subtitle: Text(
                      '${context.l10n.common_status}: ${isActive ? context.l10n.common_active : context.l10n.common_inactive}',
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Media (cover + images)
                if ((e.coverPath ?? '').isNotEmpty) ...[
                  Glass(
                    radius: 16,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: FallbackNetworkImage(
                          candidates: [e.coverPath!],
                          fit: BoxFit.cover,
                          placeholderColor: cs.surfaceContainerHighest,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if ((e.equipmentImages?.isNotEmpty ?? false))
                  Glass(
                    radius: 16,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionTitle(context.l10n.common_images),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 96,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: e.equipmentImages!.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 8),
                              itemBuilder: (_, i) {
                                final img = e.equipmentImages![i];
                                final path = img.equipmentPath ?? '';
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: AspectRatio(
                                    aspectRatio: 16 / 10,
                                    child: FallbackNetworkImage(
                                      candidates: [path],
                                      fit: BoxFit.cover,
                                      placeholderColor:
                                          cs.surfaceContainerHighest,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if ((e.equipmentImages?.isNotEmpty ?? false))
                  const SizedBox(height: 12),

                // Basics
                Glass(
                  radius: 16,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _DetailsSection(
                      title: context.l10n.common_details,
                      rows: [
                        _kv(
                          context.l10n.common_id,
                          (e.equipmentId ?? '—').toString(),
                        ),
                        _kv(context.l10n.common_english, e.descEnglish ?? '—'),
                        _kv(context.l10n.common_arabic, e.descArabic ?? '—'),
                        _kv(
                          'Created',
                          e.createDateTime?.toIso8601String() ?? '—',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Pricing
                Glass(
                  radius: 16,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _DetailsSection(
                      title: 'Pricing',
                      rows: [
                        _kv('Per day', _fmtMoney(e.rentPricePerDay)),
                        _kv('Per hour', _fmtMoney(e.rentPricePerHour)),
                        _kv('Down payment %', _fmtNum(e.downPaymentPerc)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Quantities / Status
                Glass(
                  radius: 16,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _DetailsSection(
                      title: 'Inventory & Status',
                      rows: [
                        _kv('Quantity', _fmtInt(e.quantity)),
                        _kv('Reserved', _fmtInt(e.reservedQuantity)),
                        _kv('Available', _fmtInt(e.availableQuantity)),
                        _kv(
                          'Status',
                          e.status?.detailNameEnglish ??
                              e.status?.detailNameArabic ??
                              _fmtInt(e.statusId),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Relationships
                Glass(
                  radius: 16,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _DetailsSection(
                      title: 'Relations',
                      rows: [
                        _kv(
                          'Equipment list',
                          e.equipmentList?.nameEnglish ??
                              e.equipmentList?.nameArabic ??
                              _fmtInt(e.equipmentListId),
                        ),
                        _kv(
                          'Category',
                          e.category?.detailNameEnglish ??
                              e.category?.detailNameArabic ??
                              _fmtInt(e.categoryId),
                        ),
                        _kv(
                          'Fuel responsibility',
                          e.fuelResponsibility?.detailNameEnglish ??
                              e.fuelResponsibility?.detailNameArabic ??
                              _fmtInt(e.fuelResponsibilityId),
                        ),
                        // Transfer type / responsibility from Domain 9
                        _kv(
                          'Transfer type',
                          e.transferType?.detailNameEnglish ??
                              e.transferType?.detailNameArabic ??
                              _fmtInt(e.transferTypeId),
                        ),
                        _kv(
                          'Transfer responsibility',
                          refs.nameFor(e.transferResponsibilityId),
                        ),
                        _kv(
                          'Transfer resp. (driver)',
                          refs.nameFor(e.driverTransResponsibilityId),
                        ),
                        _kv(
                          'Food resp. (driver)',
                          refs.nameFor(e.driverFoodResponsibilityId),
                        ),
                        _kv(
                          'Housing resp. (driver)',
                          refs.nameFor(e.driverHousingResponsibilityId),
                        ),

                        // Vendor (Organization) and Factory via fetched names
                        _kv('Vendor', refs.vendorName ?? _fmtInt(e.vendorId)),
                        _kv(
                          'Factory',
                          refs.factoryName ?? _fmtInt(e.factoryId),
                        ),
                        _kv(
                          'Organization',
                          e.organization?.nameEnglish ??
                              e.organization?.nameArabic ??
                              '—',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Drivers
                if ((e.drivers?.isNotEmpty ?? false))
                  Glass(
                    radius: 16,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionTitle('Drivers'),
                          const SizedBox(height: 8),
                          ...e.drivers!.map(
                            (d) => ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor: cs.surfaceContainerHighest,
                                child: AIcon(
                                  AppGlyph.user,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                              title: Text(
                                d.driverNameEnglish ?? '—',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text('${d.equipmentDriverId ?? '—'}'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if ((e.drivers?.isNotEmpty ?? false))
                  const SizedBox(height: 12),

                // Terms
                // Terms (from API; ordered by orderBy)
                if (terms.isNotEmpty)
                  Glass(
                    radius: 16,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionTitle('Terms'),
                          const SizedBox(height: 8),
                          ...terms.map(
                            (t) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('•  '),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          (t.descEnglish?.isNotEmpty ?? false)
                                              ? t.descEnglish!
                                              : (t.descArabic ?? '—'),
                                          maxLines: 4,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 4,
                                          children: [
                                            if (t.orderBy != null)
                                              _chip('Order: ${t.orderBy}'),
                                            _chip(
                                              'Active: ${_fmtBool(t.isActive)}',
                                            ),
                                            _chip(
                                              'Created: ${t.createDateTime?.toIso8601String() ?? '—'}',
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (terms.isNotEmpty) const SizedBox(height: 12),

                const SizedBox(height: 12),

                // Certificates
                if (certs.isNotEmpty)
                  Glass(
                    radius: 16,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionTitle('Certificates'),
                          const SizedBox(height: 8),
                          ...certs.map((c) {
                            final title = (c.nameEnglish?.isNotEmpty ?? false)
                                ? c.nameEnglish!
                                : (c.nameArabic ?? '—');
                            final expired = c.isExpire == true;

                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor: cs.surfaceContainerHighest,
                                child: Icon(
                                  (c.isImage == true)
                                      ? Icons.image
                                      : Icons.picture_as_pdf,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                              title: Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Issue: ${c.issueDate ?? '—'}  •  Expire: ${c.expireDate ?? '—'}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: [
                                      _chip(
                                        'Expired',
                                        color: expired
                                            ? Colors.red.withOpacity(.2)
                                            : null,
                                      ),
                                      _chip('Active'),
                                      if ((c.documentType ?? '').isNotEmpty)
                                        _chip(c.documentType!),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: (c.documentPath ?? '').isNotEmpty
                                  ? IconButton(
                                      tooltip: 'Open',
                                      icon: const Icon(Icons.open_in_new),
                                      onPressed: () =>
                                          _openCertDoc(context, c.documentPath),
                                    )
                                  : null,
                            );
                          }),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 12),

                if (!isActive)
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: _busy ? null : () => _activate(e),
                      icon: _busy
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check_circle),
                      label: Text(context.l10n.action_activate),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  _KV _kv(String k, String v) => _KV(k: k, v: v);
}

// ====================== HELPERS & SEARCH ======================
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
    final width = MediaQuery.of(context).size.width;

    // 🔥 Responsive layout behavior
    bool isDesktop = width >= 1024;
    bool isTablet = width >= 600 && width < 1024;
    bool isPhone = width < 600;

    // 🔹 Always two per row for tablets & phones unless very small
    double cardWidth;
    if (isDesktop) {
      cardWidth = (width - 80) / 4; // 4 per row
    } else if (isTablet) {
      cardWidth = (width - 48) / 2; // 2 per row
    } else {
      // On phones: try 2 per row if enough space, otherwise fallback to full width
      if (width > 400) {
        cardWidth = (width - 36) / 2;
      } else {
        cardWidth = width - 24;
      }
    }

    // 🔹 Responsive padding
    final edgePadding = isDesktop
        ? const EdgeInsets.all(16)
        : isTablet
        ? const EdgeInsets.all(12)
        : const EdgeInsets.all(8);

    return SizedBox(
      width: cardWidth,
      child: Glass(
        radius: isPhone ? 12 : 16,
        child: Padding(
          padding: edgePadding,
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
                        fontSize: isPhone ? 12 : 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: isPhone ? 18 : null,
                          ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: isPhone ? 22 : 28,
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

class _DetailsSection extends StatelessWidget {
  const _DetailsSection({required this.title, required this.rows});
  final String title;
  final List<_KV> rows;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        ...rows.map(
          (kv) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Text(
                    kv.k,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(
                  flex: 8,
                  child: Text(
                    kv.v,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _KV {
  final String k;
  final String v;
  const _KV({required this.k, required this.v});
}

Widget _sectionTitle(String text) =>
    Text(text, style: const TextStyle(fontWeight: FontWeight.w800));

String _fmtMoney(num? v) => (v == null) ? '—' : v.toStringAsFixed(2);

String _fmtNum(num? v) => (v == null) ? '—' : v.toString();

String _fmtInt(num? v) => (v == null) ? '—' : v.toInt().toString();

String _fmtBool(bool? b) => (b == true)
    ? 'Yes'
    : (b == false)
    ? 'No'
    : '—';

Widget _chip(String label, {Color? color}) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  decoration: BoxDecoration(
    color: color ?? Colors.black.withOpacity(0.04),
    borderRadius: BorderRadius.circular(999),
  ),
  child: Text(label, style: const TextStyle(fontSize: 12)),
);

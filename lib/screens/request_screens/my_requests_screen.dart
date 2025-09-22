// lib/screens/my_requests_screen.dart
// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:heavy_new/l10n/app_localizations.dart';
import 'package:heavy_new/screens/request_screens/request_details_screen.dart';
import 'package:intl/intl.dart';

import 'package:heavy_new/core/utils/model_utils.dart';
import 'package:heavy_new/core/auth/auth_store.dart';
import 'package:heavy_new/screens/auth_profile_screens/phone_auth_screen.dart';

import 'package:heavy_new/core/api/api_handler.dart' as api;
import 'package:heavy_new/core/models/admin/request.dart';
import 'package:heavy_new/core/models/organization/organization_user.dart';
import 'package:heavy_new/foundation/ui/ui_extras.dart';

extension _L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}

class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key});
  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  late Future<List<RequestModel>> _future;
  static const _ccy = 'SAR';
  final _dateFmt = DateFormat('yyyy-MM-dd');
  // Map Domain 12 (Request Status) -> human label
  Map<int, String> _statusById = {};
  bool _statusLoading = false;
  String? _statusError;

  bool get _isLoggedIn => AuthStore.instance.isLoggedIn;

  int? _myOrgId;
  String? _orgError;

  Future<void> _loadStatusDomain() async {
    setState(() {
      _statusLoading = true;
      _statusError = null;
    });
    try {
      final rows = await api.Api.getDomainDetailsByDomainId(12);
      final map = <int, String>{};
      for (final d in rows) {
        final id = d.domainDetailId ?? -1;
        final en = (d.detailNameEnglish ?? '').trim();
        final ar = (d.detailNameArabic ?? '').trim();
        map[id] = en.isNotEmpty ? en : (ar.isNotEmpty ? ar : '#$id');
      }
      if (!mounted) return;
      setState(() => _statusById = map);
    } catch (e) {
      if (!mounted) return;
      setState(() => _statusError = 'Could not load status names.');
    } finally {
      if (mounted) setState(() => _statusLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _future = _isLoggedIn ? _fetchMyRequests() : Future.value(const []);
    _loadStatusDomain();
  }

  Future<int?> _resolveMyOrganizationId() async {
    final u = AuthStore.instance.user.value;
    if (u == null) return null;
    try {
      final rows = await api.Api.getOrganizationUsers();
      final me = rows.firstWhere(
        (m) => (m.applicationUserId == u.id) && (m.isActive == true),
        orElse: () => OrganizationUser(),
      );
      return me.organizationId;
    } catch (_) {
      return null;
    }
  }

  Future<List<RequestModel>> _fetchMyRequests() async {
    _orgError = null;
    final orgId = await _resolveMyOrganizationId();
    setState(() => _myOrgId = orgId);

    if (orgId == null || orgId == 0) {
      _orgError =
          'No active Organization found for your account. Please complete your profile.';
      return const [];
    }

    // Fetch then filter locally to requests where the user is vendor or customer
    final all = await api.Api.getRequests();
    final mine =
        all.where((r) {
          final v = r.vendorId ?? r.vendor?.organizationId ?? -1;
          final c = r.customerId ?? r.customer?.organizationId ?? -2;
          return v == orgId || c == orgId;
        }).toList()..sort((a, b) {
          // Sort by createDateTime desc, then requestId desc as fallback
          final ad = a.createDateTime ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bd = b.createDateTime ?? DateTime.fromMillisecondsSinceEpoch(0);
          final byDate = bd.compareTo(ad);
          if (byDate != 0) return byDate;
          return (b.requestId ?? 0).compareTo(a.requestId ?? 0);
        });

    return mine;
  }

  Future<void> _reload() async {
    if (!_isLoggedIn) return;
    setState(() => _future = _fetchMyRequests());
  }

  String _money(num? n) => '$_ccy ${((n ?? 0).toDouble()).toStringAsFixed(2)}';

  String _statusLabel(RequestModel r) {
    // Prefer embedded names if present
    final en = (r.status?.detailNameEnglish ?? '').trim();
    final ar = (r.status?.detailNameArabic ?? '').trim();
    if (en.isNotEmpty) return en;
    if (ar.isNotEmpty) return ar;

    // Fall back to Domain 12 map
    final id = r.statusId;
    if (id == null) return '';
    return _statusById[id] ?? '#$id';
  }

  String _roleChip(RequestModel r) {
    final org = _myOrgId;
    if (org == null || org == 0) return '';
    final v = r.vendorId ?? r.vendor?.organizationId;
    final c = r.customerId ?? r.customer?.organizationId;
    if (v == org) return 'As Vendor';
    if (c == org) return 'As Customer';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // -------- Auth gate --------
    if (!AuthStore.instance.isLoggedIn) {
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.myRequestsTitle)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Glass(
              radius: 18,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.l10n.signInToViewRequests,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      context.l10n.signInToViewRequestsBody,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 14),
                    FilledButton(
                      onPressed: () async {
                        final ok = await Navigator.of(context).push<bool>(
                          MaterialPageRoute(
                            builder: (_) => const PhoneAuthScreen(),
                          ),
                        );
                        if (ok == true && mounted) {
                          setState(() => _future = _fetchMyRequests());
                        }
                      },
                      child: Text(context.l10n.actionSignIn),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    // -------- Logged-in view --------
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.myRequestsTitle)),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: FutureBuilder<List<RequestModel>>(
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
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.failedToLoadRequests,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${snap.error}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.error,
                              ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _reload,
                          child: Text(context.l10n.actionRetry),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            final cs = Theme.of(context).colorScheme;

            if ((_orgError?.isNotEmpty ?? false)) {
              return ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _orgError!,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: cs.error),
                    ),
                  ),
                ],
              );
            }

            final items = snap.data ?? const <RequestModel>[];
            if (items.isEmpty) {
              return ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      context.l10n.noRequestsYet,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final r = items[i];

                final reqNo =
                    r.requestNo?.toString() ?? r.requestId?.toString() ?? '—';

                final from = () {
                  final d = dtLoose(r.fromDate);
                  return d != null ? _dateFmt.format(d) : '—';
                }();
                final to = () {
                  final d = dtLoose(r.toDate);
                  return d != null ? _dateFmt.format(d) : '—';
                }();

                final days = r.numberDays ?? 0;
                final total = r.afterVatPrice ?? r.totalPrice ?? 0;

                final statusStr = _statusLabel(r);
                final role = _roleChip(r); // "As Vendor" | "As Customer" | ""

                return Glass(
                  radius: 16,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            RequestDetailsScreen(requestId: r.requestId ?? 0),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          // -------- Top row: icon + title/badges + amount --------
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Leading icon
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: cs.surfaceVariant,
                                child: Icon(
                                  Icons.request_page_outlined,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(width: 10),

                              // Title + badges
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // "Request #123"
                                    Text(
                                      '${context.l10n.requestNumber} $reqNo',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: [
                                        if (role.isNotEmpty)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: cs.secondaryContainer,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              role == 'As Vendor'
                                                  ? context.l10n.asVendor
                                                  : (role == 'As Customer'
                                                        ? context
                                                              .l10n
                                                              .asCustomer
                                                        : role),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelMedium
                                                  ?.copyWith(
                                                    color:
                                                        cs.onSecondaryContainer,
                                                  ),
                                            ),
                                          ),
                                        if (statusStr.isNotEmpty)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: cs.primaryContainer,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              statusStr,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelMedium
                                                  ?.copyWith(
                                                    color:
                                                        cs.onPrimaryContainer,
                                                  ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 10),

                              // Amount
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    _money(total),
                                    textAlign: TextAlign.right,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(height: 2),
                                  Icon(
                                    Icons.chevron_right,
                                    color: cs.onSurfaceVariant,
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),
                          const Divider(height: 1),

                          // -------- Bottom row: dates & length --------
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Row(
                              children: [
                                // From
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.calendar_today_outlined,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${context.l10n.fromDate} $from',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: cs.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 12),

                                // To
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.arrow_forward, size: 16),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${context.l10n.toDate} $to',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: cs.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                                const Spacer(),

                                // Days
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.schedule_outlined,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '$days ${context.l10n.daysSuffix}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: cs.onSurfaceVariant,
                                          ),
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
                );
              },
            );
          },
        ),
      ),
    );
  }
}

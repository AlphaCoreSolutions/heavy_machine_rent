// lib/screens/orders_history_screen.dart
import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:heavy_new/screens/request_details_screen.dart';
import 'package:intl/intl.dart';

import 'package:heavy_new/core/utils/model_utils.dart';
import 'package:heavy_new/core/auth/auth_store.dart';
import 'package:heavy_new/core/api/api_handler.dart' as api;

import 'package:heavy_new/core/models/admin/request.dart';
import 'package:heavy_new/core/models/organization/organization_user.dart';

import 'package:heavy_new/foundation/ui/app_icons.dart';
import 'package:heavy_new/foundation/ui/ui_extras.dart';

class OrdersHistoryScreen extends StatefulWidget {
  const OrdersHistoryScreen({super.key});
  @override
  State<OrdersHistoryScreen> createState() => _OrdersHistoryScreenState();
}

class _OrdersHistoryScreenState extends State<OrdersHistoryScreen> {
  late Future<List<RequestModel>> _future;

  // Domain 12 sample filter (keep if you still want only “orders/history” statuses)
  bool _isOrder(RequestModel r) {
    final sid = r.statusId ?? r.status?.domainDetailId ?? fint(r.status);
    return sid == 34 || sid == 35 || sid == 36 || sid == 38;
  }

  final _dateIn = DateFormat('yyyy-MM-dd');
  final _dateOut = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    _future = _loadForMyVendor();
  }

  Future<void> _reload() async {
    setState(() => _future = _loadForMyVendor());
  }

  // --- Resolve the logged-in user's active organization (vendor) ---
  Future<int?> _resolveMyOrganizationId() async {
    final auth = AuthStore.instance;
    final u = auth.user.value;
    if (!auth.isLoggedIn || u == null) return null;

    try {
      final rows = await api.Api.getOrganizationUsers();
      final me = rows.firstWhere(
        (m) => (m.applicationUserId == u.id) && (m.isActive == true),
        orElse: () => OrganizationUser(),
      );
      return me.organizationId;
    } catch (e) {
      dev.log('Failed to resolve my organization id: $e', name: 'orders');
      return null;
    }
  }

  // --- Build the SQL and call AdvanceSearch ---
  Future<List<RequestModel>> _loadForMyVendor() async {
    final auth = AuthStore.instance;
    if (!auth.isLoggedIn) return const [];

    final orgId = await _resolveMyOrganizationId();
    if (orgId == null || orgId == 0) {
      dev.log(
        'No active organization for user; returning empty list',
        name: 'orders',
      );
      return const [];
    }

    final sql =
        'Select * From Requests Where VendorId = ${orgId}'; // tweak if needed
    dev.log('[AdvanceSearch] $sql', name: 'orders');

    final all = await api.Api.advanceSearchRequests(sql);

    // Keep just “orders/history” statuses if you still want that:
    final filtered = all.where(_isOrder).toList();

    // Sort newest first using toDate > createDateTime
    filtered.sort((a, b) {
      final ad = dtLoose(a.toDate) ?? a.createDateTime ?? DateTime(0);
      final bd = dtLoose(b.toDate) ?? b.createDateTime ?? DateTime(0);
      return bd.compareTo(ad);
    });

    return filtered;
  }

  DateTime? _parseDate(String? ymd) {
    if (ymd == null || ymd.isEmpty) return null;
    try {
      return DateTime.parse(ymd);
    } catch (_) {
      try {
        return _dateIn.parse(ymd);
      } catch (_) {
        return null;
      }
    }
  }

  String _fmtDate(String? ymd) {
    final d = _parseDate(ymd);
    return d == null ? '—' : _dateOut.format(d);
  }

  String _status(RequestModel r) =>
      r.status?.detailNameEnglish ??
      r.status?.detailNameArabic ??
      (r.statusId?.toString() ?? '');

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Orders (history)')),
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
                          'Failed to load orders',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
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
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            final items = (snap.data ?? []);
            if (items.isEmpty) {
              return ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'No past orders yet',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final o = items[i];
                final s = _status(o);
                final titleNo = o.requestNo ?? o.requestId ?? 0;
                final from = _fmtDate(o.fromDate);
                final to = _fmtDate(o.toDate);

                return Glass(
                  radius: 16,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: cs.surfaceVariant,
                      child: AIcon(
                        AppGlyph.invoice,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    title: Text(
                      'Order #$titleNo',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text('$from → $to  •  ${s.isEmpty ? '—' : s}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => RequestDetailsScreen(
                          requestId: o.requestId ?? titleNo,
                        ),
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

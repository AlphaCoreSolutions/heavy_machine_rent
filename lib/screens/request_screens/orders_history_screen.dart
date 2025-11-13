// lib/screens/orders_history_screen.dart
import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:Ajjara/l10n/app_localizations.dart';
import 'package:Ajjara/screens/request_screens/request_details_screen.dart';
import 'package:intl/intl.dart';

import 'package:Ajjara/core/utils/model_utils.dart';
import 'package:Ajjara/core/auth/auth_store.dart';
import 'package:Ajjara/core/api/api_handler.dart' as api;

import 'package:Ajjara/core/models/admin/request.dart';
import 'package:Ajjara/core/models/organization/organization_user.dart';

import 'package:Ajjara/foundation/ui/app_icons.dart';
import 'package:Ajjara/foundation/ui/ui_extras.dart';

extension _L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}

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
        'Select * From Requests Where VendorId = $orgId'; // tweak if needed
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

    // tiny helper for the status chip (local to build)
    Widget statusPill(String label) {
      final showDash = label.trim().isEmpty;
      final text = showDash ? '—' : label.trim();
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: cs.secondaryContainer,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: cs.outlineVariant.withOpacity(0.6)),
        ),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: cs.onSecondaryContainer,
            fontWeight: FontWeight.w700,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.ordersHistoryTitle)),
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
                          context.l10n.failedToLoadOrders,
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
                          child: Text(context.l10n.actionRetry),
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
                      context.l10n.noPastOrdersYet,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final o = items[i];
                final s = _status(o);
                final titleNo = o.requestNo ?? o.requestId ?? 0;
                final from = _fmtDate(o.fromDate);
                final to = _fmtDate(o.toDate);

                return Glass(
                  radius: 16,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => RequestDetailsScreen(
                          requestId: o.requestId ?? titleNo,
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header: icon + order number + status chip + chevron
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: cs.surfaceContainerHighest,
                                child: AIcon(
                                  AppGlyph.invoice,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '${context.l10n.order} #$titleNo',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ),
                              const SizedBox(width: 10),
                              statusPill(s),
                              const SizedBox(width: 6),
                              const Icon(Icons.chevron_right),
                            ],
                          ),

                          const SizedBox(height: 10),
                          const Divider(height: 1),

                          // Dates row
                          Padding(
                            padding: const EdgeInsets.only(top: 10, bottom: 6),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_outlined,
                                  size: 16,
                                  color: cs.onSurfaceVariant,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    '${context.l10n.fromDate} $from',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: cs.onSurfaceVariant),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Icon(Icons.arrow_forward, size: 16),
                                const SizedBox(width: 10),
                                Flexible(
                                  child: Text(
                                    '${context.l10n.toDate} $to',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: cs.onSurfaceVariant),
                                    overflow: TextOverflow.ellipsis,
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
              },
            );
          },
        ),
      ),
    );
  }
}

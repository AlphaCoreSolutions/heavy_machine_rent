import 'package:flutter/material.dart';
import 'package:heavy_new/core/api/api_handler.dart' as api;
import 'package:heavy_new/core/models/admin/request.dart';
import 'package:heavy_new/core/models/equipment/equipment.dart';
import 'package:heavy_new/foundation/ui/app_icons.dart';
import 'package:heavy_new/foundation/ui/ui_extras.dart';

enum _Bucket { pending, open, finished, closed }

class ContractsScreen extends StatefulWidget {
  const ContractsScreen({super.key});
  @override
  State<ContractsScreen> createState() => _ContractsScreenState();
}

class _ContractsScreenState extends State<ContractsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  Future<List<RequestModel>>? _future;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
    _future = api.Api.getRequests(); // using requests as contract sources
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  String _status(RequestModel r) =>
      r.status?.detailNameEnglish ??
      r.status?.detailNameArabic ??
      r.status?.toString() ??
      '';

  _Bucket _bucketFor(RequestModel r) {
    final s = _status(r).toLowerCase();
    if (s.contains('pending') || s.contains('await')) return _Bucket.pending;
    if (s.contains('open') || s.contains('active') || s.contains('progress')) {
      return _Bucket.open;
    }
    if (s.contains('finish') || s.contains('complete')) return _Bucket.finished;
    if (s.contains('close') || s.contains('cancel')) return _Bucket.closed;
    // default guess
    return _Bucket.open;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contracts'),
        bottom: TabBar(
          controller: _tab,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Open'),
            Tab(text: 'Finished'),
            Tab(text: 'Closed'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async => setState(() {
          _future = api.Api.getRequests();
        }),
        child: FutureBuilder<List<RequestModel>>(
          future: _future,
          builder: (context, snap) {
            List<RequestModel> items = snap.data ?? [];
            if (items.isEmpty && snap.hasError) {
              // DEV demo
              items = [
                RequestModel(
                  requestId: 310,
                  requestNo: 301,
                  fromDate: DateTime.now().toIso8601String(),
                  toDate: DateTime.now()
                      .add(const Duration(days: 5))
                      .toIso8601String(),
                  status: DomainDetailRef(detailNameEnglish: 'Pending'),
                ),
                RequestModel(
                  requestId: 311,
                  requestNo: 311,
                  fromDate: DateTime.now()
                      .subtract(const Duration(days: 3))
                      .toIso8601String(),
                  toDate: DateTime.now()
                      .add(const Duration(days: 7))
                      .toIso8601String(),
                  status: DomainDetailRef(detailNameEnglish: 'Open'),
                ),
                RequestModel(
                  requestId: 312,
                  requestNo: 312,
                  fromDate: DateTime.now()
                      .subtract(const Duration(days: 20))
                      .toIso8601String(),
                  toDate: DateTime.now()
                      .subtract(const Duration(days: 10))
                      .toIso8601String(),
                  status: DomainDetailRef(detailNameEnglish: 'Finished'),
                ),
                RequestModel(
                  requestId: 313,
                  requestNo: 313,
                  fromDate: DateTime.now()
                      .subtract(const Duration(days: 60))
                      .toIso8601String(),
                  toDate: DateTime.now()
                      .subtract(const Duration(days: 55))
                      .toIso8601String(),
                  status: DomainDetailRef(detailNameEnglish: 'Closed'),
                ),
              ];
            }

            // group by buckets
            final buckets = <_Bucket, List<RequestModel>>{
              _Bucket.pending: [],
              _Bucket.open: [],
              _Bucket.finished: [],
              _Bucket.closed: [],
            };
            for (final r in items) {
              buckets[_bucketFor(r)]!.add(r);
            }
            // sorter
            int cmp(RequestModel a, RequestModel b) =>
                (b.createDateTime ?? b.fromDate ?? DateTime(0))
                    .toString()
                    .compareTo(
                      (a.createDateTime ?? a.fromDate ?? DateTime(0))
                          .toString(),
                    );
            for (final k in buckets.keys) {
              buckets[k]!.sort(cmp);
            }

            Widget listOf(List<RequestModel> list) {
              if (list.isEmpty) {
                return ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Nothing here yet',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ],
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final c = list[i];
                  final s = _status(c);
                  return Glass(
                    radius: 16,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: cs.primaryContainer,
                        child: AIcon(
                          AppGlyph.contract,
                          color: cs.onPrimaryContainer,
                        ),
                      ),
                      title: Text(
                        'Contract #${c.requestNo ?? c.requestId ?? ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        '${c.fromDate?.toString().split(' ').first ?? '—'}'
                        ' → ${c.toDate?.toString().split(' ').first ?? '—'}'
                        '  •  ${s.isEmpty ? '—' : s}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // TODO: open contract details screen
                      },
                    ),
                  );
                },
              );
            }

            return TabBarView(
              controller: _tab,
              children: [
                listOf(buckets[_Bucket.pending]!),
                listOf(buckets[_Bucket.open]!),
                listOf(buckets[_Bucket.finished]!),
                listOf(buckets[_Bucket.closed]!),
              ],
            );
          },
        ),
      ),
    );
  }
}

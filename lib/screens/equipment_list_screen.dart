// =================================================================================
// EQUIPMENT LIST (search + filter + list → details)
// Responsive: phones → desktop, debounced search, grid on wide screens.
// =================================================================================

import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:heavy_new/core/api/api_handler.dart' as api;
import 'package:heavy_new/core/models/equipment/equipment.dart';

import 'package:heavy_new/foundation/ui/app_icons.dart';
import 'package:heavy_new/foundation/ui/ui_extras.dart';
import 'package:heavy_new/foundation/ui/ui_kit.dart';
import 'package:heavy_new/screens/equipment_details_screen.dart';

class EquipmentListScreen extends StatefulWidget {
  const EquipmentListScreen({super.key});
  @override
  State<EquipmentListScreen> createState() => _EquipmentListScreenState();
}

class _EquipmentListScreenState extends State<EquipmentListScreen> {
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  Future<List<Equipment>>? _future;
  final ScrollController _scrollCtrl = ScrollController();

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _future = api.Api.getEquipments();

    // Debounce typing for desktop feel
    _searchCtrl.addListener(() {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 320), () {
        if (!mounted) return;
        _doSearch();
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _doSearch() {
    final q = _searchCtrl.text.trim();
    setState(() {
      _future = q.isEmpty
          ? api.Api.getEquipments()
          : api.Api.advanceSearchEquipments(q);
    });
  }

  void _clearSearch() {
    if (_searchCtrl.text.isEmpty) return;
    _searchCtrl.clear();
    _doSearch();
    _searchFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final searchRowH = 90.0; // TextField + buttons row
    final filterRowH = 40.0; // "Filters" button row
    const topPad = 12.0, bottomPad = 45.0, gap = 8.0;
    final headerHeight =
        topPad + searchRowH + gap + filterRowH + bottomPad; // ≈126

    // Keyboard shortcuts: Ctrl/Cmd+F to focus, Enter to search
    final shortcuts = <ShortcutActivator, Intent>{
      const SingleActivator(LogicalKeyboardKey.keyF, control: true):
          const FocusSearchIntent(),
      const SingleActivator(LogicalKeyboardKey.keyF, meta: true):
          const FocusSearchIntent(),
      const SingleActivator(LogicalKeyboardKey.enter):
          const SubmitSearchIntent(),
    };

    return Shortcuts(
      shortcuts: shortcuts,
      child: Actions(
        actions: <Type, Action<Intent>>{
          FocusSearchIntent: CallbackAction<FocusSearchIntent>(
            onInvoke: (intent) {
              _searchFocus.requestFocus();
              return null;
            },
          ),
          SubmitSearchIntent: CallbackAction<SubmitSearchIntent>(
            onInvoke: (intent) {
              _doSearch();
              return null;
            },
          ),
        },

        child: Scaffold(
          appBar: AppBar(title: const Text('Equipment')),
          body: ScrollConfiguration(
            behavior: const _DesktopScrollBehavior(),
            child: RefreshIndicator(
              onRefresh: () async =>
                  setState(() => _future = api.Api.getEquipments()),
              child: LayoutBuilder(
                builder: (context, bc) {
                  final w = bc.maxWidth;
                  final useGrid = w >= 720;
                  const pageMax = 1200.0;

                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: pageMax),
                      child: Scrollbar(
                        controller: _scrollCtrl,
                        interactive: true,
                        thumbVisibility: true,
                        child: CustomScrollView(
                          controller: _scrollCtrl,
                          physics: const AlwaysScrollableScrollPhysics(),
                          slivers: [
                            // Sticky search+actions
                            // header
                            SliverPersistentHeader(
                              pinned: true,
                              delegate: _StickyHeader(
                                child: Container(
                                  color: Theme.of(context).colorScheme.surface,
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    topPad,
                                    16,
                                    bottomPad,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Glass(
                                        radius: 16,
                                        child: Row(
                                          children: [
                                            Expanded(child: AInput(/* … */)),
                                            const SizedBox(width: 8),
                                            FilledButton.icon(
                                              onPressed: _doSearch,
                                              icon: const Icon(Icons.search),
                                              label: const Text('Search'),
                                            ),
                                            const SizedBox(width: 8),
                                            OutlinedButton.icon(
                                              onPressed: _clearSearch,
                                              icon: const Icon(Icons.clear),
                                              label: const Text('Clear'),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: gap),
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: GhostButton(
                                          onPressed: () => showFilterSheet(
                                            context,
                                          ).then((_) => _doSearch()),
                                          icon: AIcon(
                                            AppGlyph.filter,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                          ),
                                          child: const Text('Filters'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                minExtent: headerHeight, // <- >= real height
                                maxExtent:
                                    headerHeight, // <- keep pinned height constant
                              ),
                            ),

                            // Results
                            SliverToBoxAdapter(
                              child: const SizedBox(height: 6),
                            ),
                            FutureBuilder<List<Equipment>>(
                              future: _future,
                              builder: (context, snap) {
                                if (snap.connectionState ==
                                    ConnectionState.waiting) {
                                  return SliverToBoxAdapter(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      child: Column(
                                        children: const [
                                          ShimmerTile(),
                                          ShimmerTile(),
                                          ShimmerTile(),
                                          ShimmerTile(),
                                        ],
                                      ),
                                    ),
                                  );
                                }

                                if (snap.hasError) {
                                  return SliverToBoxAdapter(
                                    child: Padding(
                                      padding: const EdgeInsets.all(24),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Failed to load equipment list',
                                            style: Theme.of(
                                              context,
                                            ).textTheme.titleMedium,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '${snap.error}',
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(color: cs.error),
                                          ),
                                          const SizedBox(height: 12),
                                          FilledButton(
                                            onPressed: () => setState(
                                              () => _future =
                                                  api.Api.getEquipments(),
                                            ),
                                            child: const Text('Retry'),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }

                                final items = snap.data ?? const <Equipment>[];
                                if (items.isEmpty) {
                                  return SliverToBoxAdapter(
                                    child: Padding(
                                      padding: const EdgeInsets.all(24),
                                      child: Text(
                                        'No results',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyLarge,
                                      ),
                                    ),
                                  );
                                }

                                // LIST (phones) or GRID (tablets/desktop)
                                if (!useGrid) {
                                  return SliverList(
                                    delegate: SliverChildBuilderDelegate(
                                      (context, index) {
                                        if (index.isOdd) {
                                          return const SizedBox(
                                            height: 8,
                                          ); // separator
                                        }
                                        final i = index ~/ 2;
                                        return _EquipmentListTile(e: items[i]);
                                      },
                                      childCount: items.isEmpty
                                          ? 0
                                          : items.length * 2 - 1,
                                    ),
                                  );
                                } else {
                                  final cross = w >= 1100 ? 3 : 2;
                                  final aspect = w >= 1100 ? 1.65 : 1.4;

                                  return SliverPadding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    sliver: SliverGrid(
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: cross,
                                            mainAxisSpacing: 12,
                                            crossAxisSpacing: 12,
                                            childAspectRatio: aspect,
                                          ),
                                      delegate: SliverChildBuilderDelegate(
                                        (_, i) =>
                                            _EquipmentListTile(e: items[i]),
                                        childCount: items.length,
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                            SliverToBoxAdapter(
                              child: SizedBox(
                                height:
                                    MediaQuery.of(context).padding.bottom + 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class FocusSearchIntent extends Intent {
  const FocusSearchIntent();
}

class SubmitSearchIntent extends Intent {
  const SubmitSearchIntent();
}

// ---- One tile (reuses your SlidableEquipmentTile & image candidates) ----
class _EquipmentListTile extends StatelessWidget {
  const _EquipmentListTile({required this.e});
  final Equipment e;

  @override
  Widget build(BuildContext context) {
    final String? primaryName = (e.coverPath?.isNotEmpty ?? false)
        ? e.coverPath
        : (e.equipmentImages
                  ?.firstWhere(
                    (img) => (img.equipmentPath ?? '').isNotEmpty,
                    orElse: () => EquipmentImage(),
                  )
                  .equipmentPath ??
              e.equipmentList?.imagePath);

    final thumbCandidates = api.Api.equipmentImageCandidates(primaryName);

    return AnimateIn(
      child: SlidableEquipmentTile(
        title: e.title,
        subtitle:
            e.category?.detailNameEnglish ??
            e.equipmentList?.primaryUseEnglish ??
            '—',
        pricePerDay: e.rentPerDayDouble ?? 0,
        imageWidget: FallbackNetworkImage(
          candidates: thumbCandidates,
          placeholderColor: Theme.of(context).colorScheme.surfaceVariant,
          fit: BoxFit.cover,
        ),
        distanceKm: e.distanceKilo?.toDouble(),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                EquipmentDetailsScreen(equipmentId: e.equipmentId ?? 0),
          ),
        ),
        onRent: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                EquipmentDetailsScreen(equipmentId: e.equipmentId ?? 0),
          ),
        ),
      ),
    );
  }
}

// ---- Sticky header delegate ----
class _StickyHeader extends SliverPersistentHeaderDelegate {
  _StickyHeader({
    required this.child,
    required this.minExtent,
    required this.maxExtent,
  });
  final Widget child;
  @override
  final double minExtent;
  @override
  final double maxExtent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(
      color: Colors.transparent,
      elevation: shrinkOffset > 0 ? 1 : 0,
      child: SizedBox.expand(
        // <- force child to exactly the sliver height
        child: child,
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _StickyHeader old) =>
      old.child != child ||
      old.minExtent != minExtent ||
      old.maxExtent != maxExtent;
}

// ---- Desktop scroll behavior: allow mouse + touch dragging ----
class _DesktopScrollBehavior extends MaterialScrollBehavior {
  const _DesktopScrollBehavior();
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.mouse,
    PointerDeviceKind.touch,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
  };
}

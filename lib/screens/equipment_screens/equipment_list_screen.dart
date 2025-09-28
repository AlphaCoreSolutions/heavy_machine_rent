// =================================================================================
// EQUIPMENT LIST (search + filter + list → details)
// - Search (taller) stacked ABOVE a pill-style filter control in the same Glass.
// - Header height increased so nothing overflows when pinned.
// - Filter still opens the bottom sheet and triggers _doSearch().
// =================================================================================

import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:heavy_new/core/api/api_handler.dart' as api;
import 'package:heavy_new/core/models/equipment/equipment.dart';
import 'package:heavy_new/core/models/equipment/equipment_list.dart';

import 'package:heavy_new/foundation/ui/ui_extras.dart';
import 'package:heavy_new/foundation/ui/ui_kit.dart';
import 'package:heavy_new/l10n/app_localizations.dart';
import 'package:heavy_new/screens/equipment_screens/equipment_details_screen.dart';

extension _L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}

class EquipmentListScreen extends StatefulWidget {
  const EquipmentListScreen({super.key});
  @override
  State<EquipmentListScreen> createState() => _EquipmentListScreenState();
}

class _EquipmentListScreenState extends State<EquipmentListScreen> {
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  final _scrollCtrl = ScrollController();

  Future<List<Equipment>>? _future;
  Timer? _debounce;

  // ---- Equipment List filter (id → name) ----
  bool _loadingLists = true;
  int? _selectedListId; // null = All
  final Map<int, String> _listNames = <int, String>{};

  @override
  void initState() {
    super.initState();
    _future = api.Api.getEquipments();
    _loadEquipmentLists();

    _searchCtrl.addListener(() {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 320), () {
        if (!mounted) return;
        _doSearch(); // always drive _future
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchFocus.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadEquipmentLists() async {
    setState(() => _loadingLists = true);
    try {
      // Typed fetch
      final List<EquipmentListModel> lists = await api.Api.getEquipmentLists();

      _listNames.clear();
      for (final e in lists) {
        final int? id = e.equipmentListId;
        // Pick the best human label you have on your model
        final String name =
            (e.nameEnglish ??
                    e.primaryUseEnglish ??
                    e.primaryUseArabic ??
                    e.nameArabic ??
                    '')
                .toString()
                .trim();

        if (id != null && id > 0 && name.isNotEmpty) {
          _listNames[id] = name;
        }
      }
    } catch (_) {
      // If the endpoint fails, the filter sheet will still show "All"
    } finally {
      if (mounted) setState(() => _loadingLists = false);
    }
  }

  String _escapeSql(String input) => input.replaceAll("'", "''");

  String _buildSql({required String term, int? listId}) {
    final t = _escapeSql(term.trim());
    final whereParts = <String>[];
    if (t.isNotEmpty) {
      whereParts.add("descEnglish LIKE '%$t%'");
    }
    if (listId != null) {
      whereParts.add("equipmentListId = $listId");
    }
    final where = whereParts.isEmpty ? '1 = 1' : whereParts.join(' AND ');
    return 'SELECT * FROM Equipments WHERE $where';
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 320), () {
      _doSearch(value);
    });
  }

  void _doSearch([String? raw]) {
    final term = (raw ?? _searchCtrl.text).trim();
    final listId = _selectedListId;

    setState(() {
      if (term.isEmpty && listId == null) {
        _future = api.Api.getEquipments();
      } else {
        final sql = _buildSql(term: term, listId: listId);
        _future = api.Api.advanceSearchEquipments(sql);
      }
    });
  }

  Future<void> _refresh() async {
    final f = api.Api.getEquipments();
    setState(() {
      _selectedListId = null;
      _future = f;
    });
    await f;
  }

  void _clearSearch() {
    _debounce?.cancel();
    _searchCtrl.clear();
    final f = api.Api.getEquipments();
    setState(() {
      _selectedListId = null;
      _future = f;
    });
  }

  Future<void> showFilterSheet(BuildContext context) async {
    final ids = _listNames.keys.toList()..sort();

    final int? chosen = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true, // allow tall + draggable
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) {
        return DraggableScrollableSheet(
          // starts ~middle; can be dragged up to near full screen
          initialChildSize: 0.55,
          minChildSize: 0.32,
          maxChildSize: 0.95,
          expand: false,
          builder: (ctx, scrollCtrl) {
            return Column(
              children: [
                const SizedBox(height: 6),
                // drag handle
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 8),

                // header
                ListTile(
                  leading: const Icon(Icons.list_alt),
                  title: Text(context.l10n.filters),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),

                // list (scrolls independently of the sheet)
                Expanded(
                  child: ListView(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.only(bottom: 16),
                    children: [
                      RadioListTile<int?>(
                        value: null,
                        groupValue: _selectedListId,
                        onChanged: (v) => Navigator.of(sheetCtx).pop(v),
                        title: Text(context.l10n.all),
                      ),

                      if (_loadingLists)
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: _MiniShimmer(
                            width: 220,
                            height: 20,
                            radius: 8,
                          ),
                        )
                      else
                        ...ids.map((id) {
                          return RadioListTile<int?>(
                            value: id,
                            groupValue: _selectedListId,
                            onChanged: (v) => Navigator.of(sheetCtx).pop(v),
                            title: Text(_listNames[id] ?? '#$id'),
                          );
                        }),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (!mounted) return;
    if (chosen == _selectedListId) return;
    setState(() => _selectedListId = chosen);
    _doSearch();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Taller header so search and the pill filter fit cleanly
    const topPad = 12.0, bottomPad = 16.0, gap = 12.0;
    const searchRowH = 55.0; // taller search
    const filterRowH = 81.0; // pill control height
    final headerHeight = topPad + searchRowH + gap + filterRowH + bottomPad;

    // Keyboard shortcuts
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
          appBar: AppBar(title: Text(context.l10n.equipmentTitle)),
          body: ScrollConfiguration(
            behavior: const _DesktopScrollBehavior(),
            child: RefreshIndicator(
              onRefresh: _refresh,
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
                            // Sticky header with larger height + pill filter
                            SliverPersistentHeader(
                              pinned: true,
                              delegate: _StickyHeader(
                                minExtent: headerHeight,
                                maxExtent: headerHeight,
                                child: Container(
                                  color: Theme.of(context).colorScheme.surface,
                                  padding: const EdgeInsets.fromLTRB(
                                    8,
                                    topPad,
                                    8,
                                    bottomPad,
                                  ),
                                  child: Glass(
                                    radius: 16,
                                    child: Padding(
                                      padding: const EdgeInsets.all(5),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          // SEARCH — big, borderless, comfy
                                          ConstrainedBox(
                                            constraints: const BoxConstraints(
                                              minHeight: searchRowH,
                                            ),
                                            child: TextField(
                                              controller: _searchCtrl,
                                              focusNode: _searchFocus,
                                              onChanged: _onChanged,
                                              textInputAction:
                                                  TextInputAction.search,
                                              decoration: InputDecoration(
                                                hintText: context
                                                    .l10n
                                                    .searchByDescriptionHint,
                                                prefixIcon: const Icon(
                                                  Icons.search,
                                                ),
                                                filled: true,
                                                fillColor: Theme.of(context)
                                                    .colorScheme
                                                    .surfaceVariant
                                                    .withOpacity(.45),
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 14,
                                                      vertical: 16, // taller
                                                    ),
                                                border: InputBorder.none,
                                                enabledBorder: InputBorder.none,
                                                focusedBorder: InputBorder.none,
                                                suffixIcon:
                                                    (_searchCtrl.text.isEmpty)
                                                    ? null
                                                    : IconButton(
                                                        onPressed: _clearSearch,
                                                        icon: const Icon(
                                                          Icons.clear,
                                                        ),
                                                      ),
                                              ),
                                            ),
                                          ),

                                          // FILTER — pill style (like before), stacked under
                                          Align(
                                            alignment: Alignment.centerLeft,
                                            child: _FilterPill(
                                              label: _selectedListId == null
                                                  ? context.l10n.filters
                                                  : (_listNames[_selectedListId!] ??
                                                        context.l10n.filters),
                                              onTap: () =>
                                                  showFilterSheet(context),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // Results
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
                                            context
                                                .l10n
                                                .failedToLoadEquipmentList,
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
                                            onPressed: () {
                                              final f = api.Api.getEquipments();
                                              setState(() => _future = f);
                                            },
                                            child: Text(
                                              context.l10n.actionRetry,
                                            ),
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
                                        context.l10n.noResults,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyLarge,
                                      ),
                                    ),
                                  );
                                }

                                if (!useGrid) {
                                  return SliverList(
                                    delegate: SliverChildBuilderDelegate(
                                      (context, index) {
                                        if (index.isOdd) {
                                          return const SizedBox(height: 0);
                                        }
                                        final i = index ~/ 2;
                                        return ListTileTheme(
                                          dense: true,
                                          minVerticalPadding: 0,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 2,
                                              ),
                                          child: _EquipmentListTile(
                                            e: items[i],
                                            listNames: _listNames,
                                          ),
                                        );
                                      },
                                      childCount: items.isEmpty
                                          ? 0
                                          : items.length * 2 - 1,
                                    ),
                                  );
                                } else {
                                  return SliverPadding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    sliver: SliverList(
                                      delegate: SliverChildBuilderDelegate(
                                        (context, index) {
                                          if (index.isOdd)
                                            return const SizedBox(height: 0);
                                          final i = index ~/ 2;
                                          return ListTileTheme(
                                            dense: true,
                                            minVerticalPadding: 0,
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 2,
                                                ),
                                            child: _EquipmentListTile(
                                              e: items[i],
                                              listNames: _listNames,
                                            ),
                                          );
                                        },
                                        childCount: items.isEmpty
                                            ? 0
                                            : items.length * 2 - 1,
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),

                            SliverToBoxAdapter(
                              child: SizedBox(
                                height:
                                    MediaQuery.of(context).padding.bottom + 5,
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
  const _EquipmentListTile({required this.e, required this.listNames});
  final Equipment e;
  final Map<int, String> listNames;

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

    final listId = e.equipmentListId ?? e.equipmentList?.equipmentListId;
    final listName = (listId != null) ? listNames[listId] : null;

    final subtitle =
        e.category?.detailNameEnglish ??
        listName ??
        e.equipmentList?.primaryUseEnglish ??
        '—';

    return AnimateIn(
      child: SlidableEquipmentTile(
        title: e.title,
        subtitle: subtitle,
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

// ---- Pill-like filter control (matches your previous style) ----
class _FilterPill extends StatelessWidget {
  const _FilterPill({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = cs.surfaceVariant.withOpacity(.45);
    final fg = cs.onSurfaceVariant;

    // Cap width so long labels ellipsize, but allow smaller pills to shrink.
    final maxWidth = MediaQuery.of(context).size.width * 0.66;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          minHeight: 48, // a touch smaller than before
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: fg.withOpacity(.18)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min, // <- hug content when short
            children: [
              const Icon(Icons.tune, size: 18),
              const SizedBox(width: 8),
              // Let text shrink if needed, ellipsize if too long
              Flexible(
                fit: FlexFit.loose,
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: fg),
            ],
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
      child: SizedBox.expand(child: child),
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

// Simple shimmer used in the filter sheet loading state (and available to reuse)
class _MiniShimmer extends StatefulWidget {
  const _MiniShimmer({this.width = 220, this.height = 20, this.radius = 8});
  final double width;
  final double height;
  final double radius;

  @override
  State<_MiniShimmer> createState() => _MiniShimmerState();
}

class _MiniShimmerState extends State<_MiniShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final t = _c.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(-1 + 2 * t, 0),
              end: Alignment(1 + 2 * t, 0),
              colors: [
                cs.surfaceVariant.withOpacity(.50),
                cs.surfaceVariant.withOpacity(.35),
                cs.surfaceVariant.withOpacity(.50),
              ],
              stops: const [0.25, 0.5, 0.75],
            ),
          ),
        );
      },
    );
  }
}

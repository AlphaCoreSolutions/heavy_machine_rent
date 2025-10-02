// lib/screens/home_screen.dart
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';

// === API ===
import 'package:heavy_new/core/api/api_handler.dart' as api;
import 'package:heavy_new/core/auth/auth_store.dart';

// MODELS
import 'package:heavy_new/core/models/equipment/equipment.dart';
import 'package:heavy_new/core/models/user/auth.dart';
import 'package:heavy_new/foundation/localization/l10n_extensions.dart';

// UI kit bits
import 'package:heavy_new/foundation/ui/ui_extras.dart';
import 'package:heavy_new/foundation/ui/ui_kit.dart';
import 'package:heavy_new/foundation/ui/app_icons.dart';

// Actions
import 'package:heavy_new/foundation/widgets/chat_action_button.dart';
import 'package:heavy_new/foundation/widgets/notification_bell.dart';

// Screens
import 'package:heavy_new/screens/equipment_screens/equipment_list_screen.dart';
import 'package:heavy_new/screens/equipment_screens/equipment_details_screen.dart';
import 'package:heavy_new/screens/auth_profile_screens/phone_auth_screen.dart';
import 'package:heavy_new/screens/super_admin_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Equipment>> _futureTop;
  int? _hoveredCard;

  @override
  void initState() {
    super.initState();
    _futureTop = api.Api.getEquipments();
  }

  // Compute responsive knobs from width
  ({
    double hPad,
    double vTop,
    double vBottom,
    double maxWidth,
    int columns,
    double gap,
    double aspect, // width / height for the row card
  })
  _layoutForWidth(double w) {
    final hPad = w >= 1600
        ? 40.0
        : (w >= 1280 ? 34.0 : (w >= 1024 ? 24.0 : 16.0));
    final vTop = w >= 1280 ? 18.0 : 16.0;
    final vBottom = w >= 1280 ? 28.0 : 24.0;

    final maxW = 1440.0;
    final gap = 12.0;

    late int cols;
    late double aspect;

    if (w >= 1600) {
      // Desktop XL → 4 across
      cols = 4;
      aspect = 2.20;
    } else if (w >= 1280) {
      // Desktop L → 3 across
      cols = 3;
      aspect = 2.05;
    } else if (w >= 760) {
      // Tablet / Laptop S → 2 across
      cols = 2;
      aspect = 1.80;
    } else {
      // Phones → 1 across
      cols = 1;
      aspect = 1.45;
    }

    return (
      hPad: hPad,
      vTop: vTop,
      vBottom: vBottom,
      maxWidth: maxW,
      columns: cols,
      gap: gap,
      aspect: aspect,
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _futureTop = api.Api.getEquipments();
    });
  }

  @override
  Widget build(BuildContext context) {
    return OfflineBanner(
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Theme.of(
            context,
          ).colorScheme.surface.withOpacity(0.65),
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
          flexibleSpace: ClipRect(
            // frosted glass
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(color: Colors.transparent),
            ),
          ),
          title: Text(
            context.l10n.appName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
          leadingWidth: 120,
          leading: Padding(
            padding: const EdgeInsets.only(left: 8),
            child: _AuthButton(),
          ),
          actions: [
            ValueListenableBuilder<AuthUser?>(
              valueListenable: AuthStore.instance.user,
              builder: (context, u, _) {
                final isSuperAdmin = u?.userTypeId == 17;
                if (!isSuperAdmin) return const SizedBox.shrink();
                return IconButton(
                  tooltip: context.l10n.admin,
                  icon: const Icon(Icons.admin_panel_settings),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const SuperAdminHubScreen(),
                      ),
                    );
                  },
                );
              },
            ),
            const NotificationsBell(),
            const SizedBox(width: 4),
            const ChatActionButton(),
          ],
        ),

        body: RefreshIndicator(
          onRefresh: _refresh,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final layout = _layoutForWidth(w);

              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: layout.maxWidth),
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      layout.hPad,
                      layout.vTop,
                      layout.hPad,
                      layout.vBottom,
                    ),
                    children: [
                      // HERO — responsive height, never overflows
                      LayoutBuilder(
                        builder: (context, bc) {
                          final bw = bc.maxWidth;
                          final isWide = bw >= 1100;
                          final heroH = isWide
                              ? 380.0
                              : (bw >= 720 ? 280.0 : 220.0);

                          return Stack(
                            children: [
                              // glow blob behind hero (subtle)
                              if (isWide)
                                Positioned.fill(
                                  child: IgnorePointer(
                                    child: Align(
                                      alignment: Alignment.topCenter,
                                      child: Container(
                                        width: bw * 0.7,
                                        height: heroH * 0.9,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            28,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                                  .withOpacity(0.14),
                                              blurRadius: 120,
                                              spreadRadius: 10,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              SizedBox(
                                height: heroH,
                                child: TiltHeroCard(
                                  title: context.l10n.heroTitle,
                                  subtitle: context.l10n.heroSubtitle,
                                  image: Image.asset(
                                    'lib/assets/hero.jpg',
                                    fit: BoxFit.cover,
                                  ),
                                  onPrimaryAction: () =>
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const EquipmentListScreen(),
                                        ),
                                      ),
                                  primaryLabel: context.l10n.findEquipment,
                                ),
                              ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 15),
                      SectionHeader(
                        title: context
                            .l10n
                            .popularEquipment, // 'Popular equipment'
                        action: GhostButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const EquipmentListScreen(),
                            ),
                          ),
                          icon: AIcon(
                            AppGlyph.search,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          child: Text(context.l10n.seeMore), // 'See more'
                        ),
                      ),

                      const SizedBox(height: 12),

                      // EQUIPMENT GRID — adaptive max-extent grid with hover scale + glow
                      FutureBuilder<List<Equipment>>(
                        future: _futureTop,
                        builder: (context, snap) {
                          if (snap.connectionState == ConnectionState.waiting) {
                            return const Column(
                              children: [
                                ShimmerTile(),
                                ShimmerTile(),
                                ShimmerTile(),
                              ],
                            );
                          }
                          if (snap.hasError) {
                            final cs = Theme.of(context).colorScheme;
                            return Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                children: [
                                  Text(
                                    context.l10n.couldNotLoadEquipment,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyLarge,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${snap.error}',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(color: cs.error),
                                  ),
                                  const SizedBox(height: 12),
                                  FilledButton(
                                    onPressed: () => setState(
                                      () =>
                                          _futureTop = api.Api.getEquipments(),
                                    ),
                                    child: Text(context.l10n.retry),
                                  ),
                                ],
                              ),
                            );
                          }

                          final items = (snap.data ?? []).take(24).toList();
                          if (items.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                context
                                    .l10n
                                    .noEquipmentYet, // 'No equipment yet.'
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            );
                          }

                          // EQUIPMENT GRID — 4/3/2/1 based on actual grid width
                          return LayoutBuilder(
                            builder: (ctx, gc) {
                              final gridW = gc.maxWidth;

                              // Breakpoints tuned for your row-card layout
                              final int cols;
                              final double aspect; // width / height
                              // in grid layout calculations:
                              if (gridW >= 1500) {
                                cols = 4;
                                aspect = 2.25;
                              } else if (gridW >= 1180) {
                                cols = 3;
                                aspect = 2.05;
                              } else if (gridW >= 760) {
                                cols = 2;
                                aspect = 1.85;
                              } else {
                                cols = 1;
                                aspect = 2.20;
                              }

                              return GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: items.length,
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: cols,
                                      mainAxisSpacing: 12,
                                      crossAxisSpacing: 12,
                                      childAspectRatio: aspect,
                                    ),
                                itemBuilder: (_, i) {
                                  final e = items[i];
                                  final String? primaryName =
                                      (e.coverPath?.isNotEmpty ?? false)
                                      ? e.coverPath
                                      : (e.equipmentImages
                                                ?.firstWhere(
                                                  (img) =>
                                                      (img.equipmentPath ?? '')
                                                          .isNotEmpty,
                                                  orElse: () =>
                                                      EquipmentImage(),
                                                )
                                                .equipmentPath ??
                                            e.equipmentList?.imagePath);
                                  final thumbCandidates =
                                      api.Api.equipmentImageCandidates(
                                        primaryName,
                                      );

                                  final isHovered = _hoveredCard == i;
                                  final hasHover = _hoveredCard != null;

                                  // Dramatic but tasteful :)
                                  final outerScale = isHovered
                                      ? 1.08
                                      : (hasHover ? 0.92 : 1.0);
                                  final outerOpacity = isHovered
                                      ? 1.0
                                      : (hasHover ? 0.55 : 1.0);

                                  return MouseRegion(
                                    onEnter: (_) =>
                                        setState(() => _hoveredCard = i),
                                    onExit: (_) =>
                                        setState(() => _hoveredCard = null),
                                    child: AnimatedOpacity(
                                      duration: const Duration(
                                        milliseconds: 140,
                                      ),
                                      curve: Curves.easeOut,
                                      opacity: outerOpacity,
                                      child: AnimatedScale(
                                        duration: const Duration(
                                          milliseconds: 160,
                                        ),
                                        curve: Curves.easeOutCubic,
                                        scale: outerScale,
                                        child: HoverScaleGlow(
                                          // keep your inner hover glow/scale for “light behind it”
                                          padding: const EdgeInsets.all(2),
                                          glowColor: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                          enableHover: true,
                                          onTap: () =>
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      EquipmentDetailsScreen(
                                                        equipmentId:
                                                            e.equipmentId ?? 0,
                                                      ),
                                                ),
                                              ),
                                          child: RowEquipmentCard(
                                            title: e.title,
                                            subtitle:
                                                e.category?.detailNameEnglish ??
                                                e
                                                    .equipmentList
                                                    ?.primaryUseEnglish ??
                                                '—',
                                            pricePerDay:
                                                e.rentPerDayDouble ?? 0,
                                            distanceKm: e.distanceKilo
                                                ?.toDouble(),
                                            image: DecoratedBox(
                                              decoration: BoxDecoration(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .surfaceContainerHighest,
                                              ),
                                              child: FallbackNetworkImage(
                                                candidates: thumbCandidates,
                                                placeholderColor:
                                                    Theme.of(context)
                                                        .colorScheme
                                                        .surfaceContainerHighest,
                                                fit: BoxFit
                                                    .cover, // ← back to cover
                                              ),
                                            ),

                                            onTap: () =>
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        EquipmentDetailsScreen(
                                                          equipmentId:
                                                              e.equipmentId ??
                                                              0,
                                                        ),
                                                  ),
                                                ),
                                            onRent: () =>
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        EquipmentDetailsScreen(
                                                          equipmentId:
                                                              e.equipmentId ??
                                                              0,
                                                        ),
                                                  ),
                                                ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class HoverScaleGlow extends StatefulWidget {
  const HoverScaleGlow({
    super.key,
    required this.child,
    this.onTap,
    this.radius = const BorderRadius.all(Radius.circular(18)),
    this.glowColor,
    this.enableHover = true,
    this.padding = const EdgeInsets.all(0),
  });

  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius radius;
  final Color? glowColor;
  final bool enableHover;
  final EdgeInsets padding;

  @override
  State<HoverScaleGlow> createState() => _HoverScaleGlowState();
}

class _HoverScaleGlowState extends State<HoverScaleGlow> {
  bool _hover = false;
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final glow = widget.glowColor ?? cs.primary;

    final scale = _down ? 0.985 : (_hover && widget.enableHover ? 1.035 : 1.0);

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          padding: widget.padding,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Soft radial glow layer behind the card
              AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                opacity: (_hover && widget.enableHover) ? 0.35 : 0.0,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: widget.radius,
                      boxShadow: [
                        BoxShadow(
                          color: glow.withAlpha((0.25 * 255).toInt()),
                          blurRadius: 28,
                          spreadRadius: 2,
                        ),
                      ],
                      gradient: RadialGradient(
                        colors: [
                          glow.withAlpha((0.25 * 255).toInt()),
                          glow.withAlpha(0),
                        ],
                        radius: 0.85,
                      ),
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),

              // Scaled child
              AnimatedScale(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOut,
                scale: scale,
                child: ClipRRect(
                  borderRadius: widget.radius,
                  child: widget.child,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, required this.action});

  final String title;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return LayoutBuilder(
      builder: (context, bc) {
        final titleText = Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        );

        final underline = Container(
          height: 2.5,
          width: 42,
          margin: const EdgeInsets.only(top: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            gradient: LinearGradient(
              colors: [cs.primary, cs.primary.withOpacity(0.25)],
            ),
          ),
        );

        final left = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [titleText, underline],
        );

        // Always inline; title flexes, button keeps its size.
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: left), // ← lets the title take remaining space
            const SizedBox(width: 10),
            action, // ← stays beside the title
          ],
        );
      },
    );
  }
}

class HomeEquipmentCard extends StatelessWidget {
  const HomeEquipmentCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.pricePerDay,
    required this.image,
    this.onTap,
    this.onRent,
  });

  final String title;
  final String subtitle;
  final double pricePerDay;
  final Widget image;
  final VoidCallback? onTap;
  final VoidCallback? onRent;

  String _fmtPrice(num v) {
    // keep simple; hook up to your own formatter if you have one
    if (v % 1 == 0) return v.toStringAsFixed(0);
    return v.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: cs.surface,
          border: Border.all(
            color: cs.outlineVariant.withAlpha((0.5 * 255).toInt()),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.06 * 255).toInt()),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest,
                        ),
                        child: FallbackNetworkImage(
                          candidates:
                              [], // Provide a valid list of image URLs here
                          fit: BoxFit.contain, // show full image
                        ),
                      ),
                    ),
                    // subtle top gradient for legibility if you add labels later
                    Positioned.fill(
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withAlpha((0.08 * 255).toInt()),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title + subtitle
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),

                    const SizedBox(height: 10),

                    // Price under distance (this is the key change)
                    const SizedBox(height: 6),
                    Text(
                      context.l10n.from, // single word “from”
                      style: t.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          context.l10n.pricePerDay(
                            _fmtPrice(pricePerDay),
                          ), // e.g., “$120 / day”
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        if (onRent != null)
                          SizedBox(
                            height: 30,
                            child: FilledButton.tonalIcon(
                              onPressed: onRent,
                              icon: const Icon(
                                Icons.shopping_cart_outlined,
                                size: 16,
                              ),
                              label: Text(
                                context.l10n.rent,
                                style: t.labelSmall,
                              ),
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
  }
}

class RowEquipmentCard extends StatelessWidget {
  const RowEquipmentCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.pricePerDay,
    required this.image,
    this.distanceKm,
    this.onTap,
    this.onRent,
  });

  final String title;
  final String subtitle;
  final double pricePerDay;
  final double? distanceKm;
  final Widget image;
  final VoidCallback? onTap;
  final VoidCallback? onRent;

  String _fmtPrice(num v) =>
      (v % 1 == 0) ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: cs.surface.withOpacity(0.92), // slight translucency
          border: Border.all(color: cs.outlineVariant.withOpacity(0.35)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
            // soft highlight (top edge) for glassiness
            BoxShadow(
              color: Colors.white.withOpacity(0.15),
              blurRadius: 0,
              spreadRadius: -1,
              offset: const Offset(0, 1),
            ),
          ],
        ),

        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: LayoutBuilder(
            builder: (context, bc) {
              final w = bc.maxWidth;

              // Responsive density flags (tuned for 4-up on desktop)
              final ultraTight = w < 260; // hide extras
              final compact = w < 300; // reduce paddings
              final comfy = w >= 340; // show everything

              // Left image width: proportion + clamps so it never dominates
              final imgW = (w * (compact ? 0.42 : 0.40)).clamp(130.0, 210.0);

              return Row(
                children: [
                  // LEFT: Image
                  SizedBox(
                    width: imgW,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // use what you already pass in from the grid (FallbackNetworkImage with BoxFit.cover)
                          image,
                          // optional soft top gradient
                          IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withOpacity(0.08),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // RIGHT: Content
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        10,
                        compact ? 8 : 10,
                        10,
                        compact ? 8 : 10,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: t.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.1,
                            ),
                          ),
                          const SizedBox(height: 3),

                          // Subtitle (hide on ultra tight)
                          if (!ultraTight)
                            Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: t.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),

                          SizedBox(height: compact ? 1 : 2),

                          Text(
                            context.l10n.from,
                            style: t.labelSmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),

                          Row(
                            children: [
                              Text(
                                context.l10n.pricePerDay(
                                  _fmtPrice(pricePerDay),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: t.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const Spacer(),
                              if (onRent != null)
                                SizedBox(
                                  height: comfy ? 30 : 28,
                                  child: FilledButton.icon(
                                    onPressed: onRent,
                                    icon: const Icon(
                                      Icons.shopping_cart_outlined,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                    label: Text(
                                      context.l10n.rent,
                                      style: t.labelSmall?.copyWith(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _AuthButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final isIn = AuthStore.instance.isLoggedIn;

    return TextButton.icon(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        visualDensity: VisualDensity.compact,
        foregroundColor: cs.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      icon: AIcon(isIn ? AppGlyph.logout : AppGlyph.login),
      label: Text(
        isIn ? context.l10n.actionLogout : context.l10n.actionLogin,
        style: t.labelLarge, // smaller, app-standard size
        overflow: TextOverflow.ellipsis,
      ),
      onPressed: () async {
        if (isIn) {
          await AuthStore.instance.logout();
          if (!context.mounted) return;
          AppSnack.info(context, context.l10n.signedOut);
        } else {
          final ok = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const PhoneAuthScreen()),
          );
          if (ok == true && context.mounted) {
            AppSnack.success(context, context.l10n.signedIn);
          }
        }
      },
    );
  }
}

class SiteBackdrop extends StatelessWidget {
  const SiteBackdrop({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Stack(
      children: [
        // Gradient wash
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  cs.surfaceContainerHighest.withOpacity(0.85),
                  cs.surface,
                  cs.surface,
                  cs.surfaceContainerHighest.withOpacity(0.9),
                ],
                stops: const [0.0, 0.45, 0.75, 1.0],
              ),
            ),
          ),
        ),
        // Subtle grid/lines (very faint)
        Positioned.fill(child: CustomPaint(painter: _FaintGridPainter())),
        // content
        child,
      ],
    );
  }
}

class _FaintGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF000000).withOpacity(0.035)
      ..strokeWidth = 1;
    const step = 48.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

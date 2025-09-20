// lib/screens/home_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';

// === API ===
import 'package:heavy_new/core/api/api_handler.dart' as api;
import 'package:heavy_new/core/auth/auth_store.dart';

// MODELS
import 'package:heavy_new/core/models/equipment/equipment.dart';
import 'package:heavy_new/core/models/user/auth.dart';

// UI kit bits
import 'package:heavy_new/foundation/ui/ui_extras.dart';
import 'package:heavy_new/foundation/ui/ui_kit.dart';
import 'package:heavy_new/foundation/ui/app_icons.dart';

// Actions
import 'package:heavy_new/foundation/widgets/chat_action_button.dart';
import 'package:heavy_new/foundation/widgets/notification_bell.dart';
import 'package:heavy_new/screens/app/notification_screen.dart';

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
    Notifications().getDeviceToken();
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
    final hPad = w >= 1280 ? 32.0 : (w >= 1024 ? 24.0 : 16.0);
    final vTop = 16.0;
    final vBottom = 24.0;
    final maxW = 1440.0;
    final gap = 12.0;

    late int cols;
    late double aspect;

    if (w >= 1440) {
      // Desktop XL → 4 across
      cols = 4;
      aspect = 1.80;
    } else if (w >= 1150) {
      // Desktop L → 3 across
      cols = 3;
      aspect = 1.70;
    } else if (w >= 760) {
      // Tablet / Laptop S → 2 across
      cols = 2;
      aspect = 1.60;
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
          title: const Text(
            'HeavyRent',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          centerTitle: true,
          backgroundColor: Theme.of(context).colorScheme.surface,
          actions: [
            IconButton(
              tooltip: AuthStore.instance.isLoggedIn ? 'Logout' : 'Login',
              icon: AIcon(
                AuthStore.instance.isLoggedIn
                    ? AppGlyph.logout
                    : AppGlyph.login,
              ),
              onPressed: () async {
                if (AuthStore.instance.isLoggedIn) {
                  await AuthStore.instance.logout();
                  if (!context.mounted) return;
                  AppSnack.info(context, 'Signed out');
                } else {
                  final ok = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(builder: (_) => const PhoneAuthScreen()),
                  );
                  if (ok == true && context.mounted) {
                    AppSnack.success(context, 'Signed in');
                  }
                }
              },
            ),
            // Admin button (conditionally visible)
            ValueListenableBuilder<AuthUser?>(
              valueListenable: AuthStore.instance.user,
              builder: (context, u, _) {
                final isSuperAdmin = u?.userTypeId == 17;
                if (!isSuperAdmin) return const SizedBox.shrink();
                return IconButton(
                  tooltip: 'Admin',
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
                          final heroH = bw >= 1100
                              ? 320.0
                              : (bw >= 720 ? 260.0 : 210.0);
                          return SizedBox(
                            height: heroH,
                            child: TiltHeroCard(
                              title: 'Heavy gear, light work',
                              subtitle:
                                  'Rent certified machines with drivers, on-demand.',
                              image: Image.asset(
                                'lib/assets/hero.jpg',
                                fit: BoxFit.cover,
                              ),
                              onPrimaryAction: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const EquipmentListScreen(),
                                ),
                              ),
                              primaryLabel: 'Find equipment',
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      SectionHeader(
                        title: 'Popular equipment',
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
                          child: const Text('See more'),
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
                                    'Could not load equipment',
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
                                    child: const Text('Retry'),
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
                                'No equipment yet.',
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
                              if (gridW >= 1400) {
                                // desktop XL
                                cols = 4;
                                aspect = 1.90;
                              } else if (gridW >= 1080) {
                                // desktop / laptop
                                cols = 3;
                                aspect = 1.80;
                              } else if (gridW >= 720) {
                                // tablet
                                cols = 2;
                                aspect = 1.65;
                              } else {
                                // phones
                                cols = 1;
                                aspect = 1.45;
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
                                            image: FallbackNetworkImage(
                                              candidates: thumbCandidates,
                                              placeholderColor: Theme.of(
                                                context,
                                              ).colorScheme.surfaceVariant,
                                              fit: BoxFit.cover,
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
                          color: glow.withOpacity(0.25),
                          blurRadius: 28,
                          spreadRadius: 2,
                        ),
                      ],
                      gradient: RadialGradient(
                        colors: [glow.withOpacity(0.25), glow.withOpacity(0.0)],
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
    return LayoutBuilder(
      builder: (context, bc) {
        final wrap = bc.maxWidth < 420;
        final titleW = Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        );

        final underline = Container(
          height: 3,
          width: 46,
          margin: const EdgeInsets.only(top: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            gradient: LinearGradient(
              colors: [cs.primary, cs.primary.withOpacity(0.3)],
            ),
          ),
        );

        final left = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [titleW, underline],
        );

        if (!wrap) {
          return Row(
            children: [
              Expanded(child: left),
              const SizedBox(width: 12),
              action,
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [left, const SizedBox(height: 10), action],
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
          border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
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
                    Positioned.fill(child: image),
                    // subtle top gradient for legibility if you add labels later
                    Positioned.fill(
                      child: IgnorePointer(
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

                    // Distance row
                    if (distanceKm != null) _DistanceChip(km: distanceKm!),

                    // Price under distance (this is the key change)
                    const SizedBox(height: 6),
                    Text(
                      'From ${_fmtPrice(pricePerDay)} / day',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    // Rent button (optional, small and unobtrusive)
                    if (onRent != null) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 34,
                        child: FilledButton.tonalIcon(
                          onPressed: onRent,
                          icon: const Icon(
                            Icons.shopping_cart_outlined,
                            size: 18,
                          ),
                          label: const Text('Rent'),
                        ),
                      ),
                    ],
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

class _DistanceChip extends StatelessWidget {
  const _DistanceChip({required this.km});
  final double km;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: cs.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.place_outlined, size: 14, color: cs.onSecondaryContainer),
          const SizedBox(width: 4),
          Text(
            '${km.toStringAsFixed(km >= 100 ? 0 : 1)} km',
            style: t.labelSmall?.copyWith(color: cs.onSecondaryContainer),
          ),
        ],
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
          color: cs.surface,
          border: Border.all(color: cs.outlineVariant.withOpacity(0.45)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 6),
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
              final imgW = (w * (compact ? 0.30 : 0.28)).clamp(100.0, 150.0);

              return Row(
                children: [
                  // LEFT: Image
                  SizedBox(
                    width: imgW,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        image,
                        Positioned.fill(
                          child: IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    Colors.black.withOpacity(0.05),
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
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: t.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.1,
                            ),
                          ),
                          const SizedBox(height: 4),

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

                          SizedBox(height: compact ? 6 : 8),

                          // Distance chip (hide on ultra tight)
                          if (!ultraTight && distanceKm != null)
                            _DistanceChip(km: distanceKm!),

                          SizedBox(height: compact ? 4 : 6),

                          // Price under distance
                          Text(
                            'From ${_fmtPrice(pricePerDay)} / day',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: t.titleSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),

                          const Spacer(),

                          // Small Rent button (hide if ultra tight)
                          if (!ultraTight && onRent != null)
                            Align(
                              alignment: Alignment.bottomRight,
                              child: SizedBox(
                                height: comfy ? 32 : 30,
                                child: FilledButton.tonalIcon(
                                  onPressed: onRent,
                                  icon: const Icon(
                                    Icons.shopping_cart_outlined,
                                    size: 18,
                                  ),
                                  label: const Text('Rent'),
                                ),
                              ),
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

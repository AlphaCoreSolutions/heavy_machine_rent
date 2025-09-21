// file: lib/ui/kit/ui_modern_extras.dart
// Extra-modern UI pieces: frosted glass, offline banner, shimmer skeletons,
// and a premium filter bottom sheet template.

import 'dart:ui';
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heavy_new/foundation/formatting/money.dart';
import 'package:heavy_new/foundation/ui/app_icons.dart';
import 'package:heavy_new/foundation/ui/app_theme.dart';
import 'package:heavy_new/foundation/ui/sensor_compat.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/gestures.dart'
    show PointerHoverEvent; // for MouseRegion onHover type

import 'ui_kit.dart';

// ————————————————————————————————————————————————————————————————
// Frosted GLASS container (iOS-grade blur + tint)
// ————————————————————————————————————————————————————————————————
class Glass extends StatelessWidget {
  const Glass({
    super.key,
    required this.child,
    this.blur = 20,
    this.opacity = 0.6,
    this.radius = 20,
    this.borderColor,
    this.background,
    this.padding,
    this.margin,
  });

  final Widget child;
  final double blur;
  final double opacity;
  final double radius;
  final Color? borderColor;
  final Color? background;
  final EdgeInsets? padding;
  final EdgeInsets? margin;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: margin,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(radius)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding ?? const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (background ?? cs.surface).withOpacity(opacity),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: (borderColor ?? cs.outline).withOpacity(0.35),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

// ————————————————————————————————————————————————————————————————
// Offline banner overlay (slides in at top when no network)
// ————————————————————————————————————————————————————————————————
class OfflineBanner extends StatefulWidget {
  const OfflineBanner({super.key, required this.child});
  final Widget child;

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner> {
  bool _offline = false;

  @override
  void initState() {
    super.initState();
    Connectivity().onConnectivityChanged.listen((res) {
      final isOffline = res.contains(ConnectivityResult.none);
      if (isOffline != _offline) setState(() => _offline = isOffline);
    });
    // initial status (non-blocking)
    Connectivity().checkConnectivity().then((res) {
      final isOffline = res.contains(ConnectivityResult.none);
      if (mounted) setState(() => _offline = isOffline);
    });
  }

  @override
  Widget build(BuildContext context) {
    final banner =
        SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Glass(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  radius: 14,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AIcon(
                        AppGlyph.info,
                        color: Theme.of(context).colorScheme.warning,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'You are offline',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ],
                  ),
                ),
              ),
            )
            .animate(target: _offline ? 1 : 0)
            .slideY(begin: -1, end: 0, duration: 260.ms, curve: Curves.easeOut)
            .fadeIn(duration: 260.ms);

    return Stack(
      children: [
        widget.child,
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: IgnorePointer(ignoring: !_offline, child: banner),
        ),
      ],
    );
  }
}

// ————————————————————————————————————————————————————————————————
// Shimmer skeleton tiles for loading lists/cards
// ————————————————————————————————————————————————————————————————
class ShimmerTile extends StatelessWidget {
  const ShimmerTile({super.key});

  @override
  Widget build(BuildContext context) {
    final base = Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        children: [
          Container(
            height: 64,
            width: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 14,
                  width: 180,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  height: 12,
                  width: 140,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return base
        .animate(onPlay: (c) => c.repeat())
        .shimmer(
          duration: 1400.ms,
          color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
        );
  }
}

// ————————————————————————————————————————————————————————————————
// Filter bottom sheet (modal_bottom_sheet) with brand controls
// ————————————————————————————————————————————————————————————————
Future<void> showFilterSheet(BuildContext context) {
  final cs = Theme.of(context).colorScheme;
  return showCupertinoModalBottomSheet(
    context: context,
    barrierColor: Colors.black.withOpacity(0.25),
    builder: (c) {
      return Material(
        color: cs.surface,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Filters',
                      style: Theme.of(c).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    GhostButton(
                      onPressed: () => Navigator.of(c).maybePop(),
                      child: const Text('Close'),
                      icon: AIcon(AppGlyph.close),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Example chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    TonalIconChip(
                      label: 'Crane',
                      icon: AIcon(AppGlyph.truck, color: cs.onPrimaryContainer),
                    ),
                    TonalIconChip(
                      label: 'Loader',
                      icon: AIcon(AppGlyph.truck, color: cs.onPrimaryContainer),
                    ),
                    TonalIconChip(
                      label: 'With Driver',
                      icon: AIcon(AppGlyph.user, color: cs.onPrimaryContainer),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                const AInput(
                  label: 'From Date',
                  glyph: AppGlyph.calendar,
                  hint: 'YYYY-MM-DD',
                ),
                const SizedBox(height: 12),
                const AInput(
                  label: 'To Date',
                  glyph: AppGlyph.calendar,
                  hint: 'YYYY-MM-DD',
                ),
                const SizedBox(height: 20),
                BrandButton(
                  onPressed: () {
                    Navigator.of(c).maybePop();
                    AppSnack.success(context, 'Filters applied');
                  },
                  icon: AIcon(
                    AppGlyph.filter,
                    color: Colors.white,
                    selected: true,
                  ),
                  child: const Text('Apply Filters'),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

// ======================================================================
// SLIDABLE EQUIPMENT LIST TILE
// Requires: flutter_slidable
// ======================================================================

class SlidableEquipmentTile extends StatelessWidget {
  const SlidableEquipmentTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.pricePerDay,
    this.imageWidget, // 🔹 new (preferred)
    this.imageUrl, // (legacy) optional; keep for backward compat
    this.rating,
    this.distanceKm,
    this.isFavorite = false,
    this.onFavoriteToggle,
    this.onShare,
    this.onRent,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final double pricePerDay;
  final Widget? imageWidget; // 🔹 new
  final String? imageUrl; // (legacy)
  final double? rating;
  final double? distanceKm;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onShare;
  final VoidCallback? onRent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final card = Glass(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      radius: 18,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 86,
              height: 86,
              child:
                  imageWidget ??
                  (imageUrl == null
                      ? Container(
                          color: cs.surfaceVariant,
                          child: const Icon(Icons.broken_image),
                        )
                      : Image.network(
                          imageUrl!,
                          fit: BoxFit.cover,
                          loadingBuilder: (c, w, p) => p == null
                              ? w
                              : Container(color: cs.surfaceVariant),
                          errorBuilder: (_, __, ___) => Container(
                            color: cs.surfaceVariant,
                            child: const Icon(Icons.broken_image),
                          ),
                        )),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // keep text from overflowing
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (rating != null) ...[
                      AIcon(
                        LucideIcons.star as AppGlyph,
                        size: 16,
                        color: cs.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        rating!.toStringAsFixed(1),
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(width: 12),
                    ],
                    if (distanceKm != null) ...[
                      AIcon(
                        AppGlyph.mapPin,
                        size: 16,
                        color: cs.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${distanceKm!.toStringAsFixed(1)} km',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ],
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        Money.per('day', pricePerDay),
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: cs.onPrimaryContainer,
                          fontWeight: FontWeight.w700,
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
    );

    final content = PressableScale(onTap: onTap, child: card);

    return Slidable(
      key: ValueKey(title),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.65,
        children: [
          SlidableAction(
            onPressed: (_) {
              try {
                onFavoriteToggle?.call();
                AppSnack.success(
                  context,
                  isFavorite ? 'Removed from favorites' : 'Added to favorites',
                );
              } catch (_) {
                AppSnack.error(context, 'Could not update favorite');
              }
            },
            backgroundColor: cs.primaryContainer,
            foregroundColor: cs.onPrimaryContainer,
            icon: isFavorite ? Icons.favorite : Icons.favorite_border,
            label: 'Favorite',
            borderRadius: BorderRadius.circular(14),
          ),
          const SizedBox(width: 8),
          SlidableAction(
            onPressed: (_) {
              try {
                onShare?.call();
                AppSnack.info(context, 'Share link copied');
              } catch (_) {
                AppSnack.error(context, 'Share failed');
              }
            },
            backgroundColor: cs.surfaceVariant,
            foregroundColor: cs.onSurface,
            icon: Icons.ios_share,
            label: 'Share',
            borderRadius: BorderRadius.circular(14),
          ),
          const SizedBox(width: 8),
          SlidableAction(
            onPressed: (_) {
              try {
                onRent?.call();
                AppSnack.success(context, 'Request started');
              } catch (_) {
                AppSnack.error(context, 'Could not start request');
              }
            },
            backgroundColor: cs.primary,
            foregroundColor: Colors.white,
            icon: Icons.shopping_bag,
            label: 'Rent',
            borderRadius: BorderRadius.circular(14),
          ),
        ],
      ),
      child: content,
    );
  }
}

// ======================================================================
// TILT / PARALLAX HERO CARD (sensors_plus)
// ======================================================================

class TiltHeroCard extends StatefulWidget {
  const TiltHeroCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.image,
    this.height = 180,
    this.onPrimaryAction,
    this.primaryLabel = 'Find equipment',
  });

  final String title;
  final String subtitle;
  final Widget? image;
  final double height;
  final VoidCallback? onPrimaryAction;
  final String primaryLabel;

  @override
  State<TiltHeroCard> createState() => _TiltHeroCardState();
}

class _TiltHeroCardState extends State<TiltHeroCard> {
  StreamSubscription<AccelerometerEvent>? _sub;
  double _dx = 0, _dy = 0; // -1..1

  @override
  void initState() {
    super.initState();
    if (sensorsSupported) {
      _sub = accelerometer$().listen((e) {
        final nx = (e.y / 9.8).clamp(-0.9, 0.9);
        final ny = (e.x / 9.8).clamp(-0.9, 0.9);
        if (mounted) {
          setState(() {
            _dx = nx.toDouble();
            _dy = ny.toDouble();
          });
        }
      }, onError: (_) {});
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _hoverParallax(PointerHoverEvent e) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final p = box.globalToLocal(e.position);
    final w = box.size.width, h = box.size.height;
    // Map cursor position to [-0.9, 0.9]
    final dx = ((p.dx / w) * 2 - 1).clamp(-0.9, 0.9);
    final dy = ((p.dy / h) * 2 - 1).clamp(-0.9, 0.9);
    setState(() {
      _dx = dx;
      _dy = dy;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final depth = 0.002;
    final m = Matrix4.identity()
      ..setEntry(3, 2, depth)
      ..rotateX(_dy * 0.12)
      ..rotateY(-_dx * 0.12);

    final content = Container(
      height: widget.height,
      decoration: BoxDecoration(
        gradient: cs.brandGradient,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          if (widget.image != null)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.12),
                    BlendMode.darken,
                  ),
                  child: widget.image!,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const Spacer(),
                BrandButton(
                  onPressed: widget.onPrimaryAction,
                  icon: AIcon(
                    AppGlyph.search,
                    color: Colors.white,
                    selected: true,
                  ),
                  child: Text(widget.primaryLabel),
                ),
              ],
            ),
          ),
          // light glint that follows tilt
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 120),
                alignment: Alignment(_dx.clamp(-1, 1), -_dy.clamp(-1.0, 1.0)),
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withOpacity(0.18),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    // Pointer hover fallback works on desktop/web; mobile still uses sensors.
    return MouseRegion(
      onHover: _hoverParallax,
      onExit: (_) => setState(() {
        _dx = 0;
        _dy = 0;
      }),
      child: PressableScale(
        child: Transform(
          transform: m,
          alignment: Alignment.center,
          child: content,
        ),
      ),
    );
  }
}

/* Usage:
TiltHeroCard(
  title: 'Heavy gear, light work',
  subtitle: 'Rent certified machines with drivers, on-demand.',
  image: Image.asset('assets/hero.jpg', fit: BoxFit.cover),
  onPrimaryAction: () => AppSnack.info(context, 'Search coming up'),
)
*/

// ======================================================================
// DYNAMIC COLOR (Material You) – optional adaptive theming
// Requires: dynamic_color
// ======================================================================

ThemeData _lightFromDynamic(ColorScheme? dyn) {
  if (dyn == null) return AppTheme.light();
  final cs = dyn.harmonized();
  final theme = FlexThemeData.light(
    useMaterial3: true,
    colorScheme: cs,
    subThemesData: const FlexSubThemesData(
      defaultRadius: 16,
      splashType: FlexSplashType.inkSparkle,
    ),
    visualDensity: VisualDensity.comfortable,
    fontFamily: GoogleFonts.inter().fontFamily,
  );
  return theme.copyWith(
    textTheme: GoogleFonts.interTextTheme().apply(
      bodyColor: cs.onSurface,
      displayColor: cs.onSurface,
    ),
  );
}

ThemeData _darkFromDynamic(ColorScheme? dyn) {
  if (dyn == null) return AppTheme.dark();
  final cs = dyn.harmonized();
  final theme = FlexThemeData.dark(
    useMaterial3: true,
    colorScheme: cs,
    subThemesData: const FlexSubThemesData(
      defaultRadius: 16,
      splashType: FlexSplashType.inkSparkle,
    ),
    visualDensity: VisualDensity.comfortable,
    fontFamily: GoogleFonts.inter().fontFamily,
  );
  return theme.copyWith(
    textTheme: GoogleFonts.interTextTheme().apply(
      bodyColor: cs.onSurface,
      displayColor: cs.onSurface,
    ),
  );
}

/// Wrap your MaterialApp with this to prefer system dynamic colors on Android 12+,
/// while falling back to your brand theme elsewhere.
class AdaptiveApp extends StatelessWidget {
  const AdaptiveApp({super.key, required this.home});
  final Widget home;

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: _lightFromDynamic(lightDynamic),
          darkTheme: _darkFromDynamic(darkDynamic),
          themeMode: ThemeMode.system,
          home: home,
        );
      },
    );
  }
}

class FallbackNetworkImage extends StatefulWidget {
  const FallbackNetworkImage({
    super.key,
    required this.candidates,
    this.headers,
    this.placeholderColor,
    this.fit = BoxFit.cover,
  });

  final List<String> candidates;
  final Map<String, String>? headers;
  final Color? placeholderColor;
  final BoxFit fit;

  @override
  State<FallbackNetworkImage> createState() => _FallbackNetworkImageState();
}

class _FallbackNetworkImageState extends State<FallbackNetworkImage> {
  int _i = 0;

  @override
  Widget build(BuildContext context) {
    final bg =
        widget.placeholderColor ?? Theme.of(context).colorScheme.surfaceVariant;

    if (widget.candidates.isEmpty) {
      return Container(color: bg, child: const Icon(Icons.broken_image));
    }
    final url = widget.candidates[_i];
    if (kDebugMode) debugPrint('Image try #$_i -> $url');

    return CachedNetworkImage(
      imageUrl: url,
      httpHeaders: widget.headers,
      fit: widget.fit,
      placeholder: (_, __) => Container(color: bg),
      errorWidget: (_, __, ___) {
        if (_i + 1 < widget.candidates.length) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _i += 1);
          });
          return Container(color: bg);
        }
        return Container(color: bg, child: const Icon(Icons.broken_image));
      },
    );
  }
}

// Compact, modern dock bottom bar (no overflow, RTL-aware)
// Same API: ModernBottomBar + ModernNavItem

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:Ajjara/foundation/ui/app_icons.dart';
import 'package:Ajjara/foundation/ui/ui_extras.dart'; // Glass, PressableScale, AppSnack
import 'package:Ajjara/foundation/ui/ui_kit.dart'; // AIcon

class ModernNavItem {
  const ModernNavItem({required this.glyph, required this.label});
  final AppGlyph glyph;
  final String label;
}

class ModernBottomBar extends StatelessWidget {
  const ModernBottomBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onChanged,
    this.height = 84,
    this.elevation = 16,
  }) : assert(items.length >= 2 && items.length <= 5, 'Use 2–5 items');

  final List<ModernNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onChanged;
  final double height;
  final double elevation;

  static const _outerPad = EdgeInsets.fromLTRB(12, 4, 12, 4.1); // tighter

  @override
  Widget build(BuildContext context) {
    final shortest = MediaQuery.sizeOf(context).shortestSide;
    final isPhone = shortest < 600;

    // On phones, cap to a compact height; still respect SafeArea.
    final baseH = isPhone ? math.min(height, 84.0) : height;
    final h = baseH.clamp(105.0, 150.0);

    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: SizedBox(
        height: h,
        child: Padding(
          padding: _outerPad,
          child: Glass(
            opacity: 0.58,
            radius: 20, // slightly smaller radius
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              clipBehavior: Clip.hardEdge,
              child: _Dock(
                items: items,
                currentIndex: currentIndex,
                onChanged: onChanged,
                height: h - _outerPad.vertical,
                background: cs.surface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Dock extends StatelessWidget {
  const _Dock({
    required this.items,
    required this.currentIndex,
    required this.onChanged,
    required this.height,
    required this.background,
  });

  final List<ModernNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onChanged;
  final double height;
  final Color background;

  static const _vPad = 0; // less vertical chrome
  static const _hPad = 6.0;

  @override
  Widget build(BuildContext context) {
    // Adaptive metrics — compact ranges
    final t = ((height - 64.0) / (120.0 - 64.0)).clamp(0.0, 1.0);
    double iconSize = 18 + 4 * t; // 18–22
    double activeIconSize = iconSize + 1; // tiny pop
    double labelSize = 11 + 1.5 * t; // 11–12.5
    double gap = 4 + 2 * t; // 4–6
    double itemVPad = 5 + 4 * t; // 5–9

    final scaler = MediaQuery.textScalerOf(context);
    labelSize = scaler.scale(labelSize);

    final innerH = height - _vPad * 2;
    final approxTextH = labelSize * 1.1;
    final needed = activeIconSize + gap + approxTextH + itemVPad * 2;

    // Fit content to available height (prevents any overflow)
    final fit = (innerH / needed).clamp(0.0, 1.0);
    iconSize *= fit;
    activeIconSize *= fit;
    labelSize *= fit;
    gap *= fit;
    itemVPad *= fit;

    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(vertical: 0, horizontal: _hPad),
      child: Row(
        children: List.generate(items.length, (i) {
          final active = currentIndex == i;
          return Expanded(
            child: _DockItem(
              item: items[i],
              active: active,
              iconSize: iconSize,
              activeIconSize: activeIconSize,
              labelSize: labelSize,
              gap: gap,
              vPad: itemVPad,
              onTap: () async {
                try {
                  HapticFeedback.lightImpact();
                  onChanged(i);
                } catch (_) {
                  if (context.mounted) {
                    AppSnack.error(context, 'Could not switch tab');
                  }
                }
              },
            ),
          );
        }),
      ),
    );
  }
}

class _DockItem extends StatelessWidget {
  const _DockItem({
    required this.item,
    required this.active,
    required this.iconSize,
    required this.activeIconSize,
    required this.labelSize,
    required this.gap,
    required this.vPad,
    required this.onTap,
  });

  final ModernNavItem item;
  final bool active;
  final double iconSize;
  final double activeIconSize;
  final double labelSize;
  final double gap;
  final double vPad;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final chip = AnimatedContainer(
      duration: 180.ms,
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.symmetric(vertical: vPad, horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12), // tighter
        gradient: active
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  cs.primary.withOpacity(0.14),
                  cs.primary.withOpacity(0.08),
                ],
              )
            : null,
        border: active
            ? Border.all(color: cs.primary.withOpacity(0.18), width: 0.8)
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AIcon(
                item.glyph,
                style: active ? AppIconStyle.filled : AppIconStyle.outline,
                size: active ? activeIconSize : iconSize,
                color: active ? cs.primary : cs.onSurfaceVariant,
                selected: active,
              )
              .animate(target: active ? 1 : 0)
              .scale(
                begin: const Offset(0.92, 0.92),
                end: const Offset(1.0, 1.0),
                duration: 140.ms,
                curve: Curves.easeOut,
              ),
          SizedBox(height: gap),
          AnimatedDefaultTextStyle(
            duration: 140.ms,
            curve: Curves.easeOut,
            style: Theme.of(context).textTheme.labelMedium!.copyWith(
              fontSize: labelSize,
              fontWeight: FontWeight.w700,
              color: active ? cs.primary : cs.onSurfaceVariant,
              height: 1.0,
            ),
            child: Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.fade,
              softWrap: false,
              textHeightBehavior: const TextHeightBehavior(
                applyHeightToFirstAscent: false,
                applyHeightToLastDescent: false,
              ),
            ),
          ),
        ],
      ),
    );

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 136), // narrower chip
        child: PressableScale(scale: 0.97, onTap: onTap, child: chip),
      ),
    );
  }
}

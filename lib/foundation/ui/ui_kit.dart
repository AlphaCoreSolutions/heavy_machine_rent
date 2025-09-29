// file: lib/ui/kit/ui_kit.dart
// Modern UI kit wired to your white+green brand theme.
// Includes: theme role helpers, premium snackbars, animated buttons, input field wrapper,
// and motion utilities for list/page reveals.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:heavy_new/foundation/ui/app_icons.dart';

// ————————————————————————————————————————————————————————————————
// THEME ROLES (success, warning, info) + gradient helper
// ————————————————————————————————————————————————————————————————
extension RoleColors on ColorScheme {
  Color get success => const Color(0xFF12B76A);
  Color get warning => const Color(0xFFF59E0B);
  Color get errorStrong => const Color(0xFFEF4444);
  Color get info => const Color(0xFF0EA5E9);
}

extension BrandGradients on ColorScheme {
  LinearGradient get brandGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary.withOpacity(0.98), primaryContainer.withOpacity(0.98)],
  );
}

// ————————————————————————————————————————————————————————————————
// PREMIUM SNACKBAR / TOAST (non-blocking, swipe to dismiss)
// ————————————————————————————————————————————————————————————————

class AppSnack {
  static void _showSnackBar(
    BuildContext context, {
    required Widget content,
    Duration duration = const Duration(seconds: 3),
    Color? bg,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    final snack = SnackBar(
      content: content,
      duration: duration,
      behavior: SnackBarBehavior.floating,
      dismissDirection: DismissDirection.up,
      backgroundColor:
          bg ?? Theme.of(context).colorScheme.surface.withOpacity(0.98),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.all(12),
      // If your Flutter version supports this, uncomment to pin at top:
      // anchorOrigin: SnackBarAnchorOrigin.top,
    );

    // Schedule for next frame so it never clashes with a push/pop
    WidgetsBinding.instance.addPostFrameCallback((_) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(snack);
    });
  }

  static void show(
    BuildContext context, {
    required String message,
    String? title,
    AppGlyph glyph = AppGlyph.check,
    Color? color,
    Duration duration = const Duration(seconds: 3),
  }) {
    final theme = Theme.of(context);
    _showSnackBar(
      context,
      duration: duration,
      bg: theme.colorScheme.surface.withOpacity(0.98),
      content: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2.0, right: 8),
            child: Icon(
              // If AIcon is a widget, use that instead
              Icons
                  .check, // or build AIcon(glyph, color: color ?? theme.colorScheme.primary)
              size: 20,
              color: color ?? theme.colorScheme.primary,
            ),
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null)
                  Text(title, style: theme.textTheme.titleSmall),
                Text(message, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static void success(BuildContext c, String m, {String? title}) => show(
    c,
    title: title ?? 'Success',
    message: m,
    glyph: AppGlyph.check,
    color: Theme.of(c).colorScheme.primary,
  );

  static void error(BuildContext c, String m, {String? title}) => show(
    c,
    title: title ?? 'Error',
    message: m,
    glyph: AppGlyph.close,
    color: Theme.of(c).colorScheme.error,
  );

  static void info(BuildContext c, String m, {String? title}) => show(
    c,
    title: title ?? 'Info',
    message: m,
    glyph: AppGlyph.info,
    color: Theme.of(c).colorScheme.secondary,
  );
}

// ————————————————————————————————————————————————————————————————
// PRESSABLE SCALE (micro-interaction + haptics)
// ————————————————————————————————————————————————————————————————
class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.97,
    this.enableHaptics = true,
    this.duration = const Duration(milliseconds: 120),
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final bool enableHaptics;
  final Duration duration;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
    value: 1,
  );
  late final Animation<double> _anim =
      Tween<double>(begin: 1, end: widget.scale).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Curves.easeOut,
          reverseCurve: Curves.easeIn,
        ),
      );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.reverse(),
      onTapCancel: () => _controller.forward(),
      onTapUp: (_) async {
        _controller.forward();
        if (widget.enableHaptics) HapticFeedback.lightImpact();
        widget.onTap?.call();
      },
      child: AnimatedBuilder(
        animation: _anim,
        builder: (_, child) =>
            Transform.scale(scale: _anim.value, child: child),
        child: widget.child,
      ),
    );
  }
}

// ————————————————————————————————————————————————————————————————
// BUTTONS: Brand (gradient), Ghost, Tonal Icon
// ————————————————————————————————————————————————————————————————
class BrandButton extends StatelessWidget {
  const BrandButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.icon,
    this.height = 52,
    this.radius = 16,
    this.gradient,
    this.padding = const EdgeInsets.symmetric(horizontal: 8),
  });

  final VoidCallback? onPressed;
  final Widget child;
  final Widget? icon;
  final double height;
  final double radius;
  final EdgeInsets padding;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final btn = Container(
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: gradient ?? cs.brandGradient,
        boxShadow: [
          BoxShadow(
            color: cs.primary.withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[icon!, const SizedBox(width: 5)],
            DefaultTextStyle.merge(
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
              child: child,
            ),
          ],
        ),
      ),
    );

    return PressableScale(onTap: onPressed, child: btn)
        .animate()
        .fadeIn(duration: 220.ms)
        .moveY(begin: 6, end: 0, curve: Curves.easeOutCubic);
  }
}

class GhostButton extends StatelessWidget {
  const GhostButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.icon,
    this.height = 48,
    this.radius = 14,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final Widget? icon;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final btn = Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: cs.surface.withOpacity(0.7),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: cs.outline.withOpacity(0.8), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[icon!, const SizedBox(width: 10)],
          DefaultTextStyle.merge(
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: cs.primary),
            child: child,
          ),
        ],
      ),
    );
    return PressableScale(onTap: onPressed, child: btn);
  }
}

class TonalIconChip extends StatelessWidget {
  const TonalIconChip({
    super.key,
    required this.label,
    required this.icon,
    this.maxWidth,
  });

  final String label;
  final Widget icon;
  final double? maxWidth; // <- NEW

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        const SizedBox(width: 6),
        // Important: ellipsize the text
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: cs.onPrimaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );

    final body = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: content,
    );

    // Clamp width so very long labels don’t stretch the row
    return maxWidth == null
        ? body
        : ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth!),
            child: body,
          );
  }
}

// ————————————————————————————————————————————————————————————————
// INPUTS: AInput (brand-friendly TextFormField)
// ————————————————————————————————————————————————————————————————

class AInput extends StatelessWidget {
  const AInput({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.glyph,
    this.keyboardType,
    this.textInputAction,
    this.obscure = false,
    this.onChanged,
    this.validator,
    this.minLines,
    this.maxLines = 1,
    this.onSubmitted, // NEW
    this.onEditingComplete, // NEW
    this.readOnly = false, // NEW (useful for date pickers)
    this.onTap, // NEW (useful for date pickers)
    this.inputFormatters,
  });

  final TextEditingController? controller;
  final List<TextInputFormatter>? inputFormatters;
  final String? label;
  final String? hint;
  final AppGlyph? glyph;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscure;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;
  final int? minLines;
  final int maxLines;

  // NEW:
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onEditingComplete;
  final bool readOnly;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final effectiveMaxLines = obscure ? 1 : maxLines;
    final effectiveMinLines = obscure ? 1 : minLines;

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscure,
      minLines: effectiveMinLines,
      maxLines: effectiveMaxLines,
      readOnly: readOnly,
      onTap: onTap,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted, // ← wired
      onEditingComplete: onEditingComplete,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: glyph == null ? null : AIcon(glyph!),
      ),
      validator: validator,
    );
  }
}

// ————————————————————————————————————————————————————————————————
// MOTION HELPERS: AnimateIn + stagger extension for lists
// ————————————————————————————————————————————————————————————————
class AnimateIn extends StatelessWidget {
  const AnimateIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offsetY = 12,
  });

  final Widget child;
  final Duration delay;
  final double offsetY;

  @override
  Widget build(BuildContext context) {
    return child
        .animate(delay: delay)
        .fadeIn(duration: 260.ms, curve: Curves.easeOut)
        .moveY(
          begin: offsetY,
          end: 0,
          duration: 260.ms,
          curve: Curves.easeOutCubic,
        );
  }
}

extension Stagger on List<Widget> {
  List<Widget> staggered({Duration initial = Duration.zero, int stepMs = 40}) {
    return asMap().entries
        .map(
          (e) => AnimateIn(
            delay: initial + Duration(milliseconds: e.key * stepMs),
            child: e.value,
          ),
        )
        .toList();
  }
}

// ————————————————————————————————————————————————————————————————
// QUICK DEMO WIDGETS (can be deleted): Cards/Headers matching theme
// ————————————————————————————————————————————————————————————————
class HeroCard extends StatelessWidget {
  const HeroCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon,
  });
  final String title;
  final String subtitle;
  final AppGlyph? icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: cs.brandGradient,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            children: [
              if (icon != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: AIcon(
                    icon!,
                    color: Colors.white,
                    size: 28,
                    selected: true,
                  ),
                ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 280.ms)
        .moveY(begin: 10, end: 0, curve: Curves.easeOutCubic);
  }
}

// ————————————————————————————————————————————————————————————————
// USAGE EXAMPLES (copy into your screens)
// ————————————————————————————————————————————————————————————————
/*
// Buttons
BrandButton(
  onPressed: () => AppSnack.success(context, 'Your request has been sent'),
  icon: AIcon(AppGlyph.contract, color: Colors.white, selected: true),
  child: const Text('Rent Now'),
);

GhostButton(
  onPressed: () {},
  icon: AIcon(AppGlyph.filter, color: Theme.of(context).colorScheme.primary),
  child: const Text('Filter'),
);

// Inputs
AInput(
  label: 'From Date',
  hint: 'YYYY-MM-DD',
  glyph: AppGlyph.calendar,
);

// Stagger list
final children = [for (var i = 0; i < 10; i++) ListTile(title: Text('Item $i'))];
Column(children: children.staggered(initial: 100.ms, stepMs: 40));

// Snackbar
AppSnack.info(context, 'We saved your changes');
*/

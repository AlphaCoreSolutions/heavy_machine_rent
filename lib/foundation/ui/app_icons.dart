// lib/ui/foundation/app_icons.dart
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Semantic names you’ll reuse across the app.
enum AppGlyph {
  search,
  filter,
  calendar,
  mapPin,
  truck,
  file,
  upload,
  image,
  plus,
  edit,
  delete_,
  check,
  close,
  user,
  organization,
  terms,
  request,
  contract,
  info,
  route,
  certificate,
  refresh,
  mail,
  phone,
  money,
  save,
  people,
  logout,
  moon,
  globe,
  Settings,
  send,
  login,
  back,
  arrowRight,
  add,
  sort,
  arrowUp,
  arrowDown,
  invoice,
  notifications,
  chat,
  bell,
  attachment,
  note,
  shield,
  userGroup,
  dashboard,
  lock,
  pin,
  fileText,
  all,
}

/// Visual style intent for families that support weights.
enum AppIconStyle { outline, filled, duotone, bold }

/// Global icon sizing tokens
class AppIconTokens {
  static const double xs = 16, sm = 20, md = 24, lg = 28, xl = 32, xxl = 40;
  static const Duration micro = Duration(milliseconds: 160);
  static const Duration fast = Duration(milliseconds: 220);
}

/// Unified icon widget: animates style/selection changes.
class AIcon extends StatelessWidget {
  const AIcon(
    this.glyph, {
    super.key,
    this.style = AppIconStyle.outline,
    this.size = AppIconTokens.md,
    this.color,
    this.selected = false,
    this.semanticLabel,
  });

  final AppGlyph glyph;
  final AppIconStyle style;
  final double size;
  final Color? color;
  final bool selected;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final themeColor = color ?? IconTheme.of(context).color;
    final iconData = _resolve(glyph, style, selected); // <- IconData only

    return Semantics(
      label: semanticLabel ?? glyph.name,
      child: AnimatedSwitcher(
        duration: AppIconTokens.fast,
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: Tween(begin: 0.95, end: 1.0).animate(anim),
            child: child,
          ),
        ),
        child: Icon(
          // we construct the Icon widget here, not in _resolve
          iconData,
          key: ValueKey('${glyph.name}-${style.name}-${selected.toString()}'),
          size: size,
          color: themeColor,
        ),
      ),
    );
  }

  /// Map of semantic glyphs → IconData (no widgets here).
  IconData _resolve(AppGlyph g, AppIconStyle s, bool sel) {
    // Helper to pick a Phosphor style
    PhosphorIconsStyle pStyleFor(bool selected, AppIconStyle style) {
      if (selected) return PhosphorIconsStyle.fill;
      switch (style) {
        case AppIconStyle.filled:
          return PhosphorIconsStyle.fill;
        case AppIconStyle.bold:
          return PhosphorIconsStyle.bold;
        case AppIconStyle.duotone:
          return PhosphorIconsStyle.duotone;
        case AppIconStyle.outline:

        // ignore: unreachable_switch_default
        default:
          return PhosphorIconsStyle.regular;
      }
    }

    switch (g) {
      case AppGlyph.search:
        return LucideIcons.search; // crisp outline
      case AppGlyph.filter:
        return Iconsax.filter;
      case AppGlyph.calendar:
        return PhosphorIcons.calendar(pStyleFor(sel, s));
      case AppGlyph.mapPin:
        // Filled when selected, outline when not
        return sel
            ? PhosphorIcons.mapPin(PhosphorIconsStyle.fill)
            : LucideIcons.mapPin;
      case AppGlyph.truck:
        return LucideIcons.truck;
      case AppGlyph.file:
        return LucideIcons.file;
      case AppGlyph.upload:
        return LucideIcons.upload;
      case AppGlyph.image:
        return LucideIcons.image;
      case AppGlyph.plus:
        return LucideIcons.plus;
      case AppGlyph.edit:
        return sel ? LucideIcons.pencilLine : LucideIcons.pencil;
      case AppGlyph.delete_:
        return LucideIcons.trash;
      case AppGlyph.check:
        return LucideIcons.check;
      case AppGlyph.close:
        return LucideIcons.x;
      case AppGlyph.user:
        return PhosphorIcons.user(pStyleFor(sel, s));
      case AppGlyph.organization:
        return Iconsax.building;
      case AppGlyph.terms:
        return Iconsax.document_text;
      case AppGlyph.request:
        return Iconsax.receive_square;
      case AppGlyph.contract:
        return Iconsax.document_code;
      case AppGlyph.info:
        return LucideIcons.info;
      case AppGlyph.route:
        return LucideIcons.route;
      case AppGlyph.certificate:
        return LucideIcons.badgeCheck;
      case AppGlyph.refresh:
        return LucideIcons.refreshCcw;
      case AppGlyph.mail:
        return LucideIcons.mail;
      case AppGlyph.phone:
        return LucideIcons.phone;
      case AppGlyph.money:
        return LucideIcons.banknote;
      case AppGlyph.save:
        return LucideIcons.save;
      case AppGlyph.people:
        return LucideIcons.users;
      case AppGlyph.logout:
        return LucideIcons.logOut;
      case AppGlyph.moon:
        return LucideIcons.moon;
      case AppGlyph.globe:
        return LucideIcons.globe;
      case AppGlyph.Settings:
        return LucideIcons.settings;
      case AppGlyph.send:
        return LucideIcons.send;
      case AppGlyph.login:
        return LucideIcons.logIn;
      case AppGlyph.back:
        return LucideIcons.arrowLeft;
      case AppGlyph.arrowRight:
        return LucideIcons.arrowRight;
      case AppGlyph.arrowUp:
        return LucideIcons.arrowUp;
      case AppGlyph.arrowDown:
        return LucideIcons.arrowDown;
      case AppGlyph.add:
        return LucideIcons.plus;
      case AppGlyph.sort:
        return Iconsax.sort;
      case AppGlyph.invoice:
        return Iconsax.document;
      case AppGlyph.notifications:
        return LucideIcons.bell;
      case AppGlyph.chat:
        return LucideIcons.messageCircle;
      case AppGlyph.bell:
        return LucideIcons.bell;
      case AppGlyph.attachment:
        return Iconsax.attach_circle;
      case AppGlyph.note:
        return Iconsax.note;
      case AppGlyph.shield:
        return LucideIcons.shield;
      case AppGlyph.userGroup:
        return LucideIcons.users;
      case AppGlyph.dashboard:
        return LucideIcons.layoutDashboard;
      case AppGlyph.lock:
        return LucideIcons.lock;
      case AppGlyph.pin:
        return LucideIcons.pin;
      case AppGlyph.fileText:
        return LucideIcons.text;
      case AppGlyph.all:
        return Icons.all_inbox;
    }
  }
}

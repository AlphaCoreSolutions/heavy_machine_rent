import 'package:flutter/material.dart';
import 'package:heavy_new/foundation/ui/pressable_scale.dart';
import 'package:heavy_new/foundation/ui/ui_extras.dart';
import 'package:heavy_new/foundation/ui/ui_kit.dart' hide PressableScale;

import 'package:provider/provider.dart';
import 'l10n_extensions.dart';
import 'locale_controller.dart';

class LocaleSwitcher extends StatelessWidget {
  const LocaleSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<LocaleController>();
    final current =
        ctrl.locale?.languageCode ??
        Localizations.localeOf(context).languageCode;

    return Glass(
      radius: 14,
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: PressableScale(
              onTap: () {
                ctrl.setLocale(const Locale('en'));
                AppSnack.success(context, context.l10n.snackSaved);
              },
              child: _seg(current == 'en', context.l10n.langEnglish, context),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: PressableScale(
              onTap: () {
                ctrl.setLocale(const Locale('ar'));
                AppSnack.success(context, context.l10n.snackSaved);
              },
              child: _seg(current == 'ar', context.l10n.langArabic, context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _seg(bool active, String label, BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: active ? cs.primary : cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline.withOpacity(0.6)),
      ),
      child: Center(
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: active ? Colors.white : cs.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

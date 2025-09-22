import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:heavy_new/foundation/ui/ui_extras.dart';
import 'package:heavy_new/foundation/ui/ui_kit.dart';
import 'package:heavy_new/foundation/ui/app_icons.dart';
import 'package:heavy_new/l10n/app_localizations.dart';
import 'package:heavy_new/screens/app/app_prefs.dart';
import 'package:intl/intl.dart';

extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!; // non-null
  Locale get locale => Localizations.localeOf(this);
  bool get isArabic => locale.languageCode == 'ar';
}

class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  final prefs = AppPrefs.instance;

  Future<TimeOfDay?> _pickTime(TimeOfDay? initial) async {
    final now = TimeOfDay.now();
    return await showTimePicker(
      context: context,
      initialTime: initial ?? now,
      helpText: context.l10n.selectTime,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.appSettings),
        leading: BackButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/settings');
            }
          },
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          // THEME
          Glass(
            radius: 18,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: ValueListenableBuilder<ThemeMode>(
                valueListenable: prefs.themeMode,
                builder: (_, mode, __) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          AIcon(AppGlyph.Settings, color: cs.primary),
                          const SizedBox(width: 8),
                          Text(
                            context.l10n.settingsTheme, // ← localized
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _themeOption(
                        title: context.l10n.themeLight, // ← localized
                        selected: mode == ThemeMode.light,
                        onTap: () => prefs.setTheme(ThemeMode.light),
                      ),
                      _themeOption(
                        title: context.l10n.themeDark, // ← localized
                        selected: mode == ThemeMode.dark,
                        onTap: () => prefs.setTheme(ThemeMode.dark),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 16),

          // LANGUAGE
          Glass(
            radius: 18,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: ValueListenableBuilder<Locale?>(
                valueListenable: prefs.locale,
                builder: (_, loc, __) {
                  final code = (loc?.languageCode ?? 'en');
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          AIcon(AppGlyph.globe, color: cs.primary),
                          const SizedBox(width: 8),
                          Text(
                            context.l10n.settingsLanguage, // already in ARB
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _langOption(
                        context.l10n.langEnglish, // already in ARB
                        selected: code == 'en',
                        onTap: () => prefs.setLocale(const Locale('en')),
                      ),
                      _langOption(
                        context.l10n.langArabic, // already in ARB
                        selected: code == 'ar',
                        onTap: () => prefs.setLocale(const Locale('ar')),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 16),

          // NOTIFICATIONS (demo)
          Glass(
            radius: 18,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: ValueListenableBuilder<NotificationPrefs>(
                valueListenable: prefs.notifications,
                builder: (_, np, __) {
                  String _fmt(TimeOfDay? t) {
                    if (t == null) return '—';
                    // Use current locale for formatting
                    final locale = Localizations.localeOf(
                      context,
                    ).toLanguageTag();
                    final dt = DateTime(0, 1, 1, t.hour, t.minute);
                    return DateFormat.jm(locale).format(dt);
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          AIcon(AppGlyph.bell, color: cs.primary),
                          const SizedBox(width: 8),
                          Text(
                            context.l10n.pushNotifications, // ← new key
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const Spacer(),
                          GhostButton(
                            onPressed: () {
                              AppSnack.info(
                                context,
                                context.l10n.testNotificationMessage,
                              ); // ← new key
                            },
                            icon: AIcon(AppGlyph.send, color: cs.primary),
                            child: Text(context.l10n.test), // ← new key
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _toggleRow(
                        label: context.l10n.pushNotifications, // ← new key
                        value: np.pushEnabled,
                        onChanged: (v) =>
                            prefs.setNotifications(np.copyWith(pushEnabled: v)),
                      ),
                      _toggleRow(
                        label: context.l10n.inAppBanners, // ← new key
                        value: np.inAppEnabled,
                        onChanged: (v) => prefs.setNotifications(
                          np.copyWith(inAppEnabled: v),
                        ),
                      ),
                      _toggleRow(
                        label: context.l10n.emailUpdates, // ← new key
                        value: np.emailEnabled,
                        onChanged: (v) => prefs.setNotifications(
                          np.copyWith(emailEnabled: v),
                        ),
                      ),
                      _toggleRow(
                        label: context.l10n.sound, // ← new key
                        value: np.soundEnabled,
                        onChanged: (v) => prefs.setNotifications(
                          np.copyWith(soundEnabled: v),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        context.l10n.quietHours, // ← new key
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final t = await _pickTime(np.quietFrom);
                                if (t != null) {
                                  prefs.setNotifications(
                                    np.copyWith(quietFrom: t),
                                  );
                                }
                              },
                              icon: const Icon(Icons.nightlight_round),
                              label: Text(
                                '${context.l10n.from}: ${_fmt(np.quietFrom)}',
                              ), // ← new key
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final t = await _pickTime(np.quietTo);
                                if (t != null) {
                                  prefs.setNotifications(
                                    np.copyWith(quietTo: t),
                                  );
                                }
                              },
                              icon: const Icon(Icons.sunny_snowing),
                              label: Text(
                                '${context.l10n.to}: ${_fmt(np.quietTo)}',
                              ), // ← new key
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        context.l10n.quietHours, // ← new key
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _themeOption({
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Radio<bool>(
        value: true,
        groupValue: selected,
        onChanged: (_) => onTap(),
      ),
      title: Text(title),
      onTap: onTap,
    );
  }

  Widget _langOption(
    String title, {
    required bool selected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Radio<bool>(
        value: true,
        groupValue: selected,
        onChanged: (_) => onTap(),
      ),
      title: Text(title),
      onTap: onTap,
    );
  }

  Widget _toggleRow({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      value: value,
      onChanged: onChanged,
    );
  }
}

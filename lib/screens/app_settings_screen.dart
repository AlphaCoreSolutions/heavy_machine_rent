import 'package:flutter/material.dart';
import 'package:heavy_new/foundation/ui/ui_extras.dart';
import 'package:heavy_new/foundation/ui/ui_kit.dart';
import 'package:heavy_new/foundation/ui/app_icons.dart';
import 'package:heavy_new/screens/app_prefs.dart';
import 'package:intl/intl.dart';

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
      helpText: 'Select time',
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('App settings')),
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
                            'Theme',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _themeOption(
                        title: 'Light',
                        selected: mode == ThemeMode.light,
                        onTap: () => prefs.setTheme(ThemeMode.light),
                      ),
                      _themeOption(
                        title: 'Dark',
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
                            'Language',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _langOption(
                        'English',
                        selected: code == 'en',
                        onTap: () => prefs.setLocale(const Locale('en')),
                      ),
                      _langOption(
                        'العربية',
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
                    final dt = DateTime(0, 1, 1, t.hour, t.minute);
                    return DateFormat.jm().format(dt);
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          AIcon(AppGlyph.bell, color: cs.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Notifications',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const Spacer(),
                          GhostButton(
                            onPressed: () {
                              // demo toast
                              AppSnack.info(
                                context,
                                'This is a test notification',
                              );
                            },
                            icon: AIcon(AppGlyph.send, color: cs.primary),
                            child: const Text('Test'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _toggleRow(
                        label: 'Push notifications',
                        value: np.pushEnabled,
                        onChanged: (v) =>
                            prefs.setNotifications(np.copyWith(pushEnabled: v)),
                      ),
                      _toggleRow(
                        label: 'In-app banners',
                        value: np.inAppEnabled,
                        onChanged: (v) => prefs.setNotifications(
                          np.copyWith(inAppEnabled: v),
                        ),
                      ),
                      _toggleRow(
                        label: 'Email updates',
                        value: np.emailEnabled,
                        onChanged: (v) => prefs.setNotifications(
                          np.copyWith(emailEnabled: v),
                        ),
                      ),
                      _toggleRow(
                        label: 'Sound',
                        value: np.soundEnabled,
                        onChanged: (v) => prefs.setNotifications(
                          np.copyWith(soundEnabled: v),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Quiet hours',
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
                              label: Text('From: ${_fmt(np.quietFrom)}'),
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
                              label: Text('To: ${_fmt(np.quietTo)}'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'During quiet hours, sounds are muted. (Demo—wire to your push provider later.)',
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

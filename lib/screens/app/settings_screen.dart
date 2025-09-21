// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:heavy_new/core/auth/auth_store.dart';
import 'package:heavy_new/foundation/ui/app_icons.dart';
import 'package:heavy_new/foundation/ui/ui_extras.dart';
import 'package:heavy_new/foundation/ui/ui_kit.dart';
import 'package:heavy_new/screens/app/app_settings_screen.dart';
import 'package:heavy_new/screens/contract_screens/contracts_screen.dart';
import 'package:heavy_new/screens/equipment_screens/equipment_management_screen.dart';
import 'package:heavy_new/screens/request_screens/my_requests_screen.dart';
import 'package:heavy_new/screens/request_screens/orders_history_screen.dart';
import 'package:heavy_new/screens/organization_screens/organization_hub_screen.dart';
import 'package:heavy_new/screens/auth_profile_screens/phone_auth_screen.dart';
import 'package:heavy_new/screens/auth_profile_screens/profile_screen.dart';
// ⬇️ import your super admin screen (adjust path if different)
import 'package:heavy_new/screens/super_admin_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final auth = AuthStore.instance;
    final u = auth.user.value;
    final isLoggedIn = auth.isLoggedIn;
    final isCompleted = u?.isCompleted == true;

    // Fix precedence + expose flags
    final isSuperAdmin = (u?.userTypeId == 20);
    final isOrgUser = (u?.userTypeId == 17);
    final isAllowed = isLoggedIn && (isSuperAdmin || isOrgUser);

    if (!isAllowed) {
      return Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Glass(
              radius: 18,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: cs.surfaceVariant,
                        child: AIcon(AppGlyph.info, color: cs.primary),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isLoggedIn ? 'Not available' : 'Sign in required',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isLoggedIn
                            ? 'This page is only available for accounts with user type #17 or #20.'
                            : 'Please sign in to continue.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (!isLoggedIn)
                            FilledButton.icon(
                              icon: const Icon(Icons.login),
                              label: const Text('Sign in'),
                              onPressed: () async {
                                final ok = await Navigator.of(context)
                                    .push<bool>(
                                      MaterialPageRoute(
                                        builder: (_) => const PhoneAuthScreen(),
                                      ),
                                    );
                                if (ok == true && context.mounted) {
                                  AppSnack.success(context, 'Signed in');
                                }
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // ====== Visible for userTypeId 17 or 20 ======
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          // Account header
          Glass(
            radius: 18,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: cs.primary.withOpacity(.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: AIcon(
                        AppGlyph.user,
                        color: cs.primary,
                        selected: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (u?.fullName?.trim().isNotEmpty == true)
                              ? u!.fullName!
                              : 'Account',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          (u?.email?.trim().isNotEmpty == true)
                              ? u!.email!
                              : (u?.mobile ?? ''),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: cs.onSurfaceVariant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        _StatusChip(
                          label: isCompleted ? 'Completed' : 'Incomplete',
                          color: isCompleted ? cs.primary : cs.tertiary,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.logout),
                    label: const Text('Log out'),
                    onPressed: () async {
                      final yes = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Log out?'),
                          content: const Text('You can sign in again anytime.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Log out'),
                            ),
                          ],
                        ),
                      );
                      if (yes == true) {
                        await auth.logout();
                        if (context.mounted)
                          AppSnack.info(context, 'Signed out');
                      }
                    },
                  ),
                ],
              ),
            ),
          ),

          if (!isCompleted) ...[
            const SizedBox(height: 12),
            Glass(
              radius: 16,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    AIcon(AppGlyph.info, color: cs.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Complete your account to unlock Organization and My equipment.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ProfileScreen(),
                        ),
                      ),
                      child: const Text('Complete'),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 18),
          const _SectionHeader('Account'),
          _ActionTile(
            icon: AppGlyph.user,
            title: 'Profile',
            subtitle: 'Your personal & company details',
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const ProfileScreen())),
          ),
          _ActionTile(
            icon: AppGlyph.Settings,
            title: 'App settings',
            subtitle: 'Theme, language, notifications',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AppSettingsScreen()),
            ),
          ),

          const SizedBox(height: 18),
          const _SectionHeader('Manage'),
          LayoutBuilder(
            builder: (_, c) {
              final twoUp = c.maxWidth >= 560;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  if (isCompleted)
                    _ActionCard(
                      icon: AppGlyph.organization,
                      title: 'Organization',
                      subtitle: 'Company info & compliance',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const OrganizationScreen(),
                        ),
                      ),
                      width: twoUp ? (c.maxWidth - 12) / 2 : c.maxWidth,
                    ),
                  if (isCompleted)
                    _ActionCard(
                      icon: AppGlyph.truck,
                      title: 'My equipment',
                      subtitle: 'View and manage your fleet',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const EquipmentManagementScreen(),
                        ),
                      ),
                      width: twoUp ? (c.maxWidth - 12) / 2 : c.maxWidth,
                    ),
                  if (isCompleted)
                    _ActionCard(
                      icon: AppGlyph.organization,
                      title: 'Requests',
                      subtitle: 'Manage your requests',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const MyRequestsScreen(),
                        ),
                      ),
                      width: twoUp ? (c.maxWidth - 12) / 2 : c.maxWidth,
                    ),

                  // ✅ SUPER ADMIN ENTRY (visible only for userTypeId == 20)
                  if (isSuperAdmin)
                    _ActionCard(
                      icon: AppGlyph.Settings, // pick any suitable glyph
                      title: 'Super Admin',
                      subtitle: 'Open super admin panel (debug)',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SuperAdminHubScreen(),
                        ),
                      ),
                      width: twoUp ? (c.maxWidth - 12) / 2 : c.maxWidth,
                    ),
                ],
              );
            },
          ),

          const SizedBox(height: 18),
          const _SectionHeader('Activity'),
          _ActionTile(
            icon: AppGlyph.contract,
            title: 'Contracts',
            subtitle: 'Pending, open, finished, closed',
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const ContractsScreen())),
          ),
          _ActionTile(
            icon: AppGlyph.invoice,
            title: 'Orders (history)',
            subtitle: 'Past orders & receipts',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const OrdersHistoryScreen()),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w800,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          letterSpacing: .2,
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final AppGlyph icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Glass(
        radius: 16,
        child: ListTile(
          onTap: onTap,
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: AIcon(icon, color: cs.primary)),
          ),
          title: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: const Icon(Icons.chevron_right),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.width,
  });

  final AppGlyph icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: width,
      child: Glass(
        radius: 18,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: cs.primary.withOpacity(.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(child: AIcon(icon, color: cs.primary)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(.30)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          letterSpacing: .3,
          fontSize: 9.30,
        ),
      ),
    );
  }
}

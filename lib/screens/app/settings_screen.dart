// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:heavy_new/core/auth/auth_store.dart';
import 'package:heavy_new/foundation/ui/app_icons.dart';
import 'package:heavy_new/foundation/ui/ui_extras.dart';
import 'package:heavy_new/foundation/ui/ui_kit.dart';
import 'package:heavy_new/screens/app/app_settings_screen.dart';
import 'package:heavy_new/screens/app/calendar_screen.dart';
import 'package:heavy_new/screens/contract_screens/contracts_screen.dart';
import 'package:heavy_new/screens/equipment_screens/equipment_management_screen.dart';
import 'package:heavy_new/screens/request_screens/my_requests_screen.dart';
import 'package:heavy_new/screens/request_screens/orders_history_screen.dart';
import 'package:heavy_new/screens/organization_screens/organization_hub_screen.dart';
import 'package:heavy_new/screens/auth_profile_screens/phone_auth_screen.dart';
import 'package:heavy_new/screens/auth_profile_screens/profile_screen.dart';
import 'package:heavy_new/screens/super_admin_screen.dart';
//import 'package:heavy_new/screens/super_admin_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final auth = AuthStore.instance;
    final u = auth.user.value;
    final isLoggedIn = auth.isLoggedIn;
    final isCompleted = u?.isCompleted == true;

    final isSuperAdmin = (u?.userTypeId == 20);
    final isOrgUser = (u?.userTypeId == 17);
    final isAllowed = isLoggedIn && (isSuperAdmin || isOrgUser);

    if (!isAllowed) {
      return Scaffold(
        appBar: AppBar(title: Text(L10nX(context).l10n.settingsTitle)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Glass(
              radius: 18,
              child: Padding(
                padding: const EdgeInsets.all(5),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Stack(
                    children: [
                      // Top-right settings button
                      Positioned(
                        top: 0,
                        right: 0,
                        child: IconButton.filledTonal(
                          style: IconButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.onPrimary,
                          ),
                          tooltip: L10nX(context).l10n.appSettings,
                          icon: const Icon(Icons.settings, color: Colors.white),
                          onPressed: () => context.push('/settings/app'),
                        ),
                      ),

                      // Content
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 4),
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: cs.surfaceContainerHighest,
                            child: AIcon(AppGlyph.info, color: cs.primary),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            isLoggedIn
                                ? L10nX(context).l10n.notAvailableTitle
                                : L10nX(context).l10n.signInRequiredTitle,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isLoggedIn
                                ? L10nX(context).l10n.restrictedPageMessage
                                : L10nX(context).l10n.signInPrompt,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: cs.onSurfaceVariant),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (!isLoggedIn)
                                FilledButton.icon(
                                  icon: const Icon(Icons.login),
                                  label: Text(L10nX(context).l10n.actionSignIn),
                                  onPressed: () async {
                                    final ok = await Navigator.of(context)
                                        .push<bool>(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const PhoneAuthScreen(),
                                          ),
                                        );
                                    if (ok == true && context.mounted) {
                                      AppSnack.success(
                                        context,
                                        L10nX(context).l10n.signedIn,
                                      );
                                    }
                                  },
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // ===== visible for userTypeId 17 or 20 =====
    return Scaffold(
      appBar: AppBar(title: Text(L10nX(context).l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(8, 16, 8, 28),
        children: [
          // Account header
          Glass(
            radius: 18,
            child: Padding(
              padding: const EdgeInsets.only(
                right: 14,
                top: 14,
                bottom: 14,
                left: 1,
              ),
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
                              : L10nX(context).l10n.accountTitle,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 6),
                        _StatusChip(
                          label: isCompleted
                              ? L10nX(context).l10n.statusCompleted
                              : L10nX(context).l10n.statusIncomplete,
                          color: isCompleted ? cs.primary : cs.tertiary,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 34, // try 30–34 for compact
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        minimumSize: const Size(
                          0,
                          0,
                        ), // allow the SizedBox to control height
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: const VisualDensity(
                          horizontal: -2,
                          vertical: -2,
                        ),
                      ),
                      icon: const Icon(Icons.logout, size: 18),
                      label: Text(
                        L10nX(context).l10n.actionSignOut,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontSize: 12,
                          color: Theme.of(context).primaryColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      onPressed: () async {
                        final yes = await showDialog<bool>(
                          context: context, // OK to pass the outer context here
                          builder: (dialogCtx) => AlertDialog(
                            title: Text(L10nX(context).l10n.logoutConfirmTitle),
                            content: Text(
                              L10nX(context).l10n.logoutConfirmBody,
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(
                                  dialogCtx,
                                ).pop(false), // <-- use dialogCtx
                                child: Text(L10nX(context).l10n.cancel),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.of(
                                  dialogCtx,
                                ).pop(true), // <-- use dialogCtx
                                child: Text(L10nX(context).l10n.actionSignOut),
                              ),
                            ],
                          ),
                        );

                        if (yes == true) {
                          await auth.logout();
                          if (!context.mounted) return;
                          context.go('/'); // or to your auth/welcome route
                        }
                      },
                    ),
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
                        L10nX(context).l10n.completeYourAccountBody,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ProfileScreen(),
                        ),
                      ),
                      child: Text(L10nX(context).l10n.completeAction),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 18),
          _SectionHeader(L10nX(context).l10n.accountSection),
          _ActionTile(
            icon: AppGlyph.user,
            title: L10nX(context).l10n.profileTitle,
            subtitle: L10nX(context).l10n.profileSubtitle,
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const ProfileScreen())),
          ),
          _ActionTile(
            icon: AppGlyph.settings,
            title: L10nX(context).l10n.appSettings,
            subtitle: L10nX(context).l10n.appSettingsSubtitle,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AppSettingsScreen()),
            ),
          ),

          const SizedBox(height: 18),
          _SectionHeader(L10nX(context).l10n.manageSection),
          LayoutBuilder(
            builder: (_, c) {
              final twoUp = c.maxWidth >= 560;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  if (isCompleted)
                    _ActionCard(
                      icon: AppGlyph.dashboard,
                      title: L10nX(context).l10n.superAdminTitle,
                      subtitle: L10nX(context).l10n.superAdminSubtitle,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SuperAdminHubScreen(),
                        ),
                      ),
                      width: twoUp ? (c.maxWidth - 12) / 2 : c.maxWidth,
                    ),
                  if (isCompleted)
                    _ActionCard(
                      icon: AppGlyph.calendar,
                      title: L10nX(context).l10n.calendarTitle,
                      subtitle: L10nX(context).l10n.calendarSubtitle,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => RequestCalendarScreen(vendorId: 1),
                        ),
                      ),
                      width: twoUp ? (c.maxWidth - 12) / 2 : c.maxWidth,
                    ),
                  if (isCompleted)
                    _ActionCard(
                      icon: AppGlyph.organization,
                      title: L10nX(context).l10n.organizationTitle,
                      subtitle: L10nX(context).l10n.organizationSubtitle,
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
                      title: L10nX(context).l10n.myEquipmentTitle,
                      subtitle: L10nX(context).l10n.myEquipmentSubtitle,
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
                      title: L10nX(context).l10n.requestsTitle,
                      subtitle: L10nX(context).l10n.requestsSubtitle,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const MyRequestsScreen(),
                        ),
                      ),
                      width: twoUp ? (c.maxWidth - 12) / 2 : c.maxWidth,
                    ),
                ],
              );
            },
          ),

          const SizedBox(height: 18),
          _SectionHeader(L10nX(context).l10n.activitySection),
          _ActionTile(
            icon: AppGlyph.contract,
            title: L10nX(context).l10n.contractsTitle,
            subtitle: L10nX(context).l10n.contractsSubtitle,
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const ContractsScreen())),
          ),
          _ActionTile(
            icon: AppGlyph.invoice,
            title: L10nX(context).l10n.ordersHistoryTitle,
            subtitle: L10nX(context).l10n.ordersHistorySubtitle,
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

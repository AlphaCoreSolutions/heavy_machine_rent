// lib/main.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:heavy_new/core/api/api_handler.dart';
import 'package:heavy_new/foundation/ui/app_theme.dart';
import 'package:heavy_new/foundation/ui/scroll_behavior.dart';
import 'package:heavy_new/foundation/ui/transitions.dart';
import 'package:heavy_new/foundation/ui/ui_extras.dart';

// Shell & screens
import 'package:heavy_new/screens/app/app_shell.dart';
import 'package:heavy_new/screens/chat_screens/chat_list_screen.dart';
import 'package:heavy_new/screens/chat_screens/chat_thread_screen.dart';
import 'package:heavy_new/screens/contract_screens/contracts_screen.dart';
import 'package:heavy_new/screens/app/home_screen.dart';
import 'package:heavy_new/screens/equipment_screens/equipment_list_screen.dart';
import 'package:heavy_new/screens/equipment_screens/equipment_details_screen.dart';
import 'package:heavy_new/screens/request_screens/my_requests_screen.dart';
import 'package:heavy_new/screens/app/notification_screen.dart';
import 'package:heavy_new/screens/request_screens/orders_history_screen.dart';
import 'package:heavy_new/screens/auth_profile_screens/profile_screen.dart';
import 'package:heavy_new/screens/app/settings_screen.dart';
import 'package:heavy_new/screens/app/app_settings_screen.dart';
import 'package:heavy_new/screens/organization_screens/organization_hub_screen.dart';
import 'package:heavy_new/screens/equipment_screens/equipment_management_screen.dart';
import 'package:heavy_new/screens/auth_profile_screens/employees_screen.dart';

// Auth (login/register via phone + OTP)
import 'package:heavy_new/screens/auth_profile_screens/phone_auth_screen.dart';

// Models
import 'package:heavy_new/core/models/equipment/equipment.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const androidEmuBase = '';
  const prodBase = 'https://sr.visioncit.com/api/';

  Api.init(
    baseUrl: (defaultTargetPlatform == TargetPlatform.android && !kIsWeb)
        ? androidEmuBase
        : prodBase,
  );

  runApp(const HeavyApp());
}

class HeavyApp extends StatelessWidget {
  const HeavyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Heavy Rental',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      scrollBehavior: const AppScrollBehavior(),
      themeMode: ThemeMode.system,
      routerConfig: _router,
      builder: (context, child) =>
          OfflineBanner(child: child ?? const SizedBox.shrink()),
    );
  }
}

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

final GoRouter _router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: <RouteBase>[
    // App shell keeps bottom bar and theme wrapper
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) =>
          AppShell(child: child, path: state.uri.path),
      routes: [
        // ===== Home & catalog =====
        GoRoute(
          path: '/',
          name: AppRoutes.home,
          pageBuilder: (context, state) =>
              fadeThroughPage(child: const HomeScreen()),
        ),
        GoRoute(
          path: '/equipments',
          name: AppRoutes.equipmentList,
          pageBuilder: (context, state) =>
              sharedAxisX(child: const EquipmentListScreen()),
        ),
        GoRoute(
          path: '/equipment/:id',
          name: AppRoutes.equipmentDetails,
          pageBuilder: (context, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '');
            return sharedAxisX(
              child: EquipmentDetailsScreen(equipmentId: id ?? 0),
            );
          },
        ),

        // ===== Requests (user’s) =====
        GoRoute(
          path: '/requests',
          name: AppRoutes.requests,
          pageBuilder: (context, state) =>
              sharedAxisX(child: const MyRequestsScreen()),
        ),

        // ===== Settings hub + subpages =====
        GoRoute(
          path: '/settings',
          name: AppRoutes.settings,
          pageBuilder: (context, state) =>
              sharedAxisX(child: const SettingsScreen()),
        ),
        // App settings (general app prefs)
        GoRoute(
          path: '/settings/app',
          name: AppRoutes.settingsApp,
          pageBuilder: (context, state) =>
              fadeThroughPage(child: const AppSettingsScreen()),
        ),
        // Profile lives under settings but keep a direct path for convenience
        GoRoute(
          path: '/profile',
          name: AppRoutes.profile,
          pageBuilder: (context, state) =>
              sharedAxisX(child: const ProfileScreen()),
        ),
        // Employees is reachable from Settings (kept for now)
        GoRoute(
          path: '/employees',
          name: AppRoutes.employees,
          pageBuilder: (context, state) =>
              sharedAxisX(child: const EmployeesScreen()),
        ),

        // ===== Vendor area (visible once account is completed) =====
        GoRoute(
          path: '/organization',
          name: AppRoutes.organization,
          pageBuilder: (context, state) =>
              sharedAxisX(child: const OrganizationScreen()),
        ),
        GoRoute(
          path: '/my-equipment',
          name: AppRoutes.myEquipment,
          pageBuilder: (context, state) =>
              sharedAxisX(child: const EquipmentManagementScreen()),
        ),

        // ===== Auth =====
        GoRoute(
          path: '/auth',
          name: AppRoutes.auth,
          pageBuilder: (context, state) =>
              fadeThroughPage(child: const PhoneAuthScreen()),
        ),

        GoRoute(
          path: 'orders',
          name: 'orders',
          pageBuilder: (context, state) =>
              fadeThroughPage(child: const OrdersHistoryScreen()),
        ),
        GoRoute(
          path: 'contracts',
          name: 'contracts',
          pageBuilder: (context, state) =>
              fadeThroughPage(child: const ContractsScreen()),
        ),
        GoRoute(
          path: 'chats',
          name: 'chats',
          pageBuilder: (context, state) =>
              sharedAxisX(child: const ChatListScreen()),
        ),
        GoRoute(
          path: 'chats/:id',
          name: 'chatThread',
          pageBuilder: (context, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
            return sharedAxisX(child: ChatThreadScreen(threadId: id));
          },
        ),
        GoRoute(
          path: 'notifications',
          name: 'notifications',
          pageBuilder: (context, state) =>
              sharedAxisX(child: const NotificationsScreen()),
        ),
      ],
    ),
  ],
  errorPageBuilder: (context, state) => fadeThroughPage(
    child: Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Something went wrong'),
              const SizedBox(height: 8),
              Text(state.error?.toString() ?? 'Unknown error'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.go('/'),
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      ),
    ),
  ),
);

class AppRoutes {
  static const home = 'home';
  static const equipmentList = 'equipment_list';
  static const equipmentDetails = 'equipment_details';
  static const requests = 'requests';

  static const settings = 'settings';
  static const settingsApp = 'settings_app';
  static const profile = 'profile';
  static const employees = 'employees';

  static const organization = 'organization';
  static const myEquipment = 'my_equipment';

  static const auth = 'auth';
}

/// Optional convenience navigation
extension AppNav on BuildContext {
  // Catalog
  void goToHome() => go('/');
  void goToEquipments() => go('/equipments');
  void goToEquipmentDetails(Equipment e) =>
      go('/equipment/${e.equipmentId}', extra: e);

  // Requests
  void goToRequests() => go('/requests');

  // Settings hub + subpages
  void goToSettings() => go('/settings');
  void goToSettingsApp() => go('/settings/app');
  void goToProfile() => go('/profile');
  void goToEmployees() => go('/employees');

  // Vendor area
  void goToOrganization() => go('/organization');
  void goToMyEquipment() => go('/my-equipment');

  // Auth
  void goToAuth() => go('/auth');
}

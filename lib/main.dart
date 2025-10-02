// lib/main.dart
import 'dart:convert';
import 'dart:developer' show log;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:heavy_new/core/auth/auth_store.dart';
import 'package:heavy_new/core/models/user/auth.dart';
import 'package:heavy_new/foundation/session_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:heavy_new/core/api/api_handler.dart';
import 'package:heavy_new/firebase_options.dart';
import 'package:heavy_new/foundation/ui/app_theme.dart';
import 'package:heavy_new/foundation/ui/scroll_behavior.dart';
import 'package:heavy_new/foundation/ui/transitions.dart';
import 'package:heavy_new/foundation/ui/ui_extras.dart';
import 'package:heavy_new/foundation/widgets/notifications_store.dart';
import 'package:heavy_new/l10n/app_localizations.dart';

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
import 'package:heavy_new/screens/auth_profile_screens/phone_auth_screen.dart';

// Models
import 'package:heavy_new/core/models/equipment/equipment.dart';

// ===== NEW: localization + prefs bindings =====
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:heavy_new/screens/app/app_prefs.dart';

final navigatorKey = GlobalKey<NavigatorState>();
Future _firebaseBackgroundMessage(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (message.notification != null) {
    log('Handling a background message: ${message.messageId}');
  }
}

final NotificationsStore notificationsStore = NotificationsStore();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize notifications after Firebase. On iOS Simulator, FCM token
  // may not be immediately available due to missing APNs; our init handles it.
  await Notifications().init();
  await notificationsStore.init();
  if (!kIsWeb) {
    await Notifications().initLocalNotifications();
  }

  // Ensure FCM auto-init and foreground presentation (iOS)
  try {
    await FirebaseMessaging.instance.setAutoInitEnabled(true);
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
  } catch (_) {}

  // Register/save FCM token to backend when signed-in user is available.
  // If a user is already signed in, save immediately; also listen for changes.
  try {
    final current = FirebaseAuth.instance.currentUser;
    if (current != null) {
      await Notifications().getDeviceToken();
    }
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user != null) {
        await Notifications().getDeviceToken();
      }
    });
  } catch (_) {}

  if (!kIsWeb) {
    // Not supported on web; web uses a service worker.
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundMessage);
  }

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    if (message.notification != null) {
      log('Background message clicked!');
      final ctx = _rootNavigatorKey.currentContext;
      if (ctx != null) {
        ctx.push('/notifications'); // GoRouter navigation
      }
    }
  });

  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    final hasNotif = message.notification != null;
    final payloadData = message.data.isEmpty ? null : jsonEncode(message.data);
    if (hasNotif && !kIsWeb) {
      try {
        await Notifications.showSimpleNotifications(
          title: message.notification!.title ?? 'Notification',
          body: message.notification!.body ?? '',
          payload: payloadData ?? '{}',
        );
      } catch (e) {
        log('local notif error: $e');
      }
    }
  });

  // handling terminated state
  final remoteMessage = await FirebaseMessaging.instance.getInitialMessage();
  if (remoteMessage != null) {
    log('App opened from terminated state via notification');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _rootNavigatorKey.currentContext;
      if (ctx != null) {
        ctx.push('/notifications'); // GoRouter navigation
      }
    });
  }

  const androidEmuBase = 'https://sr.visioncit.com/api/';
  const prodBase = 'https://sr.visioncit.com/api/';
  const envBase = String.fromEnvironment('API_BASE_URL'); // optional override

  final baseUrl = kIsWeb
      // On web, default to same-origin to avoid CORS: https://<host>/api/...
      ? (envBase.isNotEmpty ? envBase : prodBase)
      : ((defaultTargetPlatform == TargetPlatform.android && !kIsWeb)
            ? androidEmuBase
            : (envBase.isNotEmpty ? envBase : prodBase));

  Api.init(baseUrl: baseUrl);
  await AuthStore.instance.init(); // or .restore() if that’s your method

  await AuthStore.instance.init();

  // If already logged in at boot, enforce existing window OR create one if missing.
  await sessionManager.enforceNow();
  await sessionManager
      .startFreshSession(); // safe: won't overwrite if key exists

  // Seed lastUser BEFORE attaching the listener
  AuthUser? _lastUser = AuthStore.instance.user.value;

  AuthStore.instance.user.addListener(() async {
    final currentUser = AuthStore.instance.user.value;

    // null -> non-null: user just logged in (runtime flow)
    if (_lastUser == null && currentUser != null) {
      await sessionManager
          .startFreshSession(); // safe: won't refresh existing key
    }

    // non-null -> null: user just logged out
    if (_lastUser != null && currentUser == null) {
      await sessionManager.enforceNow(); // cancels timer if key was removed
    }

    _lastUser = currentUser;
  });

  runApp(const HeavyApp());
}

class HeavyApp extends StatelessWidget {
  const HeavyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final prefs = AppPrefs.instance; // ← get your app prefs singleton

    // Rebuild MaterialApp when theme OR locale changes
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: prefs.themeMode,
      builder: (_, themeMode, __) {
        return ValueListenableBuilder<Locale?>(
          valueListenable: prefs.locale,
          builder: (_, locale, __) {
            return MaterialApp.router(
              debugShowCheckedModeBanner: false,
              // Use onGenerateTitle so it localizes with current context
              onGenerateTitle: (ctx) =>
                  AppLocalizations.of(ctx)?.appName ?? 'HeavyRent',
              theme: AppTheme.light(),
              darkTheme: AppTheme.dark(),
              themeMode: themeMode, // ← driven by settings
              locale: locale, // ← driven by settings
              localizationsDelegates: const [
                AppLocalizations.delegate,
                ...GlobalMaterialLocalizations.delegates,
              ],
              supportedLocales: const [Locale('en'), Locale('ar')],

              // Directionality (RTL/LTR) is handled automatically by locale
              scrollBehavior: const AppScrollBehavior(),
              routerConfig: _router,
              builder: (context, child) =>
                  OfflineBanner(child: child ?? const SizedBox.shrink()),
            );
          },
        );
      },
    );
  }
}

final _rootNavigatorKey = navigatorKey;
final _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

final GoRouter _router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: <RouteBase>[
    // App shell keeps bottom bar and theme wrapper
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) =>
          AppShell(path: state.uri.path, child: child),
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
        GoRoute(
          path: '/settings/app',
          name: AppRoutes.settingsApp,
          pageBuilder: (context, state) =>
              fadeThroughPage(child: const AppSettingsScreen()),
        ),
        GoRoute(
          path: '/profile',
          name: AppRoutes.profile,
          pageBuilder: (context, state) =>
              sharedAxisX(child: const ProfileScreen()),
        ),
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

        // ===== FIXED: give these leading slashes for consistency =====
        GoRoute(
          path: '/orders',
          name: 'orders',
          pageBuilder: (context, state) =>
              fadeThroughPage(child: const OrdersHistoryScreen()),
        ),
        GoRoute(
          path: '/contracts',
          name: 'contracts',
          pageBuilder: (context, state) =>
              fadeThroughPage(child: const ContractsScreen()),
        ),
        GoRoute(
          path: '/chats',
          name: 'chats',
          pageBuilder: (context, state) =>
              sharedAxisX(child: const ChatListScreen()),
        ),
        GoRoute(
          path: '/chats/:id',
          name: 'chatThread',
          pageBuilder: (context, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
            return sharedAxisX(child: ChatThreadScreen(threadId: id));
          },
        ),
        GoRoute(
          path: '/notifications',
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
  // Use push so the back button returns from App Settings:
  void goToSettingsApp() => push('/settings/app'); // ← changed to push()
  void goToProfile() => go('/profile');
  void goToEmployees() => go('/employees');

  // Vendor area
  void goToOrganization() => go('/organization');
  void goToMyEquipment() => go('/my-equipment');

  // Auth
  void goToAuth() => go('/auth');
}

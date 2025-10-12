// lib/main.dart
import 'dart:convert';
import 'dart:async';
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

// === Lightweight bootstrap state so macOS (and any platform) shows UI even if init stalls ===
final ValueNotifier<bool> _bootCompleted = ValueNotifier(false);
final ValueNotifier<String?> _bootError = ValueNotifier(null);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Render a minimal placeholder immediately (prevents blank/black window on macOS)
  runApp(const _BootstrapHost());

  // Perform the heavy initialization asynchronously
  unawaited(_doBootstrap());
}

Future<void> _doBootstrap() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize notifications after Firebase
    await Notifications().init();
    await notificationsStore.init();
    // Local notifications: supported on Android/iOS/macOS; skip on others
    final supportsLocalNotifs =
        (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS));
    if (supportsLocalNotifs) {
      try {
        await Notifications().initLocalNotifications();
      } catch (e) {
        log('Local notifications init skipped: $e');
      }
    }

    // FCM currently only meaningful on mobile (Android/iOS); guard desktop platforms
    final supportsFcm =
        (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

    if (supportsFcm) {
      // Ensure FCM auto-init and foreground presentation (iOS)
      try {
        await FirebaseMessaging.instance.setAutoInitEnabled(true);
        await FirebaseMessaging.instance
            .setForegroundNotificationPresentationOptions(
              alert: true,
              badge: true,
              sound: true,
            );
      } catch (e) {
        log('FCM presentation options error: $e');
      }

      // Register/save FCM token
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
      } catch (e) {
        log('FCM token init error: $e');
      }

      // Background handler (not web)
      if (!kIsWeb) {
        try {
          FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundMessage);
        } catch (e) {
          log('Background message handler set error: $e');
        }
      }

      // Foreground click / message listeners
      try {
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          if (message.notification != null) {
            log('Background message clicked!');
            final ctx = _rootNavigatorKey.currentContext;
            if (ctx != null) {
              ctx.push('/notifications');
            }
          }
        });

        FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
          final hasNotif = message.notification != null;
          final payloadData = message.data.isEmpty
              ? null
              : jsonEncode(message.data);
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

        final remoteMessage = await FirebaseMessaging.instance
            .getInitialMessage();
        if (remoteMessage != null) {
          log('App opened from terminated state via notification');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final ctx = _rootNavigatorKey.currentContext;
            if (ctx != null) {
              ctx.push('/notifications');
            }
          });
        }
      } catch (e) {
        log('Foreground messaging wiring error: $e');
      }
    }

    const androidEmuBase = 'https://sr.visioncit.com/api/';
    const prodBase = 'https://sr.visioncit.com/api/';
    const envBase = String.fromEnvironment('API_BASE_URL'); // optional override

    final baseUrl = kIsWeb
        ? (envBase.isNotEmpty ? envBase : prodBase)
        : ((defaultTargetPlatform == TargetPlatform.android && !kIsWeb)
              ? androidEmuBase
              : (envBase.isNotEmpty ? envBase : prodBase));

    Api.init(baseUrl: baseUrl);

    await AuthStore.instance.init();
    await sessionManager.enforceNow();
    await sessionManager.startFreshSession();

    AuthUser? lastUser = AuthStore.instance.user.value;
    AuthStore.instance.user.addListener(() async {
      final currentUser = AuthStore.instance.user.value;
      if (lastUser == null && currentUser != null) {
        await sessionManager.startFreshSession();
      }
      if (lastUser != null && currentUser == null) {
        await sessionManager.enforceNow();
      }
      lastUser = currentUser;
    });

    await AppPrefs.instance.init();
  } catch (e, st) {
    log('Bootstrap failure: $e\n$st');
    _bootError.value = e.toString();
  } finally {
    _bootCompleted.value = true;
  }
}

/// Minimal host that swaps itself for the real app when bootstrap completes.
class _BootstrapHost extends StatelessWidget {
  const _BootstrapHost();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _bootCompleted,
      builder: (_, done, __) {
        if (done) {
          return const HeavyApp();
        }
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Builder(
            builder: (_) => Container(
              color: Colors.white,
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Attempt to show splash asset if present
                  Image.asset(
                    'lib/assets/1.png',
                    width: 160,
                    height: 160,
                    errorBuilder: (_, __, ___) => const SizedBox(),
                  ),
                  const SizedBox(height: 24),
                  const CircularProgressIndicator(),
                  ValueListenableBuilder<String?>(
                    valueListenable: _bootError,
                    builder: (_, err, __) => err == null
                        ? const SizedBox.shrink()
                        : Padding(
                            padding: const EdgeInsets.only(
                              top: 16.0,
                              left: 24,
                              right: 24,
                            ),
                            child: Text(
                              'Startup issue: $err',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
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
              onGenerateTitle: (ctx) =>
                  AppLocalizations.of(ctx)?.appName ?? 'HeavyRent',
              theme: AppTheme.light(),
              darkTheme: AppTheme.dark(),
              scrollBehavior: const AppScrollBehavior(),
              routerConfig: _router,
              builder: (context, child) =>
                  OfflineBanner(child: child ?? const SizedBox.shrink()),
              themeMode: prefs.themeMode.value,
              locale: prefs.locale.value, // null => follow system
              supportedLocales: const [Locale('en'), Locale('ar')],
              localizationsDelegates: const [
                AppLocalizations.delegate,
                ...GlobalMaterialLocalizations.delegates,
              ],
              // optional, but recommended
              localeResolutionCallback: (device, supported) {
                // If user set explicit locale, Flutter uses it automatically.
                // If following system, pick device if supported, else fallback to Arabic.
                if (prefs.locale.value == null && device != null) {
                  for (final s in supported) {
                    if (s.languageCode == device.languageCode) return device;
                  }
                  return const Locale('ar');
                }
                return null; // let Flutter use explicit locale if present
              },
            );
          },
        );
      },
    );
  }
}

final _rootNavigatorKey = navigatorKey; // root
final _shellNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'shell',
); // one shell

final GoRouter _router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: <RouteBase>[
    // ===== Single shell for the 3-tab area =====
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) =>
          AppShell(path: state.uri.path, child: child),
      routes: [
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
          path: '/settings',
          name: AppRoutes.settings, // only defined once
          pageBuilder: (context, state) =>
              sharedAxisX(child: const SettingsScreen()),
        ),
      ],
    ),

    // ===== Non-tab routes (no bottom bar) =====
    GoRoute(
      path: '/equipment/:id',
      name: AppRoutes.equipmentDetails,
      pageBuilder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '');
        return sharedAxisX(child: EquipmentDetailsScreen(equipmentId: id ?? 0));
      },
    ),
    GoRoute(
      path: '/requests',
      name: AppRoutes.requests,
      pageBuilder: (context, state) =>
          sharedAxisX(child: const MyRequestsScreen()),
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
    GoRoute(
      path: '/auth',
      name: AppRoutes.auth,
      pageBuilder: (context, state) =>
          fadeThroughPage(child: const PhoneAuthScreen()),
    ),
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

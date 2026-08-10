import 'dart:async';
import 'dart:io';
import 'package:app_links/app_links.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

import 'firebase_options.dart';
import 'supabase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/models/group.dart';
import 'core/models/expense.dart';
import 'providers/auth_provider.dart';
import 'core/services/push_notification_service.dart';
import 'core/providers/version_check_provider.dart';
import 'presentation/widgets/update_dialog.dart';
import 'presentation/widgets/offline_banner.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isAndroid) {
    MediaStore.appFolder = "Equally";
    await MediaStore.ensureInitialized();
  }

  FirebaseAnalytics? analytics;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    analytics = FirebaseAnalytics.instance;
  } catch (e) {
    debugPrint('Firebase initialization skipped/failed: $e');
  }

  await Supabase.initialize(
    url: SupabaseOptions.url,
    publishableKey: SupabaseOptions.anonKey,
  );

  // Listen to auth events globally
  Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    if (data.event == AuthChangeEvent.passwordRecovery) {
      Future.delayed(const Duration(milliseconds: 300), () {
        AppRouter.router.refresh();
        AppRouter.router.go('${AppRouter.changePassword}?isRecovery=true');
      });
    } else if (data.event == AuthChangeEvent.signedIn) {
      Future.delayed(const Duration(milliseconds: 300), () async {
        final prefs = await SharedPreferences.getInstance();
        final pendingCode = prefs.getString('pending_invite_code');
        if (pendingCode != null && pendingCode.isNotEmpty) {
          await prefs.remove('pending_invite_code');
          AppRouter.router.refresh();
          AppRouter.router.go('/join/$pendingCode');
        } else {
          AppRouter.router.refresh();
          AppRouter.router.go(AppRouter.home);
        }
      });
    } else if (data.event == AuthChangeEvent.signedOut) {
      Future.delayed(const Duration(milliseconds: 300), () {
        AppRouter.router.refresh();
        AppRouter.router.go(AppRouter.login);
      });
    }
  });

  // Initialize Hive
  await Hive.initFlutter();

  // Register Hive adapters
  Hive.registerAdapter(GroupAdapter());
  Hive.registerAdapter(ExpenseAdapter());

  // Open boxes
  final groupsBox = await Hive.openBox<Group>('groups');
  await Hive.openBox<Expense>('expenses');
  await Hive.openBox('settings');
  await Hive.openBox('read_notifications');

  // Add sample groups if none exist
  if (groupsBox.isEmpty) {
    final sampleGroups = [
      Group(
        groupId: 'barcelona-trip',
        name: 'Barcelona Trip',
        members: ['AJ', 'SC', 'MT'],
        currency: 'USD',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      Group(
        groupId: 'grove-apartment',
        name: 'The Grove Apartment',
        members: ['AJ', 'PP', 'KW'],
        currency: 'USD',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      Group(
        groupId: 'pizza-night',
        name: 'Pizza Night',
        members: ['AJ', 'SC'],
        currency: 'USD',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
      Group(
        groupId: 'friday-dinner',
        name: 'Friday Dinner Crew',
        members: ['AJ', 'SC', 'MT', 'PP'],
        currency: 'USD',
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
      ),
    ];

    for (final group in sampleGroups) {
      await groupsBox.put(group.groupId, group);
    }
  }

  runApp(
    ProviderScope(
      observers: [
        // Add Riverpod observers if needed for debugging
      ],
      child: BillSplitterApp(analytics: analytics),
    ),
  );
}

class BillSplitterApp extends ConsumerStatefulWidget {
  const BillSplitterApp({super.key, this.analytics});

  final FirebaseAnalytics? analytics;

  @override
  ConsumerState<BillSplitterApp> createState() => _BillSplitterAppState();
}

class _BillSplitterAppState extends ConsumerState<BillSplitterApp> {
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  // Session-level flag to ensure the soft update is shown once per session only
  static bool _softUpdateChecked = false;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    // Listen for links when app is running (foreground/background)
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleIncomingLink(uri);
    });

    // Handle link when app is launched from cold start
    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        _handleIncomingLink(initialLink);
      }
    } catch (e) {
      debugPrint('Error getting initial deep link: $e');
    }
  }

  void _handleIncomingLink(Uri uri) {
    String? code;

    // Handle https://devorastudios.dev/join/CODE
    if (uri.host == 'devorastudios.dev' &&
        uri.pathSegments.isNotEmpty &&
        uri.pathSegments[0] == 'join' &&
        uri.pathSegments.length > 1) {
      code = uri.pathSegments[1];
    }
    // Handle equally://join/CODE or equally://devorastudios.dev/join/CODE
    else if (uri.scheme == 'equally') {
      if (uri.host == 'join' && uri.pathSegments.isNotEmpty) {
        code = uri.pathSegments[0];
      } else if (uri.pathSegments.isNotEmpty &&
          uri.pathSegments[0] == 'join' &&
          uri.pathSegments.length > 1) {
        code = uri.pathSegments[1];
      }
    }

    if (code != null && code.isNotEmpty) {
      AppRouter.router.push('/join/$code');
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(authStateListenerProvider);
    ref.watch(pushNotificationServiceProvider);

    // Watch the versionCheckProvider and show dialogs when results arrive
    ref.listen<AsyncValue<VersionCheckResult>>(versionCheckProvider,
        (previous, next) {
      next.when(
        data: (result) {
          debugPrint(
              'versionCheckProvider data received: isForce=${result.isForceUpdate}, isSoft=${result.isSoftUpdate}');

          void tryShowDialog() {
            final routeContext = AppRouter.navigatorKey.currentContext;
            if (routeContext == null || !routeContext.mounted) return;

            try {
              final router = GoRouter.of(routeContext);
              final currentRoute =
                  router.routeInformationProvider.value.uri.path;
              if (currentRoute == AppRouter.splash) {
                // Defer checking again in 500ms
                Future.delayed(
                    const Duration(milliseconds: 500), tryShowDialog);
                return;
              }
            } catch (_) {
              // GoRouter not fully initialized or not in tree yet, retry in 500ms
              Future.delayed(const Duration(milliseconds: 500), tryShowDialog);
              return;
            }

            if (result.isForceUpdate) {
              debugPrint('Showing force update dialog...');
              UpdateDialogs.showForceUpdate(routeContext);
            } else if (result.isSoftUpdate && !_softUpdateChecked) {
              _softUpdateChecked = true;
              UpdateDialogs.showSoftUpdate(routeContext);
            }
          }

          WidgetsBinding.instance.addPostFrameCallback((_) {
            tryShowDialog();
          });
        },
        loading: () {},
        error: (err, stack) {
          // Fail silently on config fetch errors
          debugPrint('Version check failed silently: $err');
        },
      );
    });

    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          title: 'Equally',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          routerConfig: AppRouter.router,
          debugShowCheckedModeBanner: false,
          builder: (context, child) {
            return Stack(
              children: [
                if (child != null) child,
                const OfflineBanner(),
              ],
            );
          },
        );
      },
    );
  }
}

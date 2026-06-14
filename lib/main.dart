import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'firebase_options.dart';
import 'supabase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/models/group.dart';
import 'core/models/expense.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Supabase.initialize(
    url: SupabaseOptions.url,
    publishableKey: SupabaseOptions.anonKey,
  );

  // Listen to password recovery events globally
  Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    if (data.event == AuthChangeEvent.passwordRecovery) {
      Future.delayed(const Duration(milliseconds: 300), () {
        AppRouter.router.refresh();
        AppRouter.router.go('${AppRouter.changePassword}?isRecovery=true');
      });
    }
  });

  FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  // Initialize Hive
  await Hive.initFlutter();

  // Register Hive adapters
  Hive.registerAdapter(GroupAdapter());
  Hive.registerAdapter(ExpenseAdapter());

  // Open boxes
  final groupsBox = await Hive.openBox<Group>('groups');
  await Hive.openBox<Expense>('expenses');

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

class BillSplitterApp extends ConsumerWidget {
  const BillSplitterApp({super.key, this.analytics});

  final FirebaseAnalytics? analytics;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          title: 'Bill Splitter',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          routerConfig: AppRouter.router,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

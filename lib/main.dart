import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/models/group.dart';
import 'core/models/expense.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize Firebase Analytics
  FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  // Initialize Hive
  await Hive.initFlutter();

  // Register Hive adapters
  Hive.registerAdapter(GroupAdapter());
  Hive.registerAdapter(ExpenseAdapter());

  // Open boxes
  await Hive.openBox<Group>('groups');
  await Hive.openBox<Expense>('expenses');

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
          themeMode: ThemeMode.system,
          routerConfig: AppRouter.router,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

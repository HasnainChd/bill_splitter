import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_text.dart';
import '../providers/tab_providers.dart';
import 'tabs/home_tab.dart';
import 'tabs/groups_tab.dart';
import 'tabs/settle_tab.dart';
import 'tabs/stats_tab.dart';
import 'tabs/profile_tab.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const List<Map<String, Object>> _tabs = [
    {'label': 'Home', 'icon': Icons.home_outlined, 'activeIcon': Icons.home_rounded},
    {'label': 'Groups', 'icon': Icons.people_outline_rounded, 'activeIcon': Icons.people_rounded},
    {'label': 'Settle', 'icon': Icons.check_circle_outline_rounded, 'activeIcon': Icons.check_circle_rounded},
    {'label': 'Stats', 'icon': Icons.bar_chart_rounded, 'activeIcon': Icons.bar_chart_rounded},
    {'label': 'Profile', 'icon': Icons.person_outline_rounded, 'activeIcon': Icons.person_rounded},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(homeTabIndexProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: IndexedStack(
          index: currentIndex,
          children: const [
            HomeTab(),
            GroupsTab(),
            SettleTab(),
            StatsTab(),
            ProfileTab(),
          ],
        ),
      ),
      bottomNavigationBar: _buildNavBar(ref, currentIndex),
    );
  }

  Widget _buildNavBar(WidgetRef ref, int currentIndex) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.navBarDark,
        border: Border(
          top: BorderSide(
            color: AppColors.white.withValues(alpha: 0.05),
            width: 1,
          ),
        ),
      ),
      child: BottomAppBar(
        color: Colors.transparent,
        elevation: 0,
        padding: EdgeInsets.zero,
        height: 64.h,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_tabs.length, (index) {
            final isSelected = currentIndex == index;
            final item = _tabs[index];
            return GestureDetector(
              onTap: () => ref.read(homeTabIndexProvider.notifier).state = index,
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                width: 60.w,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 24.w,
                      height: 3.h,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.onboardingViolet
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(1.5.r),
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Icon(
                      isSelected
                          ? (item['activeIcon'] as IconData)
                          : (item['icon'] as IconData),
                      color: isSelected
                          ? AppColors.onboardingViolet
                          : AppColors.white.withValues(alpha: 0.4),
                      size: 22.sp,
                    ),
                    SizedBox(height: 4.h),
                    AppText(
                      item['label'] as String,
                      fontSize: 10,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected
                          ? AppColors.onboardingViolet
                          : AppColors.white.withValues(alpha: 0.4),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

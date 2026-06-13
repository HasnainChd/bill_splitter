import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_text.dart';
import '../../core/widgets/app_card.dart';

final notificationsFilterProvider =
    StateProvider.autoDispose<String>((ref) => 'All');
final notificationsHasUnreadProvider =
    StateProvider.autoDispose<bool>((ref) => true);

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  static const List<Map<String, dynamic>> _allNotifications = [
    {
      'id': '1',
      'category': 'Payments',
      'group': 'JUST NOW',
      'title': 'Sarah Chen paid you back',
      'subtitle': '2 min ago',
      'amount': '+\$168.00',
      'amountColor': Color(0xFF00C896),
      'avatarText': 'SC',
      'avatarColor': AppColors.coralRed,
      'badgeIcon': Icons.check_circle_rounded,
      'badgeColor': Color(0xFF00C896),
      'isUnread': true,
    },
    {
      'id': '2',
      'category': 'Expenses',
      'group': 'JUST NOW',
      'title': 'Marcus Thompson added "Thai dinner" to Friday Crew',
      'subtitle': '12 min ago',
      'amount': '\$164.00',
      'amountColor': AppColors.white,
      'avatarText': 'MT',
      'avatarColor': AppColors.orange,
      'badgeIcon': Icons.restaurant_rounded,
      'badgeColor': AppColors.onboardingViolet,
      'isUnread': true,
    },
    {
      'id': '3',
      'category': 'Payments',
      'group': 'TODAY',
      'title': 'Divvy Reminder: you owe Marcus \$41 from Friday Crew',
      'subtitle': '9:00 AM',
      'amount': null,
      'amountColor': null,
      'avatarText': '⚡',
      'avatarColor': AppColors.onboardingViolet,
      'badgeIcon': Icons.alarm_rounded,
      'badgeColor': AppColors.orange,
      'isUnread': false,
    },
    {
      'id': '4',
      'category': 'Groups',
      'group': 'TODAY',
      'title': 'Priya Patel added you to NYC Getaway',
      'subtitle': '8:30 AM',
      'amount': null,
      'amountColor': null,
      'avatarText': 'PP',
      'avatarColor': Color(0xFF10B981),
      'badgeIcon': Icons.group_add_rounded,
      'badgeColor': AppColors.onboardingCyan,
      'isUnread': false,
    },
    {
      'id': '5',
      'category': 'Payments',
      'group': 'TODAY',
      'title': 'Kai Wilson settled up \$800.00 Grove Apt',
      'subtitle': '7:45 AM',
      'amount': '+\$800.00',
      'amountColor': Color(0xFF00C896),
      'avatarText': 'KW',
      'avatarColor': AppColors.onboardingCyan,
      'badgeIcon': Icons.check_circle_rounded,
      'badgeColor': Color(0xFF00C896),
      'isUnread': false,
    },
    {
      'id': '6',
      'category': 'Expenses',
      'group': 'YESTERDAY',
      'title': 'Sarah Chen added "Sagrada Família" to Barcelona Trip',
      'subtitle': 'May 17',
      'amount': '\$90.00',
      'amountColor': AppColors.white,
      'avatarText': 'SC',
      'avatarColor': AppColors.coralRed,
      'badgeIcon': Icons.flight_takeoff_rounded,
      'badgeColor': AppColors.onboardingCyan,
      'isUnread': false,
    },
    {
      'id': '7',
      'category': 'Groups',
      'group': 'YESTERDAY',
      'title': 'Marcus Thompson: "Split this differently?" Barcelona Trip',
      'subtitle': 'May 17',
      'amount': null,
      'amountColor': null,
      'avatarText': 'MT',
      'avatarColor': AppColors.orange,
      'badgeIcon': Icons.chat_bubble_rounded,
      'badgeColor': AppColors.onboardingViolet,
      'isUnread': false,
    },
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeFilter = ref.watch(notificationsFilterProvider);
    final hasUnread = ref.watch(notificationsHasUnreadProvider);

    // Filter list
    final filteredList = _allNotifications.where((n) {
      if (activeFilter == 'All') return true;
      return n['category'] == activeFilter;
    }).toList();

    // Group items
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var n in filteredList) {
      final grp = n['group'] as String;
      grouped.putIfAbsent(grp, () => []).add(n);
    }

    return SafeArea(
      top: false,
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: Column(
          children: [
            SizedBox(height: 30.h),
            // ── Header ──
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
              child: Row(
                children: [
                  Container(
                    width: 42.w,
                    height: 42.w,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1C38),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        Icons.chevron_left_rounded,
                        color: AppColors.white,
                        size: 24.sp,
                      ),
                      onPressed: () => context.pop(),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AppText(
                          'Notifications',
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.white,
                        ),
                        if (hasUnread) ...[
                          SizedBox(height: 2.h),
                          AppText(
                            '2 unread',
                            fontSize: 12,
                            color: AppColors.white.withValues(alpha: 0.4),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (hasUnread)
                    GestureDetector(
                      onTap: () {
                        ref
                            .read(notificationsHasUnreadProvider.notifier)
                            .state = false;
                      },
                      child: const AppText(
                        'Mark all read',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onboardingViolet,
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: 12.h),

            // ── Filters ──
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children:
                      ['All', 'Payments', 'Expenses', 'Groups'].map((filter) {
                    final isSelected = activeFilter == filter;
                    return Padding(
                      padding: EdgeInsets.only(right: 8.w),
                      child: GestureDetector(
                        onTap: () {
                          ref.read(notificationsFilterProvider.notifier).state =
                              filter;
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: EdgeInsets.symmetric(
                              horizontal: 16.w, vertical: 8.h),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.onboardingViolet
                                : AppColors.cardDark,
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.transparent
                                  : AppColors.white.withValues(alpha: 0.04),
                              width: 1.2,
                            ),
                          ),
                          child: AppText(
                            filter,
                            fontSize: 13,
                            fontWeight:
                                isSelected ? FontWeight.w800 : FontWeight.w700,
                            color: isSelected
                                ? AppColors.white
                                : AppColors.white.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            SizedBox(height: 20.h),

            // ── List ──
            Expanded(
              child: grouped.isEmpty
                  ? Center(
                      child: AppText(
                        'No notifications',
                        fontSize: 14,
                        color: AppColors.white.withValues(alpha: 0.3),
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      itemCount: grouped.keys.length,
                      itemBuilder: (context, index) {
                        final grpName = grouped.keys.elementAt(index);
                        final items = grouped[grpName]!;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(top: 12.h, bottom: 8.h),
                              child: AppText(
                                grpName,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppColors.white.withValues(alpha: 0.4),
                                letterSpacing: 1.2,
                              ),
                            ),
                            AppCard(
                              padding: EdgeInsets.zero,
                              child: Column(
                                children: List.generate(items.length, (idx) {
                                  final item = items[idx];
                                  final isItemUnread =
                                      hasUnread && (item['isUnread'] as bool);

                                  return Column(
                                    children: [
                                      ListTile(
                                        contentPadding: EdgeInsets.symmetric(
                                            horizontal: 14.w, vertical: 4.h),
                                        leading: Stack(
                                          clipBehavior: Clip.none,
                                          children: [
                                            Container(
                                              width: 38.w,
                                              height: 38.w,
                                              decoration: BoxDecoration(
                                                color: item['avatarColor']
                                                    as Color,
                                                borderRadius:
                                                    BorderRadius.circular(10.r),
                                              ),
                                              alignment: Alignment.center,
                                              child: AppText(
                                                item['avatarText'] as String,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.white,
                                              ),
                                            ),
                                            Positioned(
                                              bottom: -2.h,
                                              right: -2.w,
                                              child: Container(
                                                width: 16.w,
                                                height: 16.w,
                                                decoration: BoxDecoration(
                                                  color:
                                                      const Color(0xFF1E1C38),
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                      color: AppColors.cardDark,
                                                      width: 1.5.w),
                                                ),
                                                alignment: Alignment.center,
                                                child: Icon(
                                                  item['badgeIcon'] as IconData,
                                                  color: item['badgeColor']
                                                      as Color,
                                                  size: 10.sp,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        title: AppText(
                                          item['title'] as String,
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.white,
                                          height: 1.25,
                                        ),
                                        subtitle: Row(
                                          children: [
                                            AppText(
                                              item['subtitle'] as String,
                                              fontSize: 11,
                                              color: AppColors.white
                                                  .withValues(alpha: 0.35),
                                            ),
                                            if (isItemUnread) ...[
                                              SizedBox(width: 6.w),
                                              Container(
                                                width: 6.w,
                                                height: 6.w,
                                                decoration: const BoxDecoration(
                                                  color: AppColors
                                                      .onboardingViolet,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        trailing: item['amount'] != null
                                            ? AppText(
                                                item['amount'] as String,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w800,
                                                color: item['amountColor']
                                                    as Color,
                                              )
                                            : null,
                                      ),
                                      if (idx < items.length - 1)
                                        Divider(
                                          color: Colors.white
                                              .withValues(alpha: 0.04),
                                          height: 1,
                                          thickness: 1,
                                          indent: 64.w,
                                        ),
                                    ],
                                  );
                                }),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

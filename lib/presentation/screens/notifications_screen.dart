import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_text.dart';
import '../../core/widgets/app_card.dart';
import '../../providers/notifications_provider.dart';

final notificationsFilterProvider =
    StateProvider.autoDispose<String>((ref) => 'All');
final notificationsHasUnreadProvider =
    StateProvider.autoDispose<bool>((ref) => true);

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  String _getGroupLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final localDate = date.toLocal();
    final itemDate = DateTime(localDate.year, localDate.month, localDate.day);

    final diffInMinutes = now.difference(localDate).inMinutes;
    if (diffInMinutes < 60 && diffInMinutes >= 0) {
      return 'JUST NOW';
    } else if (itemDate == today) {
      return 'TODAY';
    } else if (itemDate == yesterday) {
      return 'YESTERDAY';
    } else {
      return 'OLDER';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeFilter = ref.watch(notificationsFilterProvider);
    final hasUnread = ref.watch(notificationsHasUnreadProvider);
    final notifications = ref.watch(dynamicNotificationsProvider);

    // Filter list
    final filteredList = notifications.where((n) {
      if (activeFilter == 'All') return true;
      return n.category == activeFilter;
    }).toList();

    // Group items
    final Map<String, List<NotificationItem>> grouped = {};
    for (var n in filteredList) {
      final grp = _getGroupLabel(n.date);
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
                                      hasUnread && item.isUnread;

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
                                                color: item.avatarColor,
                                                borderRadius:
                                                    BorderRadius.circular(10.r),
                                              ),
                                              alignment: Alignment.center,
                                              child: AppText(
                                                item.avatarText,
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
                                                  item.badgeIcon,
                                                  color: item.badgeColor,
                                                  size: 10.sp,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        title: AppText(
                                          item.title,
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.white,
                                          height: 1.25,
                                        ),
                                        subtitle: Row(
                                          children: [
                                            AppText(
                                              item.subtitle,
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
                                        trailing: item.amount != null
                                            ? AppText(
                                                item.amount!,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w800,
                                                color: item.amountColor ?? Colors.white,
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

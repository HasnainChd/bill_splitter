import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_text.dart';
import '../../core/widgets/app_card.dart';
import '../../providers/notifications_provider.dart';

final activityFilterProvider = StateProvider.autoDispose<String>((ref) => 'All');

class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  String _getEmojiForCategory(String category) {
    if (category == 'Expenses') return '🍕';
    if (category == 'Payments') return '💸';
    if (category == 'Groups') return '👥';
    return '📝';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeFilter = ref.watch(activityFilterProvider);
    final notifications = ref.watch(dynamicNotificationsProvider);

    final filtered = notifications.where((n) {
      if (activeFilter == 'All') return true;
      return n.category == activeFilter;
    }).toList();

    // Group items by month-year
    final Map<String, List<NotificationItem>> grouped = {};
    for (var n in filtered) {
      final monthStr = DateFormat('MMMM yyyy').format(n.date);
      grouped.putIfAbsent(monthStr, () => []).add(n);
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back button
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
                  // Title
                  const AppText(
                    'Activity',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.white,
                  ),
                  // Spacer to align title center
                  SizedBox(width: 42.w),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // ── Horizontal Filter Pills ──
            SizedBox(
              height: 38.h,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                children: [
                  _buildFilterPill(ref, 'All', activeFilter),
                  _buildFilterPill(ref, 'Expenses', activeFilter),
                  _buildFilterPill(ref, 'Payments', activeFilter),
                  _buildFilterPill(ref, 'Groups', activeFilter),
                ],
              ),
            ),
            SizedBox(height: 20.h),

            // ── Scrollable Activity Content ──
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: AppText(
                        'No activities found',
                        fontSize: 14,
                        color: AppColors.white.withValues(alpha: 0.3),
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      itemCount: grouped.keys.length,
                      itemBuilder: (context, index) {
                        final monthStr = grouped.keys.elementAt(index);
                        final items = grouped[monthStr]!;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader(
                              title: monthStr,
                              amountBadge: '${items.length} ${items.length == 1 ? 'item' : 'items'}',
                              isPositive: true,
                            ),
                            SizedBox(height: 12.h),
                            AppCard(
                              padding: EdgeInsets.zero,
                              child: Column(
                                children: List.generate(items.length, (idx) {
                                  final item = items[idx];
                                  return Column(
                                    children: [
                                      _buildActivityItem(
                                        emoji: _getEmojiForCategory(item.category),
                                        title: item.title,
                                        subtitle: '${item.groupName} • ${item.subtitle}',
                                        amount: item.amount ?? '',
                                        amountColor: item.amountColor ?? AppColors.white,
                                      ),
                                      if (idx < items.length - 1)
                                        _buildDivider(),
                                    ],
                                  );
                                }),
                              ),
                            ),
                            SizedBox(height: 24.h),
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

  Widget _buildFilterPill(WidgetRef ref, String label, String activeFilter) {
    final isSelected = activeFilter == label;
    return GestureDetector(
      onTap: () => ref.read(activityFilterProvider.notifier).state = label,
      child: Container(
        margin: EdgeInsets.only(right: 8.w),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color:
              isSelected ? AppColors.onboardingViolet : const Color(0xFF1E1C38),
          borderRadius: BorderRadius.circular(18.r),
        ),
        alignment: Alignment.center,
        child: AppText(
          label,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isSelected
              ? AppColors.white
              : AppColors.white.withValues(alpha: 0.4),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String amountBadge,
    required bool isPositive,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppText(
          title,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.white.withValues(alpha: 0.4),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: AppColors.onboardingViolet.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: AppText(
            amountBadge,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppColors.onboardingViolet,
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem({
    required String emoji,
    required String title,
    required String subtitle,
    required String amount,
    required Color amountColor,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: const Color(0xFF1E1C38),
              borderRadius: BorderRadius.circular(12.r),
            ),
            alignment: Alignment.center,
            child: AppText(
              emoji,
              fontSize: 16,
            ),
          ),
          SizedBox(width: 12.w),

          // Titles
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  title,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
                AppText(
                  subtitle,
                  fontSize: 11,
                  color: AppColors.white.withValues(alpha: 0.35),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),

          // Amount
          if (amount.isNotEmpty)
            AppText(
              amount,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: amountColor,
            ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: Colors.white.withValues(alpha: 0.04),
      height: 1,
      thickness: 1,
      indent: 68.w,
    );
  }
}

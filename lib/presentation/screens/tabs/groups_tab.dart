import 'package:bill_splitter/core/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/group.dart';
import '../../../core/widgets/app_text.dart';
import '../../../core/router/app_router.dart';
import '../../../providers/group_provider.dart';
import '../../providers/tab_providers.dart';

class GroupsTab extends ConsumerWidget {
  const GroupsTab({super.key});

  static List<Color> _gradientForId(String id) {
    switch (id) {
      case 'barcelona-trip':
        return [const Color(0xFF818CF8), const Color(0xFF6366F1)];
      case 'grove-apartment':
        return [const Color(0xFF38BDF8), const Color(0xFF0EA5E9)];
      default:
        return [const Color(0xFFFB923C), const Color(0xFFF97316)];
    }
  }

  // Helper to map a Group to our static data format
  Map<String, dynamic> _groupToMap(Group group) {
    final isOwed =
        group.groupId == 'barcelona-trip' || group.groupId == 'grove-apartment';
    return {
      'id': group.groupId,
      'name': group.name.replaceFirst(' ', '\n'),
      'rawName': group.name,
      'members': group.members,
      'memberCount': group.members.length,
      'amount': isOwed ? 337.0 : 41.0,
      'statusText': isOwed ? 'You are owed' : 'You owe',
      'isOwed': isOwed,
      'timeText':
          'Active · ${DateTime.now().difference(group.createdAt).inDays} days ago',
      'icon': group.groupId == 'barcelona-trip'
          ? Icons.flight_takeoff_rounded
          : group.groupId == 'grove-apartment'
              ? Icons.home_rounded
              : Icons.local_pizza_rounded,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchQuery = ref.watch(groupSearchQueryProvider);
    final activeFilter = ref.watch(groupFilterProvider);
    final searchController = ref.watch(groupSearchControllerProvider);
    final groupState = ref.watch(groupProvider);

    final allGroups = groupState.groups.map(_groupToMap).toList();

    final filteredGroups = allGroups.where((group) {
      final matchesSearch = (group['rawName'] as String)
          .toLowerCase()
          .contains(searchQuery.toLowerCase());
      if (!matchesSearch) return false;
      if (activeFilter == 'Owed') return group['isOwed'] == true;
      if (activeFilter == 'Owe') return group['isOwed'] == false;
      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 16.h),

        // ── Title + New Button ──
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const AppText(
                'Groups',
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.white,
              ),
              IconButton(
                onPressed: () => context.push(AppRouter.createGroup),
                icon: const Icon(Icons.add, color: AppColors.white),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.onboardingViolet,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),

        // ── Search TextField ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: AppTextField(
            controller: searchController,
            onChanged: (val) =>
                ref.read(groupSearchQueryProvider.notifier).state = val,
            hint: 'Search Groups...',
          ),
        ),

        SizedBox(height: 16.h),

        // ── Stats / Filter Chips ──
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildStatChip(
                  ref: ref,
                  label: '3 Groups',
                  filterKey: 'All',
                  activeFilter: activeFilter,
                  selectedColor: AppColors.onboardingViolet,
                  chipColor: AppColors.onboardingViolet.withValues(alpha: 0.12),
                  textColor: AppColors.onboardingViolet,
                ),
                SizedBox(width: 8.w),
                _buildStatChip(
                  ref: ref,
                  label: 'Owed \$1,077',
                  filterKey: 'Owed',
                  activeFilter: activeFilter,
                  selectedColor: const Color(0xFF10B981),
                  chipColor: const Color(0xFF10B981).withValues(alpha: 0.12),
                  textColor: const Color(0xFF10B981),
                ),
                SizedBox(width: 8.w),
                _buildStatChip(
                  ref: ref,
                  label: 'Owe \$41',
                  filterKey: 'Owe',
                  activeFilter: activeFilter,
                  selectedColor: AppColors.balanceOwed,
                  chipColor: AppColors.balanceOwed.withValues(alpha: 0.12),
                  textColor: AppColors.balanceOwed,
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 20.h),

        // ── Groups List ──
        Expanded(
          child: filteredGroups.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  itemCount: filteredGroups.length,
                  itemBuilder: (context, index) =>
                      _buildGroupCard(context, filteredGroups[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildStatChip({
    required WidgetRef ref,
    required String label,
    required String filterKey,
    required String activeFilter,
    required Color selectedColor,
    required Color chipColor,
    required Color textColor,
  }) {
    final isSelected = activeFilter == filterKey;
    return GestureDetector(
      onTap: () => ref.read(groupFilterProvider.notifier).state = filterKey,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : chipColor,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : textColor.withValues(alpha: 0.2),
          ),
        ),
        child: AppText(
          label,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: isSelected ? AppColors.white : textColor,
        ),
      ),
    );
  }

  Widget _buildGroupCard(BuildContext context, Map<String, dynamic> group) {
    final bool isOwed = group['isOwed'] == true;
    final List<Color> gradients = _gradientForId(group['id'] as String);

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          // ── Header — gradient banner ──
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradients,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20.r),
                topRight: Radius.circular(20.r),
              ),
            ),
            child: Row(
              children: [
                Icon(group['icon'] as IconData,
                    color: AppColors.white, size: 28.sp),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        group['name'] as String,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.white,
                      ),
                      SizedBox(height: 4.h),
                      AppText(
                        group['timeText'] as String,
                        fontSize: 11,
                        color: AppColors.white.withValues(alpha: 0.7),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Body — members + balance ──
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                _buildAvatars(group['members'] as List<String>),
                SizedBox(width: 8.w),
                AppText(
                  '${group['memberCount']} members',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white.withValues(alpha: 0.5),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    AppText(
                      group['statusText'] as String,
                      fontSize: 11,
                      color: AppColors.white.withValues(alpha: 0.4),
                    ),
                    SizedBox(height: 4.h),
                    AppText(
                      '\$${(group['amount'] as double).toStringAsFixed(0)}',
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isOwed
                          ? const Color(0xFF10B981)
                          : AppColors.balanceOwed,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Footer — View + Remind buttons ──
          if (isOwed)
            Padding(
              padding: EdgeInsets.only(left: 16.w, right: 16.w, bottom: 16.h),
              child: Row(
                children: [
                  Expanded(
                    child: _buildFooterButton(
                      label: 'View',
                      onTap: () => context.push(
                        '${AppRouter.groupDetail}?groupId=${group['id']}',
                      ),
                      textColor: AppColors.white,
                      borderColor: AppColors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _buildFooterButton(
                      label: 'Remind',
                      onTap: () {},
                      textColor: const Color(0xFF10B981),
                      borderColor:
                          const Color(0xFF10B981).withValues(alpha: 0.25),
                      bgColor: const Color(0xFF10B981).withValues(alpha: 0.08),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFooterButton({
    required String label,
    required VoidCallback onTap,
    required Color textColor,
    required Color borderColor,
    Color? bgColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38.h,
        decoration: BoxDecoration(
          color: bgColor ?? AppColors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: borderColor),
        ),
        alignment: Alignment.center,
        child: AppText(
          label,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildAvatars(List<String> initials) {
    const Map<String, Color> avatarColors = {
      'AJ': AppColors.onboardingViolet,
      'SC': AppColors.groupBlue,
      'MT': AppColors.groupOrange,
      'PP': Color(0xFF10B981),
      'KW': Color(0xFF8B5CF6),
    };
    return SizedBox(
      height: 24.h,
      width: (initials.length - 1) * 14.w + 24.h,
      child: Stack(
        children: List.generate(initials.length, (i) {
          final color = avatarColors[initials[i]] ?? AppColors.onboardingViolet;
          return Positioned(
            left: i * 14.w,
            child: Container(
              width: 24.h,
              height: 24.h,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.backgroundDark, width: 2.w),
              ),
              alignment: Alignment.center,
              child: AppText(
                initials[i],
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: AppColors.white,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded,
              size: 48.sp, color: AppColors.white.withValues(alpha: 0.3)),
          SizedBox(height: 16.h),
          const AppText(
            'No groups match your search',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.white,
          ),
        ],
      ),
    );
  }
}

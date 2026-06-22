import 'package:bill_splitter/core/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_text.dart';
import '../../../core/router/app_router.dart';
import '../../../providers/group_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/expense_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../providers/tab_providers.dart';
import '../../../core/utils/group_icon_helper.dart';

class GroupsTab extends ConsumerWidget {
  const GroupsTab({super.key});

  static List<Color> _gradientForId(String id) {
    final index = id.hashCode.abs() % AppColors.cardGradients.length;
    return AppColors.cardGradients[index];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchQuery = ref.watch(groupSearchQueryProvider);
    final activeFilter = ref.watch(groupFilterProvider);
    final searchController = ref.watch(groupSearchControllerProvider);
    final groupState = ref.watch(groupProvider);
    final currentUserId = ref.watch(supabaseUserProvider)?.id;
    final defaultCurrency = ref.watch(defaultCurrencyProvider);
    final currencyCode = defaultCurrency.length >= 3
        ? defaultCurrency.substring(0, 3)
        : 'PKR';

    double totalOwed = 0.0;
    double totalOwe = 0.0;
    final List<Map<String, dynamic>> mappedGroups = [];

    for (final group in groupState.groups) {
      final balances = ref.watch(balancesForGroupProvider(group.groupId));
      final myBalance = currentUserId != null ? (balances[currentUserId] ?? 0.0) : 0.0;

      if (myBalance > 0) {
        totalOwed += myBalance;
      } else if (myBalance < 0) {
        totalOwe += myBalance.abs();
      }

      mappedGroups.add({
        'id': group.groupId,
        'name': GroupIconHelper.getCleanGroupName(group.name).replaceFirst(' ', '\n'),
        'rawName': GroupIconHelper.getCleanGroupName(group.name),
        'members': group.members,
        'memberCount': group.members.length,
        'amount': myBalance.abs(),
        'myBalance': myBalance,
        'statusText': myBalance == 0
            ? 'Settled up'
            : myBalance > 0
                ? 'Others owe you'
                : 'You owe others',
        'isOwed': myBalance > 0,
        'currency': group.currency,
        'timeText': (() {
          final diff = DateTime.now().difference(group.createdAt.toLocal());
          final days = diff.inDays.abs();
          if (days > 0) {
            return 'Active · $days ${days == 1 ? 'day' : 'days'} ago';
          }
          final hours = diff.inHours.abs();
          if (hours > 0) {
            return 'Active · $hours ${hours == 1 ? 'hour' : 'hours'} ago';
          }
          final minutes = diff.inMinutes.abs();
          if (minutes > 0) {
            return 'Active · $minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
          }
          return 'Active · just now';
        })(),
        'icon': GroupIconHelper.getIconForGroup(group),
      });
    }

    final filteredGroups = mappedGroups.where((group) {
      final matchesSearch = (group['rawName'] as String)
          .toLowerCase()
          .contains(searchQuery.toLowerCase());
      if (!matchesSearch) return false;
      if (activeFilter == 'Owed') return group['isOwed'] == true;
      if (activeFilter == 'Owe') return (group['myBalance'] as double) < 0;
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
                  label: '${mappedGroups.length} Groups',
                  filterKey: 'All',
                  activeFilter: activeFilter,
                  selectedColor: AppColors.onboardingViolet,
                  chipColor: AppColors.onboardingViolet.withValues(alpha: 0.12),
                  textColor: AppColors.onboardingViolet,
                ),
                SizedBox(width: 8.w),
                _buildStatChip(
                  ref: ref,
                  label: 'Others Owe You · $currencyCode ${totalOwed.toStringAsFixed(0)}',
                  filterKey: 'Owed',
                  activeFilter: activeFilter,
                  selectedColor: const Color(0xFF10B981),
                  chipColor: const Color(0xFF10B981).withValues(alpha: 0.12),
                  textColor: const Color(0xFF10B981),
                ),
                SizedBox(width: 8.w),
                _buildStatChip(
                  ref: ref,
                  label: 'You Owe Others · $currencyCode ${totalOwe.toStringAsFixed(0)}',
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
          child: RefreshIndicator(
            onRefresh: () async {
              await ref.read(groupProvider.notifier).loadGroups();
            },
            child: filteredGroups.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    itemCount: filteredGroups.length,
                    itemBuilder: (context, index) =>
                        _buildGroupCard(context, filteredGroups[index]),
                  ),
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

    return GestureDetector(
      onTap: () => context.push(
        '${AppRouter.groupDetail}?groupId=${group['id']}',
      ),
      child: Container(
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
                          group['rawName'] as String,
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
                  GroupAvatarsWidget(groupId: group['id'] as String),
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
                        group['myBalance'] == 0
                            ? '${group['currency']} 0'
                            : '${group['currency']} ${(group['amount'] as double).toStringAsFixed(0)}',
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: group['myBalance'] == 0
                            ? AppColors.white
                            : group['myBalance'] > 0
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

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      child: Container(
        height: 300.h,
        alignment: Alignment.center,
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
      ),
    );
  }
}

class GroupAvatarsWidget extends ConsumerWidget {
  final String groupId;
  const GroupAvatarsWidget({super.key, required this.groupId});

  static const List<Color> _avatarColors = [
    Color(0xFF818CF8), // violet
    Color(0xFFEC4899), // pink
    Color(0xFFF59E0B), // amber
    Color(0xFF10B981), // green
    Color(0xFF8B5CF6), // purple
    Color(0xFF38BDF8), // cyan
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(groupMembersProvider(groupId));

    return membersAsync.when(
      loading: () => SizedBox(
        height: 24.h,
        width: 40.w,
        child: const Center(
          child: SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white24),
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (members) {
        if (members.isEmpty) return const SizedBox.shrink();

        // Take up to 4 members for avatar display
        final displayMembers = members.take(4).toList();

        return SizedBox(
          height: 24.h,
          width: (displayMembers.length - 1) * 14.w + 24.h,
          child: Stack(
            children: List.generate(displayMembers.length, (i) {
              final member = displayMembers[i];
              final nameParts = member.fullName.trim().split(' ');
              final initials = nameParts.length >= 2
                  ? '${nameParts[0][0]}${nameParts[1][0]}'
                  : nameParts.isNotEmpty && nameParts[0].isNotEmpty
                      ? nameParts[0][0]
                      : 'U';

              final avatarColor = _avatarColors[member.id.hashCode.abs() % _avatarColors.length];

              return Positioned(
                left: i * 14.w,
                child: Container(
                  width: 24.h,
                  height: 24.h,
                  decoration: BoxDecoration(
                    color: avatarColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.backgroundDark, width: 2.w),
                    image: member.avatarUrl.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(member.avatarUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: member.avatarUrl.isEmpty
                      ? AppText(
                          initials.toUpperCase(),
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: AppColors.white,
                        )
                      : null,
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

import 'package:bill_splitter/core/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/utils/app_dialog.dart';
import '../../../core/utils/app_snackbar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    final currencyCode =
        defaultCurrency.length >= 3 ? defaultCurrency.substring(0, 3) : 'PKR';

    final expenseState = ref.watch(expenseProvider);

    double totalOwed = 0.0;
    double totalOwe = 0.0;
    final List<Map<String, dynamic>> mappedGroups = [];

    for (final group in groupState.groups) {
      final balances = ref.watch(balancesForGroupProvider(group.groupId));
      final myBalance =
          currentUserId != null ? (balances[currentUserId] ?? 0.0) : 0.0;
      final hasExpenses =
          expenseState.expenses.any((e) => e.groupId == group.groupId);

      if (myBalance > 0) {
        totalOwed += myBalance;
      } else if (myBalance < 0) {
        totalOwe += myBalance.abs();
      }

      mappedGroups.add({
        'id': group.groupId,
        'name': GroupIconHelper.getCleanGroupName(group.name)
            .replaceFirst(' ', '\n'),
        'rawName': GroupIconHelper.getCleanGroupName(group.name),
        'members': group.members,
        'memberCount': group.members.length,
        'amount': myBalance.abs(),
        'myBalance': myBalance,
        'statusText': myBalance == 0
            ? (hasExpenses ? 'Settled up' : 'No expenses yet')
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

        SizedBox(height: 12.h),

        // ── Enter Invite Code Button ──
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: InkWell(
            onTap: () => _showJoinGroupBottomSheet(context, ref),
            borderRadius: BorderRadius.circular(12.r),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 12.h),
              decoration: BoxDecoration(
                color: AppColors.onboardingViolet.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: AppColors.onboardingViolet.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.vpn_key_rounded,
                    color: AppColors.onboardingViolet,
                    size: 18.sp,
                  ),
                  SizedBox(width: 8.w),
                  const AppText(
                    'Enter Invite Code to Join',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onboardingViolet,
                  ),
                ],
              ),
            ),
          ),
        ),

        SizedBox(height: 12.h),

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
                  label:
                      'Others Owe You · $currencyCode ${totalOwed.toStringAsFixed(0)}',
                  filterKey: 'Owed',
                  activeFilter: activeFilter,
                  selectedColor: const Color(0xFF10B981),
                  chipColor: const Color(0xFF10B981).withValues(alpha: 0.12),
                  textColor: const Color(0xFF10B981),
                ),
                SizedBox(width: 8.w),
                _buildStatChip(
                  ref: ref,
                  label:
                      'You Owe Others · $currencyCode ${totalOwe.toStringAsFixed(0)}',
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
                ? AppEmptyState(
                    title: 'No Groups Found',
                    subtitle: searchQuery.isNotEmpty
                        ? 'We couldn\'t find any groups matching your search.'
                        : 'You aren\'t part of any groups yet. Create one to start splitting bills!',
                    icon: Icons.group_off_rounded,
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    itemCount: filteredGroups.length,
                    itemBuilder: (context, index) => _buildGroupCard(
                        context, ref, currentUserId, filteredGroups[index]),
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

  Widget _buildGroupCard(BuildContext context, WidgetRef ref,
      String? currentUserId, Map<String, dynamic> group) {
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
                        onTap: () async {
                          final balances =
                              ref.read(balancesForGroupProvider(group['id']));
                          final targetIds = (group['members'] as List<dynamic>)
                              .map((id) => id.toString())
                              .where((id) =>
                                  id != currentUserId &&
                                  (balances[id] ?? 0.0) < -0.01)
                              .toList();

                          if (targetIds.isEmpty) {
                            AppSnackBar.showError(context,
                                'All members in this group are already settled!');
                            return;
                          }

                          final confirm = await AppDialog.showConfirm(
                            context,
                            title: 'Send Reminder',
                            message:
                                'Are you sure you want to send a payment reminder to all members who owe money in this group?',
                            confirmText: 'Send',
                            cancelText: 'Cancel',
                          );

                          if (confirm == true) {
                            try {
                              final response = await Supabase
                                  .instance.client.functions
                                  .invoke(
                                'send-notification',
                                body: {
                                  'table': 'payment_reminders',
                                  'new_record': {
                                    'group_id': group['id'],
                                    'sender_id': currentUserId,
                                    'target_user_ids': targetIds,
                                    'amount': group['amount'],
                                    'currency': group['currency'],
                                  },
                                },
                              );

                              if (response.status != 200 &&
                                  response.status != 204) {
                                throw Exception(
                                    'Server returned status code ${response.status}');
                              }

                              if (context.mounted) {
                                AppSnackBar.showSuccess(
                                  context,
                                  'Reminder sent to members!',
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                AppSnackBar.showError(
                                  context,
                                  'Failed to send reminder: $e',
                                );
                              }
                            }
                          }
                        },
                        textColor: const Color(0xFF10B981),
                        borderColor:
                            const Color(0xFF10B981).withValues(alpha: 0.25),
                        bgColor:
                            const Color(0xFF10B981).withValues(alpha: 0.08),
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

  void _showJoinGroupBottomSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundDark,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (context) {
        return const _JoinGroupBottomSheet();
      },
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
            child: CircularProgressIndicator(
                strokeWidth: 1.5, color: Colors.white24),
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

              final avatarColor = _avatarColors[
                  member.id.hashCode.abs() % _avatarColors.length];

              return Positioned(
                left: i * 14.w,
                child: Container(
                  width: 24.h,
                  height: 24.h,
                  decoration: BoxDecoration(
                    color: avatarColor,
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: AppColors.backgroundDark, width: 2.w),
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

final joinGroupLoadingProvider =
    StateProvider.autoDispose<bool>((ref) => false);
final joinGroupErrorProvider =
    StateProvider.autoDispose<String?>((ref) => null);
final joinGroupCodeControllerProvider =
    Provider.autoDispose<TextEditingController>((ref) {
  final controller = TextEditingController();
  ref.onDispose(() => controller.dispose());
  return controller;
});

class _JoinGroupBottomSheet extends ConsumerWidget {
  const _JoinGroupBottomSheet();

  Future<void> _joinGroup(BuildContext context, WidgetRef ref, TextEditingController controller) async {
    final code = controller.text.trim().toUpperCase();
    if (code.length != 8) {
      ref.read(joinGroupErrorProvider.notifier).state =
          'Invite code must be exactly 8 characters';
      return;
    }

    ref.read(joinGroupLoadingProvider.notifier).state = true;
    ref.read(joinGroupErrorProvider.notifier).state = null;

    try {
      final group =
          await ref.read(groupProvider.notifier).joinGroupByInviteCode(code);
      if (context.mounted) {
        Navigator.pop(context);
        AppSnackBar.showSuccess(
            context, 'Successfully joined "${group.name}"!');
      }
    } catch (e) {
      if (context.mounted) {
        ref.read(joinGroupLoadingProvider.notifier).state = false;
        final errorMsg = (() {
          if (e.toString() == 'already_member') {
            return "You're already in this group";
          } else if (e.toString() == 'invalid_code') {
            return "Invalid invite code. Please check and try again.";
          } else {
            return "Failed to join group: $e";
          }
        })();
        ref.read(joinGroupErrorProvider.notifier).state = errorMsg;
      }
    }
  }

  Future<void> _pasteFromClipboard(WidgetRef ref, TextEditingController controller) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null && data.text != null) {
      final pastedText = data.text!.trim().toUpperCase();
      if (pastedText.length <= 8) {
        controller.text = pastedText;
        controller.selection = TextSelection.fromPosition(
          TextPosition(offset: pastedText.length),
        );
      } else {
        final truncated = pastedText.substring(0, 8);
        controller.text = truncated;
        controller.selection = TextSelection.fromPosition(
          TextPosition(offset: 8),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(joinGroupLoadingProvider);
    final errorMessage = ref.watch(joinGroupErrorProvider);
    final controller = ref.watch(joinGroupCodeControllerProvider);

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 24.w,
          right: 24.w,
          top: 24.h,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16.h,
        ),
        child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const AppText(
                'Join Group via Code',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.white,
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white54),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          const AppText(
            'Enter the 8-character invite code shared with you to join the group.',
            fontSize: 13,
            color: Colors.white54,
          ),
          SizedBox(height: 20.h),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  autofocus: true,
                  maxLength: 8,
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                  ),
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: 'ENTER CODE',
                    hintStyle: TextStyle(
                      color: Colors.white24,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                    ),
                    counterText: '',
                    filled: true,
                    fillColor: AppColors.cardDark,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 14.h,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(
                        color: AppColors.white.withValues(alpha: 0.05),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(
                        color: AppColors.white.withValues(alpha: 0.05),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: const BorderSide(
                        color: AppColors.onboardingViolet,
                      ),
                    ),
                  ),
                  onChanged: (val) {
                    if (val.length == 8) {
                      FocusScope.of(context).unfocus();
                    }
                  },
                ),
              ),
              SizedBox(width: 8.w),
              IconButton(
                icon: const Icon(Icons.content_paste,
                    color: AppColors.onboardingViolet),
                style: IconButton.styleFrom(
                  backgroundColor:
                      AppColors.onboardingViolet.withValues(alpha: 0.12),
                  padding:
                      EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                onPressed: () => _pasteFromClipboard(ref, controller),
              ),
            ],
          ),
          if (errorMessage != null) ...[
            SizedBox(height: 8.h),
            AppText(
              errorMessage,
              color: AppColors.coralRed,
              fontSize: 12,
            ),
          ],
          SizedBox(height: 24.h),
          SizedBox(
            width: double.infinity,
            height: 48.h,
            child: ElevatedButton(
              onPressed: isLoading ? null : () => _joinGroup(context, ref, controller),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.onboardingViolet,
                disabledBackgroundColor:
                    AppColors.onboardingViolet.withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    )
                  : const AppText(
                      'Join Group',
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                    ),
            ),
          ),
        ],
      ),
    ));
  }
}

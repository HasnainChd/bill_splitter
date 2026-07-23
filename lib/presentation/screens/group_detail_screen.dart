import 'package:bill_splitter/providers/profile_provider.dart';
import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
// import 'package:qr_flutter/qr_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/expense.dart';
import '../../core/models/group.dart';
import '../../core/widgets/app_text.dart';
import '../../core/widgets/app_text_field.dart';
import '../../providers/auth_provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/expense_provider.dart';
import '../providers/screen_providers.dart';
import '../../core/utils/app_dialog.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/utils/error_handler.dart';
import '../../core/widgets/app_empty_state.dart';
import '../../core/utils/group_icon_helper.dart';
import '../../providers/settings_provider.dart';
import '../../core/utils/app_date_formatter.dart';

class GroupDetailScreen extends ConsumerWidget {
  final String groupId;
  const GroupDetailScreen({super.key, required this.groupId});

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
    final activeDateFormat = ref.watch(dateFormatProvider);
    final groupState = ref.watch(groupProvider);
    final actualExpenses = ref.watch(actualExpensesForGroupProvider(groupId));
    final balances = ref.watch(balancesForGroupProvider(groupId));
    final membersAsync = ref.watch(groupMembersProvider(groupId));
    final currentUserId = ref.watch(supabaseUserProvider)?.id;
    final group = groupState.groups.firstWhere(
      (g) => g.groupId == groupId,
      orElse: () => Group(
        groupId: groupId,
        name: 'Group Detail',
        members: const [],
        currency: 'PKR',
        createdAt: DateTime.now(),
      ),
    );

    if (group.inviteCode == null || group.inviteCode!.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          ref.read(groupProvider.notifier).generateInviteCode(groupId);
        }
      });
    }

    final currencyCode = group.currency;

    // Load latest remote expenses once per screen mount using Riverpod state
    final loadedGroups = ref.watch(loadedGroupExpensesProvider);
    if (!loadedGroups.contains(groupId)) {
      Future.microtask(() {
        ref
            .read(loadedGroupExpensesProvider.notifier)
            .update((state) => {...state, groupId});
        ref.read(expenseProvider.notifier).loadExpensesForGroup(groupId);
      });
    }

    final totalExpenses = actualExpenses.fold<double>(0, (sum, e) => sum + e.amount);
    final myBalance =
        currentUserId != null ? (balances[currentUserId] ?? 0.0) : 0.0;

    return SafeArea(
      top: false,
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: CustomScrollView(
          physics: const ClampingScrollPhysics(),
          slivers: [
            // ── Gradient Header ──
            SliverToBoxAdapter(
              child: _buildGradientHeader(
                  context, ref, group, myBalance, currencyCode),
            ),

            // ── Members Section ──
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 20.h),
                    _sectionHeader('MEMBERS'),
                    SizedBox(height: 12.h),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.cardDark,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                            color: AppColors.white.withValues(alpha: 0.05)),
                      ),
                      child: membersAsync.when(
                        loading: () => const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: CircularProgressIndicator(
                              color: AppColors.onboardingViolet,
                            ),
                          ),
                        ),
                        error: (err, stack) => Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: AppText(
                            ErrorHandler.getUserFriendlyMessage(err),
                            color: AppColors.white,
                          ),
                        ),
                        data: (membersList) {
                          if (membersList.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: AppText(
                                'No members in this group yet',
                                color: Colors.white54,
                              ),
                            );
                          }

                          return Column(
                            children: List.generate(membersList.length, (i) {
                              final m = membersList[i];
                              final isLast = i == membersList.length - 1;
                              final balance = balances[m.id] ?? 0.0;
                              final isMe = m.id == currentUserId;

                              // Compute initials
                              final nameParts = m.fullName.trim().split(' ');
                              final initials = nameParts.length >= 2
                                  ? '${nameParts[0][0]}${nameParts[1][0]}'
                                      .toUpperCase()
                                  : nameParts.isNotEmpty &&
                                          nameParts[0].isNotEmpty
                                      ? nameParts[0][0].toUpperCase()
                                      : 'U';

                              final avatarColor = _avatarColors[
                                  m.id.hashCode.abs() % _avatarColors.length];

                              return Column(
                                children: [
                                  GestureDetector(
                                    onTap: () async {
                                      if (group.createdBy == currentUserId && !isMe) {
                                        final bool isSettled = balance.abs() < 0.01;
                                        if (!isSettled) {
                                          await AppDialog.showInfo(
                                            context,
                                            title: 'Cannot Remove Member',
                                            message: 'Cannot leave/remove — ${m.fullName} still has an outstanding balance of $currencyCode ${balance.abs().toStringAsFixed(2)} in this group. This must be settled first.',
                                          );
                                        } else {
                                          final confirm = await AppDialog.showConfirm(
                                            context,
                                            title: 'Remove Member',
                                            message: 'Are you sure you want to remove ${m.fullName} from this group?',
                                            confirmText: 'Remove',
                                            cancelText: 'Cancel',
                                            isDanger: true,
                                          );
                                          if (confirm == true) {
                                            try {
                                              await ref.read(groupProvider.notifier).removeMemberFromGroup(groupId, m.id);
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text('${m.fullName} removed successfully'),
                                                    backgroundColor: AppColors.success,
                                                  ),
                                                );
                                              }
                                            } catch (e) {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text('Failed to remove member: $e'),
                                                    backgroundColor: AppColors.coralRed,
                                                  ),
                                                );
                                              }
                                            }
                                          }
                                        }
                                      }
                                    },
                                    child: _buildMemberRow(
                                      isMe: isMe,
                                      name: isMe ? 'You' : m.fullName,
                                      initials: initials,
                                      avatarColor: avatarColor,
                                      balance: balance,
                                      currency: currencyCode,
                                      avatarUrl: m.avatarUrl,
                                    ),
                                  ),
                                  if (!isLast)
                                    Divider(
                                        color: AppColors.white
                                            .withValues(alpha: 0.04),
                                        height: 1,
                                        indent: 56.w),
                                ],
                              );
                            }),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 16.h),
                    _buildInviteSection(context, ref, group),
                    SizedBox(height: 24.h),
                  ],
                ),
              ),
            ),

            // ── Expenses Section header ──
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _sectionHeader('EXPENSES'),
                    GestureDetector(
                      onTap: () => context.push('/addExpense', extra: group),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 12.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: AppColors.onboardingViolet
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.add,
                                color: AppColors.onboardingViolet, size: 14.sp),
                            SizedBox(width: 4.w),
                            const AppText(
                              'Add',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onboardingViolet,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Expense Items ──
            actualExpenses.isEmpty
                ? SliverToBoxAdapter(child: _buildEmptyExpenses())
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 16.w, vertical: 4.h),
                        child: _buildExpenseRow(
                          context,
                          actualExpenses[i],
                          {
                            for (final m
                                in membersAsync.value ?? <UserProfile>[])
                              m.id: m.fullName,
                          },
                          currentUserId ?? '',
                          currencyCode,
                          activeDateFormat,
                        ),
                      ),
                      childCount: actualExpenses.length,
                    ),
                  ),

            // ── Total Row ──
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Column(
                  children: [
                    SizedBox(height: 8.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 16.w, vertical: 14.h),
                      decoration: BoxDecoration(
                        color: AppColors.cardDark,
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(
                            color: AppColors.white.withValues(alpha: 0.05)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          AppText(
                            'Total group expenses',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.white.withValues(alpha: 0.6),
                          ),
                          AppText(
                            '$currencyCode ${totalExpenses.toStringAsFixed(2)}',
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.white,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 32.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientHeader(BuildContext context, WidgetRef ref, Group group,
      double myBalance, String currencyCode) {
    final currentUserId = ref.watch(supabaseUserProvider)?.id;
    final balances = ref.watch(balancesForGroupProvider(group.groupId));
    final String balanceStr = myBalance == 0
        ? '$currencyCode 0.00'
        : myBalance > 0
            ? '+$currencyCode ${myBalance.toStringAsFixed(2)}'
            : '-$currencyCode ${myBalance.abs().toStringAsFixed(2)}';

    final Color balanceColor = myBalance == 0
        ? AppColors.white
        : myBalance > 0
            ? const Color(0xFF10B981)
            : AppColors.balanceOwed;

    final String subText = myBalance == 0
        ? 'No outstanding balance'
        : myBalance > 0
            ? 'Others owe you'
            : 'You owe others';

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.onboardingViolet, AppColors.primaryPurpleDarker],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: back + more
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => context.go('/'),
                    child: Container(
                      width: 36.w,
                      height: 36.w,
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Icon(Icons.chevron_left_rounded,
                          color: AppColors.white, size: 20.sp),
                    ),
                  ),
                  Theme(
                    data: Theme.of(context).copyWith(
                      cardColor: AppColors.cardDark,
                    ),
                    child: PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'add_member') {
                          _showAddMemberBottomSheet(context, ref, group);
                        } else if (value == 'leave_group') {
                          if (currentUserId == null) return;
                          final balance = balances[currentUserId] ?? 0.0;
                          final bool isSettled = balance.abs() < 0.01;
                          if (!isSettled) {
                            await AppDialog.showInfo(
                              context,
                              title: 'Cannot Leave Group',
                              message:
                                  'Cannot leave/remove — You still have an outstanding balance of $currencyCode ${balance.abs().toStringAsFixed(2)} in this group. This must be settled first.',
                            );
                          } else {
                            final confirm = await AppDialog.showConfirm(
                              context,
                              title: 'Leave Group',
                              message:
                                  'Are you sure you want to leave this group?',
                              confirmText: 'Leave',
                              cancelText: 'Cancel',
                              isDanger: true,
                            );
                            if (confirm == true) {
                              try {
                                await ref
                                    .read(groupProvider.notifier)
                                    .removeMemberFromGroup(
                                        groupId, currentUserId);
                                if (context.mounted) {
                                  context.go('/');
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('You left the group successfully'),
                                      backgroundColor: AppColors.success,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Failed to leave group: $e'),
                                      backgroundColor: AppColors.coralRed,
                                    ),
                                  );
                                }
                              }
                            }
                          }
                        } else if (value == 'delete') {
                          final confirm = await AppDialog.showConfirm(
                            context,
                            title: 'Delete Group',
                            message:
                                'Are you sure you want to delete this group and all its expenses?',
                            confirmText: 'Delete',
                            cancelText: 'Cancel',
                            isDanger: true,
                          );
                          if (confirm == true) {
                            try {
                              await ref
                                  .read(groupProvider.notifier)
                                  .deleteGroup(groupId);
                              if (context.mounted) {
                                context.go('/');
                                AppSnackBar.showSuccess(
                                  context,
                                  'Group deleted successfully',
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                AppSnackBar.showError(
                                  context,
                                  'Failed to delete group. Only the group creator can delete a group.',
                                );
                              }
                            }
                          }
                        }
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'add_member',
                           child: Row(
                            children: [
                              Icon(Icons.person_add_outlined,
                                  color: AppColors.white, size: 20),
                              SizedBox(width: 8),
                              AppText('Add Member',
                                  color: AppColors.white, fontSize: 14),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                          value: 'leave_group',
                          child: Row(
                            children: [
                              Icon(Icons.logout_rounded,
                                  color: AppColors.white, size: 20),
                              SizedBox(width: 8),
                              AppText('Leave Group',
                                  color: AppColors.white, fontSize: 14),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline_rounded,
                                  color: AppColors.coralRed, size: 20),
                              SizedBox(width: 8),
                              AppText('Delete Group',
                                  color: AppColors.coralRed, fontSize: 14),
                            ],
                          ),
                        ),
                      ],
                      child: Container(
                        width: 36.w,
                        height: 36.w,
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Icon(Icons.more_horiz_rounded,
                            color: AppColors.white, size: 20.sp),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),

              // Group icon + name
              Row(
                children: [
                  Container(
                    width: 52.w,
                    height: 52.w,
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    child: Icon(GroupIconHelper.getIconForGroup(group),
                        color: AppColors.white, size: 26.sp),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          GroupIconHelper.getCleanGroupName(group.name),
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.white,
                        ),
                        AppText(
                          '${group.members.length} members',
                          fontSize: 13,
                          color: AppColors.white.withValues(alpha: 0.7),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),

              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText(
                            subText,
                            fontSize: 12,
                            color: AppColors.white.withValues(alpha: 0.7),
                          ),
                          SizedBox(height: 6.h),
                          AppText(
                            balanceStr,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: balanceColor,
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.push('/settleUp', extra: groupId),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 18.w, vertical: 10.h),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: const AppText(
                          'Settle Up',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.backgroundDark,
                          align: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMemberRow({
    required bool isMe,
    required String name,
    required String initials,
    required Color avatarColor,
    required double balance,
    required String currency,
    String? avatarUrl,
  }) {
    final bool isSettled = balance.abs() < 0.01;
    final bool isPositive = balance > 0;
    final String subText = isSettled
        ? 'settled up'
        : isMe
            ? (isPositive ? 'others owe you' : 'you owe others')
            : (isPositive ? 'is owed' : 'owes');

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        children: [
          Container(
            width: 38.w,
            height: 38.w,
            decoration: BoxDecoration(
              color: avatarColor,
              shape: BoxShape.circle,
              image: avatarUrl != null && avatarUrl.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(avatarUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            alignment: Alignment.center,
            child: avatarUrl == null || avatarUrl.isEmpty
                ? AppText(initials,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.white)
                : null,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(name,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white),
                AppText(
                  isSettled
                      ? subText
                      : '$subText $currency ${balance.abs().toStringAsFixed(0)}',
                  fontSize: 12,
                  color: isSettled
                      ? AppColors.white.withValues(alpha: 0.4)
                      : isPositive
                          ? const Color(0xFF10B981)
                          : AppColors.balanceOwed,
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: isSettled
                  ? AppColors.white.withValues(alpha: 0.05)
                  : isPositive
                      ? const Color(0xFF10B981).withValues(alpha: 0.12)
                      : AppColors.balanceOwed.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: AppText(
              isSettled
                  ? 'settled up'
                  : isPositive
                      ? '+$currency${balance.abs().toStringAsFixed(0)}'
                      : '-$currency${balance.abs().toStringAsFixed(0)}',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isSettled
                  ? Colors.white54
                  : isPositive
                      ? const Color(0xFF10B981)
                      : AppColors.balanceOwed,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseRow(
    BuildContext context,
    Expense expense,
    Map<String, String> memberMap,
    String currentUserId,
    String currencyCode,
    String activeDateFormat,
  ) {
    final isSettlement = expense.title == 'Settle Payment' ||
        expense.categoryIconCodePoint == Icons.handshake_rounded.codePoint;
    final dateStr = AppDateFormatter.format(expense.date, activeDateFormat);

    // Customize title and icon for settlements
    String displayTitle = expense.title;
    IconData displayIcon = expense.categoryIcon;
    Color displayIconColor = AppColors.onboardingViolet;
    Color displayIconBgColor =
        AppColors.onboardingViolet.withValues(alpha: 0.12);

    if (isSettlement) {
      final payerName = expense.paidBy == currentUserId
          ? 'You'
          : (memberMap[expense.paidBy] ?? 'Someone');
      final receiverId = expense.splitAmong.keys.isNotEmpty
          ? expense.splitAmong.keys.first
          : '';
      final receiverName = receiverId == currentUserId
          ? 'You'
          : (memberMap[receiverId] ?? 'Someone');
      displayTitle = '$payerName paid $receiverName';
      displayIcon = Icons.handshake_rounded;
      displayIconColor = AppColors.success;
      displayIconBgColor = AppColors.success.withValues(alpha: 0.12);
    }

    final perPerson = expense.splitAmong.isNotEmpty
        ? expense.amount / expense.splitAmong.length
        : expense.amount;

    return Container(
      margin: EdgeInsets.only(bottom: 4.h),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.04)),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        leading: Container(
          width: 38.w,
          height: 38.w,
          decoration: BoxDecoration(
            color: displayIconBgColor,
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(displayIcon, color: displayIconColor, size: 18.sp),
        ),
        title: AppText(displayTitle,
            fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.white),
        subtitle: AppText(
          isSettlement ? 'Settlement · $dateStr' : 'Paid · $dateStr',
          fontSize: 11,
          color: AppColors.white.withValues(alpha: 0.4),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            AppText(
              '$currencyCode ${expense.amount.toStringAsFixed(2)}',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
            ),
            if (!isSettlement)
              AppText(
                expense.splitType == 'Equal'
                    ? '$currencyCode ${perPerson.toStringAsFixed(0)}/person'
                    : expense.splitType == '%'
                        ? 'Percentage split'
                        : 'Custom split',
                fontSize: 11,
                color: AppColors.white.withValues(alpha: 0.4),
              ),
          ],
        ),
        onTap: () => context.push('/expenseDetail', extra: expense),
      ),
    );
  }

  Widget _buildEmptyExpenses() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 40.h),
      child: const AppEmptyState(
        title: 'No expenses yet',
        subtitle: 'Tap + Add to record the first one',
        icon: Icons.receipt_long_rounded,
      ),
    );
  }

  Widget _sectionHeader(String text) {
    return AppText(
      text,
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: AppColors.white.withValues(alpha: 0.4),
      letterSpacing: 1.2,
    );
  }

  void _showAddMemberBottomSheet(
      BuildContext context, WidgetRef ref, Group group) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundDark,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (context) {
        return _AddMemberBottomSheetContent(
          groupId: groupId,
        );
      },
    );
  }

  Widget _buildInviteSection(BuildContext context, WidgetRef ref, Group group) {
    final inviteCode = group.inviteCode;
    if (inviteCode == null || inviteCode.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 12.0),
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.onboardingViolet,
            ),
          ),
        ),
      );
    }

    // final inviteUrl = 'https://devorastudios.dev/join/$inviteCode';
    const playStoreUrl = 'https://play.google.com/store/apps/details?id=com.devorastudios.equally';
    final shareMessage = 'Join my group "${group.name}" on Equally!\n'
        'Invite code: $inviteCode\n\n'
        'Don\'t have the app? Install it here:\n'
        '$playStoreUrl';

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const AppText(
                'Invite Code',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.onboardingViolet.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: AppText(
                  inviteCode,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onboardingViolet,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              // Share Link button
              Expanded(
                child: InkWell(
                  onTap: () {
                    Share.share(shareMessage);
                  },
                  borderRadius: BorderRadius.circular(10.r),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(color: AppColors.white.withValues(alpha: 0.05)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.share, color: AppColors.white, size: 16.sp),
                        SizedBox(width: 8.w),
                        const AppText(
                          'Share Link',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              // WhatsApp button
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final waText = Uri.encodeComponent(shareMessage);
                    final url = Uri.parse('whatsapp://send?text=$waText');
                    bool launched = false;
                    try {
                      launched = await launchUrl(url, mode: LaunchMode.externalApplication);
                    } catch (e) {
                      launched = false;
                    }

                    if (!launched) {
                      final fallbackUrl = Uri.parse('https://wa.me/?text=$waText');
                      try {
                        launched = await launchUrl(fallbackUrl, mode: LaunchMode.externalApplication);
                      } catch (e) {
                        launched = false;
                      }
                    }

                    if (!launched && context.mounted) {
                      AppSnackBar.showError(context, 'Could not launch WhatsApp');
                    }
                  },
                  borderRadius: BorderRadius.circular(10.r),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFF25D366).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(color: const Color(0xFF25D366).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.message_rounded, color: const Color(0xFF25D366), size: 16.sp),
                        SizedBox(width: 8.w),
                        const AppText(
                          'WhatsApp',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF25D366),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          /*
          SizedBox(height: 8.h),
          // QR Code button
          SizedBox(
            width: double.infinity,
            child: InkWell(
              onTap: () {
                _showQRCodeBottomSheet(context, group, inviteUrl, inviteCode);
              },
              borderRadius: BorderRadius.circular(10.r),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12.h),
                decoration: BoxDecoration(
                  color: AppColors.onboardingViolet.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.qr_code_2, color: AppColors.onboardingViolet, size: 18.sp),
                    SizedBox(width: 8.w),
                    const AppText(
                      'Show QR Code',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onboardingViolet,
                    ),
                  ],
                ),
              ),
            ),
          ),
          */
        ],
      ),
    );
  }

  /*
  void _showQRCodeBottomSheet(BuildContext context, Group group, String inviteUrl, String inviteCode) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.backgroundDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.all(24.r),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const AppText(
                              'Group Invite QR',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.white,
                            ),
                            SizedBox(height: 4.h),
                            AppText(
                              group.name,
                              fontSize: 14,
                              color: Colors.white54,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white54),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  Container(
                    padding: EdgeInsets.all(16.r),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: QrImageView(
                      data: inviteUrl,
                      version: QrVersions.auto,
                      size: 180.0,
                      gapless: false,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    decoration: BoxDecoration(
                      color: AppColors.cardDark,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: AppColors.white.withValues(alpha: 0.05)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const AppText(
                                'INVITE CODE',
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.white38,
                                letterSpacing: 1.0,
                              ),
                              SizedBox(height: 4.h),
                              AppText(
                                inviteCode,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.white,
                                letterSpacing: 1.5,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, color: AppColors.onboardingViolet),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: inviteCode));
                            AppSnackBar.showSuccess(context, 'Invite code copied to clipboard');
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 8.h),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  */
}

class _AddMemberBottomSheetContent extends ConsumerStatefulWidget {
  final String groupId;

  const _AddMemberBottomSheetContent({
    required this.groupId,
  });

  @override
  ConsumerState<_AddMemberBottomSheetContent> createState() =>
      _AddMemberBottomSheetContentState();
}

class _AddMemberBottomSheetContentState
    extends ConsumerState<_AddMemberBottomSheetContent> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  bool _isSaving = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isQueryLongEnough = _searchQuery.trim().replaceAll('@', '').length >= 2;

    final usersAsync = isQueryLongEnough
        ? ref.watch(searchedUsersProvider(_searchQuery))
        : ref.watch(allUsersProvider);
    final usersList = usersAsync.value ?? [];

    final groupMembersAsync = ref.watch(groupMembersProvider(widget.groupId));
    final groupMembersList = groupMembersAsync.value ?? [];
    final currentUser = ref.watch(supabaseUserProvider);

    final existingMemberIds = {
      ...groupMembersList.map((m) => m.id),
      if (currentUser != null) currentUser.id,
    };

    // Filter out users who are already members
    final nonMembers =
        usersList.where((u) => !existingMemberIds.contains(u.id)).toList();

    // Filter by search query (email or username or full name)
    final filteredUsers = isQueryLongEnough
        ? nonMembers
        : nonMembers.where((u) {
            final cleanQ = _searchQuery.trim().startsWith('@')
                ? _searchQuery.trim().substring(1)
                : _searchQuery.trim();
            final q = cleanQ.toLowerCase();
            return u.fullName.toLowerCase().contains(q) ||
                u.username.toLowerCase().contains(q) ||
                u.email.toLowerCase().contains(q);
          }).toList();

    return Padding(
      padding: EdgeInsets.only(
        left: 20.w,
        right: 20.w,
        top: 20.h,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20.h,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const AppText(
                'Add Member',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          AppTextField(
            label: 'Search Members',
            hint: 'Search by email or username...',
            controller: _searchCtrl,
            onChanged: (val) {
              setState(() {
                _searchQuery = val;
              });
            },
            prefix: Icon(
              Icons.search_rounded,
              color: AppColors.white.withValues(alpha: 0.3),
              size: 18.sp,
            ),
          ),
          SizedBox(height: 16.h),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: 250.h),
            child: usersAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(
                    color: AppColors.onboardingViolet,
                  ),
                ),
              ),
              error: (err, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: AppText(
                    ErrorHandler.getUserFriendlyMessage(err),
                    color: AppColors.white,
                  ),
                ),
              ),
              data: (_) {
                if (filteredUsers.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: AppText(
                        'No unregistered users found',
                        color: Colors.white54,
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];
                    final isLast = index == filteredUsers.length - 1;

                    // Compute initials
                    final nameParts = user.fullName.trim().split(' ');
                    final initials = nameParts.length >= 2
                        ? '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase()
                        : nameParts.isNotEmpty && nameParts[0].isNotEmpty
                            ? nameParts[0][0].toUpperCase()
                            : 'U';

                    final avatarColor = GroupDetailScreen._avatarColors[
                        user.id.hashCode.abs() %
                            GroupDetailScreen._avatarColors.length];

                    return Column(
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 8.w, vertical: 4.h),
                          leading: CircleAvatar(
                            backgroundColor: avatarColor,
                            radius: 18.r,
                            backgroundImage: user.avatarUrl.isNotEmpty
                                ? NetworkImage(user.avatarUrl)
                                : null,
                            child: user.avatarUrl.isEmpty
                                ? AppText(
                                    initials,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.white,
                                  )
                                : null,
                          ),
                          title: AppText(
                            user.fullName,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.white,
                          ),
                          subtitle: AppText(
                            '@${user.username}',
                            fontSize: 12,
                            color: AppColors.white.withValues(alpha: 0.4),
                          ),
                          trailing: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.onboardingViolet,
                                  ),
                                )
                              : Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 12.w, vertical: 6.h),
                                  decoration: BoxDecoration(
                                    color: AppColors.onboardingViolet,
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: const AppText(
                                    'Add',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.white,
                                  ),
                                ),
                          onTap: _isSaving
                              ? null
                              : () async {
                                  setState(() {
                                    _isSaving = true;
                                  });
                                  try {
                                    await ref
                                        .read(groupProvider.notifier)
                                        .addMemberToGroup(
                                            widget.groupId, user.id);

                                    // Invalidate group members future
                                    ref.invalidate(
                                        groupMembersProvider(widget.groupId));

                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: AppText(
                                            '${user.fullName} added successfully',
                                            color: AppColors.white,
                                          ),
                                          backgroundColor: AppColors.success,
                                        ),
                                      );
                                      Navigator.pop(context);
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: AppText(
                                            'Failed to add member: $e',
                                            color: AppColors.white,
                                          ),
                                          backgroundColor: AppColors.coralRed,
                                        ),
                                      );
                                    }
                                  } finally {
                                    if (mounted) {
                                      setState(() {
                                        _isSaving = false;
                                      });
                                    }
                                  }
                                },
                        ),
                        if (!isLast)
                          Divider(
                            color: AppColors.white.withValues(alpha: 0.04),
                            height: 1,
                            indent: 48.w,
                          ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

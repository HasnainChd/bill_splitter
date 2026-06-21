import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_colors.dart';
import '../core/models/group.dart';
import 'auth_provider.dart';
import 'group_provider.dart';
import 'expense_provider.dart';
import 'profile_provider.dart';
import '../presentation/providers/screen_providers.dart';
import '../core/utils/group_icon_helper.dart';

class NotificationItem {
  final String id;
  final String category; // 'Expenses', 'Payments', 'Groups'
  final String groupName;
  final String title;
  final String subtitle;
  final String? amount;
  final Color? amountColor;
  final String avatarText;
  final Color avatarColor;
  final IconData badgeIcon;
  final Color badgeColor;
  final bool isUnread;
  final DateTime date;

  NotificationItem({
    required this.id,
    required this.category,
    required this.groupName,
    required this.title,
    required this.subtitle,
    this.amount,
    this.amountColor,
    required this.avatarText,
    required this.avatarColor,
    required this.badgeIcon,
    required this.badgeColor,
    required this.isUnread,
    required this.date,
  });
}

final notificationUsersMapProvider = Provider<Map<String, UserProfile>>((ref) {
  final usersList = ref.watch(allUsersProvider).value ?? [];
  return {for (final u in usersList) u.id: u};
});

final dynamicNotificationsProvider = Provider<List<NotificationItem>>((ref) {
  final groupState = ref.watch(groupProvider);
  final expenseState = ref.watch(expenseProvider);
  final usersMap = ref.watch(notificationUsersMapProvider);
  final currentUser = ref.watch(supabaseUserProvider);

  if (currentUser == null) return [];

  final List<NotificationItem> notifications = [];

  final List<Color> avatarColors = [
    const Color(0xFF818CF8), // violet
    const Color(0xFFEC4899), // pink
    const Color(0xFFF59E0B), // amber
    const Color(0xFF10B981), // green
    const Color(0xFF8B5CF6), // purple
    const Color(0xFF38BDF8), // cyan
  ];

  // 1. Group addition notifications
  for (final group in groupState.groups) {
    // Determine initials
    final nameParts = group.name.trim().split(' ');
    final initials = nameParts.length >= 2
        ? '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase()
        : nameParts.isNotEmpty && nameParts[0].isNotEmpty
            ? nameParts[0][0].toUpperCase()
            : 'G';

    final avatarColor = avatarColors[group.groupId.hashCode.abs() % avatarColors.length];

    final isCreator = group.createdBy == null || group.createdBy!.isEmpty || group.createdBy == currentUser.id;
    final creatorName = usersMap[group.createdBy]?.fullName ?? 'Someone';
    final cleanGroupName = GroupIconHelper.getCleanGroupName(group.name);
    final title = isCreator
        ? 'You created the group "$cleanGroupName"'
        : '$creatorName added you to "$cleanGroupName"';

    notifications.add(
      NotificationItem(
        id: 'group-${group.groupId}',
        category: 'Groups',
        groupName: group.name,
        title: title,
        subtitle: _formatTimeAgo(group.createdAt),
        avatarText: initials,
        avatarColor: avatarColor,
        badgeIcon: GroupIconHelper.getIconForGroup(group),
        badgeColor: const Color(0xFF38BDF8),
        isUnread: false,
        date: group.createdAt,
      ),
    );
  }

  // 2. Expense addition and payment notifications
  for (final expense in expenseState.expenses) {
    // Find the corresponding group
    final group = groupState.groups.firstWhere(
      (g) => g.groupId == expense.groupId,
      orElse: () => Group(
        groupId: expense.groupId,
        name: 'Unknown Group',
        members: const [],
        currency: expense.currency,
        createdAt: DateTime.now(),
      ),
    );

    if (group.name == 'Unknown Group') continue;

    final isSettlement = expense.title == 'Settle Payment' ||
        expense.categoryIconCodePoint == Icons.handshake_rounded.codePoint;

    final payerProfile = usersMap[expense.paidBy];
    final String payerName = expense.paidBy == currentUser.id
        ? 'You'
        : (payerProfile?.fullName ?? 'Someone');

    final String initials = expense.paidBy == currentUser.id
        ? 'U'
        : payerProfile != null && payerProfile.fullName.isNotEmpty
            ? payerProfile.fullName.trim().split(' ').length >= 2
                ? '${payerProfile.fullName.trim().split(' ')[0][0]}${payerProfile.fullName.trim().split(' ')[1][0]}'.toUpperCase()
                : payerProfile.fullName[0].toUpperCase()
            : 'S';

    final avatarColor = avatarColors[expense.paidBy.hashCode.abs() % avatarColors.length];

    if (isSettlement) {
      final receiverId = expense.splitAmong.keys.isNotEmpty
          ? expense.splitAmong.keys.first
          : '';
      final receiverProfile = usersMap[receiverId];
      final String receiverName = receiverId == currentUser.id
          ? 'you'
          : (receiverProfile?.fullName ?? 'Someone');

      final String title = '$payerName paid $receiverName';

      notifications.add(
        NotificationItem(
          id: 'settlement-${expense.expenseId}',
          category: 'Payments',
          groupName: GroupIconHelper.getCleanGroupName(group.name),
          title: title,
          subtitle: _formatTimeAgo(expense.date),
          amount: '+${expense.currency} ${expense.amount.toStringAsFixed(2)}',
          amountColor: const Color(0xFF00C896),
          avatarText: initials,
          avatarColor: avatarColor,
          badgeIcon: Icons.check_circle_rounded,
          badgeColor: const Color(0xFF00C896),
          isUnread: false,
          date: expense.date,
        ),
      );
    } else {
      final cleanGroupName = GroupIconHelper.getCleanGroupName(group.name);
      final String title = '$payerName added "${expense.title}" to "$cleanGroupName"';

      notifications.add(
        NotificationItem(
          id: 'expense-${expense.expenseId}',
          category: 'Expenses',
          groupName: cleanGroupName,
          title: title,
          subtitle: _formatTimeAgo(expense.date),
          amount: '${expense.currency} ${expense.amount.toStringAsFixed(2)}',
          amountColor: Colors.white,
          avatarText: initials,
          avatarColor: avatarColor,
          badgeIcon: expense.categoryIcon,
          badgeColor: AppColors.onboardingViolet,
          isUnread: false,
          date: expense.date,
        ),
      );
    }
  }

  // Deduplicate by notification ID
  final Map<String, NotificationItem> uniqueNotifications = {};
  for (final n in notifications) {
    uniqueNotifications[n.id] = n;
  }
  
  final resultList = uniqueNotifications.values.toList();

  // Sort by date, descending (newest first)
  resultList.sort((a, b) => b.date.compareTo(a.date));

  return resultList;
});

String _formatTimeAgo(DateTime dateTime) {
  final localDateTime = dateTime.toLocal();
  final now = DateTime.now();
  var difference = now.difference(localDateTime);
  
  if (difference.isNegative) {
    if (difference.abs().inMinutes < 60) {
      return 'Just now';
    }
    difference = difference.abs();
  }
  
  if (difference.inSeconds < 60) {
    return 'Just now';
  } else if (difference.inMinutes < 60) {
    return '${difference.inMinutes} min ago';
  } else if (difference.inHours < 24) {
    final hourText = difference.inHours == 1 ? 'hour' : 'hours';
    return '${difference.inHours} $hourText ago';
  } else if (difference.inDays < 7) {
    final dayText = difference.inDays == 1 ? 'day' : 'days';
    return '${difference.inDays} $dayText ago';
  } else {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[localDateTime.month - 1]} ${localDateTime.day}';
  }
}

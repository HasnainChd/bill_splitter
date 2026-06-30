import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/app_colors.dart';
import '../core/models/group.dart';
import 'auth_provider.dart';
import 'group_provider.dart';
import 'expense_provider.dart';
import 'profile_provider.dart';
import '../presentation/providers/screen_providers.dart';
import '../core/utils/group_icon_helper.dart';
import 'requests_provider.dart';

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
  final String? groupId;

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
    this.groupId,
  });
}

class ReadNotificationsNotifier extends StateNotifier<Set<String>> {
  ReadNotificationsNotifier() : super({}) {
    _load();
  }

  void _load() {
    try {
      final box = Hive.box('read_notifications');
      state = box.keys.map((k) => k.toString()).toSet();
    } catch (e) {
      debugPrint('Error loading read notifications from Hive: $e');
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      final box = Hive.box('read_notifications');
      await box.put(id, true);
      state = {...state, id};
    } catch (e) {
      debugPrint('Error marking notification as read in Hive: $e');
    }
  }

  Future<void> markAllAsRead(List<String> ids) async {
    try {
      final box = Hive.box('read_notifications');
      final map = {for (final id in ids) id: true};
      await box.putAll(map);
      state = {...state, ...ids};
    } catch (e) {
      debugPrint('Error marking all notifications as read in Hive: $e');
    }
  }

  Future<void> clearAll() async {
    try {
      final box = Hive.box('read_notifications');
      await box.clear();
      state = {};
    } catch (e) {
      debugPrint('Error clearing read notifications in Hive: $e');
    }
  }
}

final readNotificationsProvider =
    StateNotifierProvider<ReadNotificationsNotifier, Set<String>>((ref) {
  return ReadNotificationsNotifier();
});

class GroupNotificationRecord {
  final String id;
  final String groupId;
  final String userId;
  final String eventType; // 'joined', 'left'
  final DateTime createdAt;

  GroupNotificationRecord({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.eventType,
    required this.createdAt,
  });

  factory GroupNotificationRecord.fromMap(Map<String, dynamic> data) {
    return GroupNotificationRecord(
      id: data['id'] ?? '',
      groupId: data['group_id'] ?? '',
      userId: data['user_id'] ?? '',
      eventType: data['event_type'] ?? '',
      createdAt: data['created_at'] != null
          ? DateTime.parse(data['created_at']).toLocal()
          : DateTime.now(),
    );
  }
}

class GroupNotificationsNotifier
    extends StateNotifier<List<GroupNotificationRecord>> {
  final SupabaseClient _supabase = Supabase.instance.client;
  StreamSubscription? _sub;

  GroupNotificationsNotifier() : super([]) {
    _init();
  }

  void _init() {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    _sub = _supabase
        .from('group_notifications')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .listen((data) {
      final list =
          data.map((row) => GroupNotificationRecord.fromMap(row)).toList();
      if (mounted) {
        state = list;
      }
    }, onError: (e) {
      debugPrint('Error streaming group_notifications: $e');
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final groupNotificationsProvider = StateNotifierProvider<
    GroupNotificationsNotifier, List<GroupNotificationRecord>>((ref) {
  ref.watch(supabaseUserProvider);
  return GroupNotificationsNotifier();
});

final notificationUsersMapProvider = Provider<Map<String, UserProfile>>((ref) {
  final usersList = ref.watch(allUsersProvider).value ?? [];
  return {for (final u in usersList) u.id: u};
});

final dynamicNotificationsProvider = Provider<List<NotificationItem>>((ref) {
  final groupNotifs = ref.watch(groupNotificationsProvider);
  final groupState = ref.watch(groupProvider);
  final expenseState = ref.watch(expenseProvider);
  final usersMap = ref.watch(notificationUsersMapProvider);
  final currentUser = ref.watch(supabaseUserProvider);
  final requestsState = ref.watch(requestsProvider);
  final readNotifications = ref.watch(readNotificationsProvider);

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

    final avatarColor =
        avatarColors[group.groupId.hashCode.abs() % avatarColors.length];

    final isCreator = group.createdBy == null ||
        group.createdBy!.isEmpty ||
        group.createdBy == currentUser.id;
    final creatorName = usersMap[group.createdBy]?.fullName ?? 'Someone';
    final cleanGroupName = GroupIconHelper.getCleanGroupName(group.name);
    final title = isCreator
        ? 'You created the group "$cleanGroupName"'
        : '$creatorName added you to "$cleanGroupName"';

    final notifId = 'group-${group.groupId}';
    notifications.add(
      NotificationItem(
        id: notifId,
        category: 'Groups',
        groupName: group.name,
        title: title,
        subtitle: _formatTimeAgo(group.createdAt),
        avatarText: initials,
        avatarColor: avatarColor,
        badgeIcon: GroupIconHelper.getIconForGroup(group),
        badgeColor: const Color(0xFF38BDF8),
        isUnread: !readNotifications.contains(notifId),
        date: group.createdAt,
      ),
    );

  }

  // 1b. Group membership notifications (joins/leaves) from group_notifications table
  for (final record in groupNotifs) {
    // Find the corresponding group
    final group = groupState.groups.firstWhere(
      (g) => g.groupId == record.groupId,
      orElse: () => Group(
        groupId: record.groupId,
        name: 'Unknown Group',
        members: const [],
        currency: 'USD',
        createdAt: record.createdAt,
      ),
    );

    if (group.name == 'Unknown Group') continue;

    final memberProfile = usersMap[record.userId];
    final String memberName = record.userId == currentUser.id
        ? 'You'
        : (memberProfile?.fullName ?? 'Someone');

    final mNameParts = memberName.trim().split(' ');
    final mInitials = mNameParts.length >= 2
        ? '${mNameParts[0][0]}${mNameParts[1][0]}'.toUpperCase()
        : mNameParts.isNotEmpty && mNameParts[0].isNotEmpty
            ? mNameParts[0][0].toUpperCase()
            : 'M';
    final mAvatarColor =
        avatarColors[record.userId.hashCode.abs() % avatarColors.length];

    final isJoin = record.eventType == 'joined';
    final String title = isJoin
        ? '$memberName joined the group'
        : '$memberName left the group';

    final notifId = 'group-notif-${record.id}';
    notifications.add(
      NotificationItem(
        id: notifId,
        category: 'Groups',
        groupName: GroupIconHelper.getCleanGroupName(group.name),
        title: title,
        subtitle: _formatTimeAgo(record.createdAt),
        avatarText: mInitials,
        avatarColor: mAvatarColor,
        badgeIcon: isJoin ? Icons.person_add_rounded : Icons.logout_rounded,
        badgeColor: isJoin ? const Color(0xFF00C896) : AppColors.coralRed,
        isUnread: !readNotifications.contains(notifId),
        date: record.createdAt,
        groupId: group.groupId,
      ),
    );
  }

  // 3. Request Money notifications
  for (final req in requestsState.requests) {
    final group = groupState.groups.firstWhere(
      (g) => g.groupId == req.groupId,
      orElse: () => Group(
        groupId: req.groupId,
        name: 'Unknown Group',
        members: const [],
        currency: 'USD',
        createdAt: DateTime.now(),
      ),
    );

    if (group.name == 'Unknown Group') continue;

    final requesterProfile = usersMap[req.userId];
    final String requesterName = req.userId == currentUser.id
        ? 'You'
        : (requesterProfile?.fullName ?? 'Someone');

    final String initials = req.userId == currentUser.id
        ? 'U'
        : requesterProfile != null && requesterProfile.fullName.isNotEmpty
            ? requesterProfile.fullName.trim().split(' ').length >= 2
                ? '${requesterProfile.fullName.trim().split(' ')[0][0]}${requesterProfile.fullName.trim().split(' ')[1][0]}'
                    .toUpperCase()
                : requesterProfile.fullName[0].toUpperCase()
            : 'S';

    final avatarColor =
        avatarColors[req.userId.hashCode.abs() % avatarColors.length];

    final String title = req.userId == currentUser.id
        ? 'You sent a settle up reminder'
        : '$requesterName sent a settle up reminder';

    final notifId = 'req-${req.id}';
    notifications.add(
      NotificationItem(
        id: notifId,
        category: 'Payments',
        groupName: group.name,
        title: title,
        subtitle: _formatTimeAgo(req.createdAt),
        avatarText: initials,
        avatarColor: avatarColor,
        badgeIcon: Icons.handshake_rounded,
        badgeColor: AppColors.onboardingViolet,
        isUnread: !readNotifications.contains(notifId),
        date: req.createdAt,
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
                ? '${payerProfile.fullName.trim().split(' ')[0][0]}${payerProfile.fullName.trim().split(' ')[1][0]}'
                    .toUpperCase()
                : payerProfile.fullName[0].toUpperCase()
            : 'S';

    final avatarColor =
        avatarColors[expense.paidBy.hashCode.abs() % avatarColors.length];

    if (isSettlement) {
      final receiverId = expense.splitAmong.keys.isNotEmpty
          ? expense.splitAmong.keys.first
          : '';
      final receiverProfile = usersMap[receiverId];
      final String receiverName = receiverId == currentUser.id
          ? 'you'
          : (receiverProfile?.fullName ?? 'Someone');

      final String title = '$payerName paid $receiverName';

      final notifId = 'settlement-${expense.expenseId}';
      notifications.add(
        NotificationItem(
          id: notifId,
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
          isUnread: !readNotifications.contains(notifId),
          date: expense.date,
          groupId: group.groupId,
        ),
      );
    } else {
      final cleanGroupName = GroupIconHelper.getCleanGroupName(group.name);
      final String title =
          '$payerName added "${expense.title}" to "$cleanGroupName"';

      final notifId = 'expense-${expense.expenseId}';
      notifications.add(
        NotificationItem(
          id: notifId,
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
          isUnread: !readNotifications.contains(notifId),
          date: expense.date,
          groupId: group.groupId,
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
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[localDateTime.month - 1]} ${localDateTime.day}';
  }
}

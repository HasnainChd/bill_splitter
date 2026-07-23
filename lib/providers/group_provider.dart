import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../core/models/group.dart';
import '../core/utils/date_helper.dart';
import '../core/utils/error_handler.dart';
import 'auth_provider.dart';
import 'expense_provider.dart';
import 'profile_provider.dart';

// Group State
class GroupState {
  final List<Group> groups;
  final bool isLoading;
  final String? error;

  const GroupState({
    required this.groups,
    this.isLoading = false,
    this.error,
  });

  GroupState copyWith({
    List<Group>? groups,
    bool? isLoading,
    String? error,
  }) {
    return GroupState(
      groups: groups ?? this.groups,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GroupState &&
          runtimeType == other.runtimeType &&
          groups == other.groups &&
          isLoading == other.isLoading &&
          error == other.error;

  @override
  int get hashCode => groups.hashCode ^ isLoading.hashCode ^ error.hashCode;
}

// Group Notifier
class GroupNotifier extends StateNotifier<GroupState> {
  final SupabaseClient _supabase = Supabase.instance.client;
  RealtimeChannel? _groupsSubscription;
  RealtimeChannel? _groupMembersSubscription;

  GroupNotifier() : super(const GroupState(groups: [], isLoading: false)) {
    loadGroups();
    _setupRealtimeListeners();
  }

  void _setupRealtimeListeners() {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) return;

    _groupsSubscription = _supabase
        .channel('public:groups')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'groups',
          callback: (payload) {
            loadGroups();
          },
        );
    _groupsSubscription?.subscribe();

    _groupMembersSubscription = _supabase
        .channel('public:group_members')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'group_members',
          callback: (payload) {
            loadGroups();
          },
        );
    _groupMembersSubscription?.subscribe();
  }

  @override
  void dispose() {
    _groupsSubscription?.unsubscribe();
    _groupMembersSubscription?.unsubscribe();
    super.dispose();
  }

  // Load groups from Supabase, caching them in Hive
  Future<void> loadGroups() async {
    try {
      state = state.copyWith(isLoading: true);
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        // Fallback: Load from Hive cache
        final box = await Hive.openBox<Group>('groups');
        state = state.copyWith(groups: box.values.toList(), isLoading: false);
        return;
      }

      // Query group_members to get the groups this user belongs to
      final memberGroupsResponse = await _supabase
          .from('group_members')
          .select('joined_at, groups(*, group_members(user_id))')
          .eq('user_id', currentUser.id);

      final List<Group> groupsList = [];
      final box = await Hive.openBox<Group>('groups');
      await box.clear();

      for (final row in memberGroupsResponse as List) {
        final groupRow = row['groups'];
        if (groupRow == null) continue;

        final memberList = (groupRow['group_members'] as List)
            .map((m) => m['user_id']?.toString() ?? '')
            .where((m) => m.isNotEmpty)
            .toList();

        final group = Group(
          groupId: groupRow['id']?.toString() ?? '',
          name: groupRow['name'] as String,
          members: memberList,
          currency: groupRow['currency'] as String? ?? 'PKR',
          createdAt: groupRow['created_at'] != null
              ? parseUtcDateTime(groupRow['created_at'] as String)
              : DateTime.now(),
          iconCodePoint: groupRow['icon_code_point'] as int?,
          iconFontFamily: groupRow['icon_font_family'] as String?,
          createdBy: groupRow['created_by']?.toString(),
          inviteCode: groupRow['invite_code'] as String?,
        );

        groupsList.add(group);
        await box.put(group.groupId, group);
      }

      if (!mounted) return;
      state = state.copyWith(groups: groupsList, isLoading: false);
    } catch (e) {
      debugPrint('Error loading groups: $e');
      try {
        final box = await Hive.openBox<Group>('groups');
        if (!mounted) return;
        state = state.copyWith(
          groups: box.values.toList(),
          isLoading: false,
          error: 'Offline mode: $e',
        );
      } catch (boxError) {
        if (!mounted) return;
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to load groups: $e (Cache: $boxError)',
        );
      }
    }
  }

  // Add a new group
  Future<void> addGroup({
    required String name,
    required List<String> members,
    required int iconCodePoint,
    required String iconFontFamily,
    String currency = 'PKR',
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      final String inviteCode = const Uuid().v4().replaceAll('-', '').substring(0, 8).toUpperCase();

      // 1. Insert into groups table
      final groupData = await _supabase.from('groups').insert({
        'name': name,
        'currency': currency,
        'created_by': user.id,
        'icon_code_point': iconCodePoint,
        'icon_font_family': iconFontFamily,
        'invite_code': inviteCode,
      }).select().single();

      final String groupId = groupData['id'] as String;

      // 2. Insert members into group_members (creator + other members)
      final List<Map<String, dynamic>> memberRows = [
        {'group_id': groupId, 'user_id': user.id, 'added_by': user.id, 'is_creator': true},
        ...members
            .where((mId) => mId != user.id)
            .map((mId) => {'group_id': groupId, 'user_id': mId, 'added_by': user.id, 'is_creator': false}),
      ];
      await _supabase.from('group_members').insert(memberRows);

      // Insert join events for other added members into group_notifications
      final List<Map<String, dynamic>> groupNotifRows = members
          .where((mId) => mId != user.id)
          .map((mId) => {
                'group_id': groupId,
                'user_id': mId,
                'event_type': 'joined',
              })
          .toList();
      if (groupNotifRows.isNotEmpty) {
        try {
          await _supabase.from('group_notifications').insert(groupNotifRows);
        } catch (ne) {
          debugPrint('Warning: Failed to log group join notifications: $ne');
        }
      }

      // 3. Reload from remote to update local state and Hive cache
      await loadGroups();
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(error: 'Failed to add group: $e');
      rethrow;
    }
  }

  // Add a member to an existing group
  Future<void> addMemberToGroup(String groupId, String userId) async {
    try {
      final actorId = _supabase.auth.currentUser?.id;
      await _supabase.from('group_members').insert({
        'group_id': groupId,
        'user_id': userId,
        'added_by': actorId,
      });

      // Insert join event into group_notifications table
      try {
        await _supabase.from('group_notifications').insert({
          'group_id': groupId,
          'user_id': userId,
          'event_type': 'joined',
        });
      } catch (ne) {
        debugPrint('Warning: Failed to log member join notification: $ne');
      }

      // Reload groups to update local state and Hive cache
      await loadGroups();
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
          error: ErrorHandler.getUserFriendlyMessage(e));
      rethrow;
    }
  }

  // Remove a member from a group (can be used for leaving as well)
  Future<void> removeMemberFromGroup(String groupId, String userId) async {
    try {
      // 1. Insert leave event into group_notifications table first (before deleting, so RLS checks pass if leaving)
      try {
        await _supabase.from('group_notifications').insert({
          'group_id': groupId,
          'user_id': userId,
          'event_type': 'left',
        });
      } catch (ne) {
        debugPrint('Warning: Failed to log member leave notification: $ne');
      }

      // 2. Delete from group_members table
      await _supabase
          .from('group_members')
          .delete()
          .eq('group_id', groupId)
          .eq('user_id', userId);

      // 3. Reload groups to update local state and Hive cache
      await loadGroups();
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
          error: ErrorHandler.getUserFriendlyMessage(e));
      rethrow;
    }
  }

  // Get a single group by ID
  Group? getGroupById(String groupId) {
    try {
      return state.groups.firstWhere((group) => group.groupId == groupId);
    } catch (e) {
      return null;
    }
  }

  // Update a group
  Future<void> updateGroup(Group updatedGroup) async {
    try {
      await _supabase.from('groups').update({
        'name': updatedGroup.name,
        'currency': updatedGroup.currency,
      }).eq('id', updatedGroup.groupId);

      final updatedGroups = state.groups.map((group) {
        return group.groupId == updatedGroup.groupId ? updatedGroup : group;
      }).toList();

      if (!mounted) return;
      state = state.copyWith(groups: updatedGroups);
      final box = await Hive.openBox<Group>('groups');
      await box.put(updatedGroup.groupId, updatedGroup);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
          error: ErrorHandler.getUserFriendlyMessage(e));
      rethrow;
    }
  }

  // Delete a group
  Future<void> deleteGroup(String groupId) async {
    try {
      final response = await _supabase
          .from('groups')
          .delete()
          .eq('id', groupId)
          .select();

      if (response.isEmpty) {
        throw Exception(
          'Failed to delete group. You may not have permission, '
          'or the group no longer exists.'
        );
      }

      final updatedGroups =
          state.groups.where((group) => group.groupId != groupId).toList();

      if (!mounted) return;
      state = state.copyWith(groups: updatedGroups);

      final box = await Hive.openBox<Group>('groups');
      await box.delete(groupId);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
          error: ErrorHandler.getUserFriendlyMessage(e));
      rethrow;
    }
  }

  // Generate an invite code for an existing group that doesn't have one
  Future<String> generateInviteCode(String groupId) async {
    try {
      final String inviteCode = const Uuid().v4().replaceAll('-', '').substring(0, 8).toUpperCase();
      await _supabase
          .from('groups')
          .update({'invite_code': inviteCode})
          .eq('id', groupId);
      await loadGroups();
      return inviteCode;
    } catch (e) {
      debugPrint('Error generating invite code: $e');
      rethrow;
    }
  }

  // Join a group using an invite code
  Future<Group> joinGroupByInviteCode(String code) async {
    final cleanCode = code.trim().toUpperCase();
    if (cleanCode.length != 8) {
      throw 'invalid_code';
    }

    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('No user logged in');
      }

      // 1. Query groups table by invite_code
      final groupData = await _supabase
          .from('groups')
          .select()
          .eq('invite_code', cleanCode)
          .maybeSingle();

      if (groupData == null) {
        throw 'invalid_code';
      }

      final String groupId = groupData['id'] as String;

      // 2. Check if current user is already a member
      final existingMember = await _supabase
          .from('group_members')
          .select()
          .eq('group_id', groupId)
          .eq('user_id', currentUser.id)
          .maybeSingle();

      if (existingMember != null) {
        throw 'already_member';
      }

      // 3. Insert into group_members
      await _supabase.from('group_members').insert({
        'group_id': groupId,
        'user_id': currentUser.id,
        'added_by': currentUser.id,
      });

      // Insert join event into group_notifications
      try {
        await _supabase.from('group_notifications').insert({
          'group_id': groupId,
          'user_id': currentUser.id,
          'event_type': 'joined',
        });
      } catch (ne) {
        debugPrint('Warning: Failed to log group join notification: $ne');
      }

      // Reload groups to update local state and Hive cache
      await loadGroups();

      // Return the group object
      // We need to fetch the full members list for mapping
      final membersData = await _supabase
          .from('group_members')
          .select('user_id')
          .eq('group_id', groupId);

      final memberList = (membersData as List)
          .map((m) => m['user_id']?.toString() ?? '')
          .where((m) => m.isNotEmpty)
          .toList();

      return Group(
        groupId: groupId,
        name: groupData['name'] as String,
        members: memberList,
        currency: groupData['currency'] as String? ?? 'PKR',
        createdAt: groupData['created_at'] != null
            ? parseUtcDateTime(groupData['created_at'] as String)
            : DateTime.now(),
        iconCodePoint: groupData['icon_code_point'] as int?,
        iconFontFamily: groupData['icon_font_family'] as String?,
        createdBy: groupData['created_by']?.toString(),
        inviteCode: cleanCode,
      );
    } catch (e) {
      if (e == 'invalid_code' || e == 'already_member') {
        rethrow;
      }
      debugPrint('Error joining group: $e');
      rethrow;
    }
  }
}

// Provider
final groupProvider = StateNotifierProvider<GroupNotifier, GroupState>((ref) {
  ref.watch(supabaseUserProvider);
  return GroupNotifier();
});

// Balance for a specific group computed from expenses
final groupBalanceProvider = Provider.family<double, String>((ref, groupId) {
  final balances = ref.watch(balancesForGroupProvider(groupId));
  if (balances.isEmpty) return 0.0;
  return balances.values.fold(0.0, (sum, b) => sum + b);
});

final groupMembersProvider =
    FutureProvider.family<List<UserProfile>, String>((ref, groupId) async {
  ref.watch(supabaseUserProvider);
  final groups = ref.watch(groupProvider).groups;
  final group = groups.firstWhere(
    (g) => g.groupId == groupId,
    orElse: () => Group(
      groupId: groupId,
      name: '',
      members: const [],
      currency: 'PKR',
      createdAt: DateTime.now(),
    ),
  );
  final _ = group.members;

  final supabase = Supabase.instance.client;

  try {
    final data = await supabase
        .from('group_members')
        .select('user_id')
        .eq('group_id', groupId);

    final userIds = (data as List)
        .map((row) => row['user_id']?.toString())
        .whereType<String>()
        .toList();

    if (userIds.isEmpty) return [];

    final usersData = await supabase
        .from('users')
        .select()
        .inFilter('id', userIds);

    return (usersData as List)
        .map((row) => UserProfile.fromMap(row, ''))
        .toList();
  } catch (e) {
    debugPrint('Error fetching group members for $groupId: $e');
    return [];
  }
});

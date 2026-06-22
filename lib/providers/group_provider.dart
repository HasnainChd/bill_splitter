import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/models/group.dart';
import '../core/utils/date_helper.dart';
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

      // 1. Insert into groups table
      final groupData = await _supabase.from('groups').insert({
        'name': name,
        'currency': currency,
        'created_by': user.id,
        'icon_code_point': iconCodePoint,
        'icon_font_family': iconFontFamily,
      }).select().single();

      final String groupId = groupData['id'] as String;

      // 2. Insert members into group_members (creator + other members)
      final List<Map<String, dynamic>> memberRows = [
        {'group_id': groupId, 'user_id': user.id},
        ...members
            .where((mId) => mId != user.id)
            .map((mId) => {'group_id': groupId, 'user_id': mId}),
      ];
      await _supabase.from('group_members').insert(memberRows);

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
      await _supabase.from('group_members').insert({
        'group_id': groupId,
        'user_id': userId,
      });

      // Reload groups to update local state and Hive cache
      await loadGroups();
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(error: 'Failed to add member: $e');
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
      state = state.copyWith(error: 'Failed to update group: $e');
      rethrow;
    }
  }

  // Delete a group
  Future<void> deleteGroup(String groupId) async {
    try {
      await _supabase.from('groups').delete().eq('id', groupId);

      final updatedGroups =
          state.groups.where((group) => group.groupId != groupId).toList();

      if (!mounted) return;
      state = state.copyWith(groups: updatedGroups);

      final box = await Hive.openBox<Group>('groups');
      await box.delete(groupId);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(error: 'Failed to delete group: $e');
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

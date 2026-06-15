import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../core/models/group.dart';
import 'expense_provider.dart';
import 'auth_provider.dart';


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
  GroupNotifier() : super(const GroupState(groups: [], isLoading: false)) {
    _loadGroups();
  }

  // Load groups from Hive
  Future<void> _loadGroups() async {
    try {
      final box = await Hive.openBox<Group>('groups');
      final groups = box.values.toList();
      state = state.copyWith(groups: groups);
    } catch (e) {
      state = state.copyWith(error: 'Failed to load groups: $e');
    }
  }

  // Save groups to Hive
  Future<void> _saveGroups() async {
    try {
      final box = await Hive.openBox<Group>('groups');
      await box.clear();
      for (final group in state.groups) {
        await box.put(group.groupId, group);
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to save groups: $e');
    }
  }

  // Add a new group
  Future<void> addGroup({
    required String name,
    required List<String> members,
    String currency = 'PKR',
  }) async {
    print('👥 Adding group: $name');
    print('👨‍👩‍👧‍👦 Members: ${members.join(', ')}');
    print('💵 Currency: $currency');

    final newGroup = Group(
      groupId: const Uuid().v4(),
      name: name,
      members: members,
      currency: currency,
      createdAt: DateTime.now(),
    );

    state = state.copyWith(
      groups: [...state.groups, newGroup],
    );

    await _saveGroups();

    print('✅ Group added successfully. Total groups: ${state.groups.length}');
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
    final updatedGroups = state.groups.map((group) {
      return group.groupId == updatedGroup.groupId ? updatedGroup : group;
    }).toList();

    state = state.copyWith(groups: updatedGroups);
    await _saveGroups();
  }

  // Delete a group
  Future<void> deleteGroup(String groupId) async {
    final updatedGroups =
        state.groups.where((group) => group.groupId != groupId).toList();
    state = state.copyWith(groups: updatedGroups);
    await _saveGroups();
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
  // Return net total of all balances
  if (balances.isEmpty) return 0.0;
  return balances.values.fold(0.0, (sum, b) => sum + b);
});

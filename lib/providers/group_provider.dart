import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../core/models/group.dart';
import 'expense_provider.dart';

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
  GroupNotifier() : super(const GroupState(groups: [], isLoading: false));

  // Add a new group
  void addGroup({
    required String name,
    required List<String> members,
    String currency = 'PKR',
  }) {
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
  void updateGroup(Group updatedGroup) {
    final updatedGroups = state.groups.map((group) {
      return group.groupId == updatedGroup.groupId ? updatedGroup : group;
    }).toList();

    state = state.copyWith(groups: updatedGroups);
  }

  // Delete a group
  void deleteGroup(String groupId) {
    final updatedGroups =
        state.groups.where((group) => group.groupId != groupId).toList();
    state = state.copyWith(groups: updatedGroups);
  }
}

// Provider
final groupProvider = StateNotifierProvider<GroupNotifier, GroupState>((ref) {
  return GroupNotifier();
});

// Balance for a specific group computed from expenses
final groupBalanceProvider = Provider.family<double, String>((ref, groupId) {
  final balances = ref.watch(balancesForGroupProvider(groupId));
  // Return net total of all balances
  if (balances.isEmpty) return 0.0;
  return balances.values.fold(0.0, (sum, b) => sum + b);
});

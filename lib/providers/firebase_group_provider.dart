import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/models/group.dart';

// Firebase Group State
class FirebaseGroupState {
  final List<Group> groups;
  final bool isLoading;
  final String? error;

  const FirebaseGroupState({
    required this.groups,
    this.isLoading = false,
    this.error,
  });

  FirebaseGroupState copyWith({
    List<Group>? groups,
    bool? isLoading,
    String? error,
  }) {
    return FirebaseGroupState(
      groups: groups ?? this.groups,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FirebaseGroupState &&
          runtimeType == other.runtimeType &&
          groups == other.groups &&
          isLoading == other.isLoading &&
          error == other.error;

  @override
  int get hashCode => groups.hashCode ^ isLoading.hashCode ^ error.hashCode;
}

// Firebase Group Notifier (now backed by Supabase!)
class FirebaseGroupNotifier extends StateNotifier<FirebaseGroupState> {
  final SupabaseClient _supabase;

  FirebaseGroupNotifier(this._supabase)
      : super(const FirebaseGroupState(groups: [], isLoading: false)) {
    _loadGroups();
  }

  // Load groups from Supabase
  Future<void> _loadGroups() async {
    try {
      state = state.copyWith(isLoading: true);

      final user = _supabase.auth.currentUser;
      if (user == null) {
        state = state.copyWith(isLoading: false, groups: []);
        return;
      }

      final data = await _supabase
          .from('groups')
          .select()
          .eq('userId', user.id);

      final groups = (data as List).map((row) {
        return Group(
          groupId: row['id']?.toString() ?? '',
          name: row['name'] as String,
          members: List<String>.from(row['members'] ?? []),
          currency: row['currency'] as String? ?? 'USD',
          createdAt: row['createdAt'] != null
              ? DateTime.parse(row['createdAt'] as String)
              : DateTime.now(),
        );
      }).toList();

      state = state.copyWith(groups: groups, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load groups: $e',
      );
    }
  }

  // Add a new group to Supabase
  Future<void> addGroup({
    required String name,
    required List<String> members,
    String currency = 'USD',
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      await _supabase.from('groups').insert({
        'name': name,
        'members': members,
        'currency': currency,
        'userId': user.id,
        'createdAt': DateTime.now().toIso8601String(),
      });

      // Reload groups to get the updated list
      await _loadGroups();
    } catch (e) {
      state = state.copyWith(error: 'Failed to add group: $e');
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

  // Update a group in Supabase
  Future<void> updateGroup(Group updatedGroup) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      await _supabase.from('groups').update({
        'name': updatedGroup.name,
        'members': updatedGroup.members,
        'currency': updatedGroup.currency,
      }).eq('id', updatedGroup.groupId);

      await _loadGroups();
    } catch (e) {
      state = state.copyWith(error: 'Failed to update group: $e');
      rethrow;
    }
  }

  // Delete a group from Supabase
  Future<void> deleteGroup(String groupId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      await _supabase
          .from('groups')
          .delete()
          .eq('id', groupId);

      await _loadGroups();
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete group: $e');
      rethrow;
    }
  }
}

// Supabase Client Provider
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final firebaseGroupProvider =
    StateNotifierProvider<FirebaseGroupNotifier, FirebaseGroupState>((ref) {
  return FirebaseGroupNotifier(
    ref.watch(supabaseClientProvider),
  );
});

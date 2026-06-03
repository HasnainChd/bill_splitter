import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

// Firebase Group Notifier
class FirebaseGroupNotifier extends StateNotifier<FirebaseGroupState> {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FirebaseGroupNotifier(this._firestore, this._auth)
      : super(const FirebaseGroupState(groups: [], isLoading: false)) {
    _loadGroups();
  }

  // Load groups from Firestore
  Future<void> _loadGroups() async {
    try {
      state = state.copyWith(isLoading: true);

      final user = _auth.currentUser;
      if (user == null) {
        state = state.copyWith(isLoading: false, groups: []);
        return;
      }

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('groups')
          .get();

      final groups = snapshot.docs.map((doc) {
        final data = doc.data();
        return Group(
          groupId: doc.id,
          name: data['name'] as String,
          members: List<String>.from(data['members']),
          currency: data['currency'] as String? ?? 'USD',
          createdAt: (data['createdAt'] as Timestamp).toDate(),
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

  // Add a new group to Firestore
  Future<void> addGroup({
    required String name,
    required List<String> members,
    String currency = 'USD',
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('groups')
          .add({
        'name': name,
        'members': members,
        'currency': currency,
        'createdAt': FieldValue.serverTimestamp(),
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

  // Update a group in Firestore
  Future<void> updateGroup(Group updatedGroup) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('groups')
          .doc(updatedGroup.groupId)
          .update({
        'name': updatedGroup.name,
        'members': updatedGroup.members,
        'currency': updatedGroup.currency,
      });

      await _loadGroups();
    } catch (e) {
      state = state.copyWith(error: 'Failed to update group: $e');
      rethrow;
    }
  }

  // Delete a group from Firestore
  Future<void> deleteGroup(String groupId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('groups')
          .doc(groupId)
          .delete();

      await _loadGroups();
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete group: $e');
      rethrow;
    }
  }
}

// Firebase Providers
final firebaseFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final firebaseGroupProvider =
    StateNotifierProvider<FirebaseGroupNotifier, FirebaseGroupState>((ref) {
  return FirebaseGroupNotifier(
    ref.watch(firebaseFirestoreProvider),
    ref.watch(firebaseAuthProvider),
  );
});

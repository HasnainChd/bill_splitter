import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';

/// Selected category chip
final aeCategoryProvider = StateProvider.autoDispose<String>((ref) => 'Food');

/// Split type: 'Equal', 'Custom', '%'
final aeSplitTypeProvider = StateProvider.autoDispose<String>((ref) => 'Equal');

/// Which members are included in the split
final aeSelectedMembersProvider =
    StateProvider.autoDispose<Set<String>>((ref) => {});

/// Amount text controller
final aeAmountControllerProvider =
    Provider.autoDispose<TextEditingController>((ref) {
  final c = TextEditingController(text: '0');
  ref.onDispose(c.dispose);
  return c;
});

/// Description text controller
final aeTitleControllerProvider =
    Provider.autoDispose<TextEditingController>((ref) {
  final c = TextEditingController();
  ref.onDispose(c.dispose);
  return c;
});

/// Custom split amount per user ID
final aeCustomSplitsProvider =
    StateProvider<Map<String, double>>((ref) => {});

/// Percent split amount per user ID
final aePercentSplitsProvider =
    StateProvider<Map<String, double>>((ref) => {});

/// Track loaded group IDs to prevent infinite fetch loop in GroupDetailScreen
final loadedGroupExpensesProvider =
    StateProvider.autoDispose<Set<String>>((ref) => {});

// ─── Create Group providers ────────────────────────────────────────────────

/// Selected icon code point
final cgSelectedIconCodePointProvider = StateProvider.autoDispose<int>((ref) => 0xf03b); // Icons.flight_takeoff_rounded.codePoint

/// Selected color index (0-based)
final cgColorIndexProvider = StateProvider.autoDispose<int>((ref) => 1);

/// Selected members set (contains user IDs)
final cgSelectedMembersProvider =
    StateProvider.autoDispose<Set<String>>((ref) => {});

/// Member search query
final cgMemberSearchProvider =
    StateProvider.autoDispose<String>((ref) => '');

/// Group name controller
final cgNameControllerProvider =
    Provider.autoDispose<TextEditingController>((ref) {
  final c = TextEditingController();
  ref.onDispose(c.dispose);
  return c;
});

/// Member search controller
final cgSearchControllerProvider =
    Provider.autoDispose<TextEditingController>((ref) {
  final c = TextEditingController();
  ref.onDispose(c.dispose);
  return c;
});

/// Retrieve all registered user profiles from Supabase
final allUsersProvider = FutureProvider<List<UserProfile>>((ref) async {
  final supabase = Supabase.instance.client;
  final currentUser = ref.watch(supabaseUserProvider);
  if (currentUser == null) return [];

  try {
    final data = await supabase
        .from('users')
        .select()
        .neq('id', currentUser.id);

    return (data as List).map((row) {
      return UserProfile(
        id: row['id']?.toString() ?? '',
        fullName: row['fullName'] as String? ?? 'Unknown',
        username: row['username'] as String? ?? '',
        email: row['email'] as String? ?? '',
        phone: row['phone'] as String? ?? '',
        bio: row['bio'] as String? ?? '',
        currency: row['currency'] as String? ?? 'USD',
        avatarUrl: row['avatarUrl'] as String? ?? '',
      );
    }).toList();
  } catch (e) {
    debugPrint('Error fetching registered users: $e');
    return [];
  }
});

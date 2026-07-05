import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/group_provider.dart';

/// Selected category chip
final aeCategoryProvider = StateProvider.autoDispose<String>((ref) => 'Food');

/// Split type: 'Equal', 'Custom', '%'
final aeSplitTypeProvider = StateProvider.autoDispose<String>((ref) => 'Equal');

/// Which members are included in the split
final aeSelectedMembersProvider =
    StateProvider.autoDispose<Set<String>>((ref) => {});

/// Selected payer user ID
final aePaidByProvider = StateProvider.autoDispose<String?>((ref) => null);

/// Amount text controller
final aeAmountControllerProvider =
    Provider.autoDispose<TextEditingController>((ref) {
  final c = TextEditingController(text: '0');
  ref.onDispose(c.dispose);
  return c;
});

/// Amount numeric value (for reactive UI updates on keystrokes)
final aeAmountValueProvider = StateProvider.autoDispose<double>((ref) => 0.0);

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

/// Selected Date
final aeDateProvider = StateProvider.autoDispose<DateTime>((ref) => DateTime.now());

/// Notes text controller
final aeNotesControllerProvider = Provider.autoDispose<TextEditingController>((ref) {
  final c = TextEditingController();
  ref.onDispose(c.dispose);
  return c;
});

/// Selected Receipt Image File
final aeReceiptFileProvider = StateProvider.autoDispose<File?>((ref) => null);

/// Existing Receipt URL (for editing)
final aeReceiptUrlProvider = StateProvider.autoDispose<String?>((ref) => null);

/// Track loaded group IDs to prevent infinite fetch loop in GroupDetailScreen
final loadedGroupExpensesProvider =
    StateProvider.autoDispose<Set<String>>((ref) => {});

/// Track loaded expense IDs to prevent infinite fetch loop in ExpenseDetailScreen
final loadedSingleExpensesProvider =
    StateProvider.autoDispose<Set<String>>((ref) => {});

// ─── Create Group providers ────────────────────────────────────────────────

/// Selected icon code point
final cgSelectedIconCodePointProvider = StateProvider.autoDispose<int>((ref) => 0xf03b); // Icons.flight_takeoff_rounded.codePoint

/// Selected color index (0-based)
final cgColorIndexProvider = StateProvider.autoDispose<int>((ref) => 1);

/// Selected group currency code (e.g. 'PKR (Rs)', 'USD ($)')
final cgSelectedCurrencyProvider = StateProvider.autoDispose<String>((ref) {
  return ref.watch(defaultCurrencyProvider);
});

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

/// Retrieve related user profiles (members of user's groups) from Supabase
final allUsersProvider = FutureProvider<List<UserProfile>>((ref) async {
  final supabase = Supabase.instance.client;
  final currentUser = ref.watch(supabaseUserProvider);
  if (currentUser == null) return [];

  try {
    // Get all groups the current user is in
    final groups = ref.watch(groupProvider).groups;
    
    // Collect all unique user IDs across these groups (excluding current user)
    final Set<String> memberIds = {};
    for (final group in groups) {
      memberIds.addAll(group.members);
    }
    memberIds.remove(currentUser.id);

    if (memberIds.isEmpty) return [];

    // Query profiles for only these users
    final data = await supabase
        .from('users')
        .select()
        .inFilter('id', memberIds.toList());

    final rawList = (data as List).map((row) => UserProfile.fromMap(row, '')).toList();
    final List<UserProfile> filtered = [];
    for (var i = 0; i < data.length; i++) {
      final row = data[i];
      final isPublic = row['is_public'] ?? row['isPublic'] ?? true;
      if (isPublic == true) {
        filtered.add(rawList[i]);
      }
    }
    return filtered;
  } catch (e) {
    debugPrint('Error fetching related users: $e');
    return [];
  }
});

/// Search users from Supabase by query
final searchedUsersProvider = FutureProvider.autoDispose.family<List<UserProfile>, String>((ref, query) async {
  final cleanQ = query.trim().startsWith('@')
      ? query.trim().substring(1)
      : query.trim();
      
  if (cleanQ.length < 2) return [];

  final supabase = Supabase.instance.client;
  final currentUser = ref.watch(supabaseUserProvider);
  if (currentUser == null) return [];

  try {
    final data = await supabase
        .from('users')
        .select()
        .or('username.ilike.%$cleanQ%,email.ilike.%$cleanQ%,full_name.ilike.%$cleanQ%')
        .eq('is_public', true)
        .neq('id', currentUser.id)
        .limit(15);

    return (data as List).map((row) => UserProfile.fromMap(row, '')).toList();
  } catch (e) {
    debugPrint('Error searching users on server: $e');
    return [];
  }
});

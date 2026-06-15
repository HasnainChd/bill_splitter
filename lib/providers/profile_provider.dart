import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/utils/app_snackbar.dart';

import 'package:hive_flutter/hive_flutter.dart';
import 'auth_provider.dart';

class UserProfile {
  final String id;
  final String fullName;
  final String username;
  final String email;
  final String phone;
  final String bio;
  final String currency;
  final String avatarUrl;

  UserProfile({
    required this.id,
    required this.fullName,
    required this.username,
    required this.email,
    required this.phone,
    required this.bio,
    required this.currency,
    required this.avatarUrl,
  });

  UserProfile copyWith({
    String? id,
    String? fullName,
    String? username,
    String? email,
    String? phone,
    String? bio,
    String? currency,
    String? avatarUrl,
  }) {
    return UserProfile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      bio: bio ?? this.bio,
      currency: currency ?? this.currency,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  factory UserProfile.fromMap(Map<String, dynamic> data, String authEmail) {
    final box = Hive.box('settings');
    final localCurrency =
        box.get('default_currency', defaultValue: 'USD (\$)') as String;
    return UserProfile(
      id: data['id'] ?? '',
      fullName: data['fullName'] ?? data['full_name'] ?? '',
      username: data['username'] ?? '',
      email: data['email'] ?? authEmail,
      phone: data['phone'] ?? '',
      bio: data['bio'] ?? '',
      currency: data['currency'] ??
          data['default_currency'] ??
          data['defaultCurrency'] ??
          localCurrency,
      avatarUrl: data['avatarUrl'] ?? data['avatar_url'] ?? '',
    );
  }
}

class ProfileState {
  final bool isLoading;
  final UserProfile? profile;
  final String? error;

  const ProfileState({
    this.isLoading = false,
    this.profile,
    this.error,
  });

  ProfileState copyWith({
    bool? isLoading,
    UserProfile? profile,
    String? error,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      profile: profile ?? this.profile,
      error: error,
    );
  }
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final List<String> _dbColumns = [];

  ProfileNotifier() : super(const ProfileState()) {
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    state = state.copyWith(isLoading: true);
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (response != null) {
        // _dbColumns = response.keys.toList();
        // debugPrint('👤 Profile response from Supabase: $response');
        // debugPrint('👤 Available database columns: $_dbColumns');
        state = state.copyWith(
          profile: UserProfile.fromMap(response, user.email ?? ''),
          isLoading: false,
        );
      } else {
        // If not found in public.users, create default structure and try inserting
        final defaultProfile = UserProfile(
          id: user.id,
          fullName: user.userMetadata?['fullName'] ??
              user.userMetadata?['full_name'] ??
              '',
          username: user.userMetadata?['username'] ?? '',
          email: user.email ?? '',
          phone: '',
          bio: '',
          currency: 'USD (\$)',
          avatarUrl: user.userMetadata?['avatar_url'] ?? '',
        );
        state = state.copyWith(profile: defaultProfile, isLoading: false);
      }
    } catch (e, stack) {
      debugPrint('Error fetching profile: $e\n$stack');
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<bool> updateProfile({
    required String fullName,
    required String username,
    required String phone,
    required String bio,
    required String currency,
    String? avatarFilePath,
    required BuildContext context,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    state = state.copyWith(isLoading: true);
    try {
      String? avatarUrl = state.profile?.avatarUrl;

      // Handle avatar upload if a new file path is provided
      if (avatarFilePath != null && avatarFilePath.isNotEmpty) {
        final file = File(avatarFilePath);
        final fileExt = avatarFilePath.split('.').last;
        final fileName = '${user.id}_avatar.$fileExt';

        await _supabase.storage.from('avatars').upload(
              fileName,
              file,
              fileOptions: const FileOptions(upsert: true),
            );

        avatarUrl = _supabase.storage.from('avatars').getPublicUrl(fileName);
      }

      // Build safe update request using verified database columns
      final Map<String, dynamic> updateData = {'id': user.id};

      void addIfColumnExists(String colName, dynamic value) {
        if (_dbColumns.contains(colName)) {
          updateData[colName] = value;
        }
      }

      // If we don't have columns list yet, default to standard camelCase
      if (_dbColumns.isEmpty) {
        updateData['fullName'] = fullName;
        updateData['username'] = username;
        updateData['email'] = user.email;
        updateData['phone'] = phone;
        updateData['bio'] = bio;
        updateData['currency'] = currency;
        updateData['avatarUrl'] = avatarUrl;
      } else {
        addIfColumnExists('fullName', fullName);
        addIfColumnExists('full_name', fullName);
        addIfColumnExists('username', username);
        addIfColumnExists('email', user.email);
        addIfColumnExists('phone', phone);
        addIfColumnExists('bio', bio);
        addIfColumnExists('currency', currency);
        addIfColumnExists('default_currency', currency);
        addIfColumnExists('defaultCurrency', currency);
        addIfColumnExists('avatarUrl', avatarUrl);
        addIfColumnExists('avatar_url', avatarUrl);
      }

      // debugPrint('👤 Sending profile updates to Supabase: $updateData');

      // Save currency locally to Hive box immediately so fetchProfile falls back to it
      try {
        final box = Hive.box('settings');
        await box.put('default_currency', currency);
      } catch (e) {
        debugPrint('Error saving default_currency locally: $e');
      }

      await _supabase.from('users').upsert(updateData);

      // Refresh local profile
      await fetchProfile();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      if (context.mounted) {
        AppSnackBar.showError(context, 'Failed to update profile: $e');
      }
      return false;
    }
  }
}

final profileProvider =
    StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  ref.watch(supabaseUserProvider);
  return ProfileNotifier();
});

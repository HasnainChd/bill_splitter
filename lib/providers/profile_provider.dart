import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/utils/app_snackbar.dart';

import 'package:hive_flutter/hive_flutter.dart';
import '../core/utils/error_handler.dart';
import '../core/services/analytics_service.dart';
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

  static String _getString(Map<String, dynamic> data, List<String> keys, {String defaultValue = ''}) {
    for (final key in keys) {
      if (data.containsKey(key) && data[key] != null) {
        return data[key].toString();
      }
    }
    for (final key in keys) {
      final lowercaseKey = key.toLowerCase();
      for (final entry in data.entries) {
        if (entry.key.toLowerCase() == lowercaseKey && entry.value != null) {
          return entry.value.toString();
        }
      }
    }
    return defaultValue;
  }

  factory UserProfile.fromMap(Map<String, dynamic> data, String authEmail) {
    final box = Hive.box('settings');
    final id = _getString(data, ['id']);
    final key = id.isNotEmpty ? 'default_currency_$id' : 'default_currency';
    final localCurrency = box.get(key, defaultValue: 'USD (\$)') as String;

    return UserProfile(
      id: id,
      fullName: _getString(data, ['fullName', 'full_name']),
      username: _getString(data, ['username']),
      email: _getString(data, ['email'], defaultValue: authEmail),
      phone: _getString(data, ['phone']),
      bio: _getString(data, ['bio']),
      currency: _getString(data, ['currency', 'default_currency', 'defaultCurrency'], defaultValue: localCurrency),
      avatarUrl: _getString(data, ['avatarUrl', 'avatar_url']),
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

    if (!mounted) return;
    state = state.copyWith(isLoading: true);
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (response != null) {
        _dbColumns.clear();
        _dbColumns.addAll(response.keys);
        debugPrint('👤 Profile response from Supabase: $response');
        debugPrint('👤 Available database columns: $_dbColumns');
        // Sync database privacy settings to Hive
        final box = Hive.box('settings');
        if (response['is_public'] != null) {
          box.put('privacy_public_${user.id}', response['is_public'] as bool);
        }
        if (response['allow_invites'] != null) {
          box.put('privacy_invites_${user.id}', response['allow_invites'] as String);
        }
        if (response['share_analytics'] != null) {
          box.put('privacy_analytics_${user.id}', response['share_analytics'] as bool);
        }
        if (response['read_receipts'] != null) {
          box.put('privacy_read_receipts_${user.id}', response['read_receipts'] as bool);
        }

        final profile = UserProfile.fromMap(response, user.email ?? '');
        debugPrint('👤 Parsed avatarUrl: ${profile.avatarUrl}');
        AnalyticsService.setUserId(user.id);
        AnalyticsService.setDefaultCurrency(profile.currency);
        if (mounted) {
          state = state.copyWith(
            profile: profile,
            isLoading: false,
          );
        }
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
        if (mounted) {
          state = state.copyWith(profile: defaultProfile, isLoading: false);
        }
      }
    } catch (e, stack) {
      debugPrint('Error fetching profile: $e\n$stack');
      if (mounted) {
        state = state.copyWith(
            error: ErrorHandler.getUserFriendlyMessage(e), isLoading: false);
      }
    }
  }

  Future<bool> updateProfile({
    required String fullName,
    required String username,
    required String phone,
    required String bio,
    required String currency,
    String? avatarFilePath,
    BuildContext? context,
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

      final box = Hive.box('settings');
      final isPublic = box.get('privacy_public_${user.id}', defaultValue: true) as bool;
      final allowInvites = box.get('privacy_invites_${user.id}', defaultValue: 'Everyone') as String;
      final shareAnalytics = box.get('privacy_analytics_${user.id}', defaultValue: true) as bool;
      final readReceipts = box.get('privacy_read_receipts_${user.id}', defaultValue: true) as bool;

      // If we don't have columns list yet, default to standard camelCase
      if (_dbColumns.isEmpty) {
        updateData['fullName'] = fullName;
        updateData['username'] = username;
        updateData['email'] = user.email;
        updateData['phone'] = phone;
        updateData['bio'] = bio;
        updateData['currency'] = currency;
        updateData['avatarUrl'] = avatarUrl;
        updateData['is_public'] = isPublic;
        updateData['allow_invites'] = allowInvites;
        updateData['share_analytics'] = shareAnalytics;
        updateData['read_receipts'] = readReceipts;
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
        addIfColumnExists('is_public', isPublic);
        addIfColumnExists('allow_invites', allowInvites);
        addIfColumnExists('share_analytics', shareAnalytics);
        addIfColumnExists('read_receipts', readReceipts);
      }

      // debugPrint('👤 Sending profile updates to Supabase: $updateData');

      // Save currency locally to Hive box immediately so fetchProfile falls back to it
      try {
        final box = Hive.box('settings');
        await box.put('default_currency_${user.id}', currency);
      } catch (e) {
        debugPrint('Error saving default_currency locally: $e');
      }

      await _supabase.from('users').upsert(updateData);

      // Refresh local profile
      await fetchProfile();
      return true;
    } catch (e) {
      state = state.copyWith(
          error: ErrorHandler.getUserFriendlyMessage(e), isLoading: false);
      if (context != null && context.mounted) {
        AppSnackBar.showError(
            context, ErrorHandler.getUserFriendlyMessage(e));
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

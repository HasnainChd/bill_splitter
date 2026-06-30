import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_provider.dart';
import 'profile_provider.dart';

// Preferences Providers
class DefaultCurrencyNotifier extends StateNotifier<String> {
  final String? _userId;

  DefaultCurrencyNotifier(this._userId) : super('USD (\$)') {
    final box = Hive.box('settings');
    final key = _userId != null ? 'default_currency_$_userId' : 'default_currency';
    state = box.get(key, defaultValue: 'USD (\$)') as String;
  }

  @override
  set state(String value) {
    super.state = value;
    final box = Hive.box('settings');
    final key = _userId != null ? 'default_currency_$_userId' : 'default_currency';
    box.put(key, value);
  }
}

final defaultCurrencyProvider =
    StateNotifierProvider<DefaultCurrencyNotifier, String>((ref) {
  final user = ref.watch(supabaseUserProvider);
  final profileCurrency = ref.watch(profileProvider.select((s) => s.profile?.currency));
  final notifier = DefaultCurrencyNotifier(user?.id);

  if (profileCurrency != null && profileCurrency.isNotEmpty) {
    notifier.state = profileCurrency;
  }

  return notifier;
});

final languageProvider = StateProvider<String>((ref) {
  ref.watch(supabaseUserProvider);
  return 'English (US)';
});

class DateFormatNotifier extends StateNotifier<String> {
  final String? _userId;

  DateFormatNotifier(this._userId) : super('MM/DD/YYYY') {
    final box = Hive.box('settings');
    final key = _userId != null ? 'date_format_$_userId' : 'date_format';
    state = box.get(key, defaultValue: 'MM/DD/YYYY') as String;
  }

  @override
  set state(String value) {
    super.state = value;
    final box = Hive.box('settings');
    final key = _userId != null ? 'date_format_$_userId' : 'date_format';
    box.put(key, value);
  }
}

final dateFormatProvider =
    StateNotifierProvider<DateFormatNotifier, String>((ref) {
  final user = ref.watch(supabaseUserProvider);
  return DateFormatNotifier(user?.id);
});

// Security Providers
final twoFactorAuthEnabledProvider = StateProvider<bool>((ref) {
  ref.watch(supabaseUserProvider);
  return false;
});

final twoFactorMethodProvider = StateProvider<String>((ref) {
  ref.watch(supabaseUserProvider);
  return 'SMS';
});

// Privacy Providers
class PrivacyBoolNotifier extends StateNotifier<bool> {
  final String _key;
  final String _dbColumn;
  final bool _defaultValue;

  PrivacyBoolNotifier(this._key, this._dbColumn, this._defaultValue) : super(_defaultValue) {
    final box = Hive.box('settings');
    state = box.get(_key, defaultValue: _defaultValue) as bool;
  }

  @override
  set state(bool value) {
    super.state = value;
    final box = Hive.box('settings');
    box.put(_key, value);
    _syncToDb(value);
  }

  Future<void> _syncToDb(bool value) async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user != null) {
        await supabase.from('users').upsert({
          'id': user.id,
          _dbColumn: value,
        });
        debugPrint('👤 Privacy Setting Synced: $_dbColumn = $value');
      }
    } catch (e) {
      debugPrint('Error syncing privacy setting $_dbColumn: $e');
    }
  }
}

class PrivacyStringNotifier extends StateNotifier<String> {
  final String _key;
  final String _dbColumn;
  final String _defaultValue;

  PrivacyStringNotifier(this._key, this._dbColumn, this._defaultValue) : super(_defaultValue) {
    final box = Hive.box('settings');
    state = box.get(_key, defaultValue: _defaultValue) as String;
  }

  @override
  set state(String value) {
    super.state = value;
    final box = Hive.box('settings');
    box.put(_key, value);
    _syncToDb(value);
  }

  Future<void> _syncToDb(String value) async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user != null) {
        await supabase.from('users').upsert({
          'id': user.id,
          _dbColumn: value,
        });
        debugPrint('👤 Privacy Setting Synced: $_dbColumn = $value');
      }
    } catch (e) {
      debugPrint('Error syncing privacy setting $_dbColumn: $e');
    }
  }
}

final privacyProfilePublicProvider =
    StateNotifierProvider.autoDispose<PrivacyBoolNotifier, bool>((ref) {
  final user = ref.watch(supabaseUserProvider);
  final key = user != null ? 'privacy_public_${user.id}' : 'privacy_public';
  return PrivacyBoolNotifier(key, 'is_public', true);
});

final privacyAllowInvitesProvider =
    StateNotifierProvider.autoDispose<PrivacyStringNotifier, String>((ref) {
  final user = ref.watch(supabaseUserProvider);
  final key = user != null ? 'privacy_invites_${user.id}' : 'privacy_invites';
  return PrivacyStringNotifier(key, 'allow_invites', 'Everyone');
});

final privacyShareAnalyticsProvider =
    StateNotifierProvider.autoDispose<PrivacyBoolNotifier, bool>((ref) {
  final user = ref.watch(supabaseUserProvider);
  final key = user != null ? 'privacy_analytics_${user.id}' : 'privacy_analytics';
  return PrivacyBoolNotifier(key, 'share_analytics', true);
});

final privacyReadReceiptsProvider =
    StateNotifierProvider.autoDispose<PrivacyBoolNotifier, bool>((ref) {
  final user = ref.watch(supabaseUserProvider);
  final key = user != null ? 'privacy_read_receipts_${user.id}' : 'privacy_read_receipts';
  return PrivacyBoolNotifier(key, 'read_receipts', true);
});

// Security settings providers
class FaceIdNotifier extends StateNotifier<bool> {
  final String? _userId;

  FaceIdNotifier(this._userId) : super(true) {
    final box = Hive.box('settings');
    final key = _userId != null ? 'face_id_enabled_$_userId' : 'face_id_enabled';
    state = box.get(key, defaultValue: true) as bool;
  }

  Future<void> setFaceId(bool value) async {
    state = value;
    final box = Hive.box('settings');
    final key = _userId != null ? 'face_id_enabled_$_userId' : 'face_id_enabled';
    await box.put(key, value);
  }
}

final faceIdEnabledProvider =
    StateNotifierProvider<FaceIdNotifier, bool>((ref) {
  final user = ref.watch(supabaseUserProvider);
  return FaceIdNotifier(user?.id);
});

class RequireOnLaunchNotifier extends StateNotifier<bool> {
  final String? _userId;

  RequireOnLaunchNotifier(this._userId) : super(true) {
    final box = Hive.box('settings');
    final key = _userId != null ? 'require_on_launch_$_userId' : 'require_on_launch';
    state = box.get(key, defaultValue: true) as bool;
  }

  Future<void> setRequireOnLaunch(bool value) async {
    state = value;
    final box = Hive.box('settings');
    final key = _userId != null ? 'require_on_launch_$_userId' : 'require_on_launch';
    await box.put(key, value);
  }
}

final requireOnLaunchProvider =
    StateNotifierProvider<RequireOnLaunchNotifier, bool>((ref) {
  final user = ref.watch(supabaseUserProvider);
  return RequireOnLaunchNotifier(user?.id);
});

class AutoLockNotifier extends StateNotifier<String> {
  AutoLockNotifier() : super('After 5 minutes') {
    final box = Hive.box('settings');
    state = box.get('auto_lock', defaultValue: 'After 5 minutes') as String;
  }

  Future<void> setAutoLock(String value) async {
    state = value;
    final box = Hive.box('settings');
    await box.put('auto_lock', value);
  }
}

final autoLockProvider =
    StateNotifierProvider<AutoLockNotifier, String>((ref) {
  return AutoLockNotifier();
});

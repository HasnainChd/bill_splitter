import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
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

final dateFormatProvider = StateProvider<String>((ref) {
  ref.watch(supabaseUserProvider);
  return 'MM/DD/YYYY';
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
final privacyProfilePublicProvider = StateProvider<bool>((ref) {
  ref.watch(supabaseUserProvider);
  return true;
});

final privacyAllowInvitesProvider = StateProvider<String>((ref) {
  ref.watch(supabaseUserProvider);
  return 'Everyone';
});

final privacyShareAnalyticsProvider = StateProvider<bool>((ref) {
  ref.watch(supabaseUserProvider);
  return true;
});

final privacyReadReceiptsProvider = StateProvider<bool>((ref) {
  ref.watch(supabaseUserProvider);
  return true;
});

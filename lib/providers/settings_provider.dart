import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'auth_provider.dart';

// Preferences Providers
class DefaultCurrencyNotifier extends StateNotifier<String> {
  DefaultCurrencyNotifier() : super('USD (\$)') {
    final box = Hive.box('settings');
    state = box.get('default_currency', defaultValue: 'USD (\$)') as String;
  }

  @override
  set state(String value) {
    super.state = value;
    Hive.box('settings').put('default_currency', value);
  }
}

final defaultCurrencyProvider =
    StateNotifierProvider<DefaultCurrencyNotifier, String>((ref) {
  ref.watch(supabaseUserProvider);
  return DefaultCurrencyNotifier();
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

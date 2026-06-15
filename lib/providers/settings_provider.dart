import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'auth_provider.dart';

// Preferences Providers
final defaultCurrencyProvider = StateProvider<String>((ref) {
  ref.watch(supabaseUserProvider);
  final box = Hive.box('settings');
  final initial = box.get('default_currency', defaultValue: 'USD (\$)') as String;
  
  ref.listenSelf((previous, next) {
    box.put('default_currency', next);
  });
  
  return initial;
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

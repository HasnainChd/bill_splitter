import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Preferences Providers
final defaultCurrencyProvider = StateProvider<String>((ref) {
  final box = Hive.box('settings');
  final initial = box.get('default_currency', defaultValue: 'USD (\$)') as String;
  
  ref.listenSelf((previous, next) {
    box.put('default_currency', next);
  });
  
  return initial;
});
final languageProvider = StateProvider<String>((ref) => 'English (US)');
final dateFormatProvider = StateProvider<String>((ref) => 'MM/DD/YYYY');

// Security Providers
final twoFactorAuthEnabledProvider = StateProvider<bool>((ref) => false);
final twoFactorMethodProvider = StateProvider<String>((ref) => 'SMS');

// Privacy Providers
final privacyProfilePublicProvider = StateProvider<bool>((ref) => true);
final privacyAllowInvitesProvider = StateProvider<String>((ref) => 'Everyone');
final privacyShareAnalyticsProvider = StateProvider<bool>((ref) => true);
final privacyReadReceiptsProvider = StateProvider<bool>((ref) => true);

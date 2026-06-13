import 'package:flutter_riverpod/flutter_riverpod.dart';

// Preferences Providers
final defaultCurrencyProvider = StateProvider<String>((ref) => 'USD (\$)');
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

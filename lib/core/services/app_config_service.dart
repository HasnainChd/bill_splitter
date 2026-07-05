import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppConfigService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetches application configuration values from Supabase.
  /// Fails silently on network errors to avoid blocking app startup.
  Future<Map<String, String>> fetchAppConfig() async {
    try {
      final response = await _supabase.from('app_config').select('key, value');
      final result = <String, String>{};
      
      for (final item in response) {
        final k = item['key']?.toString();
        final v = item['value']?.toString();
        if (k != null && v != null) {
          result[k] = v;
        }
      }
      debugPrint('AppConfig fetched: $result');
      return result;
    } catch (e) {
      debugPrint('AppConfig fetch failed: $e');
      // Fail silently, returning an empty map so startup is never blocked
      return const {};
    }
  }

  /// Returns true if the current installed version is less than the minimum version.
  bool isForceUpdateRequired(String currentVersion, String minVersion) {
    return _compareVersions(currentVersion, minVersion) < 0;
  }

  /// Returns true if the current installed version is less than the latest available version.
  bool isSoftUpdateAvailable(String currentVersion, String latestVersion) {
    return _compareVersions(currentVersion, latestVersion) < 0;
  }

  /// Compares two semantic version strings (major.minor.patch).
  /// Returns a negative integer if [v1] < [v2], zero if they are equal,
  /// and a positive integer if [v1] > [v2].
  int _compareVersions(String v1, String v2) {
    // Strip build numbers/suffixes like "+2" or "-beta" if present
    final cleanV1 = v1.split('+').first.split('-').first;
    final cleanV2 = v2.split('+').first.split('-').first;

    final parts1 = cleanV1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final parts2 = cleanV2.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    final maxLength = parts1.length > parts2.length ? parts1.length : parts2.length;
    for (int i = 0; i < maxLength; i++) {
      final segment1 = i < parts1.length ? parts1[i] : 0;
      final segment2 = i < parts2.length ? parts2[i] : 0;

      if (segment1 != segment2) {
        return segment1.compareTo(segment2);
      }
    }
    return 0;
  }
}

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../services/app_config_service.dart';

class VersionCheckResult {
  final String currentVersion;
  final String minVersion;
  final String latestVersion;
  final bool isForceUpdate;
  final bool isSoftUpdate;

  const VersionCheckResult({
    required this.currentVersion,
    required this.minVersion,
    required this.latestVersion,
    required this.isForceUpdate,
    required this.isSoftUpdate,
  });
}

final versionCheckProvider = FutureProvider<VersionCheckResult>((ref) async {
  final info = await PackageInfo.fromPlatform();
  final currentVersion = info.version;

  final service = AppConfigService();
  final config = await service.fetchAppConfig();

  // Use platform-specific keys for iOS and Android
  final String minKey;
  final String latestKey;

  if (Platform.isIOS) {
    minKey = 'min_version_ios';
    latestKey = 'latest_version_ios';
  } else {
    minKey = 'min_version_android';
    latestKey = 'latest_version_android';
  }

  final minVersion = config[minKey] ?? '1.0.0';
  final latestVersion = config[latestKey] ?? '1.0.0';

  final isForce = service.isForceUpdateRequired(currentVersion, minVersion);
  final isSoft = service.isSoftUpdateAvailable(currentVersion, latestVersion);

  debugPrint('Version check — current: $currentVersion, min: $minVersion, latest: $latestVersion, isForce: $isForce, isSoft: $isSoft');

  return VersionCheckResult(
    currentVersion: currentVersion,
    minVersion: minVersion,
    latestVersion: latestVersion,
    isForceUpdate: isForce,
    isSoftUpdate: isSoft,
  );
});

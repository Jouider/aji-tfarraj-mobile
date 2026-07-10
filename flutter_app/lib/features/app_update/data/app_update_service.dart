import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:aji_tfarraj/app/config/app_config.dart';
import 'package:aji_tfarraj/app/network/api_client.dart';

/// Backend version gate response (GET /api/app-config).
class AppVersionConfig {
  final String latestVersion;
  final String? minVersion;
  final String? iosUrl;
  final String? androidUrl;

  const AppVersionConfig({
    required this.latestVersion,
    this.minVersion,
    this.iosUrl,
    this.androidUrl,
  });

  factory AppVersionConfig.fromJson(Map<String, dynamic> json) {
    return AppVersionConfig(
      latestVersion: (json['latest_version'] ?? json['latest'] ?? '') as String,
      minVersion: (json['min_version'] ?? json['minimum_version']) as String?,
      iosUrl: (json['ios_url'] ?? json['ios_store_url']) as String?,
      androidUrl:
          (json['android_url'] ?? json['android_store_url']) as String?,
    );
  }
}

enum UpdateRequirement {
  /// App is up to date (or check failed — never block on failure).
  none,

  /// A newer version exists; prompt is dismissible.
  optional,

  /// Installed build is below the minimum supported version; must update.
  forced,
}

class UpdateStatus {
  final UpdateRequirement requirement;
  final String? storeUrl;

  const UpdateStatus(this.requirement, [this.storeUrl]);

  static const none = UpdateStatus(UpdateRequirement.none);
}

class AppUpdateRepository {
  final ApiClient _client;

  AppUpdateRepository(this._client);

  /// Compares the installed version against the backend config.
  /// Returns [UpdateStatus.none] on any failure — a flaky network must never
  /// lock the user out (the only hard gate is an explicit `min_version`).
  Future<UpdateStatus> check() async {
    try {
      final res = await _client.get<dynamic>(
        AppConfig.appConfig,
        queryParameters: {'platform': Platform.isIOS ? 'ios' : 'android'},
      );
      final data = res.data;
      final map = (data is Map && data['data'] is Map)
          ? data['data'] as Map<String, dynamic>
          : (data is Map<String, dynamic> ? data : null);
      if (map == null) return UpdateStatus.none;

      final cfg = AppVersionConfig.fromJson(map);
      final info = await PackageInfo.fromPlatform();
      final current = info.version; // e.g. "1.0.7"
      final storeUrl = Platform.isIOS ? cfg.iosUrl : cfg.androidUrl;

      if (cfg.minVersion != null &&
          cfg.minVersion!.isNotEmpty &&
          isVersionOlder(current, cfg.minVersion!)) {
        return UpdateStatus(UpdateRequirement.forced, storeUrl);
      }
      if (cfg.latestVersion.isNotEmpty &&
          isVersionOlder(current, cfg.latestVersion)) {
        return UpdateStatus(UpdateRequirement.optional, storeUrl);
      }
      return UpdateStatus.none;
    } catch (e) {
      if (kDebugMode) debugPrint('[AppUpdate] check failed: $e');
      return UpdateStatus.none;
    }
  }
}

/// Returns true if dotted-numeric version [current] is strictly older than
/// [target]. Build metadata (`+28`) and pre-release suffixes (`-beta`) are
/// ignored; missing segments are treated as 0. "1.0.7" < "1.0.10" is true.
@visibleForTesting
bool isVersionOlder(String current, String target) {
  final c = _parseVersion(current);
  final t = _parseVersion(target);
  final len = c.length > t.length ? c.length : t.length;
  for (var i = 0; i < len; i++) {
    final cv = i < c.length ? c[i] : 0;
    final tv = i < t.length ? t[i] : 0;
    if (cv < tv) return true;
    if (cv > tv) return false;
  }
  return false;
}

List<int> _parseVersion(String v) {
  final clean = v.trim().split('+').first.split('-').first;
  return clean
      .split('.')
      .map((p) => int.tryParse(p.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
      .toList();
}

final appUpdateRepositoryProvider = Provider<AppUpdateRepository>(
  (ref) => AppUpdateRepository(ref.watch(apiClientProvider)),
);

/// One-shot update check (cached for the app session via keepAlive).
final updateStatusProvider = FutureProvider<UpdateStatus>((ref) {
  ref.keepAlive();
  return ref.watch(appUpdateRepositoryProvider).check();
});

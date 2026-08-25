import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'analytics_context.dart';

Future<void> hydrateDeviceContext(AnalyticsContext context) async {
  try {
    final info = await PackageInfo.fromPlatform();
    context.appVersion = info.version;
    context.buildNumber = info.buildNumber;
  } on Object {
    // Tests / missing plugin.
  }

  try {
    final results = await Connectivity().checkConnectivity();
    context.networkType = _networkLabel(results);
  } on Object {
    // Missing plugin.
  }

  if (kIsWeb) return;
  try {
    final android = await DeviceInfoPlugin().androidInfo;
    context.androidVersion = android.version.release;
    context.manufacturer = android.manufacturer;
    context.model = android.model;
    if (android.supportedAbis.isNotEmpty) {
      context.cpuAbi = android.supportedAbis.first;
    }
  } on Object {
    // Non-Android or plugin missing.
  }
}

String _networkLabel(List<ConnectivityResult> results) {
  if (results.contains(ConnectivityResult.wifi)) return 'wifi';
  if (results.contains(ConnectivityResult.mobile)) return 'cellular';
  if (results.contains(ConnectivityResult.ethernet)) return 'ethernet';
  if (results.contains(ConnectivityResult.vpn)) return 'vpn';
  if (results.contains(ConnectivityResult.none)) return 'none';
  return 'unknown';
}

Future<String> currentNetworkType() async {
  try {
    return _networkLabel(await Connectivity().checkConnectivity());
  } on Object {
    return 'unknown';
  }
}

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

import 'app_permission.dart';

class PermissionResult {
  const PermissionResult({
    required this.permission,
    required this.granted,
    required this.permanentlyDenied,
  });

  final AppPermission permission;
  final bool granted;
  final bool permanentlyDenied;
}

class PermissionService {
  Permission _mapPermission(AppPermission permission) {
    return switch (permission) {
      AppPermission.notifications => Permission.notification,
      AppPermission.camera => Permission.camera,
      AppPermission.clipboard => Permission.ignoreBatteryOptimizations,
    };
  }

  Future<bool> isGranted(AppPermission permission) async {
    if (kIsWeb || permission == AppPermission.clipboard) {
      return true;
    }
    return _mapPermission(permission).isGranted;
  }

  Future<PermissionResult> request(AppPermission permission) async {
    if (kIsWeb || permission == AppPermission.clipboard) {
      return PermissionResult(
        permission: permission,
        granted: true,
        permanentlyDenied: false,
      );
    }

    final status = await _mapPermission(permission).request();
    return PermissionResult(
      permission: permission,
      granted: status.isGranted,
      permanentlyDenied: status.isPermanentlyDenied,
    );
  }

  Future<void> openSettings() async {
    if (kIsWeb) return;
    await openAppSettings();
  }
}

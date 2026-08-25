import 'package:flutter_test/flutter_test.dart';
import 'package:permissions/permissions.dart';

void main() {
  test('NP-005 clipboard is always granted', () async {
    final service = PermissionService();
    expect(await service.isGranted(AppPermission.clipboard), isTrue);

    final result = await service.request(AppPermission.clipboard);
    expect(result.permission, AppPermission.clipboard);
    expect(result.granted, isTrue);
    expect(result.permanentlyDenied, isFalse);
  });

  test('NP-006 permission metadata is present', () {
    for (final permission in AppPermission.values) {
      expect(permission.title, isNotEmpty);
      expect(permission.rationale, isNotEmpty);
      expect(permission.optional, isTrue);
    }
  });
}

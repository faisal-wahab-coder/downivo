import 'package:app_core/app_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _FakePathProvider extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async => '/tmp/udm_test';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  PathProviderPlatform.instance = _FakePathProvider();

  test('bootstrap completes and provides download manager', () async {
    SharedPreferences.setMockInitialValues({});
    final container = await bootstrap().timeout(const Duration(seconds: 5));
    expect(container.read(downloadManagerProvider), isNotNull);
    expect(container.read(goRouterProvider), isNotNull);
    container.dispose();
  });
}

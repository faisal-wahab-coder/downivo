import 'foreground_host.dart';
import 'foreground_host_stub.dart'
    if (dart.library.io) 'foreground_host_io.dart'
    if (dart.library.html) 'foreground_host_stub.dart';

export 'foreground_host.dart';

ForegroundHost createForegroundHost() => createPlatformForegroundHost();

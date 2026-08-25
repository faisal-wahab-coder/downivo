import 'share_intake.dart';
import 'share_intake_stub.dart'
    if (dart.library.io) 'share_intake_io.dart'
    if (dart.library.html) 'share_intake_stub.dart';

ShareIntake createShareIntake() => createPlatformShareIntake();

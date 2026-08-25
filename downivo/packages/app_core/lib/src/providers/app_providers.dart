import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'settings_provider.dart';

export 'settings_provider.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  throw UnimplementedError('goRouterProvider must be overridden at bootstrap');
});

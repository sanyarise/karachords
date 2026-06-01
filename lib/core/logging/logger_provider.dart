import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_logger.dart';

/// Global access to the application logger.
///
/// Usage: ref.read(loggerProvider).i('message')
final loggerProvider = Provider<AppLogger>((ref) {
  return AppLogger();
});

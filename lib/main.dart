import 'package:flutter/material.dart';
import 'app.dart';
import 'core/logging/app_logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppLogger().init();
  runApp(const KaraChordsApp());
}

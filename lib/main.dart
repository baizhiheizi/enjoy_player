import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';

import 'app.dart';
import 'core/logging/setup_logging.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setupAppLogging();
  MediaKit.ensureInitialized();
  runApp(const ProviderScope(child: EnjoyApp()));
}

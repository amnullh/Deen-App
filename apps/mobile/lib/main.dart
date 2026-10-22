import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/app_overrides.dart';
import 'data/db/open_database.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ProviderScope(
      overrides: appOverrides(database: openAppDatabase()),
      child: const DeenApp(),
    ),
  );
}

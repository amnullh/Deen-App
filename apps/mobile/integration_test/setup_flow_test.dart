// Integration test for task T036: skip location, choose a manual city, refuse
// every permission, and reach today's prayer times, with no network.
//
// The scenario lives in `test/ui/setup/setup_scenario.dart` and also runs as a
// host test (`flutter test test/ui/setup_scenario_test.dart`), over an in-memory
// database with fake platform gateways.
//
// On a device or emulator: `flutter test integration_test/setup_flow_test.dart -d <id>`.
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/ui/setup/setup_scenario.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'skip location, pick a manual city, refuse every permission, see prayer times',
    skipLocationRefuseEverythingScenario,
  );
}

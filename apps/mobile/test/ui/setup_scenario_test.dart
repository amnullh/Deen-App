import 'package:flutter_test/flutter_test.dart';

import 'setup/setup_scenario.dart';

void main() {
  testWidgets(
    'skip location, pick a manual city, refuse every permission, see prayer times',
    skipLocationRefuseEverythingScenario,
  );
}

import 'package:deen_mobile/ui/tasbih/device_services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'a missing asset or plugin makes the tick sound a no-op, not a crash',
    () async {
      final player = JustAudioTickPlayer(
        assetPath: 'assets/audio/does-not-exist.wav',
        loadTimeout: const Duration(milliseconds: 200),
      );
      await player.play();
      await player.play();
      await player.dispose();
    },
  );

  test('keep-awake failures are swallowed', () async {
    // wakelock_plus has no platform implementation in the test VM.
    await const WakelockKeepAwake().setEnabled(true);
    await const WakelockKeepAwake().setEnabled(false);
  });
}

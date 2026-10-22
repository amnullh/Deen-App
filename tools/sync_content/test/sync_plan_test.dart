import 'package:sync_content/sync_plan.dart';
import 'package:test/test.dart';

void main() {
  group('planCopy', () {
    test('sends Android audio to res/raw with a valid resource name', () {
      expect(
        planCopy('content/audio/android/Voice-1 Fajr.ogg'),
        const CopyAction(
          'content/audio/android/Voice-1 Fajr.ogg',
          'apps/mobile/android/app/src/main/res/raw/voice_1_fajr.ogg',
        ),
      );
    });

    test('sends iOS clips to the Runner Sounds folder unchanged', () {
      expect(
        planCopy('content/audio/ios/voice1_fajr.caf')?.destination,
        'apps/mobile/ios/Runner/Sounds/voice1_fajr.caf',
      );
    });

    test('sends shared audio, cities and adhkar packs into assets', () {
      expect(
        planCopy('content/audio/shared/tone-short.wav')?.destination,
        'apps/mobile/assets/audio/tone-short.wav',
      );
      expect(
        planCopy('content/cities/cities.db')?.destination,
        'apps/mobile/assets/cities/cities.db',
      );
      expect(
        planCopy('content/adhkar/pack/morning.json')?.destination,
        'apps/mobile/assets/adhkar/morning.json',
      );
    });

    test('ignores files that are not synced', () {
      expect(planCopy('content/LICENSES.md'), isNull);
      expect(planCopy('content/adhkar/sources/notes.md'), isNull);
      expect(planCopy('apps/mobile/pubspec.yaml'), isNull);
    });
  });

  group('androidResourceName', () {
    test('lower-cases and replaces illegal characters', () {
      expect(
        androidResourceName('Azan-Mecca (2013).OGG'),
        'azan_mecca_2013.ogg',
      );
    });

    test('prefixes names that start with a digit', () {
      expect(androidResourceName('1st.ogg'), 'r_1st.ogg');
    });
  });
}

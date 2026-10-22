import 'package:license_scan/scanner.dart';
import 'package:test/test.dart';

const _lock = '''
packages:
  drift:
    dependency: "direct main"
    description:
      name: drift
      url: "https://pub.dev"
    source: hosted
    version: "2.35.2"
  meta:
    dependency: transitive
    description:
      name: meta
      url: "https://pub.dev"
    source: hosted
    version: "1.17.0"
  flutter:
    dependency: "direct main"
    description: flutter
    source: sdk
    version: "0.0.0"
  prayer_engine:
    dependency: "direct main"
    description:
      path: "packages/prayer_engine"
      relative: true
    source: path
    version: "0.1.0"
sdks:
  dart: ">=3.13.5 <4.0.0"
''';

const _mitText = 'Permission is hereby granted, free of charge, to any person';

void main() {
  group('parsePubspecLock', () {
    test('reads names, sources and direct flags', () {
      final packages = parsePubspecLock(_lock);
      expect(packages.map((p) => p.name), [
        'drift',
        'flutter',
        'meta',
        'prayer_engine',
      ]);
      final drift = packages.firstWhere((p) => p.name == 'drift');
      expect(drift.isDirect, isTrue);
      expect(drift.source, 'hosted');
      expect(packages.firstWhere((p) => p.name == 'meta').isDirect, isFalse);
    });
  });

  group('checkPackageLicenses', () {
    final packages = parsePubspecLock(_lock);

    test('passes when every hosted package has an allowed license', () {
      final findings = checkPackageLicenses(packages, {
        'drift': _mitText,
        'meta': _mitText,
      });
      expect(findings, isEmpty);
    });

    test('fails on a missing LICENSE file', () {
      final findings = checkPackageLicenses(packages, {
        'drift': _mitText,
        'meta': null,
      });
      expect(findings.single.subject, 'meta');
    });

    test('fails on a forbidden license', () {
      final findings = checkPackageLicenses(packages, {
        'drift': 'GNU GENERAL PUBLIC LICENSE Version 3',
        'meta': _mitText,
      });
      expect(findings.single.subject, 'drift');
      expect(findings.single.message, contains('forbidden'));
    });

    test('fails on an unknown license', () {
      final findings = checkPackageLicenses(packages, {
        'drift': 'All rights reserved.',
        'meta': _mitText,
      });
      expect(findings.single.message, contains('unknown'));
    });

    test('does not check sdk or path packages', () {
      final findings = checkPackageLicenses(packages, {
        'drift': _mitText,
        'meta': _mitText,
      });
      expect(findings.any((f) => f.subject == 'flutter'), isFalse);
      expect(findings.any((f) => f.subject == 'prayer_engine'), isFalse);
    });
  });

  group('directDependencyNames', () {
    test(
      'collects dependencies and dev dependencies, skipping sdk and members',
      () {
        const app = '''
name: app
dependencies:
  flutter:
    sdk: flutter
  drift: ^2.0.0
  prayer_engine: ^0.1.0
dev_dependencies:
  flutter_test:
    sdk: flutter
  lints: ^6.0.0
''';
        expect(directDependencyNames([app], memberNames: {'prayer_engine'}), {
          'drift',
          'lints',
        });
      },
    );
  });

  group('checkDirectDependenciesRegistered', () {
    test('flags a direct dependency missing from the register', () {
      final findings = checkDirectDependenciesRegistered({
        'drift',
        'lints',
      }, '| lints | 6.0 |');
      expect(findings.map((f) => f.subject), ['drift']);
    });

    test('passes when every direct dependency is in the register', () {
      expect(
        checkDirectDependenciesRegistered({'drift'}, '| drift | MIT |'),
        isEmpty,
      );
    });
  });

  group('checkContentRegistered', () {
    const register = '''
| content/audio/tone-short.wav | CC0 |
| Amiri-Regular.ttf | OFL |
| apps/mobile/assets/fonts/* | OFL |
Audio is described under content/audio/ in section 2.
''';

    test('accepts a file listed by path, by name or by a dir/* entry', () {
      final findings = checkContentRegistered([
        'content/audio/tone-short.wav',
        'apps/mobile/assets/fonts/Amiri-Regular.ttf',
        'apps/mobile/assets/fonts/NotoSans.ttf',
      ], register);
      expect(findings, isEmpty);
    });

    test('flags an unregistered file', () {
      final findings = checkContentRegistered([
        'content/audio/mystery.mp3',
      ], register);
      expect(findings.single.subject, 'content/audio/mystery.mp3');
    });

    test('skips ignored prefixes', () {
      final findings = checkContentRegistered(
        ['content/LICENSES.md'],
        register,
        ignoredPrefixes: {'content/LICENSES.md'},
      );
      expect(findings, isEmpty);
    });
  });

  group('checkAndroidManifest', () {
    test('flags INTERNET and other forbidden permissions', () {
      const xml = '''
<manifest>
  <uses-permission android:name="android.permission.INTERNET"/>
  <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
  <uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
</manifest>''';
      final findings = checkAndroidManifest(xml);
      expect(
        findings.map((f) => f.message),
        contains(contains('android.permission.INTERNET')),
      );
      expect(
        findings.map((f) => f.message),
        contains(contains('USE_EXACT_ALARM')),
      );
      expect(findings.length, 2);
    });

    test('passes a manifest with only allowed permissions', () {
      const xml = '''
<manifest>
  <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
  <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
</manifest>''';
      expect(checkAndroidManifest(xml), isEmpty);
    });
  });

  group('checkIosPlist', () {
    test('flags tracking and relaxed network keys', () {
      const plist = '''
<dict>
  <key>NSAppTransportSecurity</key>
  <dict><key>NSAllowsArbitraryLoads</key><true/></dict>
</dict>''';
      expect(
        checkIosPlist(plist).single.message,
        contains('NSAllowsArbitraryLoads'),
      );
    });
  });

  group('checkDenylist', () {
    const denylist = '''
# trackers
firebase_*
sentry_flutter
google_mobile_ads
''';

    test('matches exact names and prefixes', () {
      final findings = checkDenylist([
        'firebase_core',
        'sentry_flutter',
        'drift',
        'firebase',
      ], denylist);
      expect(findings.map((f) => f.subject), [
        'firebase_core',
        'sentry_flutter',
      ]);
    });
  });

  group('checkGradleReport', () {
    test('flags Play Services and Firebase coordinates once each', () {
      const report = '''
+--- androidx.core:core:1.13.0
+--- com.google.android.gms:play-services-location:21.2.0
|    \\--- com.google.android.gms:play-services-base:18.0.0
+--- com.google.android.gms:play-services-location:21.2.0 (*)
\\--- com.google.firebase:firebase-messaging:24.0.0
''';
      final findings = checkGradleReport(report);
      expect(findings.map((f) => f.subject), [
        'com.google.android.gms:play-services-location:21.2.0',
        'com.google.android.gms:play-services-base:18.0.0',
        'com.google.firebase:firebase-messaging:24.0.0',
      ]);
    });

    test('passes a clean report', () {
      expect(checkGradleReport('+--- androidx.core:core:1.13.0'), isEmpty);
    });
  });
}

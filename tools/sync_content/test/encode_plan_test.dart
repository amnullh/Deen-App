import 'dart:typed_data';

import 'package:sync_content/encode_plan.dart';
import 'package:sync_content/tone_synth.dart';
import 'package:test/test.dart';

void main() {
  group('parseEncodeArgs', () {
    test('uses defaults', () {
      final o = parseEncodeArgs([]);
      expect(o.inputDir, 'content/audio/master');
      expect(o.androidDir, 'content/audio/android');
      expect(o.iosDir, 'content/audio/ios');
      expect(o.platforms, {EncodeTarget.android, EncodeTarget.ios});
      expect(o.androidCodec, AndroidCodec.vorbis);
      expect(o.iosMaxSeconds, 28);
      expect(o.dryRun, isFalse);
      expect(o.only, isNull);
    });

    test('reads every option', () {
      final o = parseEncodeArgs([
        '--input',
        'in',
        '--android-out',
        'a',
        '--ios-out',
        'i',
        '--platform',
        'ios',
        '--android-codec',
        'opus',
        '--max-seconds',
        '20.5',
        '--only',
        'voice1-fajr',
        '--dry-run',
      ]);
      expect(o.inputDir, 'in');
      expect(o.androidDir, 'a');
      expect(o.iosDir, 'i');
      expect(o.platforms, {EncodeTarget.ios});
      expect(o.androidCodec, AndroidCodec.opus);
      expect(o.iosMaxSeconds, 20.5);
      expect(o.only, 'voice1-fajr');
      expect(o.dryRun, isTrue);
    });

    test('rejects unknown flags, bad values and unknown names', () {
      expect(() => parseEncodeArgs(['--bogus']), throwsFormatException);
      expect(
        () => parseEncodeArgs(['--platform', 'web']),
        throwsFormatException,
      );
      expect(
        () => parseEncodeArgs(['--android-codec', 'mp3']),
        throwsFormatException,
      );
      expect(() => parseEncodeArgs(['--input']), throwsFormatException);
      expect(() => parseEncodeArgs(['--only', 'nope']), throwsFormatException);
    });

    test('refuses a clip limit that is not under the iOS 30 second rule', () {
      expect(
        () => parseEncodeArgs(['--max-seconds', '30']),
        throwsFormatException,
      );
      expect(
        () => parseEncodeArgs(['--max-seconds', '0']),
        throwsFormatException,
      );
      expect(
        () => parseEncodeArgs(['--max-seconds', 'abc']),
        throwsFormatException,
      );
    });
  });

  group('azaanNames', () {
    test(
      'are the six recordings: two voices, each standard, Fajr and Shia',
      () {
        expect(azaanNames, hasLength(6));
        expect(azaanNames.toSet(), hasLength(6));
        expect(
          azaanNames,
          containsAll(['voice1-standard', 'voice1-fajr', 'voice2-shia']),
        );
      },
    );
  });

  group('findMasters', () {
    test('matches a name to a file with any supported extension', () {
      final found = findMasters(azaanNames, [
        'voice1-standard.wav',
        'voice1-fajr.FLAC',
        'voice1-shia.m4a',
        'notes.txt',
      ]);
      expect(found.masters['voice1-standard'], 'voice1-standard.wav');
      expect(found.masters['voice1-fajr'], 'voice1-fajr.FLAC');
      expect(found.masters.containsKey('notes'), isFalse);
      expect(found.missing, ['voice2-standard', 'voice2-fajr', 'voice2-shia']);
    });

    test('reports an ambiguous master', () {
      final found = findMasters(
        ['voice1-fajr'],
        ['voice1-fajr.wav', 'voice1-fajr.flac'],
      );
      expect(found.ambiguous, ['voice1-fajr']);
      expect(found.masters, isEmpty);
    });
  });

  group('planEncodeJobs', () {
    const masters = {'voice1-fajr': 'voice1-fajr.wav'};

    test('Android Ogg Vorbis uses ffmpeg and a res/raw safe file name', () {
      final jobs = planEncodeJobs(
        parseEncodeArgs(['--platform', 'android']),
        masters,
        tempDir: '/tmp/x',
      );
      expect(jobs, hasLength(1));
      final job = jobs.single;
      expect(job.platform, EncodeTarget.android);
      expect(job.outputPath, 'content/audio/android/voice1_fajr.ogg');
      expect(job.steps, hasLength(1));
      final step = job.steps.single;
      expect(step.tool, 'ffmpeg');
      expect(
        step.args,
        containsAllInOrder(['-i', 'content/audio/master/voice1-fajr.wav']),
      );
      expect(step.args, containsAllInOrder(['-c:a', 'libvorbis']));
      expect(step.args, contains('-vn'));
      expect(step.args.last, 'content/audio/android/voice1_fajr.ogg');
    });

    test('Android Opus uses libopus in an Ogg container', () {
      final job = planEncodeJobs(
        parseEncodeArgs(['--platform', 'android', '--android-codec', 'opus']),
        masters,
        tempDir: '/tmp/x',
      ).single;
      expect(job.steps.single.args, containsAllInOrder(['-c:a', 'libopus']));
      expect(job.outputPath, endsWith('.ogg'));
    });

    test('iOS trims with ffmpeg then converts to IMA4 CAF with afconvert', () {
      final job = planEncodeJobs(
        parseEncodeArgs(['--platform', 'ios', '--max-seconds', '25']),
        masters,
        tempDir: '/tmp/x',
      ).single;
      expect(job.platform, EncodeTarget.ios);
      expect(job.outputPath, 'content/audio/ios/voice1-fajr.caf');
      expect(job.steps.map((s) => s.tool), ['ffmpeg', 'afconvert']);
      final trim = job.steps.first;
      expect(trim.args, containsAllInOrder(['-t', '25']));
      expect(trim.args.last, '/tmp/x/voice1-fajr.wav');
      final convert = job.steps.last;
      expect(convert.args, containsAllInOrder(['-f', 'caff', '-d', 'ima4']));
      expect(
        convert.args,
        containsAllInOrder([
          '/tmp/x/voice1-fajr.wav',
          'content/audio/ios/voice1-fajr.caf',
        ]),
      );
    });

    test('plans both platforms for every master, in a fixed order', () {
      final jobs = planEncodeJobs(parseEncodeArgs([]), {
        'voice1-fajr': 'a.wav',
        'voice1-shia': 'b.wav',
      }, tempDir: '/tmp/x');
      expect(jobs.map((j) => '${j.platform.name}:${j.name}'), [
        'android:voice1-fajr',
        'ios:voice1-fajr',
        'android:voice1-shia',
        'ios:voice1-shia',
      ]);
    });

    test('--only limits the plan to one recording', () {
      final jobs = planEncodeJobs(parseEncodeArgs(['--only', 'voice1-shia']), {
        'voice1-fajr': 'a.wav',
        'voice1-shia': 'b.wav',
      }, tempDir: '/tmp/x');
      expect(jobs.map((j) => j.name).toSet(), {'voice1-shia'});
    });
  });

  group('requiredTools and messages', () {
    test('lists the tools the plan needs', () {
      final android = planEncodeJobs(
        parseEncodeArgs(['--platform', 'android']),
        {'voice1-fajr': 'a.wav'},
        tempDir: '/t',
      );
      expect(requiredTools(android), {'ffmpeg'});
      final both = planEncodeJobs(parseEncodeArgs([]), {
        'voice1-fajr': 'a.wav',
      }, tempDir: '/t');
      expect(requiredTools(both), {'ffmpeg', 'afconvert'});
    });

    test('lists the ffmpeg encoders the plan needs', () {
      final vorbis = planEncodeJobs(parseEncodeArgs([]), {
        'voice1-fajr': 'a.wav',
      }, tempDir: '/t');
      expect(requiredEncoders(vorbis), {'libvorbis'});
      final opus = planEncodeJobs(
        parseEncodeArgs(['--android-codec', 'opus']),
        {'voice1-fajr': 'a.wav'},
        tempDir: '/t',
      );
      expect(requiredEncoders(opus), {'libopus'});
      expect(
        missingEncoderMessage('libvorbis'),
        contains('--android-codec opus'),
      );
    });

    test('explains how to get a missing tool', () {
      expect(missingToolMessage('ffmpeg'), contains('ffmpeg'));
      expect(missingToolMessage('ffmpeg'), contains('install'));
      final afconvert = missingToolMessage('afconvert');
      expect(afconvert, contains('macOS'));
      expect(afconvert, contains('encode_audio.md'));
    });
  });

  group('verification', () {
    test('accepts an iOS clip with a safety margin', () {
      final wav = synthAlertTone();
      expect(verifyIosClip(wav, maxSeconds: 28), isNull);
    });

    test('rejects a clip over the limit, or an unreadable one', () {
      final longWav = encodeWav16(
        Int16List(toneSampleRate * 29),
        toneSampleRate,
      );
      expect(verifyIosClip(longWav, maxSeconds: 28), contains('29.0'));
      expect(
        verifyIosClip(Uint8List.fromList([1, 2, 3]), maxSeconds: 28),
        contains('cannot read'),
      );
    });

    test('checks that an Android file is an Ogg stream', () {
      final ogg = Uint8List.fromList([0x4f, 0x67, 0x67, 0x53, 0, 2, 0, 0, 0]);
      expect(verifyAndroidFile(ogg), isNull);
      expect(verifyAndroidFile(Uint8List(0)), contains('empty'));
      expect(
        verifyAndroidFile(Uint8List.fromList([1, 2, 3, 4, 5])),
        contains('Ogg'),
      );
    });
  });
}

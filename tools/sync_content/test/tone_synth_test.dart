import 'dart:convert';
import 'dart:typed_data';

import 'package:sync_content/audio_duration.dart';
import 'package:sync_content/tone_synth.dart';
import 'package:test/test.dart';

/// Reads the 16-bit samples back out of a mono WAV produced by the generator.
Int16List _samples(Uint8List wav) {
  final data = ByteData.sublistView(wav);
  final count = data.getUint32(40, Endian.little) ~/ 2;
  return Int16List.fromList([
    for (var i = 0; i < count; i++) data.getInt16(44 + i * 2, Endian.little),
  ]);
}

int _peak(Int16List samples) =>
    samples.fold<int>(0, (m, s) => s.abs() > m ? s.abs() : m);

void main() {
  group('encodeWav16', () {
    test('writes a canonical 44-byte PCM header', () {
      final wav = encodeWav16(Int16List.fromList([0, 1000, -1000, 5]), 22050);
      final data = ByteData.sublistView(wav);
      expect(latin1.decode(wav.sublist(0, 4)), 'RIFF');
      expect(data.getUint32(4, Endian.little), wav.length - 8);
      expect(latin1.decode(wav.sublist(8, 12)), 'WAVE');
      expect(latin1.decode(wav.sublist(12, 16)), 'fmt ');
      expect(data.getUint32(16, Endian.little), 16);
      expect(data.getUint16(20, Endian.little), 1, reason: 'PCM');
      expect(data.getUint16(22, Endian.little), 1, reason: 'mono');
      expect(data.getUint32(24, Endian.little), 22050);
      expect(data.getUint32(28, Endian.little), 44100, reason: 'byte rate');
      expect(data.getUint16(32, Endian.little), 2, reason: 'block align');
      expect(data.getUint16(34, Endian.little), 16);
      expect(latin1.decode(wav.sublist(36, 40)), 'data');
      expect(data.getUint32(40, Endian.little), 8);
      expect(wav.length, 44 + 8);
      expect(data.getInt16(46, Endian.little), 1000);
      expect(data.getInt16(48, Endian.little), -1000);
    });
  });

  group('alert tone', () {
    final wav = synthAlertTone();
    final samples = _samples(wav);

    test('is about 1.2 seconds long', () {
      expect(audioDurationSeconds(wav), closeTo(1.2, 0.05));
      expect(samples.length, (toneSampleRate * 1.2).round());
    });

    test('is audible but stays well below full scale', () {
      expect(_peak(samples), greaterThan(8000));
      expect(_peak(samples), lessThan(24000));
    });

    test('starts and ends at silence, with no click', () {
      expect(samples.first.abs(), lessThan(50));
      expect(samples.last.abs(), lessThan(50));
    });

    test('contains two separate notes', () {
      // Energy in the first and second half-second windows is both present.
      int energy(int from, int to) =>
          samples.sublist(from, to).fold<int>(0, (sum, s) => sum + s.abs());
      final sr = toneSampleRate;
      expect(energy(0, sr ~/ 4), greaterThan(0));
      expect(energy((sr * 0.7).round(), (sr * 0.9).round()), greaterThan(0));
    });

    test('is deterministic', () {
      expect(synthAlertTone(), orderedEquals(wav));
    });
  });

  group('tasbih tick', () {
    final wav = synthTasbihTick();
    final samples = _samples(wav);

    test('is about 60 milliseconds long', () {
      expect(audioDurationSeconds(wav), closeTo(0.060, 0.005));
    });

    test('is soft: peak well below full scale but not silent', () {
      expect(_peak(samples), greaterThan(3000));
      expect(_peak(samples), lessThan(16000));
    });

    test('starts and ends at silence', () {
      expect(samples.first.abs(), lessThan(50));
      expect(samples.last.abs(), lessThan(50));
    });

    test('is deterministic', () {
      expect(synthTasbihTick(), orderedEquals(wav));
    });
  });
}

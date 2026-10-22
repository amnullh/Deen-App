/// Synthesises the two short project-created sounds as 16-bit PCM WAV.
///
/// The sounds are plain sine partials with a smooth envelope, written by this
/// file, so they carry no third-party rights (dedicated to the public domain,
/// CC0). The output depends only on the constants below: running the
/// generator twice gives the same bytes on the same platform.
library;

import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

/// Sample rate of both sounds, in hertz.
const int toneSampleRate = 44100;

/// Wraps mono 16-bit [samples] in a canonical 44-byte-header WAV file.
Uint8List encodeWav16(Int16List samples, int sampleRate) {
  final dataBytes = samples.length * 2;
  final out = Uint8List(44 + dataBytes);
  final data = ByteData.sublistView(out);
  out.setRange(0, 4, latin1.encode('RIFF'));
  data.setUint32(4, 36 + dataBytes, Endian.little);
  out.setRange(8, 12, latin1.encode('WAVE'));
  out.setRange(12, 16, latin1.encode('fmt '));
  data.setUint32(16, 16, Endian.little);
  data.setUint16(20, 1, Endian.little); // linear PCM
  data.setUint16(22, 1, Endian.little); // mono
  data.setUint32(24, sampleRate, Endian.little);
  data.setUint32(28, sampleRate * 2, Endian.little); // byte rate
  data.setUint16(32, 2, Endian.little); // block align
  data.setUint16(34, 16, Endian.little); // bits per sample
  out.setRange(36, 40, latin1.encode('data'));
  data.setUint32(40, dataBytes, Endian.little);
  for (var i = 0; i < samples.length; i++) {
    data.setInt16(44 + i * 2, samples[i], Endian.little);
  }
  return out;
}

/// One decaying bell-like note added into [mix] starting at [startSeconds].
///
/// Envelope: a raised-cosine attack of [attackSeconds], an exponential decay
/// with rate [decayPerSecond], and a raised-cosine release over the last
/// [releaseSeconds] of the note, so the note starts and ends at zero.
void _addNote(
  Float64List mix, {
  required double startSeconds,
  required double durationSeconds,
  required double frequency,
  required double attackSeconds,
  required double decayPerSecond,
  required double releaseSeconds,
  List<double> partials = const [1.0, 0.25, 0.08],
}) {
  final first = (startSeconds * toneSampleRate).round();
  final count = (durationSeconds * toneSampleRate).round();
  for (var i = 0; i < count && first + i < mix.length; i++) {
    final t = i / toneSampleRate;
    var envelope = math.exp(-decayPerSecond * t);
    if (t < attackSeconds) {
      envelope *= 0.5 - 0.5 * math.cos(math.pi * t / attackSeconds);
    }
    final untilEnd = durationSeconds - t;
    if (untilEnd < releaseSeconds) {
      envelope *= 0.5 - 0.5 * math.cos(math.pi * untilEnd / releaseSeconds);
    }
    var value = 0.0;
    for (var k = 0; k < partials.length; k++) {
      value += partials[k] * math.sin(2 * math.pi * frequency * (k + 1) * t);
    }
    mix[first + i] += value * envelope;
  }
}

/// Scales [mix] so its largest sample is [peak] of full scale, and rounds.
Int16List _normalise(Float64List mix, double peak) {
  var largest = 0.0;
  for (final v in mix) {
    if (v.abs() > largest) largest = v.abs();
  }
  final scale = largest == 0 ? 0.0 : peak * 32767 / largest;
  return Int16List.fromList([for (final v in mix) (v * scale).round()]);
}

/// A gentle two-note alert (E5 then A5, a rising fourth), 1.2 s, peak about
/// 45 percent of full scale. Soft 15 ms attack, smooth decay, no clipping.
Uint8List synthAlertTone() {
  final mix = Float64List((toneSampleRate * 1.2).round());
  _addNote(
    mix,
    startSeconds: 0,
    durationSeconds: 0.75,
    frequency: 659.26,
    attackSeconds: 0.015,
    decayPerSecond: 3.5,
    releaseSeconds: 0.08,
  );
  _addNote(
    mix,
    startSeconds: 0.4,
    durationSeconds: 0.8,
    frequency: 880.0,
    attackSeconds: 0.015,
    decayPerSecond: 3.5,
    releaseSeconds: 0.12,
  );
  return encodeWav16(_normalise(mix, 0.45), toneSampleRate);
}

/// A very short soft tick for the tasbih counter: 60 ms, peak about 30
/// percent of full scale, 1.5 ms attack, fast decay.
Uint8List synthTasbihTick() {
  final mix = Float64List((toneSampleRate * 0.06).round());
  _addNote(
    mix,
    startSeconds: 0,
    durationSeconds: 0.06,
    frequency: 1800.0,
    attackSeconds: 0.0015,
    decayPerSecond: 90,
    releaseSeconds: 0.01,
    partials: const [1.0, 0.3],
  );
  return encodeWav16(_normalise(mix, 0.3), toneSampleRate);
}

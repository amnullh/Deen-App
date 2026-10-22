import 'dart:convert';
import 'dart:typed_data';

import 'package:sync_content/audio_duration.dart';
import 'package:test/test.dart';

Uint8List _wav({required int sampleRate, required int dataBytes}) {
  final b = BytesBuilder();
  void u32(int v) =>
      b.add((ByteData(4)..setUint32(0, v, Endian.little)).buffer.asUint8List());
  void u16(int v) =>
      b.add((ByteData(2)..setUint16(0, v, Endian.little)).buffer.asUint8List());
  b.add(latin1.encode('RIFF'));
  u32(36 + dataBytes);
  b.add(latin1.encode('WAVE'));
  b.add(latin1.encode('fmt '));
  u32(16);
  u16(1); // PCM
  u16(1); // mono
  u32(sampleRate);
  u32(sampleRate * 2); // byte rate, 16-bit mono
  u16(2);
  u16(16);
  b.add(latin1.encode('data'));
  u32(dataBytes);
  b.add(Uint8List(dataBytes));
  return b.toBytes();
}

Uint8List _caf({
  required double sampleRate,
  required int validFrames,
  int bytesPerPacket = 34,
  int framesPerPacket = 64,
}) {
  final b = BytesBuilder();
  void be32(int v) =>
      b.add((ByteData(4)..setUint32(0, v, Endian.big)).buffer.asUint8List());
  void be64(int v) =>
      b.add((ByteData(8)..setInt64(0, v, Endian.big)).buffer.asUint8List());
  void f64(double v) =>
      b.add((ByteData(8)..setFloat64(0, v, Endian.big)).buffer.asUint8List());
  b.add(latin1.encode('caff'));
  b.add([0, 1, 0, 0]);
  b.add(latin1.encode('desc'));
  be64(32);
  f64(sampleRate);
  b.add(latin1.encode('ima4'));
  be32(0);
  be32(bytesPerPacket);
  be32(framesPerPacket);
  be32(1);
  be32(0);
  b.add(latin1.encode('pakt'));
  be64(24);
  be64(0); // packets
  be64(validFrames);
  be32(0);
  be32(0);
  return b.toBytes();
}

void main() {
  test('reads WAV duration from the byte rate', () {
    final bytes = _wav(sampleRate: 8000, dataBytes: 16000 * 12); // 12 s
    expect(audioDurationSeconds(bytes), closeTo(12, 1e-9));
  });

  test('reads CAF duration from the packet table', () {
    final bytes = _caf(sampleRate: 44100, validFrames: 44100 * 25);
    expect(audioDurationSeconds(bytes), closeTo(25, 1e-9));
  });

  test('returns null for unknown formats and truncated data', () {
    expect(
      audioDurationSeconds(Uint8List.fromList(latin1.encode('OggS0000000000'))),
      isNull,
    );
    expect(audioDurationSeconds(Uint8List(4)), isNull);
  });

  test('the limit constant is 30 seconds', () {
    expect(iosNotificationSoundLimitSeconds, 30);
  });
}

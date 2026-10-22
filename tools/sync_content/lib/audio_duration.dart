/// Reads the duration of an uncompressed or IMA4 audio file header.
///
/// iOS plays a custom notification sound only when it is shorter than 30
/// seconds; a longer file silently falls back to the default sound. CI uses
/// this to reject clips that are too long (research R-I3).
library;

import 'dart:convert';
import 'dart:typed_data';

/// Longest notification sound iOS plays, in seconds (exclusive).
const double iosNotificationSoundLimitSeconds = 30;

/// Duration in seconds of WAV, AIFF or CAF audio bytes, or null when the
/// format is not recognised or the header is incomplete.
double? audioDurationSeconds(Uint8List bytes) {
  if (bytes.length < 12) return null;
  final magic = latin1.decode(bytes.sublist(0, 4));
  switch (magic) {
    case 'RIFF':
      return _wavDuration(bytes);
    case 'FORM':
      return _aiffDuration(bytes);
    case 'caff':
      return _cafDuration(bytes);
    default:
      return null;
  }
}

double? _wavDuration(Uint8List bytes) {
  final data = ByteData.sublistView(bytes);
  if (latin1.decode(bytes.sublist(8, 12)) != 'WAVE') return null;
  int? byteRate;
  var offset = 12;
  while (offset + 8 <= bytes.length) {
    final id = latin1.decode(bytes.sublist(offset, offset + 4));
    final size = data.getUint32(offset + 4, Endian.little);
    final body = offset + 8;
    if (id == 'fmt ' && body + 12 <= bytes.length) {
      byteRate = data.getUint32(body + 8, Endian.little);
    } else if (id == 'data') {
      if (byteRate == null || byteRate == 0) return null;
      return size / byteRate;
    }
    offset = body + size + (size.isOdd ? 1 : 0);
  }
  return null;
}

double? _aiffDuration(Uint8List bytes) {
  final data = ByteData.sublistView(bytes);
  double? sampleRate;
  int? frames;
  var offset = 12;
  while (offset + 8 <= bytes.length) {
    final id = latin1.decode(bytes.sublist(offset, offset + 4));
    final size = data.getUint32(offset + 4, Endian.big);
    final body = offset + 8;
    if (id == 'COMM' && body + 18 <= bytes.length) {
      frames = data.getUint32(body + 2, Endian.big);
      sampleRate = _readExtended80(data, body + 8);
    }
    offset = body + size + (size.isOdd ? 1 : 0);
  }
  if (frames == null || sampleRate == null || sampleRate <= 0) return null;
  return frames / sampleRate;
}

/// Reads an 80-bit IEEE extended float (used for the AIFF sample rate).
double _readExtended80(ByteData data, int offset) {
  final exponent = data.getUint16(offset, Endian.big) & 0x7fff;
  final high = data.getUint32(offset + 2, Endian.big);
  final low = data.getUint32(offset + 6, Endian.big);
  if (exponent == 0 && high == 0 && low == 0) return 0;
  final mantissa = high * 4294967296.0 + low;
  final shift = exponent - 16383 - 63;
  var value = mantissa;
  if (shift > 0) {
    for (var i = 0; i < shift; i++) {
      value *= 2;
    }
  } else {
    for (var i = 0; i < -shift; i++) {
      value /= 2;
    }
  }
  return value;
}

double? _cafDuration(Uint8List bytes) {
  final data = ByteData.sublistView(bytes);
  double? sampleRate;
  int? validFrames;
  int? bytesPerPacket;
  int? framesPerPacket;
  int? dataBytes;
  var offset = 8;
  while (offset + 12 <= bytes.length) {
    final id = latin1.decode(bytes.sublist(offset, offset + 4));
    final size = data.getInt64(offset + 4, Endian.big);
    final body = offset + 12;
    if (id == 'desc' && body + 32 <= bytes.length) {
      sampleRate = data.getFloat64(body, Endian.big);
      bytesPerPacket = data.getUint32(body + 12, Endian.big);
      framesPerPacket = data.getUint32(body + 16, Endian.big);
    } else if (id == 'pakt' && body + 24 <= bytes.length) {
      validFrames = data.getInt64(body + 8, Endian.big);
    } else if (id == 'data') {
      // A size of -1 means "to the end of the file".
      dataBytes = size < 0 ? bytes.length - body : size - 4;
    }
    if (size < 0) break;
    offset = body + size;
  }
  if (sampleRate == null || sampleRate <= 0) return null;
  if (validFrames != null && validFrames > 0) {
    return validFrames / sampleRate;
  }
  if (dataBytes != null &&
      bytesPerPacket != null &&
      framesPerPacket != null &&
      bytesPerPacket > 0) {
    return (dataBytes / bytesPerPacket) * framesPerPacket / sampleRate;
  }
  return null;
}

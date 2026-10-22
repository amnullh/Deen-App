/// Decides where each content file is copied.
///
/// Source layout under `content/`:
///   audio/android/*   Android recordings and the fallback channel sound
///   audio/ios/*       iOS notification clips (each under 30 seconds)
///   audio/shared/*    previews and tones played by Dart code
///   cities/cities.db  offline city database
///   adhkar/pack/*     built adhkar pack (JSON)
library;

/// One file to copy.
class CopyAction {
  const CopyAction(this.source, this.destination);

  /// Repo-relative POSIX path of the source.
  final String source;

  /// Repo-relative POSIX path of the destination.
  final String destination;

  @override
  bool operator ==(Object other) =>
      other is CopyAction &&
      other.source == source &&
      other.destination == destination;

  @override
  int get hashCode => Object.hash(source, destination);

  @override
  String toString() => '$source -> $destination';
}

const String androidRawDir = 'apps/mobile/android/app/src/main/res/raw';
const String iosSoundsDir = 'apps/mobile/ios/Runner/Sounds';
const String assetsDir = 'apps/mobile/assets';

/// Returns the copy action for [source], or null when the file is not synced
/// (the register, notes, review records).
CopyAction? planCopy(String source) {
  final parts = source.split('/');
  if (parts.length < 3 || parts.first != 'content') return null;
  final name = parts.last;
  if (source.startsWith('content/audio/android/')) {
    return CopyAction(source, '$androidRawDir/${androidResourceName(name)}');
  }
  if (source.startsWith('content/audio/ios/')) {
    return CopyAction(source, '$iosSoundsDir/$name');
  }
  if (source.startsWith('content/audio/shared/')) {
    return CopyAction(source, '$assetsDir/audio/$name');
  }
  if (source == 'content/cities/cities.db') {
    return CopyAction(source, '$assetsDir/cities/cities.db');
  }
  if (source.startsWith('content/adhkar/pack/') && name.endsWith('.json')) {
    return CopyAction(source, '$assetsDir/adhkar/$name');
  }
  return null;
}

/// Android raw resource names allow only lower-case letters, digits and
/// underscores. Converts `Voice-1 Fajr.ogg` to `voice_1_fajr.ogg`.
String androidResourceName(String fileName) {
  final dot = fileName.lastIndexOf('.');
  final stem = dot == -1 ? fileName : fileName.substring(0, dot);
  final extension = dot == -1 ? '' : fileName.substring(dot).toLowerCase();
  var cleaned = stem.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]+'), '_');
  cleaned = cleaned
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
  if (cleaned.isEmpty || RegExp(r'^[0-9]').hasMatch(cleaned)) {
    cleaned = 'r_$cleaned';
  }
  return '$cleaned$extension';
}

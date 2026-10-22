/// Builds the `LICENSES/NOTICE` file (constitution principle 10).
///
/// The notice lists every third-party package with its detected license and
/// repeats the content register (sources, licenses and attributions for audio,
/// text, datasets and fonts). The full text of each package license is shown in
/// the app's About screen through Flutter's license registry.
library;

import 'license_detector.dart';
import 'scanner.dart';

/// One package and its detected licenses.
class NoticePackage {
  const NoticePackage(this.name, this.version, this.licenses);

  final String name;
  final String version;
  final Set<String> licenses;
}

/// Pairs each hosted package with the licenses found in its LICENSE file.
List<NoticePackage> noticePackages(
  List<LockedPackage> packages,
  String? Function(LockedPackage package) readLicense,
) {
  final result = <NoticePackage>[];
  for (final package in packages) {
    if (package.source != 'hosted') continue;
    final text = readLicense(package);
    result.add(
      NoticePackage(
        package.name,
        package.version,
        text == null ? const {} : detectLicenses(text),
      ),
    );
  }
  return result;
}

/// The notice text. [generatedOn] is passed in so the output is reproducible.
String buildNotice({
  required List<NoticePackage> packages,
  required String registerText,
  required String generatedOn,
}) {
  final buffer = StringBuffer()
    ..writeln('Deen App: third-party notices')
    ..writeln('=============================')
    ..writeln()
    ..writeln(
      'Deen App is licensed under the Apache License 2.0 (see LICENSE).',
    )
    ..writeln(
      'This file lists the third-party software and content it includes.',
    )
    ..writeln(
      'Generated on $generatedOn by tools/license_scan/bin/notice.dart;',
    )
    ..writeln('do not edit by hand. The full license text of each package is')
    ..writeln('available in the app under About > Open-source licenses.')
    ..writeln()
    ..writeln('Software packages (${packages.length})')
    ..writeln('--------------------');
  for (final package in packages) {
    final licenses = package.licenses.isEmpty
        ? 'UNKNOWN'
        : (package.licenses.toList()..sort()).join(' AND ');
    buffer.writeln('${package.name} ${package.version}: $licenses');
  }
  buffer
    ..writeln()
    ..writeln('Content register')
    ..writeln('----------------')
    ..writeln(registerText.trim());
  return '${buffer.toString().trimRight()}\n';
}

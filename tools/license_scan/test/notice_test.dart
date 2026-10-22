import 'package:license_scan/notice.dart';
import 'package:license_scan/scanner.dart';
import 'package:test/test.dart';

void main() {
  const mit = 'Permission is hereby granted, free of charge, to any person';

  test('lists hosted packages with their licenses and skips others', () {
    final packages = [
      const LockedPackage(
        name: 'drift',
        version: '2.35.2',
        source: 'hosted',
        isDirect: true,
      ),
      const LockedPackage(
        name: 'flutter',
        version: '0.0.0',
        source: 'sdk',
        isDirect: true,
      ),
      const LockedPackage(
        name: 'nolicense',
        version: '1.0.0',
        source: 'hosted',
        isDirect: false,
      ),
    ];
    final result = noticePackages(
      packages,
      (package) => package.name == 'drift' ? mit : null,
    );
    expect(result.map((p) => p.name), ['drift', 'nolicense']);
    expect(result.first.licenses, {'MIT'});
    expect(result.last.licenses, isEmpty);
  });

  test('builds a reproducible notice that includes the register', () {
    final text = buildNotice(
      packages: const [
        NoticePackage('drift', '2.35.2', {'MIT'}),
        NoticePackage('odd', '1.0.0', {}),
      ],
      registerText: '# Register\n| row |',
      generatedOn: 'today',
    );
    expect(text, contains('drift 2.35.2: MIT'));
    expect(text, contains('odd 1.0.0: UNKNOWN'));
    expect(text, contains('Software packages (2)'));
    expect(text, contains('| row |'));
    expect(text.endsWith('\n'), isTrue);
    expect(
      buildNotice(
        packages: const [
          NoticePackage('drift', '2.35.2', {'MIT'}),
        ],
        registerText: 'r',
        generatedOn: 'today',
      ),
      buildNotice(
        packages: const [
          NoticePackage('drift', '2.35.2', {'MIT'}),
        ],
        registerText: 'r',
        generatedOn: 'today',
      ),
    );
  });
}

import 'package:license_scan/license_detector.dart';
import 'package:test/test.dart';

const _mit = '''
MIT License

Copyright (c) 2020 Someone

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction.
''';

const _bsd3 = '''
Copyright 2014 The Flutter Authors. All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above
      copyright notice.
    * Neither the name of Google LLC nor the names of its contributors may be
      used to endorse or promote products derived from this software.
''';

const _bsd2 = '''
Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice.
2. Redistributions in binary form must reproduce the above copyright notice.
''';

const _apache = '''
                                 Apache License
                           Version 2.0, January 2004
''';

const _gpl = 'GNU GENERAL PUBLIC LICENSE Version 3, 29 June 2007';
const _lgpl = 'GNU LESSER GENERAL PUBLIC LICENSE Version 3';
const _ofl = 'SIL OPEN FONT LICENSE Version 1.1 - 26 February 2007';

void main() {
  group('detectLicenses', () {
    test('recognises MIT', () {
      expect(detectLicenses(_mit), {'MIT'});
    });

    test('recognises BSD-3-Clause without also reporting BSD-2-Clause', () {
      expect(detectLicenses(_bsd3), {'BSD-3-Clause'});
    });

    test('recognises BSD-2-Clause', () {
      expect(detectLicenses(_bsd2), {'BSD-2-Clause'});
    });

    test('recognises Apache-2.0', () {
      expect(detectLicenses(_apache), {'Apache-2.0'});
    });

    test('reports every license in a combined file', () {
      expect(detectLicenses('$_mit\n\n$_apache'), {'MIT', 'Apache-2.0'});
    });

    test('distinguishes GPL from LGPL', () {
      expect(detectLicenses(_gpl), {'GPL'});
      expect(detectLicenses(_lgpl), {'LGPL'});
    });

    test('does not treat the MPL-2.0 Secondary Licenses sentence as GPL', () {
      const mpl = '''
Mozilla Public License Version 2.0
1.12. "Secondary License"
    means either the GNU General Public License, Version 2.0, the GNU Lesser
    General Public License, Version 2.1, the GNU Affero General Public
    License, Version 3.0, or any later versions of those licenses.
''';
      expect(detectLicenses(mpl), {'MPL-2.0'});
      expect(judge(detectLicenses(mpl)), LicenseVerdict.allowed);
    });

    test('returns nothing for unrecognised text', () {
      expect(detectLicenses('All rights reserved. Do not copy.'), isEmpty);
    });
  });

  group('judge', () {
    test('allows permissive licenses', () {
      expect(judge({'MIT'}), LicenseVerdict.allowed);
      expect(judge({'MIT', 'Apache-2.0'}), LicenseVerdict.allowed);
      expect(judge({'BSD-3-Clause'}), LicenseVerdict.allowed);
    });

    test('forbids copyleft and source-available licenses', () {
      expect(judge({'GPL'}), LicenseVerdict.forbidden);
      expect(judge({'MIT', 'LGPL'}), LicenseVerdict.forbidden);
      expect(judge({'SSPL'}), LicenseVerdict.forbidden);
    });

    test('treats unrecognised text as unknown, which fails CI', () {
      expect(judge({}), LicenseVerdict.unknown);
    });

    test('allows OFL only for fonts', () {
      expect(detectLicenses(_ofl), {'OFL-1.1'});
      expect(judge({'OFL-1.1'}), LicenseVerdict.unknown);
      expect(judge({'OFL-1.1'}, fontOnly: true), LicenseVerdict.allowed);
    });
  });
}

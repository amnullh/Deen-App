# Contributing

This project follows its [constitution](.specify/memory/constitution.md). Read the principles before opening a
pull request; every change is reviewed against them.

## Pull request rules

- Fill in the pull request template. The reviewer confirms compliance with the constitution's principles.
- Work is test-first for prayer-time calculation, scheduling, fallback logic and the alert arbiter: the failing
  test must be in the same pull request or an earlier one.
- Any change that touches religious content or calculations must include the source citation and test evidence
  in the pull request description.

## Adding a dependency

Every new library, tool or service needs its own pull request (or a clearly separated commit) that records:

1. **License**: the SPDX identifier, read from the package's LICENSE file (not just a registry tag). Allowed for
   code linked into the app: MIT, BSD-2/3, Apache-2.0, ISC, MPL-2.0, Unicode-3.0. SIL OFL 1.1 is allowed for fonts
   only. GPL, AGPL, LGPL, source-available licenses (BUSL, SSPL, RSAL, FSL) and unknown licenses are not allowed.
2. **Maintainer health**: publisher, last release date, open issues, and whether it is actively maintained.
3. **Alternatives considered**: at least one other option and why it was not chosen.
4. **Privacy impact**: confirm it adds no network access, analytics, ads or tracking, and no proprietary Google
   Play Services library.
5. **Register entry**: a row in [content/LICENSES.md](content/LICENSES.md).

CI runs `tools/license_scan` and fails on a disallowed or unknown license.

## Adding content (audio, text, fonts, datasets)

Add the file together with a row in [content/LICENSES.md](content/LICENSES.md): source, license, attribution text,
and for audio and religious text the named scholar reviewer and review date. Do not add content that is not
freely redistributable. CI fails when a file has no register entry.

## Large binary files

Store large binaries (the city database `cities.db`, Azaan recordings) as GitHub release assets or with Git LFS,
not as plain Git objects, once they exceed 5 MB per file or 25 MB in total. Record the chosen location in the
content register row. Until then, files under those limits may be committed normally.

## Amending the constitution

Use the Spec Kit command `/speckit-constitution`. Every amendment needs a written rationale, a version bump (semver)
and a dated entry in the Amendment Changelog section.

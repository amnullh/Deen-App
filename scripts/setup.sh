#!/usr/bin/env bash
# Prepares a developer machine or CI runner: turns off Flutter and Dart tool analytics,
# checks the Flutter version, and resolves the Dart workspace.
set -euo pipefail

REQUIRED_FLUTTER_MAJOR=3
REQUIRED_FLUTTER_MINOR=44

if ! command -v flutter >/dev/null 2>&1; then
  echo "flutter not found on PATH. Install Flutter ${REQUIRED_FLUTTER_MAJOR}.${REQUIRED_FLUTTER_MINOR} or newer." >&2
  exit 1
fi

# Tool telemetry is separate from the app, which collects nothing; keep it off for everyone.
flutter --disable-analytics >/dev/null
dart --disable-analytics >/dev/null

version_line="$(flutter --version --machine 2>/dev/null | grep -m1 '"frameworkVersion"' || true)"
version="$(echo "${version_line}" | sed -E 's/.*"frameworkVersion": *"([0-9]+\.[0-9]+)\..*/\1/')"
major="${version%%.*}"
minor="${version#*.}"

if [[ -z "${version}" || "${major}" -lt "${REQUIRED_FLUTTER_MAJOR}" ||
  ( "${major}" -eq "${REQUIRED_FLUTTER_MAJOR}" && "${minor}" -lt "${REQUIRED_FLUTTER_MINOR}" ) ]]; then
  echo "Flutter ${REQUIRED_FLUTTER_MAJOR}.${REQUIRED_FLUTTER_MINOR} or newer is required (found: ${version:-unknown})." >&2
  exit 1
fi

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${repo_root}"
dart pub get

echo "Setup complete (Flutter ${version})."

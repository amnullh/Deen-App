#!/usr/bin/env python3
"""Lists the license of every Android dependency in a Gradle dependency report.

Reads the POM of each `group:artifact:version` from Google Maven, Maven Central
or Flutter's artifact store and prints a table. Exits 1 when a license is
missing, unknown, or in the forbidden family (GPL, LGPL, AGPL, source-available),
so CI fails before such a library is shipped (constitution principle 10).
Usage: android-licenses.py <gradle-dependencies-report.txt>
"""
import re
import sys
import urllib.error
import urllib.request
import xml.etree.ElementTree as ET

REPOSITORIES = [
    "https://dl.google.com/dl/android/maven2",
    "https://repo.maven.apache.org/maven2",
    "https://storage.googleapis.com/download.flutter.io",
]
ALLOWED = ("apache", "mit license", "bsd", "isc", "mozilla public license", "eclipse public license 1.0", "unicode")
FORBIDDEN = ("gpl", "lgpl", "agpl", "general public license", "sspl", "busl", "business source")
NS = {"m": "http://maven.apache.org/POM/4.0.0"}
# Flutter engine artifacts publish POMs without a license element. The engine is
# licensed BSD-3-Clause, like the Flutter SDK (flutter/flutter LICENSE).
KNOWN_BY_GROUP = {"io.flutter": "BSD-3-Clause (Flutter engine, same license as the Flutter SDK)"}


def fetch_pom(group, artifact, version):
    path = f"{group.replace('.', '/')}/{artifact}/{version}/{artifact}-{version}.pom"
    for base in REPOSITORIES:
        try:
            with urllib.request.urlopen(f"{base}/{path}", timeout=30) as response:
                return ET.fromstring(response.read())
        except (urllib.error.URLError, ET.ParseError):
            continue
    return None


def licenses_of(pom, depth=0):
    names = [e.text.strip() for e in pom.findall(".//m:licenses/m:license/m:name", NS) if e.text]
    if names or depth > 3:
        return names
    parent = pom.find("m:parent", NS)
    if parent is None:
        return []
    values = {t: (parent.find(f"m:{t}", NS).text or "").strip() for t in ("groupId", "artifactId", "version")}
    parent_pom = fetch_pom(values["groupId"], values["artifactId"], values["version"])
    return licenses_of(parent_pom, depth + 1) if parent_pom is not None else []


def main(path):
    text = open(path, encoding="utf-8", errors="replace").read()
    found = {}
    for match in re.finditer(r"([A-Za-z0-9_.-]+):([A-Za-z0-9_.-]+):(?:[A-Za-z0-9_.+-]+ -> )?([0-9][A-Za-z0-9_.+-]*)", text):
        group, artifact, version = match.groups()
        found[(group, artifact, version)] = None
    problems = []
    rows = []
    for (group, artifact, version) in sorted(found):
        pom = fetch_pom(group, artifact, version)
        names = licenses_of(pom) if pom is not None else None
        if group in KNOWN_BY_GROUP and not names:
            names = [KNOWN_BY_GROUP[group]]
        label = "POM NOT FOUND" if names is None else ("NO LICENSE IN POM" if not names else "; ".join(names))
        rows.append(f"{group}:{artifact}:{version} | {label}")
        lowered = label.lower()
        if names is None or not names:
            problems.append(f"{group}:{artifact}:{version}: {label}")
        elif any(word in lowered for word in FORBIDDEN):
            problems.append(f"{group}:{artifact}:{version}: forbidden license {label}")
        elif not any(word in lowered for word in ALLOWED):
            problems.append(f"{group}:{artifact}:{version}: license not on the allowlist: {label}")
    print(f"{len(rows)} Android dependencies")
    print("\n".join(rows))
    # A notice annotation makes the table readable without a login.
    body = "%0A".join(r.replace("%", "%25") for r in rows)[:60000]
    print(f"::notice title=Android dependency licenses ({len(rows)})::{body}")
    for problem in problems:
        print(f"::error title=Android dependency license::{problem}")
    sys.exit(1 if problems else 0)


if __name__ == "__main__":
    main(sys.argv[1])

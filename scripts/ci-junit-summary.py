#!/usr/bin/env python3
"""Prints one GitHub annotation per failed test found in JUnit XML result files.

Usage: ci-junit-summary.py <directory searched recursively for *.xml>
"""
import pathlib
import sys
import xml.etree.ElementTree as ET


def main(root: str) -> None:
    total = failed = 0
    for path in sorted(pathlib.Path(root).rglob("*.xml")):
        try:
            suite = ET.parse(path).getroot()
        except ET.ParseError:
            continue
        for case in suite.iter("testcase"):
            total += 1
            problem = case.find("failure")
            if problem is None:
                problem = case.find("error")
            if problem is None:
                continue
            failed += 1
            text = (problem.get("message") or "") + "\n" + (problem.text or "")
            text = text.replace("%", "%25").replace("\r", "").replace("\n", "%0A")[:1200]
            name = f"{case.get('classname', '')}.{case.get('name', '')}".replace(",", ";").replace(":", "-")
            print(f"::error title=Failed test::{name}%0A{text}")
    print(f"{total} tests found, {failed} failed")


if __name__ == "__main__":
    main(sys.argv[1])

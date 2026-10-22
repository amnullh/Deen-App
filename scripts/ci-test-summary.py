#!/usr/bin/env python3
"""Turns `flutter test --machine` output into one GitHub annotation per failed test.

Annotations are readable on a run's summary page without a login, which plain
logs are not. Usage: ci-test-summary.py <machine-output.json>
"""
import json
import sys


def handle(event, names, errors, failed, counter):
    kind = event.get("type")
    if kind == "testStart":
        names[event["test"]["id"]] = event["test"]["name"]
    elif kind == "error":
        errors.setdefault(event["testID"], str(event.get("error", "")))
    elif kind == "testDone" and not event.get("hidden"):
        counter["total"] += 1
        if event.get("result") in ("failure", "error"):
            failed.append(event["testID"])


def main(path: str) -> None:
    names: dict = {}
    errors: dict = {}
    failed: list = []
    counter = {"total": 0}
    with open(path, encoding="utf-8", errors="replace") as handle_file:
        for line in handle_file:
            try:
                decoded = json.loads(line)
            except ValueError:
                continue
            # The tool prints some events as a one-element list.
            for event in decoded if isinstance(decoded, list) else [decoded]:
                if isinstance(event, dict):
                    handle(event, names, errors, failed, counter)
    print(f"{counter['total']} tests run, {len(failed)} failed")
    for test_id in failed[:30]:
        message = errors.get(test_id, "").replace("%", "%25").replace("\r", "")
        message = message.replace("\n", "%0A")[:900]
        title = names.get(test_id, str(test_id)).replace(",", ";").replace(":", "-")
        print(f"::error title=Failed test::{title}%0A{message}")


if __name__ == "__main__":
    main(sys.argv[1])

#!/usr/bin/env python3
"""Compile edited, source-referenced micro-lessons; never truncate source articles.

Authoring format: topic | three complete sentences, each with one {answer}.
The same sentences teach and assess the selected ideas. Full source documents and
their licenses remain bundled separately. No network or generated content at runtime.
"""
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DIRECTORY = ROOT / "Sources/FirstStateCore/Resources/Curriculum"


def topic(value):
    value = re.sub(r"^\s*\d+(?:\.\d+)*[.)]?\s+", "", value)
    return " ".join(value.replace("’", "'").replace("–", "-").replace("—", "-").casefold().split())


def build():
    edited = {}
    for path in sorted((ROOT / "Design/BiteLessons").glob("*.txt")):
        for number, line in enumerate(path.read_text().splitlines(), 1):
            if not line.strip() or line.startswith("#"):
                continue
            parts = [part.strip() for part in line.split("|")]
            assert len(parts) == 4, (path.name, number, "Expected a topic and three teaching steps")
            key = topic(parts[0])
            assert key not in edited, (path.name, number, "Duplicate topic", key)
            facts = []
            for sentence in parts[1:]:
                answers = re.findall(r"\{([^{}]+)\}", sentence)
                assert len(answers) == 1, (path.name, number, sentence)
                evidence = sentence.replace("{", "").replace("}", "")
                assert 8 <= len(evidence.split()) <= 65, (path.name, number, "Step length", evidence)
                facts.append(dict(answer=answers[0], prompt=re.sub(r"\{[^{}]+\}", "_____", sentence), evidence=evidence))
            assert len({fact['answer'].casefold() for fact in facts}) == 3, (path.name, number, "Distinct answers required")
            edited[key] = facts
    catalog = json.loads((DIRECTORY / "catalog.json").read_text())
    result, missing, used = {}, [], set()
    for reading in catalog["readings"].values():
        key = topic(reading["title"])
        if key not in edited:
            missing.append(reading["title"])
            continue
        used.add(key)
        result[reading["id"]] = edited[key]
    if missing:
        raise SystemExit("Missing edited lessons:\n" + "\n".join(sorted(set(missing))))
    unused = sorted(set(edited) - used)
    assert not unused, ("Unmatched topics", unused)
    (DIRECTORY / "bite-lessons.json").write_text(json.dumps(result, indent=2, ensure_ascii=False) + "\n")
    print(f"Compiled {len(result)} source-referenced lessons from {len(edited)} edited topics.")


if __name__ == "__main__":
    build()

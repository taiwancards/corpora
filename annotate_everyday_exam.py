#!/usr/bin/env python3
import json
import glob
import os
import re
import subprocess
import sys
import tempfile
from collections import Counter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
HUAYU = os.path.join(ROOT, "data", "huayu")
MOCK = os.path.join(ROOT, "dict_and_corpora", "corpora", "tocfl_mock")

STREET_ORIGINS = {"hokkien", "internet"}
STREET_REGISTERS = {"casual", "vulgar"}


def mock_text():
    chunks = []
    with tempfile.TemporaryDirectory() as tmp:
        for pdf in glob.glob(os.path.join(MOCK, "*.pdf")):
            base = os.path.basename(pdf)
            if "_s" in base and "_s_" not in base and not base.endswith("_listen.pdf"):
                continue
            txt = os.path.join(tmp, base + ".txt")
            subprocess.run(["pdftotext", "-q", pdf, txt], check=False)
            if os.path.exists(txt):
                chunks.append(open(txt, encoding="utf-8", errors="ignore").read())
    return "\n".join(chunks)


def main():
    everyday = json.load(open(os.path.join(HUAYU, "taiwan_everyday.json"), encoding="utf-8"))
    tocfl = json.load(open(os.path.join(HUAYU, "tocfl_official.json"), encoding="utf-8"))
    tbcl = json.load(open(os.path.join(HUAYU, "school_levels.json"), encoding="utf-8"))

    tocfl_levels = {row["traditional"]: row["level"] for row in tocfl}
    tbcl_levels = {}
    for row in tbcl:
        tbcl_levels.setdefault(row["traditional"], row["level"])

    corpus = mock_text()

    statuses = Counter()
    for item in everyday:
        text = item["text"]
        forms = [text] + ([item["full"]] if item.get("full") else [])
        listed_level = next((tocfl_levels[f] for f in forms if f in tocfl_levels), None)
        tbcl_level = next((tbcl_levels[f] for f in forms if f in tbcl_levels), None)
        hits = sum(corpus.count(f) for f in forms)

        streety = item.get("origin") in STREET_ORIGINS or item.get("register") in STREET_REGISTERS

        if listed_level or tbcl_level:
            status = "exam_listed"
        elif hits > 0 and not streety:
            status = "exam_attested"
        elif streety:
            status = "street"
        else:
            status = "unmarked"

        item["exam_status"] = status
        if listed_level:
            item["exam_level"] = listed_level
        elif "exam_level" in item:
            del item["exam_level"]
        if tbcl_level:
            item["tbcl_level"] = tbcl_level
        elif "tbcl_level" in item:
            del item["tbcl_level"]
        if hits:
            item["mock_hits"] = hits
        elif "mock_hits" in item:
            del item["mock_hits"]
        statuses[status] += 1

    with open(os.path.join(HUAYU, "taiwan_everyday.json"), "w", encoding="utf-8") as f:
        json.dump(everyday, f, ensure_ascii=False, indent=1)

    print(dict(statuses))
    street_listed = [i["text"] for i in everyday if i["exam_status"] == "exam_listed" and (i.get("origin") in STREET_ORIGINS or i.get("register") in STREET_REGISTERS)]
    print("street-flavored but officially listed:", len(street_listed), street_listed[:15])


if __name__ == "__main__":
    main()

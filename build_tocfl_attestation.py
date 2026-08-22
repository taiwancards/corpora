#!/usr/bin/env python3
import json
import re
import glob
import os
import subprocess
import tempfile
from collections import Counter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MOCK = os.path.join(ROOT, "dict_and_corpora", "corpora", "tocfl_mock")
POINTS = os.path.join(ROOT, "data", "huayu", "tbcl_grammar_points.json")
OUT = os.path.join(ROOT, "data", "huayu", "tocfl_grammar_attestation.json")

STOP = {
    "補語",
    "賓語",
    "名詞",
    "動詞",
    "形容詞",
    "主語",
    "數字",
    "量詞",
    "句子",
    "重疊",
    "成分",
    "省略",
    "用法",
    "表達",
    "結構",
    "句型",
    "疑問",
    "反問",
    "目的",
    "結果",
    "方式",
    "程度",
    "狀態",
    "被動",
    "比較",
    "強調",
    "假設",
    "條件",
    "因果",
    "轉折",
    "遞進",
    "並列",
    "選擇",
    "時間",
    "地點",
    "方向",
    "存在",
    "持續",
    "完成",
    "經驗",
    "變化",
    "可能",
    "能願",
    "祈使",
    "感嘆",
}
HAND = {"繫動詞": [[["是"]]], "賓+被+V": [[["被"]]], "A-not-A": "ANOTA"}

BANDS = {
    "novice": ["*Novice*_t.pdf", "ls_mock_test_Novice_listen.pdf"],
    "band_a": ["*BandA_en_t.pdf", "*BandA_listen.pdf"],
    "band_b": ["*BandB_t.pdf", "*BandB_listen*.pdf"],
    "band_c": ["*BandC_t*.pdf", "*BandC_listen*.pdf"],
}


def band_text(tmp, patterns):
    chunks = []
    for pattern in patterns:
        for pdf in sorted(glob.glob(os.path.join(MOCK, pattern))):
            txt = os.path.join(tmp, os.path.basename(pdf) + ".txt")
            if not os.path.exists(txt):
                subprocess.run(["pdftotext", "-q", pdf, txt], check=False)
            if os.path.exists(txt):
                chunks.append(open(txt, encoding="utf-8", errors="ignore").read())
    return "\n".join(chunks)


def expand_parens(text):
    m = re.search(r"（([^）]*)）", text)
    if not m:
        return [text]
    with_inner = text[: m.start()] + m.group(1) + text[m.end() :]
    without = text[: m.start()] + text[m.end() :]
    return expand_parens(with_inner) + expand_parens(without)


def branch_markers(branch, literal):
    branch = re.sub(r"\d+$", "", branch)
    runs = re.findall(r"[一-鿿]+", branch)
    if not literal:
        runs = [r for r in runs if r not in STOP]
    return runs


def part_alternatives(part, literal=False):
    alternatives = []
    for expanded in expand_parens(part):
        for piece in expanded.split("/"):
            markers = branch_markers(piece, literal)
            if markers and markers not in alternatives:
                alternatives.append(markers)
    return alternatives


def compile_point(pattern):
    if pattern in HAND:
        return HAND[pattern]
    quoted = re.findall(r"「([^」]+)」", pattern)
    if quoted:
        compiled = [part_alternatives(q, literal=True) for q in quoted]
    else:
        parts = [p for p in re.split(r"[，…]", pattern) if p.strip()]
        compiled = [part_alternatives(p) for p in parts]
    compiled = [c for c in compiled if c]
    return compiled or None


def sentence_matches(sentence, compiled):
    if compiled == "ANOTA":
        return bool(re.search(r"([一-鿿])不\1", sentence))
    position = 0
    for part in compiled:
        best = -1
        for alternative in part:
            p = position
            ok = True
            for marker in alternative:
                i = sentence.find(marker, p)
                if i < 0:
                    ok = False
                    break
                p = i + len(marker)
            if ok and (best < 0 or p < best):
                best = p
        if best < 0:
            return False
        position = best
    return True


def main():
    with tempfile.TemporaryDirectory() as tmp:
        bands = {band: band_text(tmp, patterns) for band, patterns in BANDS.items()}
    sentences = {
        band: [s for s in re.split(r"[。？！\n]", text) if s.strip()]
        for band, text in bands.items()
    }
    han_totals = {
        band: len(re.findall(r"[一-鿿]", text)) for band, text in bands.items()
    }

    points = json.load(open(POINTS, encoding="utf-8"))
    out = []
    for point in points:
        compiled = compile_point(point["pattern"])
        counts = {}
        if compiled:
            for band, sents in sentences.items():
                counts[band] = sum(1 for s in sents if sentence_matches(s, compiled))
        first = next((b for b in BANDS if counts.get(b, 0) > 0), None)
        per_10k = (
            {b: round(c * 10000.0 / han_totals[b], 2) for b, c in counts.items()}
            if counts
            else {}
        )
        out.append(
            {
                "id": point["id"],
                "pattern": point["pattern"],
                "tier": point["tier"],
                "level": point["level"],
                "starred": point["starred"],
                "markers": compiled if compiled != "ANOTA" else "A-not-A",
                "counts": counts,
                "per_10k_han": per_10k,
                "first_band": first,
                "example": point["example"],
            }
        )

    result = {
        "han_per_band": han_totals,
        "source": "SC-TOP official mock papers, traditional editions + listening transcripts, statistics only",
        "points": out,
    }
    with open(OUT, "w", encoding="utf-8") as f:
        json.dump(result, f, ensure_ascii=False, indent=1)

    attested = [p for p in out if p["first_band"]]
    print(
        "compiled:",
        sum(1 for p in out if p["markers"]),
        "of",
        len(points),
        "| attested:",
        len(attested),
    )
    print("first band:", Counter(p["first_band"] for p in attested))


if __name__ == "__main__":
    main()

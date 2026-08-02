# corpora

Offline pipeline behind [TaiwanCards](https://github.com/taiwancards/taiwancards):
collection, sentence extraction, segmentation, frequency and dispersion, and the
statistical evaluation of all of it. Nothing here runs on the server.

[SCRIPTS.md](SCRIPTS.md) — what each script does. [METHOD.md](METHOD.md) — the
algorithms and their measurements.

## Run the tests

Unit tests cover the shared modules under `lib/`, where the algorithms live.
They use only the standard library, so they need neither Rails nor a bundle.

macOS: `brew install ruby`. Ubuntu: `sudo apt install -y ruby-full`.

```bash
rake test
```

Fixtures are hand-written and carry no corpus material, so the suite passes on
a bare checkout with no data and no credentials.

## Configuration

Every endpoint, key and path comes from `.env` in the application repository,
which is never committed. No credential, host or download endpoint is stored
here. Clone and the tests pass; nothing can be collected until you point the
variables at your own copies of the sources.

## Sources

Attribution and license transparency. Home pages only: no download endpoints or
credentials, here or in the scripts.

All are Taiwan-originated. Nothing is Chinese text converted to traditional
characters; the origin filter runs on every source and what survives is reviewed
by hand.

### Licenses permitting commercial use

| Source | Register | License |
| --- | --- | --- |
| [全國法規資料庫](https://law.moj.gov.tw/) — Laws & Regulations Database | official | OGDL v1 |
| [教育部重編國語辭典修訂本](https://dict.revised.moe.edu.tw/) — MOE Revised Dictionary | academic | CC BY-ND 3.0 TW |
| [教育部國語辭典簡編本](https://dict.concised.moe.edu.tw/) — MOE Concised Dictionary | academic | CC BY-ND 3.0 TW |
| [教育部成語典](https://dict.idioms.moe.edu.tw/) — MOE Dictionary of Idioms | literary | CC BY-ND 3.0 TW |
| [國家教育研究院 TBCL](https://coct.naer.edu.tw/) — NAER proficiency benchmark examples | colloquial | NAER open government declaration |
| [樂詞網](https://terms.naer.edu.tw/) — NAER bilingual terminology, signage and counters | official | NAER open government declaration |
| [全字庫 CNS 11643](https://www.cns11643.gov.tw/) — components, stroke order, zhuyin, syllable recordings | reference | OGDL v1 or SIL OFL 1.1 |
| [小學堂](https://xiaoxue.iis.sinica.edu.tw/) — 廣韻 rhyme tables, Academia Sinica | reference | CC0 1.0 |
| [立法院開放資料](https://data.ly.gov.tw/) — Legislative Yuan Open Data | colloquial | OGDL v1 |
| [新北市政府開放資料](https://data.ntpc.gov.tw/) — New Taipei City press releases | publicistic | Copyright Act art. 9 + OGDL v1 |
| ROC ministry press releases | publicistic | Copyright Act art. 9 (not subject to copyright) |
| [Mozilla Common Voice](https://commonvoice.mozilla.org/) (zh-TW) | colloquial | CC0 1.0 |
| [維基百科](https://zh.wikipedia.org/) — Chinese Wikipedia | academic | CC BY-SA 4.0 |
| [維基詞典](https://zh.wiktionary.org/) — Wiktionary | academic | CC BY-SA 4.0 |
| [維基導遊](https://zh.wikivoyage.org/) — Wikivoyage, Taiwan articles | publicistic | CC BY-SA 4.0 |
| [維基文庫](https://zh.wikisource.org/) — Taiwanese vernacular literature | literary | public domain |

### Non-commercial or unresolved licenses

Used for frequency statistics and model fitting only. No text from these
sources is redistributed.

| Source | Register | License |
| --- | --- | --- |
| [TED](https://www.ted.com/) — TED2020 subtitles | academic | CC BY-NC-ND 4.0 |
| Taiwan Text Excellence — Taiwanese news, published as a research dataset | publicistic | CC BY-NC-SA 4.0 |
| [OPUS](https://opus.nlpl.eu/) — OpenSubtitles, zh-TW portion | subtitles | rights held by the film rightsholders |
| PTT Gossiping corpus — forum threads, published as a research dataset | internet | Apache-2.0 for the corpus; post authors' rights not cleared |
| [YouTube](https://www.youtube.com/) — comments, read through the public Data API | internet | rights held by the comment authors |
| [方格子 vocus](https://vocus.cc/) — contemporary prose | literary | rights held by the article authors |
| [台灣光華雜誌](https://www.taiwan-panorama.com/) — Taiwan Panorama | publicistic | unresolved |

The application separates the two classes at import and records the license of
every source beside the material derived from it.

## Origin filtering

The origin filter is not defined here. `lib/origin_filter.rb`, `lib/sentences.rb`
and `lib/registers.rb` are thin adapters over the
[twfilter](https://github.com/taiwan-corpora/twfilter) gem, which the Rails
application also loads, so the offline pipeline and the server cannot disagree
about sentence boundaries, the character inventory or the mainland lexicon.

Measured over 987 740 sentences from fifteen sources under `Policy.corpus`:
1.91 % rejected overall, 0.13 % for 全國法規資料庫, and the lexical detectors fire
only on the two sources composed outside Taiwan and mechanically converted.

## Provenance axes

Every source in `data/content_sources.json` carries four independent axes —
`medium`, `production`, `formality`, `purpose` — in addition to the derived
`register` label. `build_frequency.rb` uses `production` to select the reference
model: `native` by default, `FREQUENCY_PRODUCTION=native,converted,translated`
for the full model, written to `corpus_frequency_full.json`.

## Resources

`TWP_CORES` bounds `Corpus.each_slice_parallel`. Volume, wall time, CPU seconds
and peak resident size for anything run through twpipeline are recorded in
`work/benchmarks.jsonl`.

## Method

Viterbi over Kneser–Ney bigrams with a token penalty, EM re-segmentation,
entropy pruning. Frequency dispersion-corrected by deviation of proportions.
Gold set of 510 cases; bigram over unigram at p < 1e-6 (McNemar), confirmed by
paired bootstrap over F1. Collocation significance by Dunning's log-likelihood,
ranked by logDice. Phonetic series scored by modal 廣韻 rhyme group over the
members sharing a component; confusability by inverse-document-frequency
weighted Jaccard over CNS component sets.

Details and measurements in [METHOD.md](METHOD.md).

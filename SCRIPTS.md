# Scripts

Offline pipeline. Nothing here runs on the server or during a request; the
application reads only the finished files these scripts produce. Run them when
the corpus or the methodology changes, not otherwise.

All Ruby except `build_thesaurus.py`, which stays on Python because its output
depends on LAPACK's SVD and cannot be reproduced bit-for-bit in another
implementation.

Every source location and key is read from `.env`. Nothing here hard-codes a
download endpoint, a dataset identifier or a credential, so the scripts are
readable and runnable but produce nothing without a configured environment. See
`.env.dev` in the application repository for the full list of variables, and
`README.md` here for the sources themselves.

## Order

```text
fetch → parse → build vocabulary → frequency → bigrams → prune
```

Each stage reads the output of the previous one.

The vocabulary stage is not optional before a bigram rebuild. `segvocab.json` is
the word list the counts are tokenised with, and a word missing from it gets a
count of zero, which no amount of corpus can repair — the segmenter simply never
proposes it. Refresh the export first:

```text
bin/rails runner corpora/export_dict.rb
VOCAB_LEVEL=app bundle exec ruby corpora/build_vocabulary.rb
```

`bundle exec rails huayu:segmentation_drift` reports what the shipped model has
never seen. It should be close to zero after a rebuild.

## Collection

Downloads raw material into `CORPORA_DIR`. Slow and rate-limited; run only when
refreshing a source.

| Script | Source style | Run |
| --- | --- | --- |
| `fetch.sh` | official, legal, press, reference dictionaries | `bash corpora/fetch.sh` |
| `fetch_wikisource.rb` | literary prose | `bundle exec ruby corpora/fetch_wikisource.rb` |
| `fetch_vocus.rb` | contemporary essays and prose | `bundle exec ruby corpora/fetch_vocus.rb` |
| `fetch_youtube.rb` | colloquial, user comments | `YOUTUBE_API_KEY=… bundle exec ruby corpora/fetch_youtube.rb` |

## Parsing

Turns raw material into sentence sets under `data/corpora/sentences/`.

| Script | Purpose | Run |
| --- | --- | --- |
| `unpack_concised.rb` | lifts the spreadsheet out of the learner dictionary archive, decoding Big5 member names | `bundle exec ruby corpora/unpack_concised.rb <dir>` |
| `unpack_cns.rb` | splits the CNS 11643 archives: Unicode mapping tables, and the per-speaker syllable recordings into the media tree | `bundle exec ruby corpora/unpack_cns.rb <dir> [media-dir]` |
| `parse_concised.rb` | learner dictionary to senses and examples | `bundle exec ruby corpora/parse_concised.rb` |
| `parse_ntpc.rb` | municipal press CSV to sentences | `bundle exec ruby corpora/parse_ntpc.rb` |
| `extract_all.rb` | every corpus to one sentence set per source | `bundle exec ruby corpora/extract_all.rb` |
| `extract_registers.rb` | register-tagged extraction | `bundle exec ruby corpora/extract_registers.rb <source>` |
| `extract_tte.rb` | news dataset to sentences | `bundle exec ruby corpora/extract_tte.rb` |
| `extract_etymology.rb` | character etymology | `bundle exec ruby corpora/extract_etymology.rb` |

## Building

Produces the files the application reads at runtime.

| Script | Output | Run |
| --- | --- | --- |
| `build_vocabulary.rb` | segmentation vocabulary | `bundle exec ruby corpora/build_vocabulary.rb` |
| `filter_vocabulary.rb` | filtered segmentation vocabulary | `bundle exec ruby corpora/filter_vocabulary.rb` |
| `build_frequency.rb` | frequency and dispersion, per register | `bundle exec ruby corpora/build_frequency.rb` |
| `build_corpus_frequency.rb` | frequency over the reference corpora | `bundle exec ruby corpora/build_corpus_frequency.rb` |
| `build_bigrams.rb` | Kneser–Ney bigram counts | `bundle exec ruby corpora/build_bigrams.rb` |
| `build_web_runs.rb` | Han runs from the HPLT Taiwan slice, one host per line prefix | `bundle exec ruby corpora/build_web_runs.rb` |
| `build_web_bigrams.rb` | the same counts over the web corpus, counted once per host | `bundle exec ruby corpora/build_web_bigrams.rb` |
| `merge_bigram_counts.rb` | blend two count files, scaled to a common total | `MERGE_PRIMARY=a.json MERGE_SECONDARY=b.json bundle exec ruby corpora/merge_bigram_counts.rb` |
| `prune_bigrams.rb` | pruned bigram model | `bundle exec ruby corpora/prune_bigrams.rb` |
| `build_classifiers.rb` | measure-word pairs, parts of speech | `bundle exec ruby corpora/build_classifiers.rb` |
| `build_thesaurus.py` | synonyms, antonyms, distributional neighbors | `python3 corpora/build_thesaurus.py` |
| `build_cns.rb` | stroke counts and stroke sequences per character, plus the syllable index of the reference recordings | `bundle exec ruby corpora/build_cns.rb` |
| `build_series.rb` | phonetic series and visually confusable neighbors | `bundle exec ruby corpora/build_series.rb` |
| `build_sketches.rb` | word sketches: grammatical relations per headword | `bundle exec ruby corpora/build_sketches.rb` |
| `build_moe_revised.rb` | senses of the unabridged dictionary, trimmed to the learner-relevant head | `bundle exec ruby corpora/build_moe_revised.rb` |
| `build_naer.rb` | bilingual signage, counter and culture terminology | `bundle exec ruby corpora/build_naer.rb` |
| `build_names.rb` | surname and given-name frequencies from the national naming statistics | `bundle exec ruby corpora/build_names.rb` |
| `build_grammar_examples.rb` | corpus sentences that attest each grammar point | `bin/rails runner corpora/build_grammar_examples.rb` |
| `annotate_grammar_examples.rb` | zhuyin, pinyin, segments and sentence links on every grammar example | `bin/rails runner corpora/annotate_grammar_examples.rb` |
| `build_grammar_glossary.rb` | readings for every Han run in a grammar lesson; adds what is missing and leaves existing entries alone | `bin/rails runner corpora/build_grammar_glossary.rb` |
| `build_course_lessons.rb` | readings for the course vocabulary, plus the practice tasks in every lesson and the test at the end of every level | `bin/rails runner corpora/build_course_lessons.rb` |
| `build_tocfl_papers.rb` | answer keys and audio manifests for the official TOCFL mock papers held under `data/tocfl_official` | `bin/rails runner corpora/build_tocfl_papers.rb` |
| `export_dict.rb` | dictionary export from the database | `bin/rails runner corpora/export_dict.rb` |

## Evaluation

Measurement only; these write no runtime files.

| Script | Reports | Run |
| --- | --- | --- |
| `evaluate_segmentation.rb` | exact match and F1 against the gold set | `bundle exec ruby corpora/evaluate_segmentation.rb` |
| `significance.rb` | McNemar test, bigram against unigram | `bundle exec ruby corpora/significance.rb` |
| `bootstrap_f1.rb` | paired bootstrap over F1 | `bundle exec ruby corpora/bootstrap_f1.rb` |
| `sweep_pruning.rb` | pruning threshold sweep | `bundle exec ruby corpora/sweep_pruning.rb` |
| `compare_models.rb` | model comparison on the gold set | `bundle exec ruby corpora/compare_models.rb` |
| `mine_disagreements.rb` | cases where models disagree | `bundle exec ruby corpora/mine_disagreements.rb` |
| `stats_corpora.rb` | size and composition of every corpus | `bundle exec ruby corpora/stats_corpora.rb` |
| `verify_china_markers.rb` | China-marker precision | `bundle exec ruby corpora/verify_china_markers.rb` |

## Database maintenance

Under `rails/`. These need the application environment.

| Script | Purpose | Run |
| --- | --- | --- |
| `export_untranslated_words.rb` | untranslated words, batched for translation | `bin/rails runner corpora/rails/export_untranslated_words.rb` |
| `export_untranslated_senses.rb` | untranslated senses | `bin/rails runner corpora/rails/export_untranslated_senses.rb` |
| `export_untranslated_collocations.rb` | untranslated collocations | `bin/rails runner corpora/rails/export_untranslated_collocations.rb` |
| `merge_word_glosses.rb` | merge translations back into the gloss store | `bin/rails runner corpora/rails/merge_word_glosses.rb <file>` |
| `merge_sense_glosses.rb` | same, for senses | `bin/rails runner corpora/rails/merge_sense_glosses.rb <file>` |
| `merge_collocation_glosses.rb` | same, for collocations | `bin/rails runner corpora/rails/merge_collocation_glosses.rb <file>` |
| `merge_sentence_glosses.rb` | same, for sentences | `bin/rails runner corpora/rails/merge_sentence_glosses.rb <file>` |
| `rekey_sentence_glosses.rb` | re-attaches sentence glosses whose key changed under punctuation trimming, drops the orphans | `bin/rails runner corpora/rails/rekey_sentence_glosses.rb` |
| `export_content.sh` | dump dictionary content, no user data | `bash corpora/rails/export_content.sh` |
| `import_content.sh` | load such a dump into a target database | `bash corpora/rails/import_content.sh <url> <file>` |

## Libraries

`lib/` holds the shared code: `corpus.rb` (paths, JSON, `.env`, fork-based
parallelism), `segmenter.rb` and `bigram_model.rb` (Viterbi, Kneser–Ney),
`pruning.rb` (entropy-based pruning), `http.rb`,
`spreadsheet.rb` (ODS and XLSX reader over the raw XML, no gem dependency),
`python_random.rb` (Mersenne Twister, for reproducing Python's sampling).

`origin_filter.rb`, `sentences.rb` and `registers.rb` are thin adapters over the
[twfilter](https://github.com/taiwan-corpora/twfilter) gem; the linguistic
decisions themselves live there and are shared with the Rails application.

## Method

Segmentation is Viterbi decoding over a Kneser–Ney bigram model with a token
penalty, refined by EM re-segmentation and pruned by the entropy criterion.
It is evaluated on a 510-case gold set; the bigram model beats the unigram
baseline at p < 1e-6 by McNemar's test, confirmed by a 10,000-round paired
bootstrap.

Frequency uses deviation of proportions for dispersion, so a word that occurs
often but only in one register is not treated as common.

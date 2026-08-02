# Method

Rationale for the derived resources. Kept out of the sources so the scripts
carry code only.

The approach follows the author's 2015 master's thesis in computational
linguistics and quantitative typology. Each classical estimator below is kept
only where it outscores the alternative on the gold set.

## Segmentation

Viterbi over a Kneser–Ney bigram model with a token penalty, refined by EM
re-segmentation, pruned by the relative-entropy criterion of Stolcke (1998).

Gold set of 510 cases. Bigram over unigram at p < 1e-6 (McNemar), confirmed by a
10,000-round paired bootstrap over F1.

## Frequency

Dispersion-corrected by deviation of proportions, per register.

## Origin filter

Implemented in [twfilter](https://github.com/taiwan-corpora/twfilter) and shared
with the Rails application. Conjunction of MOE character-chart membership,
simplified-character detection over an OpenCC round-trip, mainland traditional
orthography, a corpus-verified mainland lexicon (149 rejecting, 38 marking),
written-Cantonese characters and Hong Kong, Cantonese-sequence and Singapore
word forms (17 and 19), and literary-Chinese density. The erhua rule inspects
both windows around 兒 so root uses survive.

Non-Taiwanese toponyms and institutions are tagged, not rejected: subject matter
is not provenance. Taiwanese media covers the mainland constantly, several of the
terms are ordinary ROC administrative vocabulary, and Taipei streets are named
after mainland cities, so an address suffix suppresses the tag.

Grading of lexical candidates: hard if the mainland form is absent from a ten-
source native reference corpus of 11 923 110 characters and the Taiwan form is
attested at least three times; soft if the Taiwan form dominates by 20 : 1;
rejected otherwise. 593 of 780 candidates from the OpenCC `TWPhrases` table were
rejected — that table is an IT-register conversion list in which 程序, 支持,
設備, 文件 and 質量 are ordinary Taiwanese words, and using it naively flags
8.83 % of the ROC statute book.

The reference corpus excludes sources with an open authorship gate. Every
mainland form attested anywhere in the wider corpus occurs in open web comments
and nowhere else, so counting them would license mainland commenters' vocabulary
as Taiwanese.

Measured over 987 740 sentences from fifteen sources under twfilter 0.1.0:
2.36 % rejected overall, 0.12 % for 全國法規資料庫 with zero lexical and zero
orthographic rejections. Mainland orthography fires 67 times across 424 024
natively composed sentences against 1 278 times across 563 716 that are not.

## Thesaurus

Four relations, not conflated.

**Synonyms, antonyms** — the 相似詞 and 相反詞 columns of both MOE dictionaries.
Lexicographers' annotation, not inference. Symmetrized.

**Paradigmatic neighbors** — Harris's distributional hypothesis: co-occurrence
matrix, PPMI with context-distribution smoothing and shift (Levy & Goldberg
2015), cosine between rows.

    PMI_a(w,c) = log[ p(w,c) / (p(w) * p_a(c)) ],  p_a(c) ~ #(c)^a

a = 0.75 damps the PMI bias toward rare contexts. The shift −log k cuts weak
associations, as in SGNS with k negative samples. Window ±2 beats ±4 and ±6:
narrow windows give paradigmatic relations, wide ones drift to topical.

Truncated SVD (M = U·S·Vᵀ, vector = U·Sᵖ, randomised Halko–Martinsson–Tropp) is
implemented and stays in the sweep, but is not in the pipeline — it loses at
every dimensionality:

    window ±2, no SVD           recall 0.151   MRR 0.138
    window ±2, SVD d=500 p=0.5  recall 0.130   MRR 0.117
    window ±2, SVD d=300 p=0.5  recall 0.120   MRR 0.109
    window ±2, SVD d=200 p=0.5  recall 0.111   MRR 0.101

Quality rises with dimensionality, so truncation itself is the loss. At seven
million tokens with contexts capped at three hundred the matrix is already
near-noise-free.

**Syntagmatic collocates** — two stages. Significance by Dunning's
log-likelihood ratio (1993) over the 2×2 presence table:

    G² = 2 · Σ O_ij · ln(O_ij / E_ij)

G² assumes no normality and holds at low frequencies. Threshold 10.83 is
p < 0.001 at one degree of freedom. Significance is not interest, so ranking is
by logDice (Rychlý 2008):

    logDice = 14 + log₂[ 2·f(x,y) / (f(x) + f(y)) ]

Corpus-size independent; the denominator is a sum of frequencies, not a product
of probabilities. Function words removed by official part of speech.

Window, a and thresholds are set by measurement against the gold set:

    python3 corpora/build_thesaurus.py
    SWEEP=1 python3 corpora/build_thesaurus.py   # scores every combination

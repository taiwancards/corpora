#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "lib/bigram_model"
require_relative "lib/python_random"

ROUNDS = Integer(ENV.fetch("BOOTSTRAP", "10000"))
SAVED = ENV["SAVED_DIR"].to_s

def vocabulary(extra)
  base = Corpus.read_json(Corpus.corpora("dict.json"))
  words = Segmenter.entries(base.fetch("words"))
  chars = Segmenter.entries(base.fetch("chars"))

  if extra
    payload = Corpus.read_json(extra)
    words |= Segmenter.entries(payload.fetch("words"))
    chars |= Segmenter.entries(payload.fetch("chars"))
  end

  [words, chars]
end

def scores(cases, &guess) = cases.map { |kase| BigramModel.score(kase["gold"], guess.call(kase["text"])) }

def bootstrap(first, second, rounds, seed: 20260725)
  random = Corpus::PythonRandom.new(seed)
  size = first.length
  observed = (first.sum / size.to_f) - (second.sum / size.to_f)
  sign = observed >= 0 ? 1 : -1
  hits = 0

  rounds.times do
    total = 0.0
    size.times do
      index = random.randrange(size)
      total += first[index] - second[index]
    end

    hits += 1 if (total / size) * sign <= 0
  end

  [observed, (hits + 1) / (rounds + 1).to_f]
end

cases = BigramModel.gold_cases

words, = vocabulary(Corpus.corpora("segvocab.json"))
limit = Segmenter.max_word(words)
unigram_model = BigramModel.unigram_model(limit)
unigram = scores(cases) { |text| Segmenter.segment(text, words, unigram_model) }

model = BigramModel.load
bigram = scores(cases) { |text| BigramModel.viterbi(text, words, model, limit, 2.5) }

rows = [["bigram against unigram", bigram, unigram]]

unless SAVED.empty?
  old_words, = vocabulary(nil)
  old_limit = Segmenter.max_word(old_words)
  old_model = BigramModel.load(Pathname(SAVED).join("bigram_frequency.app.json"))
  narrow = scores(cases) { |text| BigramModel.viterbi(text, old_words, old_model, old_limit, 1.25) }
  rows << ["+MOE vocabulary against application vocabulary", bigram, narrow]
end

Corpus.say("cases #{cases.length}, bootstrap rounds #{ROUNDS}")
Corpus.say("")

rows.each do |name, first, second|
  delta, probability = bootstrap(first, second, ROUNDS)
  Corpus.say(
    format(
      "%-40s F1 %.4f -> %.4f  delta %+.4f  p = %.4f",
      name,
      second.sum / cases.length.to_f,
      first.sum / cases.length.to_f,
      delta,
      probability
    )
  )
end

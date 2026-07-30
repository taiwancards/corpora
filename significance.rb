#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "lib/bigram_model"

PENALTY = Float(ENV.fetch("PENALTY", "1.0"))

def mcnemar(first, second)
  only_first = first.zip(second).count { |a, b| a && !b }
  only_second = first.zip(second).count { |a, b| b && !a }
  total = only_first + only_second
  return [only_first, only_second, 1.0] if total.zero?

  smaller = [only_first, only_second].min
  tail = (0..smaller).sum { |k| Corpus.combinations(total, k) }
  [only_first, only_second, [1.0, 2.0 * tail / (2.0 ** total)].min]
end

cases = BigramModel.gold_cases
words, = Segmenter.vocabulary(Corpus.corpora("segvocab.json"))
limit = Segmenter.max_word(words)
unigram = BigramModel.unigram_model(limit)
model = BigramModel.load

unigram_hits = cases.map { |kase| Segmenter.segment(kase["text"], words, unigram) == kase["gold"] }
bigram_hits = cases.map { |kase| BigramModel.viterbi(kase["text"], words, model, limit, PENALTY) == kase["gold"] }

only_first, only_second, probability = mcnemar(bigram_hits, unigram_hits)

Corpus.say("cases #{cases.length}, penalty λ = #{PENALTY}")
Corpus.say("unigram exact #{unigram_hits.count(true)}, bigram exact #{bigram_hits.count(true)}")
Corpus.say("only bigram right: #{only_first}, only unigram: #{only_second}")
Corpus.say(format("McNemar, two-sided p = %.3g", probability))

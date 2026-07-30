#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "lib/pruning"

THETAS = ENV.fetch("THETAS", "0,1e-12,1e-11,1e-10,1e-9,1e-8,1e-7").split(",").map { |value| Float(value) }
PENALTIES = (0..24).map { |step| step * 0.25 }
FLOOR = Float(ENV.fetch("CONT_FLOOR", "0"))

cases = BigramModel.gold_cases
words, = Segmenter.vocabulary(Corpus.corpora("segvocab.json"))
limit = Segmenter.max_word(words)
unigram = BigramModel.unigram_probabilities

bigrams, history, preceders, total = Pruning.load_counts
discount = Pruning.discounts(bigrams)
continuation = Pruning.continuation_table(preceders)
continuation = continuation.transform_values { |value| [value, FLOOR].max } if FLOOR.positive?

scored, = Pruning.deltas(bigrams, history, continuation, discount, total)
Corpus.say(format("bigrams %d, discount D %.6f", scored.length, discount))
Corpus.say("")

THETAS.each do |theta|
  table = Hash.new { |memo, key| memo[key] = {} }
  spent = Hash.new(0.0)
  kept = 0

  scored.each do |delta, context, token, value|
    next if delta < theta

    table[token][context] = value
    spent[context] += value
    kept += 1
  end

  weights = history.keys.to_h { |context| [context, [1.0 - spent.fetch(context, 0.0), 1e-12].max] }
  model = BigramModel::Model.new(table: table, weights: weights, continuation: continuation, unigram: unigram)

  penalty, exact, average = Pruning.best_penalty(cases, words, model, limit, PENALTIES)
  share = 100.0 * kept / scored.length

  Corpus.say(
    format(
      "θ=%8g  kept %8d (%5.1f%%)  λ=%4.2f  exact %3d/%d (%5.1f%%)  F1 %.4f",
      theta,
      kept,
      share,
      penalty,
      exact,
      cases.length,
      100.0 * exact / cases.length,
      average
    )
  )
end

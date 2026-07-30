#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "lib/pruning"

PENALTIES = (0..24).map { |step| step * 0.25 }

cases = BigramModel.gold_cases
words, = Segmenter.vocabulary(Corpus.corpora("segvocab.json"))
limit = Segmenter.max_word(words)
unigram = BigramModel.unigram_probabilities

bigrams, history, preceders, total = Pruning.load_counts
discount = Pruning.discounts(bigrams)
continuation = Pruning.continuation_table(preceders)

followers = Hash.new(0)
bigrams.each_key { |context, _| followers[context] += 1 }

scored, = Pruning.deltas(bigrams, history, continuation, discount, total)
entropy = scored.to_h { |delta, context, token, _| [[context, token], delta] }

Corpus.say(format("bigrams %d, discount D %.6f, cases %d", bigrams.size, discount, cases.length))
Corpus.say("")
Corpus.say(format("%16s %10s %10s %6s %9s %7s", "pruning", "λ mass", "kept", "penalty", "exact", "F1"))

build = lambda do |keep|
  table = Hash.new { |memo, key| memo[key] = {} }
  spent = Hash.new(0.0)
  kept = 0

  bigrams.each do |(context, token), count|
    next unless keep.call(context, token, count)

    value = [count - discount, 0.0].max / history[context]
    next unless value.positive?

    table[token][context] = value
    spent[context] += value
    kept += 1
  end

  leftover = history.keys.to_h { |context| [context, [1.0 - spent.fetch(context, 0.0), 1e-12].max] }
  deficient = history
    .filter_map { |context, count|
      [context, discount * followers[context] / count] if count.positive?
    }
    .to_h

  [table, leftover, deficient, kept]
end

plans = [["count >= 1", -> (_, _, _) { true }]]
[2, 3, 4, 6].each { |minimum| plans << ["count >= #{minimum}", -> (_, _, count) { count >= minimum }] }
[1e-7, 3e-7, 1e-6, 3e-6].each do |theta|
  plans << [format("entropy %g", theta), -> (context, token, _) { entropy.fetch([context, token], 0.0) >= theta }]
end

plans.each do |name, keep|
  table, leftover, deficient, kept = build.call(keep)

  [["leftover", leftover], ["deficient", deficient]].each do |label, weights|
    model = BigramModel::Model.new(table: table, weights: weights, continuation: continuation, unigram: unigram)
    penalty, exact, average = Pruning.best_penalty(cases, words, model, limit, PENALTIES)
    Corpus.say(format("%16s %10s %10d %6.2f %4d/%d %7.4f", name, label, kept, penalty, exact, cases.length, average))
  end
end

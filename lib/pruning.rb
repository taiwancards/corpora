# frozen_string_literal: true

require_relative "bigram_model"

module Pruning
  module_function

  def load_counts(path = Corpus.corpora("bigram_counts.json"))
    payload = Corpus.read_json(path)
    bigrams = payload.fetch("bigrams").to_h { |key, count| [key.split("\t", 2), count] }
    [bigrams, payload.fetch("history"), payload.fetch("preceders"), payload.fetch("total")]
  end

  def discounts(bigrams)
    ones = twos = 0
    bigrams.each_value do |count|
      ones += 1 if count == 1
      twos += 1 if count == 2
    end

    total = ones + (2 * twos)
    total.zero? ? 0.75 : ones.fdiv(total)
  end

  def continuation_table(preceders)
    total = preceders.each_value.sum
    preceders.transform_values { |value| value / total.to_f }
  end

  def deltas(bigrams, history, continuation, discount, total)
    direct = Hash.new { |memo, key| memo[key] = {} }
    spent = Hash.new(0.0)

    bigrams.each do |(context, token), count|
      value = [count - discount, 0.0].max / history[context]
      next unless value.positive?

      direct[context][token] = value
      spent[context] += value
    end

    weights = history.keys.to_h { |context| [context, [1.0 - spent.fetch(context, 0.0), 1e-12].max] }

    scored = []
    direct.each do |context, row|
      prior = history[context] / total.to_f
      lambda_value = weights[context]

      row.each do |token, value|
        follow = continuation.fetch(token, 0.0)
        next unless follow.positive?

        probability = value + (lambda_value * follow)
        raised = lambda_value + value
        gain = probability * Math.log(probability / (raised * follow))
        gain -= value * (1.0 - follow)
        scored << [prior * gain, context, token, value]
      end
    end

    [scored, weights]
  end

  def best_penalty(cases, words, model, limit, penalties)
    best = nil

    penalties.each do |penalty|
      exact = 0
      total = 0.0

      cases.each do |kase|
        pieces = BigramModel.viterbi(kase["text"], words, model, limit, penalty)
        exact += 1 if pieces == kase["gold"]
        total += BigramModel.score(kase["gold"], pieces)
      end

      average = total / cases.length
      best = [penalty, exact, average] if best.nil? || ([average, exact] <=> [best[2], best[1]]).positive?
    end

    best
  end
end

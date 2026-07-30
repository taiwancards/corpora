#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "lib/corpus"

THRESHOLD = Float(ENV.fetch("BIGRAM_THETA", "0"))
MIN_COUNT = Integer(ENV.fetch("BIGRAM_MIN", "4"))

def discounts(bigrams)
  ones = twos = 0
  bigrams.each_value do |count|
    ones += 1 if count == 1
    twos += 1 if count == 2
  end

  total = ones + (2 * twos)
  total.zero? ? 0.75 : ones.fdiv(total)
end

payload = Corpus.read_json(Corpus.corpora("bigram_counts.json"))

bigrams = payload.fetch("bigrams").to_h { |key, count| [key.split("\t", 2), count] }
history = payload.fetch("history")
preceders = payload.fetch("preceders")
total = payload.fetch("total")

discount = discounts(bigrams)

continuation_total = preceders.each_value.sum
continuation = preceders.transform_values { |value| value / continuation_total.to_f }

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

scored.sort_by! { |row| row[0] }

kept = Hash.new { |memo, key| memo[key] = {} }
spent_kept = Hash.new(0.0)
dropped = 0

scored.each do |delta, context, token, value|
  if delta < THRESHOLD || bigrams[[context, token]] < MIN_COUNT
    dropped += 1
    next
  end

  kept[context][token] = value
  spent_kept[context] += value
end

final_weights = history
  .filter_map { |context, count|
    [context, [1.0 - spent_kept.fetch(context, 0.0), 1e-12].max] if count.positive?
  }
  .to_h

by_context = kept.to_h { |context, row| [context, row.transform_values { |value| value.round(10) }.sort.to_h] }

out = {
  "bigram" => by_context.sort.to_h,
  "continuation" => continuation.transform_values { |value| value.round(12) }.sort.to_h,
  "discount" => discount.round(6),
  "lambda" => final_weights.transform_values { |value| value.round(10) }.sort.to_h,
  "theta" => THRESHOLD,
  "tokens" => total
}

target = Corpus.write_json(Corpus.data("huayu/bigram_frequency.json"), out)

survived = by_context.each_value.sum(&:size)
Corpus.say(format("discount D = %.6f, threshold θ = %g", discount, THRESHOLD))
Corpus.report("bigrams", scored: scored.length, dropped: dropped, kept: survived)
Corpus.report("contexts", total: by_context.size, continuations: continuation.size)
Corpus.report("file", megabytes: (target.size / 1024.0 / 1024).round(1), path: target.basename)

#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "lib/corpus"

PRIMARY = ENV.fetch("MERGE_PRIMARY")
SECONDARY = ENV.fetch("MERGE_SECONDARY")
WEIGHT = Float(ENV.fetch("MERGE_WEIGHT", "1.0"))

def blend(primary, secondary, scale)
  merged = primary.dup
  secondary.each do |key, count|
    merged[key] = (merged.fetch(key, 0) + (count * scale)).round
  end

  merged.reject { |_, count| count.zero? }
end

first = Corpus.read_json(PRIMARY)
second = Corpus.read_json(SECONDARY)

first_total = first.fetch("total").to_f
second_total = second.fetch("total").to_f
scale = second_total.positive? ? WEIGHT * first_total / second_total : 0.0

Corpus.report(
  "inputs",
  primary: first.fetch("bigrams").size,
  secondary: second.fetch("bigrams").size,
  scale: scale.round(4)
)

bigrams = blend(first.fetch("bigrams"), second.fetch("bigrams"), scale)
history = blend(first.fetch("history"), second.fetch("history"), scale)
preceders = blend(first.fetch("preceders"), second.fetch("preceders"), scale)
total = (first_total + (second_total * scale)).round

ones = bigrams.each_value.count { |count| count == 1 }
twos = bigrams.each_value.count { |count| count == 2 }
denominator = ones + (2 * twos)
discount = denominator.zero? ? 0.75 : ones.fdiv(denominator)

payload = {
  "bigrams" => bigrams,
  "history" => history,
  "preceders" => preceders,
  "total" => total,
  "discount" => discount
}

target = Corpus.write_json(Corpus.corpora("bigram_counts.json"), payload)
Corpus.report("merged", bigrams: bigrams.size, contexts: history.size, discount: discount.round(6))
Corpus.report("file", megabytes: (target.size / 1024.0 / 1024).round(1), path: target.basename)
Corpus.say("next: corpora/prune_bigrams.rb")

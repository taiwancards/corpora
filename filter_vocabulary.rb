#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "lib/corpus"

threshold = Float(ENV.fetch("VOCAB_ASSOC", "0.0"))

frequency = Corpus.read_json(Corpus.data("huayu/corpus_frequency.json"))
scale = frequency.fetch("words").each_value.sum + frequency.fetch("chars").each_value.sum

probability = {}
frequency.fetch("words").each { |token, value| probability[token] = value / scale.to_f }
frequency.fetch("chars").each { |token, value| probability[token] ||= value / scale.to_f }

def association(word, probability)
  own = probability[word]
  return nil unless own&.positive?

  denominator = -Math.log(own)

  (1...word.length)
    .filter_map { |cut|
      left = probability[word[0, cut]]
      right = probability[word[cut..]]
      next unless left&.positive? && right&.positive?

      Math.log(own / (left * right)) / denominator
    }
    .min
end

base = Corpus.read_json(Corpus.corpora("dict.json"))
app_words = base.fetch("words").keys.to_set
chars = base.fetch("chars").keys.to_set
every = Corpus.read_json(Corpus.corpora("segvocab.json")).fetch("words").to_set
extra = (every - app_words).to_a

Corpus.report("input", application: app_words.size, "MOE additions": extra.size)

scored = Corpus
  .each_slice_parallel(extra) { |slice| slice.to_h { |word| [word, association(word, probability)] } }
  .reduce(:merge)

kept = scored.count { |_, value| value.nil? || value >= threshold }
Corpus.report("association", threshold: threshold, kept: kept, dropped: scored.size - kept)

words = app_words | scored.filter_map { |word, value| word if value.nil? || value >= threshold }

target = Corpus.write_json(
  Corpus.corpora("segvocab_filtered.json"),
  {"words" => words.sort, "chars" => chars.sort, "association" => threshold}
)

Corpus.report("written", words: words.size, characters: chars.size, path: target.basename)

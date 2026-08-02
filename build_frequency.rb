#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "lib/segmenter"

WEIGHTS = {
  "colloquial" => 0.20,
  "internet" => 0.18,
  "subtitles" => 0.18,
  "publicistic" => 0.16,
  "academic" => 0.12,
  "official" => 0.10,
  "literary" => 0.06
}.freeze

ROUNDS = 3
CORPUS_HAN_RUN = /[\u{4E00}-\u{9FFF}]+/

PRODUCTION = ENV.fetch("FREQUENCY_PRODUCTION", "native").split(",").freeze
MODEL = PRODUCTION == %w[native] ? "" : "_full"
OUT_DIR = "huayu/frequency#{MODEL}"
OUT_FILE = "huayu/corpus_frequency#{MODEL}.json"

def sources
  Corpus
    .read_json(Corpus.data("content_sources.json"))
    .select { |row| row["register"] && PRODUCTION.include?(row.fetch("production", "native")) }
    .map { |row| [row["slug"], row["register"]] }
end

def texts(slug)
  path = Corpus.data("corpora/sentences/#{slug}.json")
  path.exist? ? Corpus.read_json(path) : []
end

def per_million(counts, total)
  return {} if total.zero?

  counts.to_h { |token, count| [token, [Corpus.python_round(count * 1_000_000.0 / total), 1].max] }
end

def deviation_of_proportions(shares, sizes)
  0.5 * sizes.sum { |part, size| (shares.fetch(part, 0.0) - size).abs }
end

def merge!(into, from) = from.each { |token, count| into[token] += count }

words, chars = Segmenter.vocabulary(Corpus.corpora("segvocab.json"))
limit = Segmenter.max_word(words)

per_corpus = sources.filter_map do |slug, register|
  runs = texts(slug).flat_map { |text| text.scan(CORPUS_HAN_RUN) }
  next if runs.empty?

  word_counts, char_counts = Segmenter.expectation_maximisation(runs, words, limit, rounds: ROUNDS)
  Corpus.say(
    format(
      "%-18s %-14s runs %8d  tokens %9d  distinct %6d",
      slug,
      register,
      runs.length,
      word_counts.each_value.sum,
      word_counts.size
    )
  )
  [slug, register, word_counts, char_counts]
end

by_register = Hash.new { |memo, key| memo[key] = [Hash.new(0), Hash.new(0)] }
per_corpus.each do |_, register, word_counts, char_counts|
  target_words, target_chars = by_register[register]
  merge!(target_words, word_counts)
  merge!(target_chars, char_counts)
end

by_register.sort.each do |register, (word_counts, char_counts)|
  total = word_counts.each_value.sum + char_counts.each_value.sum
  payload = {
    "chars" => per_million(char_counts, total).sort.to_h,
    "sources" => per_corpus.filter_map { |slug, name, _, _| slug if name == register },
    "tokens" => total,
    "words" => per_million(word_counts, total).sort.to_h
  }
  Corpus.write_json(Corpus.data("#{OUT_DIR}/#{register}.json"), payload)
  Corpus.report("-> #{register}.json", words: payload["words"].size, tokens: total)
end

total_all = per_corpus.sum { |_, _, word_counts, char_counts| word_counts.each_value.sum + char_counts.each_value.sum }
sizes = per_corpus.to_h { |slug, _, word_counts, char_counts|
  [slug, (word_counts.each_value.sum + char_counts.each_value.sum) / total_all.to_f]
}

raw = {"words" => Hash.new(0), "chars" => Hash.new(0)}
spread = {"words" => {}, "chars" => {}}

per_corpus.each do |slug, _, word_counts, char_counts|
  {"words" => word_counts, "chars" => char_counts}.each do |kind, counts|
    counts.each do |token, count|
      raw[kind][token] += count
      (spread[kind][token] ||= {})[slug] = count
    end
  end
end

dispersion = {"words" => {}, "chars" => {}}
spread.each do |kind, tokens|
  tokens.each do |token, parts|
    total = raw[kind][token].to_f
    shares = parts.transform_values { |count| count / total }
    dispersion[kind][token] = deviation_of_proportions(shares, sizes)
  end
end

mixed = {"words" => Hash.new(0.0), "chars" => Hash.new(0.0)}
used = 0.0

by_register.each do |register, (word_counts, char_counts)|
  weight = WEIGHTS.fetch(register, 0.0)
  total = word_counts.each_value.sum + char_counts.each_value.sum
  next if weight.zero? || total.zero?

  used += weight
  scale = weight / total
  {"words" => word_counts, "chars" => char_counts}.each do |kind, counts|
    counts.each { |token, count| mixed[kind][token] += count * scale }
  end
end

entries = mixed.to_h { |kind, counts|
  [
    kind,
    counts.to_h { |token, value|
      frequency = [Corpus.python_round(value / used * 1_000_000), 1].max
      deviation = dispersion[kind].fetch(token, 1.0)
      [
        token,
        {"f" => frequency, "dp" => deviation.round(3), "u" => [Corpus.python_round(frequency * (1 - deviation)), 1].max}
      ]
    }
  ]
}

def column(entries, kind, key) = entries[kind].to_h { |token, entry| [token, entry[key]] }.sort.to_h

payload = {
  "adjusted" => {"chars" => column(entries, "chars", "u"), "words" => column(entries, "words", "u")},
  "chars" => column(entries, "chars", "f"),
  "dispersion" => {"chars" => column(entries, "chars", "dp"), "words" => column(entries, "words", "dp")},
  "words" => column(entries, "words", "f")
}

target = Corpus.write_json(Corpus.data(OUT_FILE), payload)

Corpus.say("")
Corpus.report("combined model", words: entries["words"].size, characters: entries["chars"].size, path: target.basename)
applied = by_register.keys.to_h { |register| [register, WEIGHTS.fetch(register, 0.0)] }.reject { |_, value|
  value.zero?
}
Corpus.say("production: #{PRODUCTION.join(", ")}")
Corpus.say(
  "weights: " +
    applied.sort_by { |_, value| -value }.map { |key, value| format("%s %.3f", key, value / used) }.join(", ")
)
Corpus.say("")
Corpus.say("top 15 by raw frequency:")
entries["words"].max_by(15) { |_, entry| entry["f"] }.each do |token, entry|
  Corpus.say("  #{token}\tf=#{entry["f"]}\tDP=#{entry["dp"]}\tU=#{entry["u"]}")
end

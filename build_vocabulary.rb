#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "lib/corpus"

MAX_LENGTH = 8
MIN_COMPOSITE = 3
LEVELS = %w[app concised full].freeze

level = ENV.fetch("VOCAB_LEVEL", "app")
abort("VOCAB_LEVEL must be one of #{LEVELS.join(", ")}") unless LEVELS.include?(level)

def headwords(path, key)
  return Set.new unless File.exist?(path)

  Corpus
    .read_json(path)
    .filter_map { |row| row[key] }
    .select { |text| text.match?(Corpus::HAN) && (2..MAX_LENGTH).cover?(text.length) }
    .to_set
end

def composite?(word, known)
  (1...word.length).any? { |cut| known.include?(word[0, cut]) && known.include?(word[cut..]) }
end

def keepable(added, known)
  added.reject { |word| word.length >= MIN_COMPOSITE && composite?(word, known) }
end

def entries(value) = (value.is_a?(Hash) ? value.keys : Array(value)).to_set

base = Corpus.read_json(Corpus.corpora("dict.json"))
words = entries(base.fetch("words"))
chars = entries(base.fetch("chars"))
Corpus.report("application dictionary", words: words.size, characters: chars.size)

supplement = Corpus.data("huayu/segmentation_vocab.json")
if supplement.exist?
  added = entries(Corpus.read_json(supplement).fetch("words"))
    .select { |text| (2..MAX_LENGTH).cover?(text.length) }
  words.merge(added)
  Corpus.report("+ runtime supplement", headwords: added.size, words: words.size)
end

known = words | chars

if %w[concised full].include?(level)
  added = headwords(Corpus.corpora("concised.json"), "word")
  words.merge(keepable(added, known))
  Corpus.report("+ MOE concise", headwords: added.size, words: words.size)
end

if level == "full"
  added = headwords(Corpus.corpora("moedict/dict-revised.json"), "title")
  words.merge(keepable(added, known))
  Corpus.report("+ MOE revised", headwords: added.size, words: words.size)
end

words.each { |word| chars.merge(word.chars) }

target = Corpus.write_json(
  Corpus.corpora("segvocab.json"),
  {"words" => words.sort, "chars" => chars.sort, "level" => level}
)

Corpus.report("written", words: words.size, characters: chars.size, path: target.basename)

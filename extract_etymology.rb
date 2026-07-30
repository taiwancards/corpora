#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "lib/corpus"

FOREIGN_TAGS = %w[
  Mainland-China
  mainland-China
  Singapore
  Malaysia
  Hong-Kong
  Cantonese
  Hokkien
  Teochew
  Hakka
  Wu
  Min-Nan
  Simplified-Chinese
  simplified
]
  .to_set
  .merge(["Mainland China", "Hong Kong"])
  .freeze

REGIONAL_NOTE = /\A[[:space:]]*The (Malaysian|Singaporean|Singapore|Hong Kong|Cantonese|Mainland[- ]China|mainland Chinese|PRC) sense/i

LEADING_MARKUP = /\A[[:space:]\]\[|}{*#:;]+/
HAN = /[\u{4E00}-\u{9FFF}]/

source = Corpus.corpora("wiktionary/zh.jsonl")
dictionary = Corpus.corpora("dict.json")

abort("missing #{source}") unless source.exist?
abort("missing #{dictionary} — run export_dict first") unless dictionary.exist?

base = Corpus.read_json(dictionary)
ours = base.fetch("words").keys.to_set | base.fetch("chars").keys.to_set
Corpus.report("our dictionary", entries: ours.size)

def foreign?(entry)
  %w[tags categories topics].any? do |key|
    Array(entry[key]).any? do |value|
      name = value.is_a?(Hash) ? value["name"] : value
      name && FOREIGN_TAGS.include?(name.to_s)
    end
  end
end

result = {}
seen = 0
not_ours = foreign = no_etymology = mainland_text = 0

source.each_line do |line|
  entry = begin
    JSON.parse(line)
  rescue JSON::ParserError
    next
  end

  seen += 1
  word = entry["word"]

  if word.nil? || !ours.include?(word) || !word.match?(HAN)
    not_ours += 1
    next
  end

  if foreign?(entry)
    foreign += 1
    next
  end

  text = Corpus.strip(entry["etymology_text"].to_s.sub(LEADING_MARKUP, ""))
  if text.empty?
    no_etymology += 1
    next
  end

  if text.match?(REGIONAL_NOTE)
    mainland_text += 1
    next
  end

  current = result[word]
  result[word] = {"text" => text, "pos" => entry["pos"]} if current.nil? || text.length > current["text"].length
end

target = Corpus.write_json(Corpus.corpora("etymology.json"), result)

Corpus.report("entries scanned", total: seen)
Corpus.report("  not in our dictionary", count: not_ours)
Corpus.report("  foreign labels", count: foreign)
Corpus.report("  mainland wording", count: mainland_text)
Corpus.report("  no etymology", count: no_etymology)
Corpus.report("ETYMOLOGIES", collected: result.size, path: target.basename)

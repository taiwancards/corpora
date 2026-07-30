#!/usr/bin/env ruby
# frozen_string_literal: true

require "roo"

require_relative "lib/origin_filter"

SENSE_SPLIT = /(?:\A|\n|　|[[:space:]])*◎(?:[[:space:]]|　)*|(?:\A|\n)[[:space:]]*[[:digit:]]+\.|(?:\A|\n|　|[[:space:]])*[（(][[:space:]]*[[:digit:]]+[[:space:]]*[)）][[:space:]]*/
EXAMPLE_MARK = "[例]"
SENT_END = /[。！？]/
LEAD_JUNK = /\A[[:space:]◎△▲＊*※]*(?:[（(][[:space:]]*[[:digit:]]+[[:space:]]*[)）]|[[:digit:]]+[.、])?[[:space:]]*/
ORPHAN_QUOTE = /\A[」』]+|[「『]+\z/
COLUMNS = {word: "字詞名", gloss: "釋義", zhuyin: "注音一式", pinyin: "漢語拼音"}.freeze

def clean(text) = Corpus.strip(text.to_s.gsub("_x000D_", "\n").tr("\r", "\n"))

def tidy(text) = Corpus.strip(Corpus.strip(text).sub(LEAD_JUNK, "").gsub(ORPHAN_QUOTE, ""))

def han_length(text) = text.unpack("U*").count { |code| code >= 0x4E00 && code <= 0x9FFF }

def split_senses(gloss)
  clean(gloss).then { |text| text.empty? ? [] : text.split(SENSE_SPLIT) }.filter_map { |part|
    Corpus.strip(part).presence
  }
end

def split_examples(sense)
  return [Corpus.strip(sense), []] unless sense.include?(EXAMPLE_MARK)

  definition, _, tail = sense.partition(EXAMPLE_MARK)

  items = tail
    .split("\n")
    .flat_map { |chunk|
      stripped = Corpus.strip(chunk)
      next [] if stripped.empty?

      if stripped.match?(SENT_END)
        stripped.split(/(?<=[。！？])/)
      else
        stripped.split("、")
      end
    }
    .filter_map { |piece| Corpus.strip(piece).presence }

  [Corpus.strip(definition), items]
end

def usable?(item)
  length = han_length(item)
  return false if length < 2
  return false if length.fdiv([item.length, 1].max) < 0.6

  !item.start_with?("（", "(")
end

source = Pathname(ENV.fetch("CONCISED_XLSX") { Corpus.corpora("moedict/dict_concised.xlsx").to_s })
abort("missing #{source}") unless source.exist?

sheet = Roo::Excelx.new(source.to_s)
sheet.default_sheet = sheet.sheets.first
header = sheet.row(1)
index = COLUMNS.transform_values { |name| header.index(name) or abort("no column #{name}") }

entries = []
sentences_total = collocations_total = dropped = 0

(2..sheet.last_row).each do |number|
  row = sheet.row(number)
  word = row[index[:word]]
  gloss = row[index[:gloss]]
  next if word.nil? || gloss.nil?

  senses = split_senses(gloss.to_s).filter_map do |raw|
    definition, items = split_examples(raw)
    next if items.empty? && definition.end_with?("：", ":")

    sentences, collocations = [], []

    items.map { |item| tidy(item) }.each do |item|
      next unless usable?(item)

      unless OriginFilter.keep?(item)
        dropped += 1
        next
      end

      (item.match?(SENT_END) || han_length(item) >= 8 ? sentences : collocations) << item
    end

    sentences_total += sentences.length
    collocations_total += collocations.length
    {"definition" => definition, "sentences" => sentences, "collocations" => collocations}
  end

  next if senses.empty?

  entries <<
    {
      "word" => word.to_s,
      "zhuyin" => row[index[:zhuyin]],
      "pinyin" => row[index[:pinyin]],
      "senses" => senses
    }
end

target = Corpus.write_json(Corpus.corpora("concised.json"), entries)

multi = entries.count { |entry| entry["senses"].length > 1 }
Corpus.report(
  "entries",
  total: entries.length,
  "with >1 sense": format("%d (%.1f%%)", multi, 100.0 * multi / entries.length)
)
Corpus.report("senses", total: entries.sum { |entry| entry["senses"].length })
Corpus.report("examples", sentences: sentences_total, collocations: collocations_total)
Corpus.report("origin filter", dropped: dropped, path: target.basename)

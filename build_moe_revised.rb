#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "lib/corpus"

SOURCE = Corpus.corpora("moedict/dict-revised.json")
MAX_DEFINITIONS = 4
MAX_LENGTH = 6
PLACEHOLDER = /\{\[[0-9a-f]+\]\}/
HAN = /\A\p{Han}+\z/

raise "#{SOURCE} is missing" unless SOURCE.exist?

def senses(entry)
  Array(entry["heteronyms"])
    .flat_map do |heteronym|
      reading = heteronym["bopomofo"].to_s.strip
      Array(heteronym["definitions"]).map do |definition|
        text = definition["def"].to_s.strip
        next if text.empty?

        {
          "gloss" => text,
          "pos" => definition["type"].to_s.strip.presence,
          "reading" => reading.presence,
          "examples" => Array(definition["example"]).first(2)
        }.compact
      end
    end
    .compact
end

payload = Corpus.read_json(SOURCE)
Corpus.report("source", entries: payload.length)

entries = payload.filter_map do |entry|
  title = entry["title"].to_s.strip
  next if title.empty? || title.match?(PLACEHOLDER) || !title.match?(HAN) || title.length > MAX_LENGTH

  rows = senses(entry).first(MAX_DEFINITIONS)
  next if rows.empty?

  [title, rows]
end

target = Corpus.data("huayu/moe_revised.jsonl")
target.dirname.mkpath
written = 0

target.open("w") do |file|
  entries.sort_by(&:first).each do |title, rows|
    file.puts(JSON.generate({"t" => title, "s" => rows}))
    written += 1
  end
end

Corpus.report("moe revised", kept: written, path: target.basename, bytes: target.size)

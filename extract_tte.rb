#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "lib/sentences"

include(Sentences)

SENTENCE_SPLIT = /(?<=[。！？])/
WIKI = /wikipedia\.org|wikisource\.org|wiktionary\.org/

def documents(path)
  return to_enum(:documents, path) unless block_given?

  path.each_line do |line|
    row = begin
      JSON.parse(line)
    rescue JSON::ParserError
      next
    end

    url = begin
      JSON.parse(row["meta"].to_s.empty? ? "{}" : row["meta"])["url"].to_s
    rescue JSON::ParserError, TypeError
      ""
    end

    next if url.match?(WIKI)

    yield row["text"].to_s
  end
end

cap = Integer(ENV.fetch("TTE_CAP", "36000"))
directory = Corpus.corpora("tte")
files = directory.directory? ? directory.glob("*.jsonl").sort : []

if files.empty?
  Corpus.say("tte_news: no .jsonl files in #{directory}")
  Corpus.say("convert the parquet dumps first, for example:")
  Corpus.say("  duckdb -c \"copy (select meta, text from '#{directory}/*.parquet') to '#{directory}/tte.jsonl'\"")
  exit(0)
end

out = []
seen = Set.new

files.each do |path|
  before = out.length

  documents(path) do |document|
    document.split(SENTENCE_SPLIT).each do |piece|
      text = Corpus.strip(piece)
      next if text.empty? || !seen.add?(text)
      next unless usable?(text)

      out << text
    end
  end

  Corpus.say("  #{path.basename}: +#{out.length - before}")
end

write("tte_news", thin(out, cap))

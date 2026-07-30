#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "lib/corpus"
require_relative "lib/spreadsheet"

SOURCES = {
  "場所標示壓縮檔.zip" => "signage",
  "業務標示壓縮檔.zip" => "counters",
  "漢語文化特色詞條壓縮檔.zip" => "culture",
  "選舉詞彙壓縮檔.zip" => "elections",
  "地方機關首長職稱壓縮檔.zip" => "titles"
}.freeze

HAN = /\A[\u{4E00}-\u{9FFF}\u{3400}-\u{4DBF}]+\z/
MAX_LENGTH = 8
PLACEHOLDER = /[_A-Za-z0-9（）()]/

def header_index(rows)
  head = rows.first || []
  {
    zh: head.index { |cell| cell.to_s.include?("中文") } || 2,
    en: head.index { |cell| cell.to_s.include?("英文") } || 1,
    tag: head.index { |cell| cell.to_s.include?("類別") }
  }
end

def clean(value)
  value.to_s.strip.gsub(/\s+/, "")
end

def usable?(text)
  return false if text.empty? || text.length > MAX_LENGTH
  return false if text.match?(PLACEHOLDER)

  text.match?(HAN)
end

entries = {}
SOURCES.each do |file, domain|
  path = Corpus.corpora("naer/#{file}")
  next Corpus.say("naer: #{file} missing, skipped") unless path.exist?

  rows = Spreadsheet.rows(path)
  index = header_index(rows)
  kept = 0

  rows.drop(1).each do |row|
    zh = clean(row[index[:zh]])
    en = row[index[:en]].to_s.strip
    next unless usable?(zh) && !en.empty?

    entry = entries[zh] ||= {"text" => zh, "en" => en, "domain" => domain, "tags" => []}
    tag = index[:tag] && clean(row[index[:tag]])
    entry["tags"] |= [tag] if tag && !tag.empty?
    kept += 1
  end

  Corpus.report("naer/#{domain}", rows: rows.length - 1, kept:)
end

target = Corpus.write_json(Corpus.data("huayu/naer_terms.json"), entries.values.sort_by { |row| row["text"] })
Corpus.report("naer terms", entries: entries.size, path: target.basename)

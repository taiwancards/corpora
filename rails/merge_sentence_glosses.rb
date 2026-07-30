#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"

language = Language.find_by!(code: "zh-TW")
paths = Dir[Rails.root.join("tmp/translate/sent-out-*.jsonl")].sort
rows = paths.flat_map { |path| File.readlines(path).filter_map { |line| JSON.parse(line) if line.strip.present? } }

known = language.lexemes.where(kind: :sentence, text: rows.map { |row| row["text"] }).pluck(:text).to_set
rejected = Hash.new(0)

entries = rows.filter_map do |row|
  text = row["text"].to_s
  unless known.include?(text)
    rejected[:unknown_sentence] += 1
    next
  end

  if row["en"].to_s.match?(/\p{Han}/) || row["ru"].to_s.match?(/\p{Han}/)
    rejected[:han_in_translation] += 1
    next
  end

  if row["en"].to_s.strip.empty? || row["ru"].to_s.strip.empty?
    rejected[:empty] += 1
    next
  end

  Huayu::SentenceGlossStore::Entry.new(text: text, en: row["en"].strip, ru: row["ru"].strip)
end

added = Huayu::SentenceGlossStore.append(entries)
puts(
  format(
    "files: %d, rows accepted: %d, new entries: %d",
    paths.length,
    entries.length,
    added
  )
)
puts("total in store: #{Huayu::SentenceGlossStore.read.length}")
rejected.each { |reason, count| puts("  rejected (#{reason}): #{count}") }

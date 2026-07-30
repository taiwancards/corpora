#!/usr/bin/env ruby
# frozen_string_literal: true

entries = Huayu::SentenceGlossStore.read
sentences = Lexeme.where(kind: :sentence)
alive = sentences.where(text: entries.map(&:text)).pluck(:text).to_set

rekeyed = 0
dropped = 0

kept = entries.filter_map do |entry|
  next entry if alive.include?(entry.text)

  trimmed = Huayu::SentenceText.trim(entry.text)
  if trimmed != entry.text && sentences.exists?(text: trimmed)
    rekeyed += 1
    next Huayu::SentenceGlossStore::Entry.new(text: trimmed, en: entry.en, ru: entry.ru)
  end

  dropped += 1
  nil
end

Huayu::SentenceGlossStore.write(kept)
puts("rekeyed: #{rekeyed}, dropped with the sentence: #{dropped}, kept: #{kept.length}")

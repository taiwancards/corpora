#!/usr/bin/env ruby
# frozen_string_literal: true

require "rexml/document"

require_relative "lib/segmenter"

WEIGHTS = {"ntpc" => 0.40, "concised" => 0.35, "law" => 0.15, "moe_revised" => 0.10}.freeze
ROUNDS = 3
CORPUS_HAN_RUN = /[\u{4E00}-\u{9FFF}]+/

def law_texts
  path = Corpus.corpora("law/FalV.xml")
  return [] unless path.exist?

  REXML::XPath
    .match(REXML::Document.new(path.read), "//條文內容")
    .filter_map(&:text)
    .flat_map { |content| content.split(Segmenter::SENT_SPLIT) }
    .filter_map { |piece| Corpus.strip(piece).presence }
end

def ntpc_texts
  path = Corpus.corpora("ntpc_sentences.json")
  path.exist? ? Corpus.read_json(path) : []
end

def concised_texts
  path = Corpus.corpora("concised.json")
  return [] unless path.exist?

  Corpus.read_json(path).flat_map { |entry|
    entry.fetch("senses").flat_map { |sense|
      [sense["definition"].presence].compact + sense.fetch("sentences") + sense.fetch("collocations")
    }
  }
end

def moe_revised_texts
  path = Corpus.corpora("moe_examples.json")
  return [] unless path.exist?

  data = Corpus.read_json(path)
  data.fetch("sents").map(&:last) + data.fetch("colloc").keys
end

CORPORA = {
  "law" => method(:law_texts),
  "ntpc" => method(:ntpc_texts),
  "concised" => method(:concised_texts),
  "moe_revised" => method(:moe_revised_texts)
}.freeze

words, chars = Segmenter.vocabulary(Corpus.corpora("segvocab.json"))
limit = Segmenter.max_word(words)

per_corpus = CORPORA.filter_map do |name, source|
  runs = source.call.flat_map { |text| text.scan(CORPUS_HAN_RUN) }
  next Corpus.say("#{name}: no data, skipped") if runs.empty?

  word_counts, char_counts = Segmenter.expectation_maximisation(runs, words, limit, rounds: ROUNDS)
  Corpus.report(name, runs: runs.length, tokens: word_counts.each_value.sum)
  [name, word_counts, char_counts]
end

words_out = Hash.new(0.0)
chars_out = Hash.new(0.0)

per_corpus.each do |name, word_counts, char_counts|
  weight = WEIGHTS.fetch(name, 0.0)
  total = word_counts.each_value.sum + char_counts.each_value.sum
  next if total.zero?

  scale = weight / total
  word_counts.each { |token, count| words_out[token] += count * scale }
  char_counts.each { |token, count| chars_out[token] += count * scale }
end

def per_million(table)
  table
    .transform_values { |value| [Corpus.python_round(value * 1_000_000), 1].max }
    .sort
    .to_h
end

payload = {"chars" => per_million(chars_out), "words" => per_million(words_out)}
target = Corpus.write_json(Corpus.data("huayu/corpus_frequency.json"), payload)

Corpus.report("model", words: payload["words"].size, characters: payload["chars"].size, path: target.basename)
Corpus.say("")
Corpus.say("top 25 words:")
payload["words"].max_by(25) { |_, value| value }.each { |token, value| Corpus.say("  #{token}\t#{value}") }

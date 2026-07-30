#!/usr/bin/env ruby
# frozen_string_literal: true

require "csv"
require "cgi"

require_relative "lib/origin_filter"

TAG = /<[^>]+>/
SPACE = /[ \t　 ]+/
BREAK = %r{<br\s*/?>|</p>}i
HAN = /[\u{4E00}-\u{9FFF}]/
TERMINAL = %w[。 ！ ？].freeze

BOILERPLATE = %w[
  新北市訊
  新北市政府
  訊】
  詳情請洽
  更多訊息
  請上網查詢
  資料來源
  新聞聯絡人
  聯絡電話
  業務承辦
  如有疑問
]
  .freeze

def strip_html(text)
  CGI.unescapeHTML(text.to_s).gsub(BREAK, "\n").gsub(TAG, "").gsub(SPACE, " ")
end

def han_length(text) = text.unpack("U*").count { |code| code >= 0x4E00 && code <= 0x9FFF }

def sentences_from(text)
  return to_enum(:sentences_from, text) unless block_given?

  strip_html(text).each_line do |line|
    line.chomp.split(/(?<=[。！？])/).each do |raw|
      candidate = raw.strip
      next if candidate.empty?
      next unless TERMINAL.any? { |mark| candidate.end_with?(mark) }
      next if candidate[0, [candidate.length / 2, 8].max].include?("：")

      han = han_length(candidate)
      next unless (10..60).cover?(han)
      next if han.fdiv([candidate.length, 1].max) < 0.72
      next if BOILERPLATE.any? { |mark| candidate.include?(mark) }

      yield candidate
    end
  end
end

seen = Set.new
kept = []
dropped = Hash.new(0)
total = 0

%w[news.csv activities.csv].each do |name|
  path = Corpus.corpora("ntpc/#{name}")
  next Corpus.say("missing: #{path}") unless path.exist?

  CSV.foreach(path, headers: true, encoding: "bom|utf-8") do |row|
    body = row["Content"]
    next if body.nil? || body.empty?

    sentences_from(body) do |sentence|
      total += 1
      next unless seen.add?(sentence)

      verdict = OriginFilter.inspect_text(sentence)
      if verdict.ok
        kept << sentence
      else
        verdict.reasons.each { |reason| dropped[reason.split(":").first] += 1 }
      end
    end
  end
end

target = Corpus.write_json(Corpus.corpora("ntpc_sentences.json"), kept)

lengths = kept.map { |sentence| han_length(sentence) }.sort
Corpus.report("sentences", total: total, unique: seen.size)
Corpus.report("passed the filter", kept: kept.size, share: format("%.2f%%", 100.0 * kept.size / [seen.size, 1].max))
dropped.sort_by { |_, count| -count }.each { |reason, count| Corpus.say("  dropped [#{reason}]: #{count}") }
Corpus.report("median han length", value: lengths.empty? ? 0 : lengths[lengths.length / 2], path: target.basename)

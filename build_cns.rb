#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "lib/corpus"

ROOT = Corpus.corpora("cns11643")
UNICODE_FILES = %w[
  CNS2UNICODE_Unicode_BMP.txt
  CNS2UNICODE_Unicode_2.txt
  CNS2UNICODE_Unicode_3.txt
  CNS2UNICODE_Unicode_15.txt
]
  .freeze

def read_pairs(name)
  path = ROOT.join(name)
  return {} unless path.exist?

  path.each_line.with_object({}) do |line, memo|
    code, *rest = line.split("\t").map(&:strip)
    next if code.nil? || rest.empty?

    memo[code] = rest
  end
end

def unicode_index
  UNICODE_FILES.each_with_object({}) do |name, memo|
    read_pairs(name).each do |code, values|
      point = values.first.to_s
      next unless point.match?(/\A[0-9A-F]{4,6}\z/)

      memo[code] ||= [point.to_i(16)].pack("U")
    end
  end
end

chars = unicode_index
Corpus.report("cns2unicode", codes: chars.size)

strokes = read_pairs("CNS_stroke.txt").transform_values { |values| values.first.to_i }
sequences = read_pairs("CNS_strokes_sequence.txt").transform_values(&:first)

wanted = Corpus.read_json(Corpus.data("huayu/moe4808.json")).to_set
next_tier = Corpus.data("huayu/moe_next6343.json")
wanted.merge(Corpus.read_json(next_tier)) if next_tier.exist?

payload = {}
chars.each do |code, char|
  next unless wanted.include?(char)

  total = strokes[code]
  next if total.nil? || total.zero?

  payload[char] = [total, sequences[code]].compact
end

target = Corpus.write_json(Corpus.data("huayu/cns_strokes.json"), payload.sort.to_h)
Corpus.report(
  "cns_strokes",
  characters: payload.size,
  with_sequence: payload.count { |_, entry| entry.length > 1 },
  path: target.basename
)

voice = Corpus.app_root.join("media/cns_voice/syllables.txt")
if voice.exist?
  table = voice.each_line.with_object({}) do |line, memo|
    bopomofo, pinyin = line.strip.split("\t")
    next unless bopomofo&.match?(/[ㄅ-ㄩ]/) && pinyin&.match?(/\A[a-z]+[1-5]?\z/)

    memo[bopomofo] = pinyin
  end

  written = Corpus.write_json(Corpus.data("huayu/cns_voice.json"), table.sort.to_h)
  Corpus.report("cns_voice", syllables: table.size, path: written.basename)
else
  Corpus.say("cns_voice: #{voice} is missing, skipped")
end

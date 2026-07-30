#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "lib/corpus"
require_relative "lib/spreadsheet"

CNS = Corpus.corpora("cns11643")
CCR = Corpus.corpora("ccr")
GUANGYUN = "020"

MIN_MEMBERS = 4
MIN_REGULARITY = 0.5
KEEP_SERIES = 400
NEIGHBOURS = 8
MIN_SIMILARITY = 0.34
TONE_MARKS = "ˊˇˋ˙"

UNICODE_FILES = %w[
  CNS2UNICODE_Unicode_BMP.txt
  CNS2UNICODE_Unicode_2.txt
  CNS2UNICODE_Unicode_3.txt
  CNS2UNICODE_Unicode_15.txt
]
  .freeze

def pairs(name)
  path = CNS.join(name)
  return {} unless path.exist?

  path.each_line.with_object({}) do |line, memo|
    code, *rest = line.split("\t").map(&:strip)
    memo[code] = rest unless code.nil? || rest.empty?
  end
end

def unicode_index
  UNICODE_FILES.each_with_object({}) do |name, memo|
    pairs(name).each do |code, values|
      point = values.first.to_s
      memo[code] ||= [point.to_i(16)].pack("U") if point.match?(/\A[0-9A-F]{4,6}\z/)
    end
  end
end

def guangyun
  archive = CCR.join("ccr03_yunshu_data_xlsx.zip")
  return {} unless archive.exist?

  member = Zip::File.open(archive) { |zip| zip.find { |entry| entry.name.include?(GUANGYUN) }&.name }
  return {} if member.nil?

  payload = Zip::File.open(archive) { |zip| zip.find_entry(member).get_input_stream.read }
  rows = Spreadsheet.xlsx_rows(payload)
  head = rows.first
  glyph = head.index("字")
  group = head.index("攝")
  rhyme = head.index("韻目")
  initial = head.index("字母")

  rows.drop(1).each_with_object({}) do |row, memo|
    char = row[glyph].to_s.strip
    next if char.empty? || memo.key?(char)

    memo[char] = {
      "group" => row[group].to_s.strip,
      "rhyme" => row[rhyme].to_s.strip,
      "initial" => row[initial].to_s.strip
    }
  end
end

def modal(values)
  counts = values.compact.reject(&:empty?).tally
  return [nil, 0.0] if counts.empty?

  top, hits = counts.max_by { |_, count| count }
  [top, hits.fdiv(values.length)]
end

def decompositions
  path = Corpus.corpora("../dictionaries/makemeahanzi/dictionary.txt")
  return {} unless path.exist?

  path.each_line.with_object({}) do |line, memo|
    row = JSON.parse(line)
    glyph = row["character"].to_s
    parts = row["decomposition"].to_s.chars.select { |char| char.match?(/\p{Han}/) } - [glyph]
    memo[glyph] = parts.uniq if parts.any?
  rescue JSON::ParserError
    next
  end
end

chars = unicode_index
components = pairs("CNS_component.txt").transform_values { |values| values.first.to_s.split(",") }
reference = pairs("CNS_component_ref.txt").each_with_object({}) do |(id, values), memo|
  memo[id] = values.last if values.last.to_s.length == 1
end

phonetics = pairs("CNS_phonetic.txt").transform_values { |values| values.last.to_s }
radicals = pairs("CNS_radical.txt").transform_values { |values| values.first.to_s }
sounds = guangyun
Corpus.report("sources", characters: chars.size, guangyun: sounds.size, components: components.size)

wanted = Corpus.read_json(Corpus.data("huayu/moe4808.json")).to_set
parts_of = {}
reading_of = {}
radical_of = {}

chars.each do |code, char|
  next unless wanted.include?(char)

  parts = Array(components[code]).filter_map { |id| reference[id] }.reject { |glyph| glyph == char }
  parts_of[char] = parts if parts.any?
  reading = phonetics[code].to_s
  reading_of[char] = reading if reading.match?(/[ㄅ-ㄩ]/)
  radical_of[char] = radicals[code]
end

Corpus.report("covered", with_parts: parts_of.size, with_reading: reading_of.size)

ids = decompositions
Corpus.report("decompositions", entries: ids.size)

members = Hash.new { |memo, key| memo[key] = [] }
ids.each do |char, parts|
  next unless wanted.include?(char)

  parts.each { |part| members[part] << char }
end

series = members.filter_map do |component, group|
  next if group.length < MIN_MEMBERS

  sounded = group.select { |char| sounds.key?(char) }
  next if sounded.length < MIN_MEMBERS

  group_name, regularity = modal(sounded.map { |char| sounds[char]["group"] })
  next if group_name.nil? || regularity < MIN_REGULARITY

  rhyme, _ = modal(sounded.map { |char| sounds[char]["rhyme"] })

  rimes = group.filter_map { |char| reading_of[char]&.delete(TONE_MARKS)&.slice(1..) }
  rime, payoff = modal(rimes)

  {
    "component" => component,
    "members" => group.sort,
    "group" => group_name,
    "rhyme" => rhyme,
    "regularity" => regularity.round(3),
    "rime" => rime,
    "payoff" => payoff.round(3),
    "size" => group.length
  }
end

series = series.sort_by { |row| [-(row["regularity"] * row["size"]), row["component"]] }.first(KEEP_SERIES)
target = Corpus.write_json(Corpus.data("huayu/phonetic_series.json"), series)
Corpus.report(
  "phonetic series",
  kept: series.length,
  median_regularity: series.map { |row| row["regularity"] }.sort[series.length / 2],
  path: target.basename
)

document_frequency = Hash.new(0)
parts_of.each_value { |parts| parts.uniq.each { |part| document_frequency[part] += 1 } }
total = parts_of.size.to_f
weight = document_frequency.transform_values { |count| Math.log(total / count) }

buckets = Hash.new { |memo, key| memo[key] = [] }
parts_of.each do |char, parts|
  rare = parts.uniq.min_by { |part| document_frequency[part] }
  buckets[rare] << char
end

confusable = {}
buckets.each_value do |group|
  next if group.length < 2

  group.each do |char|
    mine = parts_of[char].uniq
    scored = group.filter_map do |other|
      next if other == char

      theirs = parts_of[other].uniq
      shared = (mine & theirs).sum { |part| weight[part] }
      union = (mine | theirs).sum { |part| weight[part] }
      next if union.zero?

      score = shared / union
      next if score < MIN_SIMILARITY

      [other, score.round(3)]
    end

    next if scored.empty?

    confusable[char] = scored.sort_by { |(_, score)| -score }.first(NEIGHBOURS)
  end
end

written = Corpus.write_json(Corpus.data("huayu/confusable_characters.json"), confusable.sort.to_h)
Corpus.report(
  "confusable",
  characters: confusable.size,
  pairs: confusable.values.sum(&:size),
  path: written.basename
)

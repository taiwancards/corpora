# frozen_string_literal: true

require_relative "lib/corpus"
require_relative "lib/japanese_bridge"

UNIHAN = Corpus.corpora("unihan")
OPENCC = Corpus.corpora("opencc")
CNS = Corpus.corpora("cns11643")
TARGET = Corpus.data("huayu/japanese_bridge.json")
COMMON = Corpus.data("huayu/moe4808.json")

UNIHAN_FIELDS = {
  "Unihan_Readings.txt" => %w[kJapanese],
  "Unihan_Variants.txt" => %w[kJapaneseNewVariant kZVariant],
  "Unihan_OtherMappings.txt" => %w[kJoyoKanji kJinmeiyoKanji],
  "Unihan_IRGSources.txt" => %w[kTotalStrokes]
}.freeze

CNS_FILES = %w[
  CNS2UNICODE_Unicode_BMP.txt
  CNS2UNICODE_Unicode_2.txt
  CNS2UNICODE_Unicode_15.txt
].freeze

def glyph(code) = [code.delete_prefix("U+").to_i(16)].pack("U")

def unihan
  fields = Hash.new { |memo, key| memo[key] = {} }
  UNIHAN_FIELDS.each do |name, wanted|
    UNIHAN.join(name).each_line do |line|
      next if line.start_with?("#")

      code, field, value = line.chomp.split("\t", 3)
      next unless wanted.include?(field)

      fields[field][glyph(code)] = value
    end
  end

  fields
end

def variant_list(value) = value.to_s.split.map { |item| glyph(item.split("<").first) }

def opencc(name)
  OPENCC.join(name).each_line.each_with_object({}) do |line, memo|
    next if line.start_with?("#") || !line.include?("\t")

    key, values = line.chomp.split("\t", 2)
    memo[key] = values.split
  end
end

def cns_pairs(name)
  CNS.join(name).each_line.each_with_object({}) do |line, memo|
    code, *rest = line.split("\t").map(&:strip)
    memo[code] = rest unless code.nil? || rest.empty?
  end
end

def cns_components
  chars = CNS_FILES.each_with_object({}) do |name, memo|
    cns_pairs(name).each { |code, values| memo[code] ||= [values.first.to_i(16)].pack("U") }
  end

  lists = cns_pairs("CNS_component.txt")
  chars.each_with_object({}) do |(code, char), memo|
    ids = lists[code]&.first.to_s.split(",")
    memo[char] ||= ids unless ids.nil? || ids.empty?
  end
end

def ids_parts(text, ids) = ids.to_s.scan(Corpus::HAN_CHAR).uniq - [text]

fields = Corpus.timed("unihan") { unihan }
components = Corpus.timed("cns components") { cns_components }
jp_variants = opencc("JPVariants.txt")
shinjitai = opencc("JPShinjitaiCharacters.txt").each_with_object({}) do |(new_form, old_forms), memo|
  old_forms.each { |old| memo[old] ||= new_form unless old == new_form }
end

joyo = fields["kJoyoKanji"].keys.to_set
partners = fields["kJinmeiyoKanji"].transform_values { |value| value[/U\+\h+/]&.then { |code| glyph(code) } }
jinmei_old = partners.select { |_, partner| joyo.include?(partner) }
jinmei_plain = partners.keys - jinmei_old.keys
taiwan = opencc("TWVariants.txt").each_with_object({}) do |(standard, forms), memo|
  forms.each { |form| memo[form] ||= standard unless form == standard }
end

strokes = fields["kTotalStrokes"].transform_values { |value| value.split.first.to_i }
onyomi = fields["kJapanese"].transform_values { |value| JapaneseBridge::Kana.onyomi(value) }
Corpus.report("japanese sets", joyo: joyo.size, jinmei: jinmei_plain.size, jinmei_old: jinmei_old.size)

forms = JapaneseBridge::Forms.new(
  joyo:,
  jinmei: jinmei_plain,
  jinmei_old:,
  new_variants: fields["kJapaneseNewVariant"].transform_values { |value| variant_list(value).first },
  opencc: jp_variants.transform_values(&:first),
  taiwan:,
  shinjitai:,
  z_variants: fields["kZVariant"].transform_values { |value| variant_list(value) }
)

decompositions = Lexeme.where(kind: :character).pluck(:text, Arel.sql("data->>'decomposition'")).to_h
parts = decompositions.to_h { |text, ids| [text, ids_parts(text, ids)] }
common = Corpus.read_json(COMMON).to_set

rows = Lexeme
  .where(kind: :character)
  .where("level_index IS NOT NULL OR text IN (?)", common.to_a)
  .pluck(:text, :readings, :level_index, :freq_rank)
  .map { |text, readings, level, rank|
    {text:, zhuyin: readings["zhuyin"].to_s, pinyin: readings["pinyin"].to_s, level:, rank:}
  }
  .sort_by { |row| [row[:level] || 99, row[:rank] || Float::INFINITY, row[:text]] }
Corpus.report("characters", taught: rows.size, leveled: rows.count { |row| row[:level] })

order = rows.each_with_index.to_h { |row, index| [row[:text], index] }
resolved = rows.to_h { |row| [row[:text], forms.counterpart(row[:text])] }
pairs = resolved.filter_map { |text, (jp, relation)| [text, jp] if relation == JapaneseBridge::Forms::DIFFERS }.to_h

bridge = JapaneseBridge::Patterns.new(
  pairs:,
  components:,
  parts:,
  strokes:,
  counterpart: -> (char) {
    forms.counterpart(char).then { |jp, relation| jp if relation == JapaneseBridge::Forms::DIFFERS }
  }
)
patterns = bridge
  .patterns(order: -> (char) { order.fetch(char, Float::INFINITY) })
  .sort_by { |pattern| [-pattern["members"].length, order.fetch(pattern["id"], Float::INFINITY), pattern["id"]] }
pattern_of = patterns.each_with_object({}) { |pattern, memo|
  pattern["members"].each { |char| memo[char] = pattern["id"] }
}

characters = rows.to_h do |row|
  jp, relation = resolved[row[:text]]
  entry = {"jp" => jp, "relation" => relation, "level" => row[:level]}
  entry["on"] = Array(onyomi[jp] || onyomi[row[:text]]).first if jp
  entry["pattern"] = pattern_of[row[:text]] if pattern_of.key?(row[:text])
  entry["small"] = true if relation == JapaneseBridge::Forms::DIFFERS && bridge.small?(row[:text], jp)
  [row[:text], entry.compact]
end

measured = rows.filter_map do |row|
  jp, relation = resolved[row[:text]]
  next if row[:level].nil? || relation == JapaneseBridge::Forms::UNUSED

  on = Array(onyomi[jp] || onyomi[row[:text]]).first
  next if on.nil?

  JapaneseBridge::Correspondence::Row.new(
    char: row[:text],
    on:,
    zhuyin: row[:zhuyin],
    pinyin: row[:pinyin],
    rank: row[:rank]
  )
end

readings = JapaneseBridge::Correspondence.new(measured).summary

relations = characters.values.map { |entry| entry["relation"] }.tally
patterned = pattern_of.size
counts = {
  "characters" => characters.size,
  "leveled" => rows.count { |row| row[:level] },
  "same" => relations.fetch("same", 0),
  "differs" => relations.fetch("differs", 0),
  "unused" => relations.fetch("unused", 0),
  "small" => characters.values.count { |entry| entry["small"] },
  "patterns" => patterns.size,
  "patterned" => patterned,
  "singletons" => pairs.size - patterned,
  "measured" => readings["characters"]
}
Corpus.report("bridge", **counts.transform_values(&:to_s))

payload = {"counts" => counts, "patterns" => patterns, "readings" => readings, "characters" => characters}
Corpus.write_json(TARGET, payload, pretty: true)
Corpus.say("wrote #{TARGET}")

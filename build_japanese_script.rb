# frozen_string_literal: true

require_relative "lib/corpus"

UNIHAN = Corpus.corpora("unihan", "Unihan_OtherMappings.txt")
TAIWAN = %w[huayu/moe4808.json huayu/moe_next6343.json].map { |name| Corpus.data(name) }.freeze
TARGET = Corpus.data("huayu/japanese_script.json")
BRIDGE = Corpus.data("huayu/japanese_bridge.json")
VARIANTS = Corpus.corpora("opencc", "JPVariants.txt")
MARKS = %w[々 〆].freeze

def glyph(code) = [code.delete_prefix("U+").to_i(16)].pack("U")

joyo = {}
jinmei = {}
everyday = []
UNIHAN.each_line do |line|
  next if line.start_with?("#")

  code, field, value = line.chomp.split("\t", 3)
  partner = value.to_s[/U\+\h+/]&.then { |found| glyph(found) }
  case field
  when "kJoyoKanji"
    joyo[glyph(code)] = partner
  when "kJinmeiyoKanji"
    jinmei[glyph(code)] = partner
  when "kJis0"
    everyday << glyph(code) if (16..47).cover?(value.to_s[0, 2].to_i)
  end
end

allowed = joyo.keys +
  joyo.values.compact +
  jinmei.reject { |_, partner| partner && joyo.key?(partner) }.keys +
  everyday
japanese = (allowed.uniq + MARKS).sort
taiwan = TAIWAN.flat_map { |path| Corpus.read_json(path) }.to_set
japanese_only = japanese.reject { |char| taiwan.include?(char) }

bridged = Corpus.read_json(BRIDGE).fetch("characters", {}).select { |_, entry| entry["relation"] == "differs" }.keys
variants = VARIANTS.each_line.filter_map do |line|
  key, value = line.chomp.split("\t", 2)
  key if value && !line.start_with?("#") && value.split.first != key
end

known = japanese.to_set
differs = (bridged + variants).uniq.reject { |char| known.include?(char) }.sort

payload = {"japanese" => japanese.join, "japanese_only" => japanese_only.join, "differs" => differs.join}
Corpus.write_json(TARGET, payload, pretty: true)
Corpus.report(
  "japanese script",
  japanese: japanese.size.to_s,
  japanese_only: japanese_only.size.to_s,
  differs: differs.size.to_s
)
Corpus.say("wrote #{TARGET}")

# frozen_string_literal: true

require "json"

root = File.expand_path("..", __dir__)
path = File.join(root, "data/huayu/grammar_lessons.json")
lessons = JSON.parse(File.read(path))

han = /\p{Han}/
run = /\p{Han}(?:[\p{Han}，、：；]*\p{Han})?/

runs_in = lambda do |lesson|
  sources = [lesson["pattern"], lesson["head"]] +
    %w[en ru].flat_map { |locale| lesson[locale].values_at("title", "body", "tip") }
  sources.compact.flat_map { |text| text.scan(run) }.map { |text| text.gsub(/\P{Han}/, "") }.reject(&:empty?).uniq
end

wanted = lessons.flat_map { |lesson| runs_in.call(lesson) }.uniq

chunks = wanted.flat_map do |piece|
  (1..piece.length).flat_map { |length| (0..piece.length - length).map { |start| piece[start, length] } }
end.uniq

vocab = {}
chunks.each_slice(5000) do |slice|
  Lexeme.where(kind: %i[word character], text: slice).where.not(readings: {}).each do |lexeme|
    vocab[lexeme.text] ||= lexeme
  end
end

preferred = {
  "嗎" => ["˙ㄇㄚ", "ma"],
  "呢" => ["˙ㄋㄜ", "ne"],
  "吧" => ["˙ㄅㄚ", "ba"],
  "啊" => ["˙ㄚ", "a"],
  "的" => ["˙ㄉㄜ", "de"],
  "了" => ["˙ㄌㄜ", "le"],
  "個" => ["˙ㄍㄜ", "ge"],
  "誰" => ["ㄕㄟˊ", "shéi"],
  "和" => ["ㄏㄢˋ", "hàn"]
}

reading_of = lambda do |lexeme, key|
  set = lexeme.reading_set.first || {}
  set[key].to_s.split(/[[:space:]]+/).reject(&:empty?)
end

segment = lambda do |piece|
  parts = []
  index = 0
  while index < piece.length
    length = [4, piece.length - index].min
    length -= 1 while length > 1 && vocab[piece[index, length]].nil?
    parts << piece[index, length]
    index += length
  end
  parts
end

reading = lambda do |text|
  zhuyin = []
  pinyin = []
  text.scan(/\p{Han}+/).each do |piece|
    segment.call(piece).each do |part|
      if (override = preferred[part])
        zhuyin << override[0]
        pinyin << override[1]
        next
      end

      lexeme = vocab[part]
      z = lexeme ? reading_of.call(lexeme, "zhuyin") : []
      p = lexeme ? reading_of.call(lexeme, "pinyin") : []
      if z.size != part.length
        z = part.chars.map { |char| (entry = vocab[char]) ? reading_of.call(entry, "zhuyin").first : nil }
        p = part.chars.map { |char| (entry = vocab[char]) ? reading_of.call(entry, "pinyin").first : nil }
      end
      return nil if z.any?(&:nil?) || z.size != part.length

      zhuyin.concat(z)
      pinyin.concat(p.map { |syllable| syllable || "" })
    end
  end
  return nil if zhuyin.size != text.scan(han).size

  {"zhuyin" => zhuyin.join(" "), "pinyin" => pinyin.join(" ")}
end

readings = wanted.to_h { |text| [text, reading.call(text)] }

added = 0
missing = []
lessons.each do |lesson|
  glossary = lesson["glossary"] ||= {}
  runs_in.call(lesson).each do |text|
    next if glossary.key?(text)

    found = readings[text]
    next missing << text if found.nil?

    glossary[text] = found
    added += 1
  end
end

File.write(path, JSON.pretty_generate(lessons))
puts("glossary entries added: #{added}, unresolved: #{missing.uniq.size}")
missing.uniq.first(10).each { |text| puts("  #{text}") }

# frozen_string_literal: true

require "json"

root = File.expand_path("..", __dir__)
path = File.join(root, "data/huayu/grammar_lessons.json")
lessons = JSON.parse(File.read(path))

han = /\p{Han}/

texts = lessons.flat_map { |lesson| lesson["examples"].map { |e| e["zh"] } }.uniq
segments_needed = texts.flat_map { |t| t.scan(/\p{Han}+/) }.uniq

sentences = Lexeme.where(kind: :sentence, text: texts).index_by(&:text)

vocab = {}
chunks = segments_needed.flat_map { |run| (1..run.length).flat_map { |len| (0..run.length - len).map { |i| run[i, len] } } }.uniq
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
  "喝" => ["ㄏㄜ", "hē"],
  "誰" => ["ㄕㄟˊ", "shéi"],
  "個" => ["˙ㄍㄜ", "ge"]
}

reading_of = lambda do |lexeme, key|
  set = lexeme.reading_set.first || {}
  set[key].to_s.split(/[[:space:]]+/).reject(&:empty?)
end

annotate = lambda do |text, segments|
  zhuyin = []
  pinyin = []
  segments.each do |segment|
    next unless segment.match?(han)

    if (override = preferred[segment])
      zhuyin << override[0]
      pinyin << override[1]
      next
    end

    lexeme = vocab[segment]
    z = lexeme ? reading_of.call(lexeme, "zhuyin") : []
    p = lexeme ? reading_of.call(lexeme, "pinyin") : []
    if z.size != segment.length
      z = segment.chars.map { |ch| (c = vocab[ch]) ? reading_of.call(c, "zhuyin").first : nil }
      p = segment.chars.map { |ch| (c = vocab[ch]) ? reading_of.call(c, "pinyin").first : nil }
    end
    return nil if z.any?(&:nil?) || z.size != segment.length

    zhuyin.concat(z)
    pinyin.concat(p.map { |syl| syl || "" })
  end
  return nil if zhuyin.size != text.scan(han).size

  [zhuyin.join(" "), pinyin.join(" ")]
end

greedy = lambda do |text|
  runs = []
  text.scan(/\p{Han}+|[^\p{Han}]+/) do |chunk|
    if chunk.match?(han)
      i = 0
      while i < chunk.length
        len = [4, chunk.length - i].min
        len -= 1 while len > 1 && vocab[chunk[i, len]].nil?
        runs << chunk[i, len]
        i += len
      end
    else
      runs << chunk
    end
  end
  runs
end

annotated = 0
missing = []
lessons.each do |lesson|
  lesson["examples"].each do |example|
    text = example["zh"]
    db = sentences[text]
    segments = db ? Array(db.data["segments"]) : []
    segments = greedy.call(text) if segments.empty?
    result = annotate.call(text, segments)
    if db&.public_id
      example["sentence"] = db.public_id
    else
      example.delete("sentence")
    end
    if result
      example["zhuyin"], example["pinyin"] = result
      example["segments"] = segments
      annotated += 1
    else
      example.delete("zhuyin")
      example.delete("pinyin")
      example.delete("segments")
      missing << text
    end
  end
end

File.write(path, JSON.pretty_generate(lessons))
puts "annotated: #{annotated}, missing readings: #{missing.size}"
missing.first(10).each { |t| puts "  #{t}" }

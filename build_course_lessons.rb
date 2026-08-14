# frozen_string_literal: true

require "json"
require "digest"

root = File.expand_path("..", __dir__)
path = File.join(root, "data/huayu/course_lessons.json")
data = JSON.parse(File.read(path))
lessons = data.fetch("lessons", [])

han = /\p{Han}/
blank = "＿＿"

grammar_slugs = JSON
  .parse(File.read(File.join(root, "data/huayu/grammar_lessons.json")))
  .to_h { |lesson| [lesson["slug"], lesson] }

texts = lessons.flat_map { |lesson| lesson["vocabulary"].map { |word| word["zh"] } }.uniq
pieces = texts.flat_map { |text| text.chars } + texts

vocab = {}
pieces.uniq.each_slice(4000) do |slice|
  Lexeme.where(kind: %i[word collocation measure_word character], text: slice).where.not(readings: {}).each do |lexeme|
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
  "和" => ["ㄏㄢˋ", "hàn"],
  "個" => ["˙ㄍㄜ", "ge"]
}

reading_of = lambda do |lexeme, key|
  set = lexeme.reading_set.first || {}
  set[key].to_s.split(/[[:space:]]+/).reject(&:empty?)
end

readings_for = lambda do |text|
  return preferred[text] if preferred.key?(text)

  lexeme = vocab[text]
  zhuyin = lexeme ? reading_of.call(lexeme, "zhuyin") : []
  pinyin = lexeme ? reading_of.call(lexeme, "pinyin") : []
  if zhuyin.size != text.length
    zhuyin = text.chars.map { |char| preferred[char]&.first || (vocab[char] && reading_of.call(vocab[char], "zhuyin").first) }
    pinyin = text.chars.map { |char| preferred[char]&.last || (vocab[char] && reading_of.call(vocab[char], "pinyin").first) }
  end
  return nil if zhuyin.any?(&:nil?) || zhuyin.size != text.length

  [zhuyin.join(" "), pinyin.map { |syllable| syllable || "" }.join(" ")]
end

segmenter = Huayu::TextAnalyzer.new(locale: :en)

chunks_for = lambda do |sentence|
  runs = []
  sentence.scan(/\p{Han}+|[^\p{Han}]+/) do |run|
    if run.match?(han)
      segmenter.segment(run).each { |piece| runs << piece }
    elsif runs.any?
      runs[-1] = runs[-1] + run
    else
      runs << run
    end
  end
  runs.reject { |run| run.strip.empty? }
end

seed_for = ->(slug) { Digest::MD5.hexdigest(slug)[0, 8].to_i(16) }

missing_words = []
missing_grammar = []
short_lessons = []
built = 0

pool = lessons.each_with_object(Hash.new { |memo, key| memo[key] = [] }) do |lesson, memo|
  lesson["vocabulary"].each { |word| memo[lesson["stage"]] << word }
end

lessons.each do |lesson|
  random = Random.new(seed_for.call(lesson["slug"]))
  words = lesson["vocabulary"]

  words.each do |word|
    result = readings_for.call(word["zh"])
    if result
      word["zhuyin"], word["pinyin"] = result
    else
      word.delete("zhuyin")
      word.delete("pinyin")
      missing_words << "#{lesson["slug"]}: #{word["zh"]}"
    end
  end

  lesson["grammar"].each do |ref|
    missing_grammar << "#{lesson["slug"]}: #{ref["slug"]}" unless grammar_slugs.key?(ref["slug"])
  end

  others = (pool[lesson["stage"]] - words).uniq { |word| word["zh"] }
  others = pool.values.flatten.uniq { |word| word["zh"] } - words if others.size < 6

  distractors = lambda do |word, key|
    picks = others
      .reject { |other| other[key] == word[key] || other["zh"] == word["zh"] }
      .sample(3, random: random)
    picks.size == 3 ? picks : nil
  end

  exercises = []

  meaning_words = words.each_slice([words.size / 3, 1].max).map(&:first).first(3)
  meaning_words.each do |word|
    picks = distractors.call(word, "en")
    next if picks.nil?

    options = ([word] + picks).shuffle(random: random)
    exercises << {
      "kind" => "meaning",
      "zh" => word["zh"],
      "options" => options.map { |option| {"en" => option["en"], "ru" => option["ru"]} },
      "answer" => options.index(word)
    }
  end

  word_words = words.reverse.each_slice([words.size / 2, 1].max).map(&:first).first(2)
  word_words.each do |word|
    picks = distractors.call(word, "zh")
    next if picks.nil?

    options = ([word] + picks).shuffle(random: random)
    exercises << {
      "kind" => "word",
      "gloss" => {"en" => word["en"], "ru" => word["ru"]},
      "options" => options.map { |option| option["zh"] },
      "answer" => options.index(word)
    }
  end

  lines = Array(lesson.dig("text", "lines"))
  cloze_used = []
  lines.each do |line|
    break if cloze_used.size >= 2

    word = words.find do |candidate|
      candidate["zh"].match?(han) &&
        candidate["zh"].length >= 2 &&
        line["zh"].include?(candidate["zh"]) &&
        cloze_used.exclude?(candidate["zh"])
    end
    next if word.nil?

    picks = distractors.call(word, "zh")
    next if picks.nil?

    options = ([word] + picks).shuffle(random: random)
    cloze_used << word["zh"]
    exercises << {
      "kind" => "cloze",
      "zh" => line["zh"].sub(word["zh"], blank),
      "gloss" => {"en" => line["en"], "ru" => line["ru"]},
      "options" => options.map { |option| option["zh"] },
      "answer" => options.index(word)
    }
  end

  ordered = lines
    .map { |line| [line, chunks_for.call(line["zh"])] }
    .select { |_line, chunks| chunks.size.between?(3, 7) }
    .max_by { |_line, chunks| chunks.size }
  if ordered
    line, chunks = ordered
    exercises << {
      "kind" => "order",
      "gloss" => {"en" => line["en"], "ru" => line["ru"]},
      "chunks" => chunks,
      "order" => (0...chunks.size).to_a.shuffle(random: random),
      "answer" => 0
    }
  end

  pairs = words.select { |word| word["en"].present? }.sample(4, random: random)
  if pairs.size == 4
    exercises << {
      "kind" => "pair",
      "pairs" => pairs.map { |word| {"zh" => word["zh"], "en" => word["en"], "ru" => word["ru"]} },
      "order" => (0...4).to_a.shuffle(random: random),
      "answer" => 0
    }
  end

  lesson["exercises"] = exercises
  short_lessons << "#{lesson["slug"]}: #{exercises.size}" if exercises.size < 6
  built += exercises.size
end

exam_built = 0
Array(data["stages"]).each do |stage|
  random = Random.new(seed_for.call("exam:#{stage["slug"]}"))
  stage_lessons = lessons.select { |lesson| lesson["stage"] == stage["slug"] }
  words = stage_lessons.flat_map { |lesson| lesson["vocabulary"] }.uniq { |word| word["zh"] }
  lines = stage_lessons.flat_map { |lesson| Array(lesson.dig("text", "lines")) }
  if words.size < 8
    stage["exam"] = []
    next
  end

  pick_options = lambda do |word, key|
    picks = words.reject { |other| other[key] == word[key] }.sample(3, random: random)
    picks.size == 3 ? ([word] + picks).shuffle(random: random) : nil
  end

  exam = []
  words.sample(6, random: random).each do |word|
    options = pick_options.call(word, "en")
    next if options.nil?

    exam << {
      "kind" => "meaning",
      "zh" => word["zh"],
      "options" => options.map { |option| {"en" => option["en"], "ru" => option["ru"]} },
      "answer" => options.index(word)
    }
  end
  words.sample(5, random: random).each do |word|
    options = pick_options.call(word, "zh")
    next if options.nil?

    exam << {
      "kind" => "word",
      "gloss" => {"en" => word["en"], "ru" => word["ru"]},
      "options" => options.map { |option| option["zh"] },
      "answer" => options.index(word)
    }
  end

  used = []
  lines.shuffle(random: random).each do |line|
    break if used.size >= 6

    word = words.find do |candidate|
      candidate["zh"].length >= 2 && line["zh"].include?(candidate["zh"]) && used.exclude?(candidate["zh"])
    end
    next if word.nil?

    options = pick_options.call(word, "zh")
    next if options.nil?

    used << word["zh"]
    exam << {
      "kind" => "cloze",
      "zh" => line["zh"].sub(word["zh"], blank),
      "gloss" => {"en" => line["en"], "ru" => line["ru"]},
      "options" => options.map { |option| option["zh"] },
      "answer" => options.index(word)
    }
  end

  ordered = lines
    .map { |line| [line, chunks_for.call(line["zh"])] }
    .select { |_line, chunks| chunks.size.between?(4, 8) }
    .shuffle(random: random)
    .first(3)
  ordered.each do |line, chunks|
    exam << {
      "kind" => "order",
      "gloss" => {"en" => line["en"], "ru" => line["ru"]},
      "chunks" => chunks,
      "order" => (0...chunks.size).to_a.shuffle(random: random),
      "answer" => 0
    }
  end

  pairs = words.sample(5, random: random)
  exam << {
    "kind" => "pair",
    "pairs" => pairs.map { |word| {"zh" => word["zh"], "en" => word["en"], "ru" => word["ru"]} },
    "order" => (0...pairs.size).to_a.shuffle(random: random),
    "answer" => 0
  }

  stage["exam"] = exam
  exam_built += exam.size
end

File.write(path, JSON.pretty_generate(data))

puts "stage exams: #{exam_built} tasks across #{Array(data["stages"]).size} stages"
puts "lessons: #{lessons.size}, exercises: #{built}"
puts "words without a dictionary reading: #{missing_words.size}"
missing_words.first(30).each { |entry| puts "  #{entry}" }
puts "grammar slugs that do not exist: #{missing_grammar.size}"
missing_grammar.first(30).each { |entry| puts "  #{entry}" }
puts "lessons with fewer than six tasks: #{short_lessons.size}"
short_lessons.first(20).each { |entry| puts "  #{entry}" }

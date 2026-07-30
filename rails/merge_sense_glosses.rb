source = Rails.root.join(ENV["IN"] || "tmp/translate")
files = Pathname.glob(source.join("out-*.jsonl")).sort
abort("no files in #{source}") if files.empty?

language = Language.find_by!(code: "zh-TW")
valid_pairs = LexemeSense
  .joins(:lexeme)
  .where(lexemes: {language_id: language.id})
  .pluck(Arel.sql("lexemes.text"), :gloss_zh)
  .to_set

HAN = /\p{Han}/
entries = []
rejected = Hash.new(0)

files.each do |file|
  file.each_line do |line|
    line = line.strip
    next if line.empty?

    row = begin
      JSON.parse(line)
    rescue JSON::ParserError
      rejected[:broken_json] += 1
      next
    end

    word = row["word"].to_s
    zh = row["zh"].to_s
    en = row["en"].to_s.strip
    ru = row["ru"].to_s.strip

    if word.empty? || zh.empty?
      rejected[:no_key] += 1
      next
    end

    unless valid_pairs.include?([word, zh])
      rejected[:unknown_sense] += 1
      next
    end

    if en.empty? && ru.empty?
      rejected[:empty] += 1
      next
    end

    if en.match?(HAN) || ru.match?(HAN)
      rejected[:han_in_translation] += 1
      next
    end

    entries << Huayu::SenseGlossStore::Entry.new(word:, zh:, en: en.presence, ru: ru.presence)
  end
end

added = Huayu::SenseGlossStore.append(entries)
total = Huayu::SenseGlossStore.rewrite_sorted

puts("files: #{files.length}, rows accepted: #{entries.length}, new entries: #{added}")
puts("total in store: #{total}")
rejected.each { |reason, count| puts("  rejected (#{reason}): #{count}") }

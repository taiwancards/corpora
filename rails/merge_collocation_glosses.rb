source = Rails.root.join(ENV["IN"] || "tmp/colloc")
files = Pathname.glob(source.join("out-*.jsonl")).sort
abort("no files in #{source}") if files.empty?

language = Language.find_by!(code: "zh-TW")
valid = Lexeme
  .where(language_id: language.id, kind: Lexeme.kinds[:collocation])
  .pluck(:text)
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

    text = row["text"].to_s
    en = row["en"].to_s.strip
    ru = row["ru"].to_s.strip

    if text.empty?
      rejected[:no_key] += 1
      next
    end

    unless valid.include?(text)
      rejected[:unknown_collocation] += 1
      next
    end

    if en.empty? || ru.empty?
      rejected[:empty] += 1
      next
    end

    if en.match?(HAN) || ru.match?(HAN)
      rejected[:han_in_translation] += 1
      next
    end

    entries << Huayu::CollocationGlossStore::Entry.new(text:, en:, ru:)
  end
end

added = Huayu::CollocationGlossStore.append(entries)
total = Huayu::CollocationGlossStore.rewrite_sorted

puts("files: #{files.length}, rows accepted: #{entries.length}, new entries: #{added}")
puts("total in store: #{total}")
rejected.each { |reason, count| puts("  rejected (#{reason}): #{count}") }

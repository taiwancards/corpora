require "json"

source = Rails.root.join(ENV["IN"] || "tmp/words")
files = Pathname.glob(source.join("out-*.jsonl")).sort
abort("no files in #{source}") if files.empty?

language = Language.find_by!(code: "zh-TW")
valid = Lexeme
  .where(language_id: language.id, kind: Lexeme.kinds[:word])
  .pluck(:text)
  .to_set

path = AppData.path("huayu/gloss_overrides.json")
overrides = path.exist? ? JSON.parse(path.read) : {}

han = /\p{Han}/
added = 0
updated = 0
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

    if text.empty? || !valid.include?(text)
      rejected[:unknown_word] += 1
      next
    end

    if ru.empty?
      rejected[:empty] += 1
      next
    end

    if ru.match?(han) || (en.present? && en.match?(han))
      rejected[:han_in_translation] += 1
      next
    end

    existing = overrides[text]
    if existing.nil?
      record = {"ru" => ru}
      record["en"] = en if en.present?
      overrides[text] = record
      added += 1
    else
      changed = false
      if existing["en"].to_s.strip.empty? && en.present?
        existing["en"] = en
        changed = true
      end

      if existing["ru"].to_s.strip.empty? && ru.present?
        existing["ru"] = ru
        changed = true
      end

      updated += 1 if changed
    end
  end
end

sorted = overrides.sort_by { |k, _| k }.to_h
path.write(JSON.pretty_generate(sorted) + "\n")

puts("files: #{files.length}, added: #{added}, extended: #{updated}")
puts("total in gloss_overrides.json: #{sorted.length}")
rejected.each { |reason, count| puts("  rejected (#{reason}): #{count}") }

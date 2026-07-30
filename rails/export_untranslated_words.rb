require "fileutils"

lang = Language.find_by!(code: "zh-TW")
words = Lexeme.where(language_id: lang.id, kind: Lexeme.kinds[:word])

field_blank = -> (lexeme, field) { lexeme.meanings[field].to_s.strip.empty? }

need_en = []
need_ru = []

words.to_a.each do |w|
  en_blank = field_blank.call(w, "en")
  ru_blank = field_blank.call(w, "ru")
  next unless en_blank || ru_blank

  row = {
    "text" => w.text,
    "py" => w.readings["pinyin"],
    "pos" => w.data["pos"],
    "grade" => w.data["tbcl_grade"],
    "sources" => w.sources
  }
  if en_blank
    need_en << row
  else
    row["en"] = w.meanings["en"]
    need_ru << row
  end
end

grade = -> (r) { r["grade"] || 99 }
need_en.sort_by! { |r| [grade.call(r), r["text"]] }
need_ru.sort_by! { |r| [grade.call(r), r["text"]] }

ordered = need_en + need_ru

dir = Rails.root.join("tmp/words")
FileUtils.rm_rf(dir)
FileUtils.mkdir_p(dir)

size = 400
batches = ordered.each_slice(size).to_a
batches.each_with_index do |slice, i|
  path = dir.join(format("batch-%03d.json", i + 1))
  File.write(path, JSON.pretty_generate(slice))
end

puts("no EN: #{need_en.length}, no RU (EN present): #{need_ru.length}")
puts("rows: #{ordered.length}, batches: #{batches.length} of #{size}")

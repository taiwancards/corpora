language = Language.find_by!(code: "zh-TW")
limit = (ENV["LIMIT"] || 2000).to_i
batch_size = (ENV["BATCH"] || 50).to_i
out = Rails.root.join(ENV["OUT"] || "tmp/translate")
out.mkpath

done = Huayu::SenseGlossStore.index.keys.to_set

scope = LexemeSense
  .joins(:lexeme)
  .where(lexemes: {language_id: language.id})
  .where("COALESCE(lexeme_senses.meanings->>'en','') = '' OR COALESCE(lexeme_senses.meanings->>'ru','') = ''")

scope = if ENV["TBCL_MAX"].present?
  scope
    .where(lexemes: {kind: [Lexeme.kinds[:character], Lexeme.kinds[:word]]})
    .where("(lexemes.data->>'tbcl_grade')::int <= ?", ENV["TBCL_MAX"].to_i)
elsif ENV["ALL"].present?
  scope.where(lexemes: {kind: [Lexeme.kinds[:character], Lexeme.kinds[:word], Lexeme.kinds[:phrase]]})
else
  scope.where("lexemes.data->>'tbcl_grade' IS NOT NULL OR lexemes.data->>'tocfl_level' IS NOT NULL")
end

rows = scope
  .order(
    Arel.sql(
      "COALESCE((lexemes.data->>'tbcl_grade')::int, 9), lexemes.score NULLS LAST, lexeme_senses.lexeme_id, lexeme_senses.position"
    )
  )
  .pluck(
    Arel.sql("lexemes.text"),
    Arel.sql("lexemes.readings->>'pinyin'"),
    Arel.sql("lexemes.readings->>'zhuyin'"),
    Arel.sql("lexemes.meanings->>'en'"),
    Arel.sql("lexemes.meanings->>'ru'"),
    Arel.sql("lexemes.data->>'tbcl_grade'"),
    Arel.sql("lexeme_senses.gloss_zh"),
    Arel.sql("lexeme_senses.position")
  )
  .reject { |row| done.include?([row[0], row[6]]) }
  .first(limit)

grouped = rows.group_by { |row| row[0] }
words = grouped.map do |text, group|
  first = group.first
  {
    word: text,
    pinyin: first[1],
    zhuyin: first[2],
    known_en: first[3],
    known_ru: first[4],
    tbcl: first[5],
    senses: group.sort_by { |row| row[7] }.map { |row| {zh: row[6]} }
  }
end

files = []
words.each_slice(batch_size).with_index do |slice, index|
  path = out.join(format("batch-%03d.json", index + 1))
  path.write(JSON.pretty_generate(slice))
  files << path.to_s
end

puts("words: #{words.length}, senses: #{rows.length}, files: #{files.length}")
files.each { |file| puts("  #{file}") }

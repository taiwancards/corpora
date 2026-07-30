language = Language.find_by!(code: "zh-TW")
limit = (ENV["LIMIT"] || 100_000).to_i
batch_size = (ENV["BATCH"] || 400).to_i
out = Rails.root.join(ENV["OUT"] || "tmp/colloc")
out.mkpath

done = Huayu::CollocationGlossStore.index.keys.to_set

rows = SenseExample
  .joins(:lexeme_sense)
  .joins("JOIN lexemes c ON c.id = sense_examples.lexeme_id")
  .joins("JOIN lexemes w ON w.id = lexeme_senses.lexeme_id")
  .where(kind: SenseExample.kinds[:collocation])
  .where("c.language_id = ?", language.id)
  .where("c.kind = ?", Lexeme.kinds[:collocation])
  .where("COALESCE(c.meanings->>'en','') = '' OR COALESCE(c.meanings->>'ru','') = ''")
  .order(Arel.sql("COALESCE((w.data->>'tbcl_grade')::int, 9), w.text, lexeme_senses.position, c.text"))
  .pluck(
    Arel.sql("c.text"),
    Arel.sql("w.text"),
    Arel.sql("w.readings->>'pinyin'"),
    Arel.sql("lexeme_senses.position"),
    Arel.sql("lexeme_senses.gloss_zh"),
    Arel.sql("lexeme_senses.meanings->>'en'"),
    Arel.sql("lexeme_senses.meanings->>'ru'")
  )

seen = Set.new
rows = rows.reject { |row| done.include?(row[0]) || !seen.add?(row[0]) }.first(limit)

groups = rows.chunk_while { |a, b| a[1] == b[1] && a[3] == b[3] }.map do |chunk|
  head = chunk.first
  {
    word: head[1],
    pinyin: head[2],
    position: head[3],
    zh: head[4],
    en: head[5],
    ru: head[6],
    items: chunk.map(&:first)
  }
end

files = []
batch = []
count = 0
index = 0

flush = lambda do
  next if batch.empty?

  index += 1
  path = out.join(format("batch-%03d.json", index))
  path.write(JSON.pretty_generate(batch))
  files << path.to_s
  batch = []
  count = 0
end

groups.each do |group|
  batch << group
  count += group[:items].length
  flush.call if count >= batch_size
end

flush.call

puts("collocations: #{rows.length}, groups: #{groups.length}, files: #{files.length}")
files.each { |file| puts("  #{file}") }

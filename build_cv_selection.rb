# frozen_string_literal: true

require "json"

root = File.expand_path("..", __dir__)
source = ContentSource.find_by!(slug: "common_voice")

rows = Lexeme
  .where(kind: :sentence, restricted: false)
  .joins(:lexeme_content_sources)
  .where(lexeme_content_sources: {content_source_id: source.id})
  .joins("JOIN sentence_profiles ON sentence_profiles.lexeme_id = lexemes.id")
  .select(
    "lexemes.text, lexemes.meanings, lexemes.tbcl_half, lexemes.tocfl_half, " \
      "sentence_profiles.difficulty, sentence_profiles.han_length"
  )
  .order("sentence_profiles.difficulty ASC")

selection = []
rows.each do |row|
  level = [row.tbcl_half.to_i, row.tocfl_half.to_i].reject { |v| v.zero? || v >= 99 }.min
  next if level.nil?
  next unless row.han_length.to_i.between?(4, 24)

  selection <<
    {
      "text" => row.text,
      "level" => level,
      "difficulty" => row.difficulty,
      "han_length" => row.han_length,
      "en" => row.meanings&.dig("en"),
      "ru" => row.meanings&.dig("ru"),
      "priority" => level <= 4 ? "core" : "extended"
    }
end

File.write(
  File.join(root, "data/huayu/cv_listening_selection.json"),
  JSON.pretty_generate(
    {
      "source" => "Common Voice zh-TW sentence prompts already in corpus (CC0)",
      "purpose" => "clips to pull from a Common Voice release for sentence-level listening; match validated.tsv by exact sentence text",
      "counts_by_level" => selection.group_by { |s| s["level"] }.transform_values(&:size).sort.to_h,
      "core_count" => selection.count { |s| s["priority"] == "core" },
      "sentences" => selection
    }
  )
)

puts("eligible: #{selection.size}")
selection.group_by { |s| s["level"] }.sort.each { |level, group| puts("level #{level}: #{group.size}") }
puts("core (<= level 4): #{selection.count { |s| s["priority"] == "core" }}")

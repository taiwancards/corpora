# frozen_string_literal: true

require "json"

MIN_HAN = 6

root = File.expand_path("..", __dir__)
manifest_path = File.join(root, "media/listening/manifest.json")
manifest = JSON.parse(File.read(manifest_path))
emoji_map = JSON.parse(File.read(File.join(root, "data/huayu/emoji_map.json")))

texts = manifest["clips"].map { |row| row["text"] }
segments_by_text = Lexeme
  .where(kind: :sentence, text: texts)
  .pluck(:text, Arel.sql("data -> 'segments'"))
  .to_h

annotated = 0
rejected = Hash.new(0)
manifest["clips"].each do |row|
  segments = Array(segments_by_text[row["text"]])
  hits = segments.select { |segment| emoji_map.key?(segment) && !emoji_map[segment]["ambiguous"] }
  emojis = hits.map { |word| emoji_map[word]["emoji"] }.uniq

  reason =
    if row["text"].scan(/\p{Han}/).size < MIN_HAN then :too_short
    elsif emojis.size != 1 then :no_single_emoji
    end

  if reason
    rejected[reason] += 1
    row.delete("emoji_word")
    row.delete("emoji")
    row.delete("emoji_category")
    next
  end

  word = hits.first
  row["emoji_word"] = word
  row["emoji"] = emoji_map[word]["emoji"]
  row["emoji_category"] = emoji_map[word]["category"]
  annotated += 1
end

File.write(manifest_path, JSON.pretty_generate(manifest))
levels = manifest["clips"].select { |row| row["emoji"] }.group_by { |row| row["level"] }.transform_values(&:size)
puts "emoji-annotated: #{annotated} of #{manifest["clips"].size}"
puts "by level: #{levels.sort.to_h}"
puts "rejected: #{rejected.sort_by { |_, v| -v }.to_h}"

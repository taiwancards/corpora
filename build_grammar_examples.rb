# frozen_string_literal: true

require "json"

root = File.expand_path("..", __dir__)
attestation = JSON.parse(File.read(File.join(root, "data/huayu/tocfl_grammar_attestation.json")))
points = attestation["points"].select { |p| p["markers"].is_a?(Array) || p["markers"] == "A-not-A" }

matcher = lambda do |text, markers|
  if markers == "A-not-A"
    !!text.match(/([一-鿿])不\1/)
  else
    pos = 0
    markers.all? do |part|
      best = nil
      part.each do |alt|
        alt = [alt] if alt.is_a?(String)
        p = pos
        ok = alt.all? do |m|
          i = text.index(m, p)
          i && (p = i + m.length)
        end

        best = p if ok && (best.nil? || p < best)
      end

      best && (pos = best)
    end
  end
end

buckets = points.to_h { |p| [p["id"], []] }
active = points.dup

scope = Lexeme
  .where(kind: :sentence)
  .where(restricted: false)
  .where("tbcl_half <= 7")
  .joins("JOIN sentence_profiles ON sentence_profiles.lexeme_id = lexemes.id")
  .select("lexemes.id, lexemes.text, lexemes.meanings, lexemes.tbcl_half, sentence_profiles.difficulty")
  .order("sentence_profiles.difficulty ASC")

scope.find_each(batch_size: 2000) do |sentence|
  active.reject! do |point|
    bucket = buckets[point["id"]]
    if bucket.size >= 5
      true
    else
      if sentence.tbcl_half.to_i <= point["level"].to_i && matcher.call(sentence.text, point["markers"])
        bucket <<
          {
            "text" => sentence.text,
            "en" => sentence.meanings&.dig("en"),
            "ru" => sentence.meanings&.dig("ru"),
            "tbcl" => sentence.tbcl_half,
            "difficulty" => sentence.difficulty
          }
      end

      bucket.size >= 5
    end
  end

  break if active.empty?
end

File.open(File.join(root, "data/huayu/tbcl_grammar_examples.jsonl"), "w") do |f|
  points.each do |point|
    f.puts(
      JSON.generate(
        {
          "id" => point["id"],
          "pattern" => point["pattern"],
          "level" => point["level"],
          "examples" => buckets[point["id"]]
        }
      )
    )
  end
end

filled = buckets.values.count { |b| b.size >= 5 }
some = buckets.values.count(&:any?)
puts("points with 5 examples: #{filled}, with any: #{some}, total: #{points.size}")

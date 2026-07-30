# frozen_string_literal: true

require "json"

root = ENV["CORPORA_DIR"].presence || Rails.root.join("dict_and_corpora/corpora").to_s
FileUtils.mkdir_p(root)

payload = {
  "words" => Lexeme.where(kind: %i[word collocation]).pluck(:text, :data).to_h { |text, data|
    [text, data["freq_rank"]&.to_i]
  },
  "chars" => Lexeme.where(kind: :character).pluck(:text, :data).to_h { |text, data|
    [text, data["freq_rank"]&.to_i]
  }
}

File.write(File.join(root, "dict.json"), JSON.dump(payload))
puts("words=#{payload["words"].size} chars=#{payload["chars"].size} -> #{File.join(root, "dict.json")}")

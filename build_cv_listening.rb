# frozen_string_literal: true

require "csv"
require "fileutils"
require "json"
require "open-uri"
require "rubygems/package"

require_relative "lib/corpus"

REPO = Corpus.source(:COMMON_VOICE_DATASET_ID)
LOCALE = "zh-TW"
HOST = Corpus.source(:COMMON_VOICE_BASE_URL).chomp("/")
BASE = "#{HOST}/datasets/#{REPO}/resolve/main"
LISTING = "#{HOST}/api/datasets/#{REPO}/tree/main/audio/#{LOCALE}"
BUCKETS = %w[train dev test other].freeze
MAX_LEVEL = Integer(Corpus.env.fetch("MAX_LEVEL", "9"))

root = File.expand_path("..", __dir__)
work = File.join(root, "tmp", "cv_listening_work")
out_dir = File.join(root, "media", "listening", "audio")
FileUtils.mkdir_p(work)
FileUtils.mkdir_p(out_dir)

def fetch(url, target)
  return target if File.size?(target)

  URI.parse(url).open("rb") { |remote| IO.copy_stream(remote, target) }
  target
end

def parse(path)
  CSV.read(path, col_sep: "\t", headers: true, quote_char: nil, encoding: "utf-8").map(&:to_h)
end

normalize = -> (text) { text.to_s.strip.gsub(/\s+/, "") }

bucket_of = {}
BUCKETS.each do |bucket|
  parse(fetch("#{BASE}/transcript/#{LOCALE}/#{bucket}.tsv", File.join(work, "#{bucket}.tsv"))).each do |row|
    bucket_of[File.basename(row["path"].to_s)] = bucket
  end
end

wanted = Lexeme
  .where(kind: :sentence, restricted: false)
  .joins("JOIN sentence_profiles ON sentence_profiles.lexeme_id = lexemes.id")
  .select(
    "lexemes.id, lexemes.text, lexemes.meanings, lexemes.tbcl_half, lexemes.tocfl_half, " \
      "sentence_profiles.difficulty, sentence_profiles.han_length"
  )
  .each_with_object({}) do |row, acc|
    level = [row.tbcl_half.to_i, row.tocfl_half.to_i].reject { |v| v.zero? || v >= 99 }.min || 9
    next if level > MAX_LEVEL

    acc[normalize.call(row.text)] = {
      "text" => row.text,
      "level" => level,
      "difficulty" => row.difficulty,
      "han_length" => row.han_length,
      "en" => row.meanings&.dig("en"),
      "ru" => row.meanings&.dig("ru")
    }
  end

puts("sentences in our system (level <= #{MAX_LEVEL}): #{wanted.size}")

best = {}
parse(fetch("#{BASE}/transcript/#{LOCALE}/validated.tsv", File.join(work, "validated.tsv"))).each do |row|
  sentence = normalize.call(row["sentence"])
  next unless wanted.key?(sentence)

  name = File.basename(row["path"].to_s)
  bucket = bucket_of[name]
  next unless bucket

  score = row["up_votes"].to_i - row["down_votes"].to_i
  current = best[sentence]
  best[sentence] = {"name" => name, "score" => score, "bucket" => bucket} if current.nil? || score > current["score"]
end

puts("matched with a downloadable clip: #{best.size}")

pending = best.reject { |_, clip| File.exist?(File.join(out_dir, clip["name"])) }
puts("to extract: #{pending.size}")

pending.group_by { |_, clip| clip["bucket"] }.each do |bucket, entries|
  names = entries.to_set { |_, clip| clip["name"] }
  listing = JSON.parse(URI.parse("#{LISTING}/#{bucket}").read)
  shards = listing.filter_map { |entry| File.basename(entry["path"]) if entry["type"] == "file" }.sort
  puts("#{bucket}: #{names.size} clips across #{shards.size} shards")

  shards.each do |shard|
    break if names.empty?

    tar = fetch("#{BASE}/audio/#{LOCALE}/#{bucket}/#{shard}", File.join(work, shard))
    File.open(tar, "rb") do |io|
      Gem::Package::TarReader.new(io).each do |entry|
        name = File.basename(entry.full_name)
        next unless names.include?(name)

        File.binwrite(File.join(out_dir, name), entry.read)
        names.delete(name)
      end
    end

    FileUtils.rm_f(tar)
    puts("  #{shard} done, #{names.size} left")
  end
end

manifest = best.filter_map do |sentence, clip|
  next unless File.exist?(File.join(out_dir, clip["name"]))

  wanted[sentence].merge("clip" => clip["name"])
end

File.write(
  File.join(root, "media", "listening", "manifest.json"),
  JSON.pretty_generate(
    {
      "source" => "Common Voice zh-TW (CC0) via #{REPO}, best-voted validated clip per sentence, original mp3",
      "scope" => "sentences present in our corpus, level <= #{MAX_LEVEL}",
      "n_clips" => manifest.size,
      "clips" => manifest.sort_by { |row| [row["level"], row["difficulty"] || 0] }
    }
  )
)

FileUtils.rm_rf(work)
puts("written: #{manifest.size} clips, manifest at media/listening/manifest.json")

#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "lib/bigram_model"

EXTRA_REGISTER = {"vocus_prose" => "literary"}.freeze
EXTRA_LICENCE = {"vocus_prose" => [false, false]}.freeze

REGISTER_ORDER = %w[colloquial subtitles internet publicistic official academic literary].freeze
REGISTER_NAME = {
  "colloquial" => "colloquial",
  "subtitles" => "subtitles",
  "internet" => "internet",
  "publicistic" => "publicistic",
  "official" => "official",
  "academic" => "academic",
  "literary" => "literary"
}.freeze

CORPUS_HAN_RUN = /[\u{4E00}-\u{9FFF}]+/

def thousands(value) = value.to_s.reverse.scan(/\d{1,3}/).join(",").reverse

def source_meta
  meta = {}

  Corpus.read_json(Corpus.data("content_sources.json")).each do |row|
    register = row["register"]
    next if register.nil? || register.to_s.empty?

    meta[row["slug"]] = {
      "register" => register,
      "name" => row.fetch("name", row["slug"]),
      "free" => !!row["license_commercial"] && !!row["license_derivatives"]
    }
  end

  EXTRA_REGISTER.each do |slug, register|
    commercial, derivatives = EXTRA_LICENCE.fetch(slug, [false, false])
    meta[slug] = {"register" => register, "name" => slug, "free" => commercial && derivatives}
  end

  meta
end

def count_source(path, words, model)
  rows = Corpus.read_json(path)
  chars = 0
  tokens = 0
  types = Set.new

  rows.each do |text|
    text.scan(CORPUS_HAN_RUN).each do |run|
      chars += run.length
      Segmenter.segment(run, words, model).each do |piece|
        tokens += 1
        types << piece if piece.length > 1
      end
    end
  end

  {"sentences" => rows.length, "chars" => chars, "tokens" => tokens, "types" => types}
end

def group(rows, &predicate)
  out = Hash.new { |memo, key|
    memo[key] = {"sentences" => 0, "chars" => 0, "tokens" => 0, "types" => Set.new, "sources" => 0}
  }

  rows.each do |slug, data|
    next unless predicate.call(slug)

    bucket = out[data["meta"]["register"]]
    bucket["sentences"] += data["counts"]["sentences"]
    bucket["chars"] += data["counts"]["chars"]
    bucket["tokens"] += data["counts"]["tokens"]
    bucket["types"] |= data["counts"]["types"]
    bucket["sources"] += 1
  end

  out
end

def render(title, grouped)
  puts("")
  puts("### #{title}")
  puts("")
  puts(format("%-17s %9s %12s %12s %12s %12s", "register", "corpora", "sentences", "characters", "tokens", "distinct"))

  totals = {"sentences" => 0, "chars" => 0, "tokens" => 0, "sources" => 0}
  all_types = Set.new

  REGISTER_ORDER.each do |register|
    next unless grouped.key?(register)

    bucket = grouped[register]
    puts(
      format(
        "%-17s %9d %12s %12s %12s %12s",
        REGISTER_NAME[register],
        bucket["sources"],
        thousands(bucket["sentences"]),
        thousands(bucket["chars"]),
        thousands(bucket["tokens"]),
        thousands(bucket["types"].size)
      )
    )
    %w[sentences chars tokens sources].each { |key| totals[key] += bucket[key] }
    all_types |= bucket["types"]
  end

  puts(
    format(
      "%-17s %9d %12s %12s %12s %12s",
      "TOTAL",
      totals["sources"],
      thousands(totals["sentences"]),
      thousands(totals["chars"]),
      thousands(totals["tokens"]),
      thousands(all_types.size)
    )
  )
end

words, = Segmenter.vocabulary(Corpus.corpora("segvocab.json"))
limit = Segmenter.max_word(words)
model = BigramModel.unigram_model(limit)
meta = source_meta

rows = {}
Corpus.data("corpora/sentences").glob("*.json").sort.each do |path|
  slug = path.basename(".json").to_s
  next Corpus.say("skipping #{slug}: not in sources") unless meta.key?(slug)

  counts = count_source(path, words, model)
  rows[slug] = {"meta" => meta[slug], "counts" => counts}

  Corpus.say(
    format(
      "%-18s %-13s %-10s sentences %7d chars %8d tokens %8d distinct %7d",
      slug,
      meta[slug]["register"],
      meta[slug]["free"] ? "free" : "restricted",
      counts["sentences"],
      counts["chars"],
      counts["tokens"],
      counts["types"].size
    )
  )
end

render("Table 1. Every corpus, license aside", group(rows) { true })
render("Table 2. Free licenses only (commercial + derivatives)", group(rows) { |slug| rows[slug]["meta"]["free"] })

payload = rows.sort.to_h { |slug, data|
  [
    slug,
    {
      "chars" => data["counts"]["chars"],
      "free" => data["meta"]["free"],
      "register" => data["meta"]["register"],
      "sentences" => data["counts"]["sentences"],
      "tokens" => data["counts"]["tokens"],
      "types" => data["counts"]["types"].size
    }
  ]
}

target = Corpus.write_json(Corpus.data("huayu/corpus_stats.json"), payload, pretty: true)
Corpus.say("")
Corpus.say("per source -> #{target}")

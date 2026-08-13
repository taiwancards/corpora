#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "lib/segmenter"
require_relative "lib/forked"

START = "<s>"
EM_MIN = Integer(ENV.fetch("BIGRAM_EM_MIN", "2"))
ROUNDS = Integer(ENV.fetch("BIGRAM_ROUNDS", "3"))
FLOOR = 1e-9
CORPUS_HAN_RUN = /[\u{4E00}-\u{9FFF}]+/

def frequency_payload = @frequency ||= Corpus.read_json(Corpus.data("huayu/corpus_frequency.json"))

def unigram_model(limit)
  payload = frequency_payload
  Segmenter.build_model(payload.fetch("words"), payload.fetch("chars"), limit)
end

def unigram_probabilities
  payload = frequency_payload
  scale = payload.fetch("words").each_value.sum + payload.fetch("chars").each_value.sum
  table = payload.fetch("words").transform_values { |value| value / scale.to_f }
  payload.fetch("chars").each { |token, value| table[token] = value / scale.to_f }
  table
end

def discounts(bigrams)
  ones = twos = 0
  bigrams.each_value do |count|
    ones += 1 if count == 1
    twos += 1 if count == 2
  end

  total = ones + (2 * twos)
  total.zero? ? 0.75 : ones.fdiv(total)
end

def kneser_ney(bigrams, history, preceders, minimum)
  discount = discounts(bigrams)
  continuation_total = preceders.each_value.sum(&:size)
  continuation = preceders.transform_values { |set| set.size / continuation_total.to_f }

  table = Hash.new { |memo, key| memo[key] = {} }
  spent = Hash.new(0.0)

  bigrams.each do |(context, token), count|
    next if count < minimum

    value = [count - discount, 0.0].max / history[context]
    next unless value.positive?

    table[token][context] = value
    spent[context] += value
  end

  weights = history.each_with_object({}) do |(context, count), memo|
    memo[context] = [1.0 - spent.fetch(context, 0.0), 0.0].max if count.positive?
  end

  [discount, table, weights, continuation]
end

def bigram_segment(run, words, model, limit, floor)
  table, weights, continuation, unigram = model
  chars = run.chars
  size = chars.length
  best = Array.new(size + 1) { {} }
  best[0][START] = [0.0, nil, nil]

  (1..size).each do |stop|
    low = [1, stop - limit + 1].max
    (low..stop).each do |start|
      previous = best[start - 1]
      next if previous.empty?

      token = chars[(start - 1)...stop].join
      next if token.length > 1 && !words.include?(token)

      direct = table[token] if table.key?(token)
      base = continuation.fetch(token, 0.0)
      fallback = floor * unigram.fetch(token, floor)

      previous.each do |context, (cost, _, _)|
        probability = 0.0
        probability += direct.fetch(context, 0.0) if direct
        probability += weights.fetch(context, 0.0) * base
        probability = fallback if probability <= 0.0

        value = cost - Math.log(probability)
        current = best[stop][token]
        best[stop][token] = [value, start - 1, context] if current.nil? || value < current[0]
      end
    end
  end

  return nil if best[size].empty?

  token = best[size].min_by { |_, entry| entry[0] }.first
  pieces = []
  stop = size
  while stop.positive?
    _, start, context = best[stop][token]
    pieces << chars[start...stop].join
    stop = start
    token = context
  end

  pieces.reverse
end

def bigram_shard(runs, &splitter)
  bigrams = Hash.new(0)
  history = Hash.new(0)
  preceders = {}
  total = 0

  runs.each do |run|
    pieces = splitter.call(run)
    next if pieces.nil? || pieces.empty?

    previous = START
    pieces.each do |token|
      bigrams[[previous, token]] += 1
      history[previous] += 1
      (preceders[token] ||= Set.new) << previous
      previous = token
      total += 1
    end
  end

  bigrams.default = nil
  history.default = nil
  [bigrams, history, preceders, total]
end

def count_bigrams(runs, &splitter)
  bigrams = Hash.new(0)
  history = Hash.new(0)
  preceders = Hash.new { |memo, key| memo[key] = Set.new }
  total = 0

  partials = Forked.map(runs.length) do |shard|
    bigram_shard(runs.values_at(*shard), &splitter)
  end

  partials.each do |shard_bigrams, shard_history, shard_preceders, shard_total|
    shard_bigrams.each { |key, count| bigrams[key] += count }
    shard_history.each { |context, count| history[context] += count }
    shard_preceders.each { |token, set| preceders[token].merge(set) }
    total += shard_total
  end

  [bigrams, history, preceders, total]
end

words, chars = Segmenter.vocabulary(Corpus.corpora("segvocab.json"))
limit = Segmenter.max_word(words)
model = unigram_model(limit)
unigram = unigram_probabilities

runs = Corpus
  .data("corpora/sentences")
  .glob("*.json")
  .sort
  .flat_map { |path| Corpus.read_json(path).flat_map { |text| text.scan(CORPUS_HAN_RUN) } }

Corpus.report("runs", total: runs.length)

bigrams, history, preceders, total = count_bigrams(runs) { |run| Segmenter.segment(run, words, model) }
Corpus.report("pass 0 (unigram)", tokens: total, bigrams: bigrams.size)

ROUNDS.times do |step|
  discount, table, weights, continuation = kneser_ney(bigrams, history, preceders, EM_MIN)
  current = [table, weights, continuation, unigram]

  bigrams, history, preceders, total = count_bigrams(runs) { |run| bigram_segment(run, words, current, limit, FLOOR) }

  Corpus.say(
    format("pass %d (bigram): tokens %d, bigrams %d, D %.4f", step + 1, total, bigrams.size, discount)
  )
end

payload = {
  "bigrams" => bigrams.to_h { |(context, token), count| ["#{context}\t#{token}", count] },
  "history" => history,
  "preceders" => preceders.transform_values(&:size),
  "total" => total
}

target = Corpus.write_json(Corpus.corpora("bigram_counts.json"), payload)
Corpus.report("counts saved", bigrams: bigrams.size, megabytes: (target.size / 1024.0 / 1024).round(1))
Corpus.say("next: scripts/prune_bigrams.rb")

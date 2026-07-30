#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "lib/bigram_model"
require_relative "lib/python_random"

MIN_LEN = 4
MAX_LEN = 18
PER_SOURCE = Integer(ENV.fetch("MINE_PER_SOURCE", "60"))
RANDOM_PER_SOURCE = Integer(ENV.fetch("MINE_RANDOM", "12"))
STRIDE = Integer(ENV.fetch("MINE_STRIDE", "7"))
LOW = 0.5
HIGH = 2.5
CORPUS_HAN_RUN = /[\u{4E00}-\u{9FFF}]+/

words, = Segmenter.vocabulary(Corpus.corpora("segvocab.json"))
limit = Segmenter.max_word(words)
unigram = BigramModel.unigram_model(limit)
model = BigramModel.load

random = Corpus::PythonRandom.new(20260725)
picked = []
seen = Set.new
stats = Hash.new { |memo, key| memo[key] = [0, 0, 0] }

Corpus.data("corpora/sentences").glob("*.json").sort.each do |path|
  name = path.basename(".json").to_s
  rows = Corpus.read_json(path)

  pool = Hash.new { |memo, key| memo[key] = [] }
  control = []

  rows.each_with_index do |text, index|
    next unless (index % STRIDE).zero?

    text.scan(CORPUS_HAN_RUN).each do |run|
      next unless (MIN_LEN..MAX_LEN).cover?(run.length)
      next unless seen.add?(run)

      stats[name][0] += 1
      base = Segmenter.segment(run, words, unigram)
      middle = BigramModel.viterbi(run, words, model, limit, 1.25)

      if base != middle
        pool["unigram"] << [run, base, middle]
        stats[name][1] += 1
        next
      end

      low = BigramModel.viterbi(run, words, model, limit, LOW)
      high = BigramModel.viterbi(run, words, model, limit, HIGH)

      if low != high
        pool["penalty"] << [run, low, high]
        stats[name][2] += 1
      elsif control.length < 4000
        control << [run, middle, middle]
      end
    end
  end

  [["unigram", 0.6], ["penalty", 0.4]].each do |kind, share|
    candidates = pool[kind]
    random.shuffle!(candidates)

    by_length = Hash.new { |memo, key| memo[key] = [] }
    candidates.each { |row| by_length[row[0].length / 4] << row }

    quota = (PER_SOURCE * share).to_i
    order = by_length.keys.sort
    index = 0

    while quota.positive? && order.any? { |key| by_length[key].any? }
      key = order[index % order.length]
      index += 1
      next if by_length[key].empty?

      run, first, second = by_length[key].pop
      picked << {"text" => run, "source" => name, "reason" => kind, "a" => first, "b" => second, "set" => "hard"}
      quota -= 1
    end
  end

  random.shuffle!(control)
  control.first(RANDOM_PER_SOURCE).each do |run, first, _|
    picked << {"text" => run, "source" => name, "reason" => "random", "a" => first, "b" => first, "set" => "random"}
  end

  Corpus.say(
    format("%-20s runs %7d  models differ %6d  penalty differs %6d", name, *stats[name])
  )
end

random.shuffle!(picked)
target = Corpus.write_json(Corpus.data("huayu/segmentation_candidates.json"), picked, pretty: true)

hard = picked.count { |row| row["set"] == "hard" }
Corpus.say("")
Corpus.report("picked", total: picked.length, hard: hard, random: picked.length - hard, path: target.basename)

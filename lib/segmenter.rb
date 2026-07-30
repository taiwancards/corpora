# frozen_string_literal: true

require_relative "corpus"

module Segmenter
  HAN_RUN = /[\u{4E00}-\u{9FFF}\u{3400}-\u{4DBF}]+/
  SENT_SPLIT = /[。！？；\n]/
  MAX_WORD = 8

  Model = Data.define(:cost, :char_cost, :unseen_word, :unseen_char, :max_word)

  module_function

  def han_runs(text) = text.scan(HAN_RUN)

  def max_word(words) = [words.map(&:length).max.to_i, MAX_WORD].min

  def vocabulary(path)
    data = Corpus.read_json(path)
    [entries(data.fetch("words")), entries(data.fetch("chars"))]
  end

  def entries(value) = (value.is_a?(Hash) ? value.keys : Array(value)).to_set

  def naive_counts(runs, words, limit)
    word_counts = Hash.new(0)
    char_counts = Hash.new(0)

    runs.each do |run|
      chars = run.chars
      size = chars.length
      chars.each { |char| char_counts[char] += 1 }

      size.times do |start|
        stop = [limit, size - start].min
        (2..stop).each do |length|
          token = chars[start, length].join
          word_counts[token] += 1 if words.include?(token)
        end
      end
    end

    [word_counts, char_counts]
  end

  def build_model(word_counts, char_counts, limit)
    total = word_counts.each_value.sum + char_counts.each_value.sum
    total = 1 if total.zero?

    Model.new(
      cost: word_counts.transform_values { |count| -Math.log(count.fdiv(total)) },
      char_cost: char_counts.transform_values { |count| -Math.log(count.fdiv(total)) },
      unseen_word: -Math.log(0.5 / total),
      unseen_char: -Math.log(0.2 / total),
      max_word: limit
    )
  end

  def segment(run, words, model)
    chars = run.chars
    size = chars.length
    best = Array.new(size + 1, Float::INFINITY)
    best[0] = 0.0
    back = Array.new(size + 1, 0)

    (1..size).each do |stop|
      low = [1, stop - model.max_word + 1].max
      (low..stop).each do |start|
        previous = best[start - 1]
        next if previous.infinite?

        token = chars[(start - 1)...stop].join
        price = if token.length == 1
          model.char_cost.fetch(token, model.unseen_char)
        elsif words.include?(token)
          model.cost.fetch(token, model.unseen_word)
        end

        next if price.nil?

        value = previous + price
        if value < best[stop]
          best[stop] = value
          back[stop] = start - 1
        end
      end
    end

    pieces = []
    stop = size
    while stop.positive?
      start = back[stop]
      pieces << chars[start...stop].join
      stop = start
    end

    pieces.reverse
  end

  def recount(runs, words, model)
    word_counts = Hash.new(0)
    char_counts = Hash.new(0)

    runs.each do |run|
      segment(run, words, model).each do |token|
        (token.length == 1 ? char_counts : word_counts)[token] += 1
      end
    end

    [word_counts, char_counts]
  end

  def expectation_maximisation(runs, words, limit, rounds:)
    word_counts, char_counts = naive_counts(runs, words, limit)

    rounds.times do
      model = build_model(word_counts, char_counts, limit)
      word_counts, char_counts = recount(runs, words, model)
    end

    [word_counts, char_counts]
  end
end

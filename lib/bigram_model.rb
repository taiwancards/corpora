# frozen_string_literal: true

require_relative "segmenter"

module BigramModel
  START = "<s>"
  FLOOR = 1e-9
  SETS = %w[seed hard random].freeze

  Model = Data.define(:table, :weights, :continuation, :unigram)

  module_function

  def frequency_payload = @frequency ||= Corpus.read_json(Corpus.data("huayu/corpus_frequency.json"))

  def unigram_probabilities
    payload = frequency_payload
    scale = payload.fetch("words").each_value.sum + payload.fetch("chars").each_value.sum
    table = payload.fetch("words").transform_values { |value| value / scale.to_f }
    payload.fetch("chars").each { |token, value| table[token] = value / scale.to_f }
    table
  end

  def unigram_model(limit)
    payload = frequency_payload
    Segmenter.build_model(payload.fetch("words"), payload.fetch("chars"), limit)
  end

  def load(path = Corpus.data("huayu/bigram_frequency.json"))
    payload = Corpus.read_json(path)

    table = {}
    payload.fetch("bigram").each do |context, row|
      row.each { |token, value| (table[token] ||= {})[context] = value }
    end

    continuation = payload.fetch("continuation")
    if continuation.each_value.max.to_f > 1
      continuation = continuation.transform_values { |value| value / 1_000_000.0 }
    end

    Model.new(
      table: table,
      weights: payload.fetch("lambda"),
      continuation: continuation,
      unigram: unigram_probabilities
    )
  end

  def viterbi(run, words, model, limit, penalty, floor: FLOOR)
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

        direct = model.table[token]
        base = model.continuation.fetch(token, 0.0)
        fallback = floor * model.unigram.fetch(token, floor)

        previous.each do |context, (cost, _, _)|
          probability = 0.0
          probability += direct.fetch(context, 0.0) if direct
          probability += model.weights.fetch(context, 0.0) * base
          probability = fallback if probability <= 0.0

          value = cost - Math.log(probability) + penalty
          current = best[stop][token]
          best[stop][token] = [value, start - 1, context] if current.nil? || value < current[0]
        end
      end
    end

    return [] if best[size].empty?

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

  def boundaries(pieces)
    position = 0
    pieces.each_with_object(Set.new) do |piece, memo|
      position += piece.length
      memo << position
    end
  end

  def score(gold, guessed)
    gold_set = boundaries(gold)
    guessed_set = boundaries(guessed)
    hit = (gold_set & guessed_set).size

    precision = hit / [guessed_set.size, 1].max.to_f
    recall = hit / [gold_set.size, 1].max.to_f
    return 0.0 if (precision + recall).zero?

    2 * precision * recall / (precision + recall)
  end

  def gold_cases = Corpus.read_json(Corpus.data("huayu/segmentation_gold.json"))

  def report(name, cases, &guess)
    exact = Hash.new(0)
    counted = Hash.new(0)
    f1 = Hash.new(0.0)

    cases.each do |kase|
      pieces = guess.call(kase["text"])
      group = kase["set"]
      counted[group] += 1
      counted["total"] += 1

      hit = pieces == kase["gold"] ? 1 : 0
      exact[group] += hit
      exact["total"] += hit

      value = score(kase["gold"], pieces)
      f1[group] += value
      f1["total"] += value
    end

    parts = (SETS + ["total"]).filter_map do |group|
      next if counted[group].zero?

      format(
        "%s %3d/%3d (%5.1f%%) F1 %.4f",
        group,
        exact[group],
        counted[group],
        100.0 * exact[group] / counted[group],
        f1[group] / counted[group]
      )
    end

    Corpus.say(format("%-26s ", name) + parts.join(" | "))
    [exact["total"], f1["total"] / [counted["total"], 1].max]
  end
end

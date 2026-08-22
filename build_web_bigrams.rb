#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "lib/bigram_model"
require_relative "lib/forked"

START = BigramModel::START
EM_ROUNDS = Integer(ENV.fetch("WEB_EM_ROUNDS", "2"))
BIGRAM_ROUNDS = Integer(ENV.fetch("WEB_BIGRAM_ROUNDS", "0"))
KEEP_MIN = Integer(ENV.fetch("WEB_KEEP_MIN", "2"))
SMOOTH_MIN = Integer(ENV.fetch("WEB_SMOOTH_MIN", "2"))
PENALTY = Float(ENV.fetch("WEB_PENALTY", "1.0"))
RUN_LIMIT = ENV["WEB_RUN_LIMIT"]&.to_i

def load_corpus(path, limit)
  runs = []
  hosts = []
  seen = {}

  path.each_line do |line|
    host, run = line.chomp.split("\t", 2)
    next if run.nil? || run.empty?

    runs << run
    hosts << (seen[host] ||= seen.size)
    break if limit && runs.length >= limit
  end

  groups = Array.new(seen.size) { [] }
  hosts.each_with_index { |host, index| groups[host] << index }

  [runs, groups]
end

def merge_counts(partials)
  merged = [Hash.new(0), Hash.new(0)]
  partials.each do |pair|
    pair.each_with_index do |counts, side|
      counts.each { |token, count| merged[side][token] += count }
    end
  end

  merged
end

def naive_shard(runs, groups, words, limit)
  word_counts = Hash.new(0)
  char_counts = Hash.new(0)

  groups.each do |indices|
    words_here = {}
    chars_here = {}

    indices.each do |index|
      chars = runs[index].chars
      size = chars.length
      chars.each { |char| chars_here[char] = true }

      size.times do |start|
        stop = [limit, size - start].min
        (2..stop).each do |length|
          token = chars[start, length].join
          words_here[token] = true if words.include?(token)
        end
      end
    end

    words_here.each_key { |token| word_counts[token] += 1 }
    chars_here.each_key { |char| char_counts[char] += 1 }
  end

  [word_counts, char_counts]
end

def naive_counts(runs, groups, words, limit)
  merge_counts(
    Forked.map(groups.length) { |shard| naive_shard(runs, groups.values_at(*shard), words, limit) }
  )
end

def recount_shard(runs, groups, words, model)
  word_counts = Hash.new(0)
  char_counts = Hash.new(0)

  groups.each do |indices|
    words_here = {}
    chars_here = {}

    indices.each do |index|
      Segmenter.segment(runs[index], words, model).each do |token|
        (token.length == 1 ? chars_here : words_here)[token] = true
      end
    end

    words_here.each_key { |token| word_counts[token] += 1 }
    chars_here.each_key { |char| char_counts[char] += 1 }
  end

  [word_counts, char_counts]
end

def recount(runs, groups, words, model)
  merge_counts(
    Forked.map(groups.length) { |shard| recount_shard(runs, groups.values_at(*shard), words, model) }
  )
end

def bigram_shard(runs, groups)
  bigrams = {}

  groups.each do |indices|
    here = {}

    indices.each do |index|
      pieces = yield(runs[index])
      next if pieces.nil? || pieces.empty?

      context = START
      pieces.each do |token|
        (here[context] ||= {})[token] = true
        context = token
      end
    end

    here.each do |context, row|
      target = (bigrams[context] ||= Hash.new(0))
      row.each_key { |token| target[token] += 1 }
    end
  end

  bigrams.each_value { |row| row.default = nil }
  bigrams
end

def count_bigrams(runs, groups, &splitter)
  merged = Hash.new { |memo, key| memo[key] = Hash.new(0) }
  partials = Forked.map(groups.length) do |shard|
    bigram_shard(runs, groups.values_at(*shard), &splitter)
  end

  partials.each do |partial|
    partial.each do |context, row|
      target = merged[context]
      row.each { |token, count| target[token] += count }
    end
  end

  merged
end

def aggregates(bigrams)
  history = {}
  preceders = Hash.new(0)
  total = 0
  distinct = 0

  bigrams.each do |context, row|
    sum = 0
    row.each do |token, count|
      sum += count
      preceders[token] += 1
      distinct += 1
    end

    history[context] = sum
    total += sum
  end

  [history, preceders, total, distinct]
end

def discount_for(bigrams)
  ones = twos = 0

  bigrams.each_value do |row|
    row.each_value do |count|
      ones += 1 if count == 1
      twos += 1 if count == 2
    end
  end

  total = ones + (2 * twos)
  total.zero? ? 0.75 : ones.fdiv(total)
end

def kneser_ney(bigrams, history, preceders, discount, minimum)
  continuation_total = preceders.each_value.sum
  continuation = preceders.transform_values { |value| value / continuation_total.to_f }

  table = {}
  spent = Hash.new(0.0)

  bigrams.each do |context, row|
    base = history[context].to_f
    next unless base.positive?

    row.each do |token, count|
      next if count < minimum

      value = [count - discount, 0.0].max / base
      next unless value.positive?

      (table[token] ||= {})[context] = value
      spent[context] += value
    end
  end

  weights = history.to_h { |context, _| [context, [1.0 - spent.fetch(context, 0.0), 0.0].max] }

  [table, weights, continuation]
end

words, = Segmenter.vocabulary(Corpus.corpora("segvocab.json"))
limit = Segmenter.max_word(words)
runs, groups = load_corpus(Corpus.corpora("web_runs.txt"), RUN_LIMIT)
Corpus.report("corpus", runs: runs.length, hosts: groups.length, vocabulary: words.size)

word_counts, char_counts = naive_counts(runs, groups, words, limit)
Corpus.report("naive counts", words: word_counts.size, characters: char_counts.size)

EM_ROUNDS.times do |step|
  model = Segmenter.build_model(word_counts, char_counts, limit)
  word_counts, char_counts = recount(runs, groups, words, model)
  Corpus.say(format("unigram EM %d: types %d, host counts %d", step + 1, word_counts.size, word_counts.each_value.sum))
end

model = Segmenter.build_model(word_counts, char_counts, limit)
bigrams = count_bigrams(runs, groups) { |run| Segmenter.segment(run, words, model) }
history, preceders, total, distinct = aggregates(bigrams)
Corpus.say(format("pass 0 (unigram): host counts %d, contexts %d, bigrams %d", total, history.size, distinct))

BIGRAM_ROUNDS.times do |step|
  table, weights, continuation = kneser_ney(bigrams, history, preceders, discount_for(bigrams), SMOOTH_MIN)
  current = BigramModel::Model.new(
    table: table,
    weights: weights,
    continuation: continuation,
    unigram: BigramModel.unigram_probabilities
  )

  bigrams = nil
  GC.start

  bigrams = count_bigrams(runs, groups) { |run| BigramModel.viterbi(run, words, current, limit, PENALTY) }
  history, preceders, total, distinct = aggregates(bigrams)
  Corpus.say(
    format("pass %d (bigram): host counts %d, contexts %d, bigrams %d", step + 1, total, history.size, distinct)
  )
end

discount = discount_for(bigrams)

kept = {}
dropped = 0
bigrams.each do |context, row|
  row.each do |token, count|
    if count < KEEP_MIN
      dropped += 1
      next
    end

    kept["#{context}\t#{token}"] = count
  end
end

payload = {
  "bigrams" => kept,
  "history" => history,
  "preceders" => preceders,
  "total" => total,
  "discount" => discount
}

target = Corpus.write_json(Corpus.corpora("bigram_counts.json"), payload)
Corpus.report("counts", kept: kept.size, dropped: dropped, discount: discount.round(6))
Corpus.report("file", megabytes: (target.size / 1024.0 / 1024).round(1), path: target.basename)

head = history.sort_by { |_, count| -count }.first(24).map { |token, count| "#{token}:#{count}" }
Corpus.say("head: #{head.join(" ")}")
Corpus.say("next: corpora/prune_bigrams.rb")

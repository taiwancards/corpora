#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "lib/corpus"

MIN_NODE = 50
MIN_PAIR = 5
KEEP = 12
WINDOW = 5

DEGREE = %w[很 非常 太 最 挺 蠻 滿 超 更 好].freeze
ASPECT = %w[了 過 著].freeze
RESULT = %w[完 好 到 上 下 出 起來 下去 過來 回來 進去 走 掉].freeze
NEGATION = %w[不 沒 沒有 別 甭].freeze
PREPOSITION = %w[在 對 跟 從 給 向 往 用 為 於 by].freeze
PRONOUN = %w[我 你 妳 他 她 它 您 我們 你們 他們 她們 大家 自己 這 那 誰].freeze
NUMERALS = %w[一 兩 二 三 四 五 六 七 八 九 十 幾 半 這 那 每].freeze

PAIRS = [
  %w[一 就],
  %w[越 越],
  %w[不但 而且],
  %w[雖然 但是],
  %w[雖然 可是],
  %w[除了 以外],
  %w[連 都],
  %w[又 又],
  %w[既 又],
  %w[因為 所以],
  %w[如果 就],
  %w[只要 就],
  %w[不是 而是],
  %w[一邊 一邊],
  %w[先 再]
].freeze

RELATIONS = %w[
  modifier
  modified
  manner
  complement
  degree
  disposal
  passive
  resultative
  aspect
  negated
  preposition
  classifier
  construction
]
  .freeze

def measure_words
  path = Corpus.data("huayu/measure_words.json")
  return Set.new unless path.exist?

  payload = Corpus.read_json(path)
  entries = payload.is_a?(Hash) ? payload.keys : payload.map { |row| row.is_a?(Hash) ? row["text"] : row }
  entries.compact.to_set
end

MEASURE = measure_words

class Counter
  def initialize
    @nodes = Hash.new(0)
    @pairs = Hash.new(0)
  end

  attr_reader :nodes, :pairs

  def observe(relation, head, tail)
    return if head.nil? || tail.nil? || head == tail

    @pairs[[relation, head, tail]] += 1
  end

  def merge!(other)
    other.nodes.each { |token, count| @nodes[token] += count }
    other.pairs.each { |key, count| @pairs[key] += count }
    self
  end
end

def scan(tokens, counter)
  tokens.each { |token| counter.nodes[token] += 1 }

  tokens.each_with_index do |token, index|
    left = index.positive? ? tokens[index - 1] : nil
    right = tokens[index + 1]

    case token
    when "的"
      counter.observe("modifier", right, left) unless PRONOUN.include?(left)
      counter.observe("modified", left, right)
    when "地"
      counter.observe("manner", right, left)
    when "得"
      counter.observe("complement", left, right)
    end

    counter.observe("degree", right, token) if DEGREE.include?(token)
    counter.observe("negated", right, token) if NEGATION.include?(token)
    counter.observe("aspect", left, token) if ASPECT.include?(token)
    counter.observe("resultative", left, token) if RESULT.include?(token) && left
    counter.observe("preposition", right, token) if PREPOSITION.include?(token)

    if NUMERALS.include?(token) && right && MEASURE.include?(right)
      counter.observe("classifier", tokens[index + 2], right)
    end

    verb_after(tokens, index, token, counter) if %w[把 被 讓 給].include?(token)
  end

  scan_pairs(tokens, counter)
end

def verb_after(tokens, index, marker, counter)
  object = tokens[index + 1]
  return if object.nil?

  relation = marker == "把" ? "disposal" : "passive"
  window = tokens[(index + 2)..(index + 1 + WINDOW)] || []
  window.each { |candidate| counter.observe(relation, candidate, object) }
end

def scan_pairs(tokens, counter)
  PAIRS.each do |opener, closer|
    first = tokens.index(opener)
    next if first.nil?

    tail = tokens[(first + 1)..(first + WINDOW + 3)] || []
    counter.observe("construction", "#{opener}…#{closer}", tokens[first + 1]) if tail.include?(closer)
  end
end

def log_dice(pair, head, tail)
  14 + Math.log2((2.0 * pair) / (head + tail))
end

lines = Corpus.corpora("segmented_tokens.txt")
raise "#{lines} is missing" unless lines.exist?

Corpus.say("reading #{lines.basename}")
chunks = []
buffer = []
lines.each_line do |line|
  buffer << line.split
  if buffer.length >= 50_000
    chunks << buffer
    buffer = []
  end
end

chunks << buffer if buffer.any?
Corpus.say("chunks #{chunks.length}")

counter = Corpus
  .each_slice_parallel(chunks) { |group|
    local = Counter.new
    group.each { |rows| rows.each { |tokens| scan(tokens, local) } }
    local
  }
  .reduce(Counter.new) { |memo, part| memo.merge!(part) }

Corpus.report("counted", nodes: counter.nodes.size, pairs: counter.pairs.size)

frequent = counter.nodes.select { |_, count| count >= MIN_NODE }
Corpus.report("nodes kept", above_floor: frequent.size, floor: MIN_NODE)

grouped = Hash.new { |memo, key| memo[key] = [] }
counter.pairs.each do |(relation, head, tail), count|
  next if count < MIN_PAIR

  head_total = counter.nodes[head]
  tail_total = counter.nodes[tail]
  next if head_total < MIN_NODE || tail_total.zero?

  grouped[[head, relation]] << [tail, log_dice(count, head_total, tail_total).round(3), count]
end

payload = Hash.new { |memo, key| memo[key] = {} }
grouped.each do |(head, relation), rows|
  payload[head][relation] = rows.sort_by { |(_, score, count)| [-score, -count] }.first(KEEP)
end

target = Corpus.data("huayu/word_sketches.jsonl")
target.dirname.mkpath
target.open("w") do |file|
  payload.sort.each { |head, relations| file.puts(JSON.generate({"h" => head, "r" => relations})) }
end

Corpus.report(
  "sketches",
  heads: payload.size,
  relations: payload.values.sum(&:size),
  collocates: payload.values.sum { |rows| rows.values.sum(&:size) },
  path: target.basename
)

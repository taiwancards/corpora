# frozen_string_literal: true

require "json"

ROOT = File.expand_path("..", __dir__)
LOOKUP = File.join(ROOT, "storage/json/cangjie5.json")
INDEX = File.join(ROOT, "data/huayu/cangjie_index.json")
PATH = File.join(ROOT, "data/huayu/cangjie_lessons.json")

require_relative "../app/services/huayu/cangjie"

KEYS = Huayu::Cangjie::KEYS
CORE = 120
EXAM_LEVELS = %w[Novice1 Novice2 A1].freeze

GROUPS = [
  {
    "id" => "nature",
    "zh" => "哲理類",
    "keys" => %w[a b c d e f g],
    "ru" => "Природа: то, что снаружи человека",
    "en" => "Nature: the world outside a person"
  },
  {
    "id" => "strokes",
    "zh" => "筆劃類",
    "keys" => %w[h i j k l m n],
    "ru" => "Черты: не иероглифы, а движения кисти",
    "en" => "Strokes: not characters but brush movements"
  },
  {
    "id" => "body",
    "zh" => "人體類",
    "keys" => %w[o p q r],
    "ru" => "Человек: то, что при нём самом",
    "en" => "The body: what a person is made of"
  },
  {
    "id" => "shapes",
    "zh" => "字形類",
    "keys" => %w[s t u v w y],
    "ru" => "Формы: замкнутые и полузамкнутые очертания",
    "en" => "Shapes: closed and half-closed outlines"
  },
  {
    "id" => "special",
    "zh" => "特別鍵",
    "keys" => %w[x z],
    "ru" => "Служебные клавиши",
    "en" => "Utility keys"
  }
].freeze

STAGES = [
  {"id" => "basics", "ru" => "Как работает цанцзе", "en" => "How Cangjie works"},
  {"id" => "letters", "ru" => "Двадцать четыре буквы", "en" => "The twenty-four letters"},
  {"id" => "splitting", "ru" => "Разбиение иероглифа", "en" => "Splitting a character"},
  {"id" => "exceptions", "ru" => "Исключения", "en" => "Exceptions"},
  {"id" => "taiwan", "ru" => "Тайвань на клавиатуре", "en" => "Taiwan on the keyboard"}
].freeze

AUXILIARY = {
  "a" => 1,
  "b" => 5,
  "c" => 3,
  "d" => 2,
  "e" => 4,
  "f" => 4,
  "g" => 1,
  "h" => 2,
  "i" => 3,
  "j" => 1,
  "k" => 3,
  "l" => 3,
  "m" => 4,
  "n" => 6,
  "o" => 7,
  "p" => 6,
  "q" => 4,
  "r" => 0,
  "s" => 5,
  "t" => 6,
  "u" => 3,
  "v" => 5,
  "w" => 2,
  "y" => 4
}.freeze

CONFUSABLE = {
  "a" => %w[b w r],
  "b" => %w[a n s],
  "c" => %w[f t o],
  "d" => %w[j q h],
  "e" => %w[i v n],
  "f" => %w[c n h],
  "g" => %w[j m q],
  "h" => %w[i o d],
  "i" => %w[h y e],
  "j" => %w[d m g],
  "k" => %w[i o x],
  "l" => %w[h j n],
  "m" => %w[j l g],
  "n" => %w[s p v],
  "o" => %w[c h k],
  "p" => %w[o n u],
  "q" => %w[d g m],
  "r" => %w[w a s],
  "s" => %w[n r b],
  "t" => %w[c y j],
  "u" => %w[v l p],
  "v" => %w[u n e],
  "w" => %w[r a b],
  "y" => %w[i t o],
  "x" => %w[k i n],
  "z" => %w[x m j]
}.freeze

class Table
  def initialize(path)
    raw = JSON.parse(File.read(path))
    @primary = {}
    @all = Hash.new { |memo, key| memo[key] = [] }
    raw.each do |code, chars|
      chars.each do |char|
        @primary[char] ||= code
        @all[char] << code
      end
    end
  end

  MARKED = {"晾" => "xayrf", "筍" => "xhpa"}.freeze

  def code(char)
    return MARKED[char] if MARKED.key?(char)
    return nil if @primary[char].nil?

    Huayu::Cangjie.fifth(char, @primary[char])
  end

  def codes(char) = @all[char]
  def known?(char) = @primary.key?(char)
end

class Builder
  attr_reader :problems

  def initialize(table)
    @table = table
    @problems = []
    @lessons = []
  end

  def lesson(slug, stage:, key: nil, **rest)
    row = {"slug" => slug, "stage" => stage, "key" => key}
    row["letter"] = KEYS.fetch(key) if key
    row.merge!(rest.transform_keys(&:to_s))
    @lessons << row
    row
  end

  def entry(char, slug)
    code = @table.code(char)
    if code.nil?
      @problems << "#{slug}: #{char} has no Cangjie code"
      return nil
    end

    {"char" => char, "code" => code, "parts" => code.chars.map { |letter| KEYS.fetch(letter) }}
  end

  def entries(chars, slug) = Array(chars).filter_map { |char| entry(char, slug) }
  def resolve!
    @lessons.each_with_index do |lesson, index|
      lesson["id"] = index + 1
      slug = lesson["slug"]
      Array(lesson["blocks"]).each { |block| resolve_block(block, slug) }
      lesson["bank"] = entries(lesson["bank"], slug)
      audit(lesson)
    end

    attach_index
    pool = @lessons.flat_map { |lesson| lesson["bank"] }.uniq { |row| row["char"] }
    shapes = @lessons.flat_map { |lesson| shape_rows(lesson) }
    @lessons.each { |lesson| lesson["drills"] = Drills.new(lesson, pool, shapes).call }
    self
  end

  def payload
    {
      "groups" => GROUPS,
      "stages" => STAGES,
      "core" => @core.to_a,
      "exam" => @exam.to_a,
      "lessons" => @lessons
    }
  end

  def attach_index
    return @problems << "cangjie_index.json is missing; run corpora/build_cangjie_index.rb" unless File.exist?(INDEX)

    index = JSON.parse(File.read(INDEX))
    rows = index.values.flatten
    @core = rows
      .select { |row| row["rank"] }
      .sort_by { |row| row["rank"] }
      .first(CORE)
      .map { |row| row.slice("char", "code") }
    @exam = rows
      .select { |row| EXAM_LEVELS.include?(row["level"]) }
      .sort_by { |row| [EXAM_LEVELS.index(row["level"]), row["rank"] || Float::INFINITY] }
      .map { |row| row.slice("char", "code") }
    @lessons.each do |lesson|
      listing = index[lesson["key"].to_s]
      next if listing.nil?

      lesson["index"] = listing.map { |row| row.slice("char", "code", "level") }
    end
  end

  private

  def shape_rows(lesson)
    return [] if lesson["key"].nil?

    Array(lesson["blocks"])
      .select { |block| block["kind"] == "shapes" }
      .flat_map { |block| Array(block["rows"]) }
      .select { |row| row["glyph"] }
      .map { |row| {"glyph" => row["glyph"], "rotate" => row["rotate"], "key" => lesson["key"], "id" => lesson["id"]} }
  end

  def audit(lesson)
    key = lesson["key"]
    return if key.nil? || key == "z" || lesson["stage"] != "letters"

    rows = lesson["bank"] +
      Array(lesson["blocks"])
        .select { |block| block["kind"] == "shapes" }
        .flat_map { |block| Array(block["rows"]).flat_map { |row| row["chars"].to_a } }

    rows.each do |row|
      next if row["code"].include?(key)

      @problems << "#{lesson["slug"]}: #{row["char"]} (#{row["code"]}) never presses #{key}"
    end

    shown = Array(lesson["blocks"])
      .select { |block| block["kind"] == "shapes" }
      .sum { |block| Array(block["rows"]).size }
    wanted = AUXILIARY[key].to_i + 1
    return if shown >= wanted || AUXILIARY[key].nil?

    @problems << "#{lesson["slug"]}: shows #{shown - 1} auxiliary shapes, the 字母表 lists #{wanted - 1}"
  end

  def resolve_block(block, slug)
    Array(block["rows"]).each do |row|
      row["chars"] = entries(row["chars"], slug) if row.key?("chars")
      resolve_walk(row, slug) if row.key?("char")
    end

    block["chars"] = entries(block["chars"], slug) if block.key?("chars")
  end

  def resolve_walk(row, slug)
    resolved = entry(row["char"], slug)
    return if resolved.nil?

    row.merge!(resolved)
    if row["wrong"].is_a?(String)
      wrong = row["wrong"]
      row["wrong"] = {"code" => wrong, "parts" => wrong.chars.map { |letter| KEYS.fetch(letter) }}
      @problems << "#{slug}: #{row["char"]} wrong code equals the right one" if wrong == row["code"]
    end

    return if row["pieces"].nil?

    return if row["pieces"].size == row["code"].size

    @problems << "#{slug}: #{row["char"]} has #{row["pieces"].size} pieces for code #{row["code"]}"
  end
end

class Drills
  TASKS = 14
  QUOTA = {shape: 3, which: 2, first: 3, split: 3, code: 3}.freeze

  def initialize(lesson, pool, shapes)
    @lesson = lesson
    @pool = pool
    @shape_pool = shapes
    @random = Random.new(lesson["slug"].sum)
  end

  def call
    banks = {shape: shape_tasks, which: which_tasks, first: first_tasks, split: split_tasks, code: code_tasks}
    banks = banks.to_h { |kind, rows| [kind, kind == :shape ? rows : rows.shuffle(random: @random)] }
    taken = QUOTA.flat_map { |kind, count| banks[kind].first(count) }
    spare = QUOTA.flat_map { |kind, count| banks[kind].drop(count) }
    (taken + spare).first(TASKS)
  end

  private

  def shapes
    @shapes ||= Array(@lesson["blocks"])
      .select { |block| block["kind"] == "shapes" }
      .flat_map { |block| Array(block["rows"]) }
      .select { |row| row["glyph"] }
  end

  def bank = @lesson["bank"].to_a
  def key_options(right)
    pool = (CONFUSABLE.fetch(right, []) + KEYS.keys - [right, "x", "z"]).uniq
    options = ([right] + pool.first(6).shuffle(random: @random).first(3)).shuffle(random: @random)
    {
      "options" => options.map { |letter| {"key" => letter, "letter" => KEYS.fetch(letter)} },
      "answer" => options.index(right)
    }
  end

  def shape_tasks
    own = shapes.first(2).map { |row| shape_task(row["glyph"], row["rotate"], @lesson["key"]) }
    seen = @shape_pool.select { |row| row["id"] < @lesson["id"] && row["key"] != @lesson["key"] }
    revision = seen
      .shuffle(random: @random)
      .first(4)
      .map { |row| shape_task(row["glyph"], row["rotate"], row["key"]) }

    own + revision
  end

  def shape_task(glyph, rotate, key)
    {"kind" => "shape", "glyph" => glyph, "rotate" => rotate}.merge(key_options(key))
  end

  def first_tasks
    bank.first(6).map do |row|
      {"kind" => "first", "char" => row["char"]}.merge(key_options(row["code"][0]))
    end
  end

  def code_tasks
    bank.map { |row| {"kind" => "code", "char" => row["char"], "code" => row["code"]} }
  end

  def which_tasks
    key = @lesson["key"]
    return [] if key.nil? || key == "z"

    strangers = @pool.reject { |row| row["code"].include?(key) }
    return [] if strangers.size < 3

    bank.select { |row| row["code"].include?(key) }.map do |row|
      others = strangers.sample(3, random: @random)
      options = ([row] + others).shuffle(random: @random)
      {
        "kind" => "which",
        "glyph" => @lesson["letter"],
        "options" => options.map { |item| {"char" => item["char"], "code" => item["code"]} },
        "answer" => options.index(row)
      }
    end
  end

  def split_tasks
    bank.select { |row| row["code"].size.between?(2, 5) }.map do |row|
      wrong = wrong_codes(row["code"])
      options = ([row["code"]] + wrong).shuffle(random: @random)
      {
        "kind" => "split",
        "char" => row["char"],
        "options" => options.map { |code| {"code" => code, "parts" => code.chars.map { |l| KEYS.fetch(l) }} },
        "answer" => options.index(row["code"])
      }
    end
  end

  def wrong_codes(code)
    seen = [code]
    guard = 0
    while seen.size < 4 && guard < 40
      guard += 1
      candidate = @random.rand(3).zero? ? swap(code) : mutate(code)
      seen << candidate if candidate && !seen.include?(candidate)
    end

    while seen.size < 4
      seen << (seen.last + KEYS.keys.sample(random: @random))
    end

    seen.drop(1)
  end

  def swap(code)
    return nil if code.size < 2

    spot = @random.rand(code.size - 1)
    chars = code.chars
    chars[spot], chars[spot + 1] = chars[spot + 1], chars[spot]
    chars.join
  end

  def mutate(code)
    spot = @random.rand(code.size)
    chars = code.chars
    chars[spot] = CONFUSABLE.fetch(chars[spot], KEYS.keys).sample(random: @random)
    chars.join
  end
end

require_relative "cangjie_lessons_content"
require_relative "cangjie_lessons_strokes"
require_relative "cangjie_lessons_shapes"
require_relative "cangjie_lessons_rules"

table = Table.new(LOOKUP)
builder = Builder.new(table)
CangjieContent::SECTIONS.each { |section| CangjieContent.public_send(section, builder) }
builder.resolve!

if builder.problems.any?
  warn("#{builder.problems.size} problems:")
  builder.problems.each { |line| warn("  #{line}") }
  abort("#{PATH} not written")
end

payload = builder.payload
File.write(PATH, "#{JSON.pretty_generate(payload)}\n")
puts("#{payload["lessons"].size} lessons -> #{PATH}")

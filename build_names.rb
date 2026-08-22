#!/usr/bin/env ruby
# frozen_string_literal: true

require "csv"

require_relative "lib/corpus"
require_relative "lib/spreadsheet"

DIRECTORY = "moi"
SPREADSHEETS = %w[.ods .xlsx .zip].freeze
SURNAME_HEADERS = %w[姓氏 姓 lastname].freeze
GIVEN_HEADERS = %w[名字 命名 姓名 名].freeze
NOT_A_NAME = %w[排名 名次 名列].freeze
COUNT_HEADERS = %w[人口數 人數 人数 數量 数量 個數].freeze
SEX_HEADERS = %w[性別 性别].freeze
AGE_HEADERS = %w[age 年齡 年龄].freeze
YOUNG = "0~14"
MALE = %w[男 男性].freeze
FEMALE = %w[女 女性].freeze
MIN_COUNT = 1
MAX_LENGTH = 4

def tables(root)
  return [] unless root.exist?

  root.children.sort.filter_map do |path|
    next unless path.file?

    rows = read(path)
    rows.presence && [path.basename.to_s, rows]
  end
end

def read(path)
  name = path.to_s
  return Spreadsheet.rows(path) if SPREADSHEETS.any? { |suffix| name.end_with?(suffix) }
  return CSV.read(name, headers: false, encoding: "bom|utf-8") if name.end_with?(".csv")

  []
rescue StandardError => e
  Corpus.say("names: #{path.basename} unreadable (#{e.class})")
  []
end

def header_row(rows)
  rows.first(5).each_with_index do |row, index|
    cells = row.map { |cell| Corpus.strip(cell) }
    return [index, cells] if column(cells, COUNT_HEADERS)
  end

  [nil, []]
end

def column(cells, needles, except: [])
  cells.index do |cell|
    next false if except.any? { |needle| cell.include?(needle) }

    needles.any? { |needle| cell.include?(needle) }
  end
end

def clean(value) = Corpus.strip(value)

def number(value)
  digits = value.to_s.gsub(/[^0-9]/, "")
  digits.empty? ? nil : digits.to_i
end

def usable?(text)
  return false if text.empty? || text.length > MAX_LENGTH

  text.match?(Corpus::HAN)
end

def sex_of(value)
  text = clean(value)
  return "male" if MALE.include?(text)
  return "female" if FEMALE.include?(text)

  nil
end

def collect(rows)
  index, cells = header_row(rows)
  return nil if index.nil?

  {
    body: rows.drop(index + 1),
    count: column(cells, COUNT_HEADERS),
    surname: column(cells, SURNAME_HEADERS, except: NOT_A_NAME),
    age: column(cells, AGE_HEADERS),
    given: column(cells, GIVEN_HEADERS, except: NOT_A_NAME),
    sex: column(cells, SEX_HEADERS)
  }
end

def tally(body, text_at:, count_at:, sex_at: nil, age_at: nil)
  totals = Hash.new(0)
  young = Hash.new(0)
  sexes = {}

  body.each do |row|
    text = clean(row[text_at])
    amount = number(row[count_at])
    next unless amount && amount >= MIN_COUNT && usable?(text)

    totals[text] += amount
    young[text] += amount if age_at && clean(row[age_at]).start_with?(YOUNG)
    sex = sex_at && sex_of(row[sex_at])
    sexes[text] = sex if sex && sexes[text].nil?
  end

  [totals, sexes, young]
end

def ranked(totals, sexes = {}, young = {})
  whole = totals.values.sum
  youngest = young.values.sum
  return [] if whole.zero?

  totals.sort_by { |text, amount| [-amount, text] }.each_with_index.map do |(text, amount), position|
    row = {"text" => text, "count" => amount, "rank" => position + 1, "share" => (amount.to_f / whole).round(6)}
    row["young_share"] = (young[text].to_f / youngest).round(6) if youngest.positive?
    sex = sexes[text]
    sex ? row.merge("sex" => sex) : row
  end
end

surnames = Hash.new(0)
surnames_young = Hash.new(0)
given = Hash.new(0)
given_sexes = {}
seen = 0

tables(Corpus.corpora(DIRECTORY)).each do |name, rows|
  layout = collect(rows)
  next Corpus.say("names: #{name} has no recognised count column") if layout.nil?

  seen += 1

  if layout[:surname]
    counts, _sexes, young = tally(
      layout[:body],
      text_at: layout[:surname],
      count_at: layout[:count],
      age_at: layout[:age]
    )
    counts.each { |text, amount| surnames[text] += amount }
    young.each { |text, amount| surnames_young[text] += amount }
    Corpus.report("names/#{name}", surnames: counts.size, young: young.values.sum)
  end

  next unless layout[:given]

  counts, sexes = tally(layout[:body], text_at: layout[:given], count_at: layout[:count], sex_at: layout[:sex])
  counts.each { |text, amount| given[text] += amount }
  given_sexes.merge!(sexes) { |_key, existing, _new| existing }
  Corpus.report("names/#{name}", given: counts.size)
end

if seen.zero?
  Corpus.say("names: nothing under #{DIRECTORY}, skipped")
  exit(0)
end

payload = {"surnames" => ranked(surnames, {}, surnames_young), "given" => ranked(given, given_sexes)}
target = Corpus.write_json(Corpus.data("huayu/taiwan_names.json"), payload)
Corpus.report("taiwan names", surnames: payload["surnames"].size, given: payload["given"].size, path: target.basename)

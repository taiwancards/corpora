#!/usr/bin/env ruby
# frozen_string_literal: true

require "csv"
require "roo"

require_relative "lib/corpus"

NUMERALS = "一二三四五六七八九十兩百千萬幾半這那每"
NUM_RUN = /[#{NUMERALS}]+/
LIANGCI = /量詞|計算[^。]{0,30}的單位/
POS_TAG = /\[(名|動|形|副|代|助|介|連|歎|嘆|擬|量|綴)\]/
EXAMPLE = /\[例\]([^⏎\n]*)/
COUNTER_PREFIX = (NUMERALS + "大小多幾整").chars.to_set
BOUNDARY = "的了是在和與或就都也而但卻很沒不會要能可又還請將被把給對從跟為以之"
  .chars
  .to_set
HAN_RANGE = ("\u{3400}".."\u{9FFF}")

MAX_WORD = 6
MIN_CORPUS = 3
NOUN_CATEGORIES = %w[individual collective container partition temporary].to_set

NOT_A_NOUN = %w[
  一些
  一樣
  一點
  上
  上下
  下
  中
  之
  之一
  之中
  之內
  之前
  之外
  之後
  之間
  人家
  什麼
  他
  他們
  以上
  以下
  以來
  以內
  以前
  以外
  以後
  你
  你們
  來
  內
  其中
  別人
  前
  前後
  可以
  同時
  外
  多少
  大家
  她
  她們
  妳
  它
  它們
  左右
  後
  我
  我們
  是
  時候
  時間
  會
  有
  期間
  本身
  止
  沒
  沒有
  為止
  當中
  當時
  者
  能
  自己
  裡
  要
  誰
  起
  開始
]
  .to_set

EXCLUDE = [
  %w[行 博物館],
  %w[行 遺址],
  %w[行 臉],
  %w[重 站],
  %w[重 方向],
  %w[股 國小],
  %w[股 地區],
  %w[股 方向],
  %w[層 遺址],
  %w[層 塔],
  %w[邊 可能],
  %w[邊 說明],
  %w[邊 回答],
  %w[邊 目前],
  %w[邊 站],
  %w[家 大小],
  %w[家 燈火],
  %w[家 站],
  %w[家 龍],
  %w[個 站],
  %w[個 女],
  %w[個 男],
  %w[個 表],
  %w[個 基本],
  %w[個 比較],
  %w[個 現在],
  %w[個 臺灣],
  %w[個 台灣],
  %w[個 目前],
  %w[種 女生],
  %w[種 地方],
  %w[種 專業],
  %w[張 站],
  %w[張 臺灣],
  %w[位 努力],
  %w[位 數],
  %w[位 許],
  %w[條 情形],
  %w[座 典型],
  %w[艘 補助],
  %w[部 外匯],
  %w[堆 中國],
  %w[堆 台灣],
  %w[堆 南部],
  %w[堆 國中],
  %w[堆 妹],
  %w[堵 站],
  %w[劑 才能],
  %w[格 公園],
  %w[格 路],
  %w[所 網球]
].to_set

def han_only?(word) = word.each_char.all? { |char| HAN_RANGE.cover?(char) }

def clean(text) = text.to_s.gsub("_x000D_", "\n").tr("\r", "\n")

def read_xlsx(path)
  return to_enum(:read_xlsx, path) unless block_given?
  return unless path.exist?

  sheet = Roo::Excelx.new(path.to_s)
  sheet.default_sheet = sheet.sheets.first
  header = sheet.row(1)
  index = %w[字詞名 釋義 注音一式 漢語拼音].to_h { |name| [name, header.index(name)] }

  (2..sheet.last_row).each do |number|
    row = sheet.row(number)
    word = row[index["字詞名"]]
    gloss = row[index["釋義"]]
    next if word.nil? || gloss.nil?

    yield word.to_s, clean(gloss), row[index["注音一式"]], row[index["漢語拼音"]]
  end
end

def tocfl_forms(row)
  raw = row["Variants"].to_s
  unless Corpus.strip(raw).empty?
    begin
      parsed = JSON.parse(raw)
      forms = parsed.filter_map { |entry| Corpus.strip(entry["Traditional"].to_s).presence }
      return forms
    rescue JSON::ParserError
      nil
    end
  end

  row["Traditional"].to_s.split(/[\/／]/).filter_map { |form| Corpus.strip(form).presence }
end

def parts_of_speech
  tocfl = {}
  CSV.foreach(Corpus.data("huayu/tocfl.csv"), headers: true, encoding: "bom|utf-8") do |row|
    tocfl_forms(row).each { |form| tocfl[form] = row["POS"].to_s }
  end

  moe = {}
  read_xlsx(Corpus.corpora("moedict/dict_revised.xlsx")) do |word, gloss, _, _|
    tags = gloss.scan(POS_TAG).flatten
    (moe[word] ||= Set.new).merge(tags) if tags.any?
  end

  [tocfl, moe.transform_values(&:sort)]
end

def classifier_entries
  entries = {}
  read_xlsx(Corpus.corpora("moedict/dict_concised.xlsx")) do |word, gloss, zhuyin, pinyin|
    next if word.length > 2 || !gloss.match?(LIANGCI)

    start = gloss.index("量詞")
    tail = (start ? gloss[start..] : gloss).split(/\n[[:space:]]*[[:digit:]]+\./).first.to_s
    entries[word] = {"zhuyin" => zhuyin, "pinyin" => pinyin, "gloss" => Corpus.strip(tail)}
  end

  entries
end

def dictionary_words
  words = Set.new
  words.merge(Corpus.read_json(Corpus.corpora("concised.json")).map { |entry| entry["word"] })
  words.merge(Corpus.read_json(Corpus.data("huayu/school_levels.json")).map { |row| row["traditional"] })
  CSV.foreach(Corpus.data("huayu/tocfl.csv"), headers: true, encoding: "bom|utf-8") { |row|
    words.merge(tocfl_forms(row))
  }
  words.select { |word| word && !word.empty? && han_only?(word) }.to_set
end

def moe_pairs(entries, words)
  found = Set.new
  entries.each do |classifier, entry|
    entry["gloss"].scan(EXAMPLE).flatten.each do |example|
      example.split(/[、，,　]/).each do |raw|
        item = Corpus.strip(raw)
        next unless item.include?(classifier)

        head, _, noun = item.partition(classifier)
        next if head.empty? || !head.chars.all? { |char| COUNTER_PREFIX.include?(char) }

        trimmed = noun.gsub(/\A[。」「.]+|[。」「.]+\z/, "")
        found << [classifier, trimmed] if words.include?(trimmed)
      end
    end
  end

  found
end

def cedict_pairs(words)
  path = Corpus.app_root.join("dict_and_corpora/dictionaries/cedict.json")
  return {} unless path.exist?

  found = {}
  Corpus.read_json(path).each do |headword, entry|
    next unless words.include?(headword)

    Array(entry["glosses"]).each do |gloss|
      next unless gloss.start_with?("CL:")

      gloss[3..].split(",").each_with_index do |item, position|
        classifier = Corpus.strip(item.split("|").first.to_s.gsub(/\[.*?\]/, ""))
        found[[classifier, headword]] ||= position unless classifier.empty?
      end
    end
  end

  found
end

def corpus_pairs(classifiers, words, noun_test)
  counts = Hash.new(0)
  loose = Hash.new(0)
  usage = Hash.new(0)
  sentences = 0

  longest = lambda do |chars, start|
    [MAX_WORD, chars.length - start].min.downto(1) do |length|
      token = chars[start, length].join
      return token if words.include?(token)
    end

    nil
  end

  Corpus.data("corpora/sentences").glob("*.json").sort.each do |path|
    Corpus.read_json(path).each do |sentence|
      sentences += 1
      chars = sentence.chars

      offset = 0
      while (match = NUM_RUN.match(sentence, offset))
        start = match.begin(0)
        after = match.end(0)
        offset = after
        next if start.positive? && "第進退".include?(chars[start - 1])
        next if after >= chars.length

        [2, 1].each do |size|
          classifier = chars[after, size]&.join
          next if classifier.nil? || !classifiers.include?(classifier)

          covering = longest.call(chars, after)
          break if covering && covering.length > size
          break if words.include?(chars[start...(after + size)].join)

          usage[classifier] += 1
          noun = longest.call(chars, after + size)
          if noun && !classifiers.include?(noun) && noun_test.call(noun)
            loose[[classifier, noun]] += 1
            stop = after + size + noun.length
            tail = stop < chars.length ? chars[stop] : ""
            if tail.empty? || !HAN_RANGE.cover?(tail) || BOUNDARY.include?(tail)
              counts[[classifier, noun]] += 1
            end
          end

          break
        end
      end
    end
  end

  [counts, loose, usage, sentences]
end

tocfl, moe_pos = parts_of_speech
tocfl_nouns = tocfl.filter_map { |word, pos| word if pos.to_s.split("/").include?("N") }.to_set
moe_nouns = moe_pos.filter_map { |word, tags| word if tags.include?("名") }.to_set

noun_test = lambda do |word|
  return false if NOT_A_NOUN.include?(word) || word.match?(/\A#{NUM_RUN}\z/)
  return tocfl_nouns.include?(word) if word.length == 1

  tocfl_nouns.include?(word) || moe_nouns.include?(word)
end

entries = classifier_entries
words = dictionary_words
classifiers = entries.keys.to_set

from_moe = moe_pairs(entries, words)
from_cedict = cedict_pairs(words).select { |(classifier, _), _| classifiers.include?(classifier) }
from_corpus, loose, usage, sentences = corpus_pairs(classifiers, words, noun_test)

pairs = {}
(from_moe | from_cedict.keys.to_set | from_corpus.keys.to_set).each do |pair|
  classifier, noun = pair
  next if NOT_A_NOUN.include?(noun)

  sources = []
  sources << "moe" if from_moe.include?(pair)
  sources << "cedict" if from_cedict.key?(pair)
  sources << "corpus" if from_corpus.key?(pair)

  (pairs[classifier] ||= []) <<
    {
      "noun" => noun,
      "count" => from_corpus.fetch(pair, 0),
      "seen" => loose.fetch(pair, 0),
      "rank" => from_cedict[pair],
      "sources" => sources
    }
end

pairs.each_value { |rows| rows.sort_by! { |row| [-row["seen"], -row["count"], row["noun"]] } }

payload = {
  "classifiers" => entries.sort.to_h { |word, entry|
    [
      word,
      {
        "zhuyin" => entry["zhuyin"],
        "pinyin" => entry["pinyin"],
        "gloss" => entry["gloss"],
        "tocfl" => tocfl[word],
        "usage" => usage.fetch(word, 0)
      }
    ]
  },
  "pairs" => pairs
}

Corpus.write_json(Corpus.app_root.join("dict_and_corpora/classifier_candidates.json"), payload)

ours = Corpus.read_json(Corpus.data("huayu/measure_words.json")).to_h { |row| [row["traditional"], row["category"]] }

kept = ours.sort.to_h do |classifier, category|
  allowed = NOUN_CATEGORIES.include?(category)
  chosen = pairs.fetch(classifier, []).select { |row|
    !EXCLUDE.include?([classifier, row["noun"]]) &&
      ((%w[moe cedict] & row["sources"]).any? || (allowed && row["count"] >= MIN_CORPUS))
  }
  [classifier, {"usage" => usage.fetch(classifier, 0), "nouns" => chosen}]
end

Corpus.write_json(Corpus.data("huayu/classifier_pairs.json"), kept, pretty: true)

speech = {}
tocfl.each { |word, pos| (speech[word] ||= {})["tocfl"] = pos }
moe_pos.each { |word, tags| (speech[word] ||= {})["moe"] = tags }
speech = speech.sort.to_h.select { |word, _| word && !word.empty? && han_only?(word) }

Corpus.write_json(Corpus.data("huayu/parts_of_speech.json"), speech, pretty: true)

total = pairs.each_value.sum(&:length)
Corpus.report("sentences scanned", total: sentences)
Corpus.report("classifiers in 簡編本", total: entries.size)
Corpus.report("candidate pairs", total: total, moe: from_moe.size, cedict: from_cedict.size, corpus: from_corpus.size)
Corpus.report(
  "selected",
  pairs: kept.each_value.sum { |row| row["nouns"].length },
  classifiers: kept.count { |_, row| row["nouns"].any? }
)
Corpus.report("parts of speech", tocfl: tocfl.size, moe: moe_pos.size)

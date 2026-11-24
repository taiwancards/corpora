# frozen_string_literal: true

require "set"

module JapaneseBridge
  module Kana
    SMALL = "ャュョァィゥェォヮ"
    ENTERING = %w[ク キ ツ チ].freeze
    ROWS = {
      "カ" => "カキクケコ",
      "ガ" => "ガギグゲゴ",
      "サ" => "サシスセソ",
      "ザ" => "ザジズゼゾ",
      "タ" => "タチツテト",
      "ダ" => "ダヂヅデド",
      "ナ" => "ナニヌネノ",
      "ハ" => "ハヒフヘホ",
      "バ" => "バビブベボ",
      "パ" => "パピプペポ",
      "マ" => "マミムメモ",
      "ヤ" => "ヤユヨ",
      "ラ" => "ラリルレロ",
      "ワ" => "ワヰヱヲ",
      "ア" => "アイウエオ"
    }.freeze
    ROW_OF = ROWS.each_with_object({}) { |(row, kana), memo| kana.each_char { |char| memo[char] = row } }.freeze
    VOWEL_OF = {
      "a" => "アカガサザタダナハバパマヤラワャ",
      "i" => "イキギシジチヂニヒビピミリヰ",
      "u" => "ウクグスズツヅヌフブプムユルュ",
      "e" => "エケゲセゼテデネヘベペメレヱ",
      "o" => "オコゴソゾトドノホボポモヨロヲョ"
    }.each_with_object({}) { |(vowel, kana), memo| kana.each_char { |char| memo[char] = vowel } }.freeze
    SUBROWS = {"ジ" => "ジ", "ニ" => "ニ"}.freeze

    module_function

    def katakana?(token) = token.to_s.match?(/\A[\p{Katakana}ー]+\z/)

    def onyomi(field) = field.to_s.split.select { |token| katakana?(token) }

    def morae(reading)
      reading.to_s.each_char.with_object([]) do |char, memo|
        if SMALL.include?(char) && memo.any?
          memo[-1] += char
        else
          memo << char
        end
      end
    end

    def ending(reading)
      units = morae(reading)
      return nil if units.empty?

      last = units.last
      return "n" if last == "ン"
      return nil if units.length < 2
      return "k" if %w[ク キ].include?(last)
      return "t" if %w[ツ チ].include?(last)

      glide = "y" if units[-2].end_with?("ョ", "ュ", "ヨ", "ユ")
      before = VOWEL_OF[units[-2][-1]]
      return "#{glide}#{before}u" if last == "ウ" && %w[o u].include?(before)
      return "#{before}i" if last == "イ" && %w[e a u].include?(before)

      nil
    end

    def row(reading)
      first = reading.to_s[0]
      ROW_OF[first]
    end

    def subrow(reading)
      SUBROWS[reading.to_s[0]]
    end

    def voiced?(reading) = %w[ガ ザ ダ バ].include?(row(reading))
  end

  module Zhuyin
    TONES = {"ˊ" => 2, "ˇ" => 3, "ˋ" => 4, "˙" => 0}.freeze
    INITIALS = {
      "ㄅ" => "b",
      "ㄆ" => "p",
      "ㄇ" => "m",
      "ㄈ" => "f",
      "ㄉ" => "d",
      "ㄊ" => "t",
      "ㄋ" => "n",
      "ㄌ" => "l",
      "ㄍ" => "g",
      "ㄎ" => "k",
      "ㄏ" => "h",
      "ㄐ" => "j",
      "ㄑ" => "q",
      "ㄒ" => "x",
      "ㄓ" => "zh",
      "ㄔ" => "ch",
      "ㄕ" => "sh",
      "ㄖ" => "r",
      "ㄗ" => "z",
      "ㄘ" => "c",
      "ㄙ" => "s"
    }.freeze
    GROUPS = {
      "b" => "bp",
      "p" => "bp",
      "m" => "m",
      "f" => "f",
      "d" => "dt",
      "t" => "dt",
      "n" => "n",
      "l" => "l",
      "g" => "gkh",
      "k" => "gkh",
      "h" => "gkh",
      "j" => "jqx",
      "q" => "jqx",
      "x" => "jqx",
      "zh" => "zhchsh",
      "ch" => "zhchsh",
      "sh" => "zhchsh",
      "r" => "r",
      "z" => "zcs",
      "c" => "zcs",
      "s" => "zcs",
      "" => "zero"
    }.freeze

    module_function

    def body(zhuyin) = zhuyin.to_s.delete(TONES.keys.join).strip

    def tone(zhuyin)
      mark = zhuyin.to_s.each_char.find { |char| TONES.key?(char) }
      mark ? TONES[mark] : 1
    end

    def initial(zhuyin) = INITIALS.fetch(body(zhuyin)[0], "")

    def group(zhuyin) = GROUPS.fetch(initial(zhuyin))

    def coda(zhuyin)
      text = body(zhuyin)
      return "er" if text == "ㄦ"
      return "n" if text.end_with?("ㄢ", "ㄣ")
      return "ng" if text.end_with?("ㄤ", "ㄥ")

      "open"
    end

    def syllable?(zhuyin) = body(zhuyin).match?(/\A[ㄅ-ㄩ]+\z/)
  end

  class Forms
    SAME = "same"
    DIFFERS = "differs"
    UNUSED = "unused"

    def initialize(
      joyo:,
      jinmei:,
      jinmei_old: {},
      new_variants: {},
      opencc: {},
      taiwan: {},
      shinjitai: {},
      z_variants: {}
    )
      @joyo = joyo.to_set
      @jinmei = jinmei.to_set
      @jinmei_old = jinmei_old
      @new_variants = new_variants
      @opencc = opencc
      @taiwan = taiwan
      @shinjitai = shinjitai
      @z_variants = z_variants
    end

    def japanese?(char) = joyo.include?(char) || jinmei.include?(char)

    def joyo?(char) = joyo.include?(char)

    def counterpart(char)
      return [char, SAME] if japanese?(char)

      found = candidates(char).find { |candidate| candidate != char && japanese?(candidate) }
      found ? [found, DIFFERS] : [nil, UNUSED]
    end

    private

    attr_reader :joyo, :jinmei, :jinmei_old, :new_variants, :opencc, :taiwan, :shinjitai, :z_variants

    def candidates(char)
      standard = taiwan[char]
      [
        jinmei_old[char],
        new_variants[char],
        opencc[char],
        shinjitai[char],
        *Array(z_variants[char]),
        standard,
        (opencc[standard] if standard),
        (new_variants[standard] if standard)
      ].compact
    end
  end

  module Multiset
    module_function

    def difference(left, right)
      counts = right.tally
      left.each_with_object([]) do |item, memo|
        if counts[item].to_i.positive?
          counts[item] -= 1
        else
          memo << item
        end
      end
    end

    def subset?(small, large) = difference(small, large).empty?
  end

  class Patterns
    SMALL_STROKES = 1
    SMALL_PARTS = 3

    def initialize(pairs:, components:, parts:, strokes: {}, counterpart: -> (_) { })
      @pairs = pairs
      @components = components
      @parts = parts
      @strokes = strokes
      @counterpart = counterpart
    end

    def signature(from, to)
      ours = components[from]
      theirs = components[to]
      return nil if ours.nil? || theirs.nil?

      [Multiset.difference(ours, theirs).sort, Multiset.difference(theirs, ours).sort]
    end

    def subparts(char, seen = Set.new)
      Array(parts[char]).each_with_object([]) do |part, memo|
        next if part == char || seen.include?(part)

        seen << part
        memo << part
        memo.concat(subparts(part, seen))
      end
    end

    def key(from, to)
      diff = signature(from, to)
      return from if diff.nil?

      removed = diff.first
      return from if removed.empty?

      candidates = subparts(from).select { |part| components.key?(part) }
      echoed = candidates.select { |part| echoes?(part, removed) }.max_by { |part| components[part].length }
      return echoed if echoed

      covering = candidates.select { |part| Multiset.subset?(removed, components[part]) }
      covering.max_by { |part| [components[part].length, -candidates.index(part)] } || from
    end

    def echoes?(part, removed)
      twin = counterpart.call(part)
      return false if twin.nil? || twin == part

      own = signature(part, twin)&.first
      !own.nil? && !own.empty? && Multiset.subset?(own, removed)
    end

    def small?(from, to)
      diff = signature(from, to)
      return false if diff.nil?

      ours = strokes[from]
      theirs = strokes[to]
      return false if ours.nil? || theirs.nil?

      (ours - theirs).abs <= SMALL_STROKES && diff.sum(&:length) <= SMALL_PARTS
    end

    def groups
      keyed = pairs.to_h { |from, to| [from, key(from, to)] }
      heads = keyed.values.to_set & pairs.keys.to_set
      heads.each { |head| keyed[head] = head }
      keyed.group_by { |_, head| head }.transform_values { |rows| rows.map(&:first) }
    end

    def patterns(order: -> (char) { char })
      groups.filter_map do |head, members|
        next if members.length < 2

        sorted = members.sort_by { |char| [order.call(char), char] }
        twin = pairs[head] || counterpart.call(head)
        small = sorted.count { |char| small?(char, pairs[char]) } * 2 > sorted.length
        {"id" => head, "from" => head, "to" => (twin == head ? nil : twin), "small" => small, "members" => sorted}
      end
    end

    private

    attr_reader :pairs, :components, :parts, :strokes, :counterpart
  end

  class Correspondence
    ENDING_PREDICTIONS = {
      "n" => "n",
      "ou" => "ng",
      "you" => "ng",
      "uu" => "ng",
      "yuu" => "ng",
      "ei" => "ng",
      "ai" => "open",
      "ui" => "open",
      "k" => "open",
      "t" => "open"
    }.freeze
    SAMPLE = 6

    Row = Data.define(:char, :on, :zhuyin, :pinyin, :rank)

    def initialize(rows)
      @rows = rows.select { |row| Zhuyin.syllable?(row.zhuyin) && Kana.katakana?(row.on) }
    end

    attr_reader :rows

    def endings
      ENDING_PREDICTIONS.filter_map do |ending, expected|
        members = rows.select { |row| Kana.ending(row.on) == ending }
        next if members.empty?

        hits, misses = members.partition { |row| Zhuyin.coda(row.zhuyin) == expected }
        {
          "ending" => ending,
          "expected" => expected,
          "total" => members.length,
          "hits" => hits.length,
          "reliability" => hits.length.fdiv(members.length).round(3),
          "codas" => tally(members) { |row| Zhuyin.coda(row.zhuyin) },
          "examples" => sample(hits),
          "exceptions" => sample(misses)
        }
      end
    end

    def initials
      keys = rows.group_by { |row| Kana.row(row.on) }.except(nil)
      subrows = rows.group_by { |row| Kana.subrow(row.on) }.except(nil)
      keys.merge(subrows.transform_keys { |key| "#{key}…" }).map { |key, members| initial_row(key, members) }
    end

    def nasals
      members = rows.select { |row| %w[n ng].include?(Zhuyin.coda(row.zhuyin)) }
      members.group_by { |row| nasal_cue(row.on) }.sort.to_h do |cue, group|
        codas = tally(group) { |row| Zhuyin.coda(row.zhuyin) }
        expected = {"n" => "n", "long" => "ng"}[cue]
        hits = expected ? group.select { |row| Zhuyin.coda(row.zhuyin) == expected } : []
        misses = expected ? group - hits : []
        reliability = expected ? hits.length.fdiv(group.length).round(3) : nil
        [
          cue,
          {"total" => group.length, "codas" => codas, "reliability" => reliability, "exceptions" => sample(misses)}.compact
        ]
      end
    end

    def entering_tones
      members = rows.select { |row| %w[k t].include?(Kana.ending(row.on)) && Zhuyin.tone(row.zhuyin).positive? }
      tally(members) { |row| Zhuyin.tone(row.zhuyin).to_s }
    end

    def voicing_tones
      rows
        .select { |row| Zhuyin.tone(row.zhuyin).positive? && !%w[k t].include?(Kana.ending(row.on)) }
        .group_by { |row| Kana.voiced?(row.on) ? "voiced" : "plain" }
        .transform_values { |members| tally(members) { |row| Zhuyin.tone(row.zhuyin).to_s } }
        .sort
        .to_h
    end

    def summary
      {
        "characters" => rows.length,
        "endings" => endings,
        "nasals" => nasals,
        "initials" => initials.sort_by { |row| [-row["total"], row["row"]] },
        "entering_tones" => entering_tones,
        "voicing_tones" => voicing_tones
      }
    end

    private

    def nasal_cue(reading)
      ending = Kana.ending(reading)
      return "n" if ending == "n"
      return "long" if %w[ou you uu yuu ei].include?(ending)

      "other"
    end

    def initial_row(key, members)
      groups = tally(members) { |row| Zhuyin.group(row.zhuyin) }
      {
        "row" => key,
        "total" => members.length,
        "groups" => groups,
        "initials" => tally(members) { |row|
          Zhuyin.initial(row.zhuyin).then { |initial| initial.empty? ? "zero" : initial }
        },
        "examples" => groups.keys.first(3).to_h { |group|
          [group, sample(members.select { |row| Zhuyin.group(row.zhuyin) == group }, 3)]
        }
      }
    end

    def tally(members, &)
      members.map(&).tally.sort_by { |value, count| [-count, value.to_s] }.to_h
    end

    def sample(members, limit = SAMPLE)
      members.sort_by { |row| [row.rank || Float::INFINITY, row.char] }.first(limit).map do |row|
        {"char" => row.char, "on" => row.on, "zhuyin" => row.zhuyin, "pinyin" => row.pinyin}
      end
    end
  end
end

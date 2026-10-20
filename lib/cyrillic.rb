# frozen_string_literal: true

module Cyrillic
  INITIALS = %w[zh ch sh b p m f d t n l g k h j q x r z c s].freeze

  ZERO = {
    "yi" => "i",
    "ya" => "ia",
    "yo" => "io",
    "ye" => "ie",
    "yao" => "iao",
    "you" => "iou",
    "yan" => "ian",
    "yin" => "in",
    "yang" => "iang",
    "ying" => "ing",
    "yong" => "iong",
    "yu" => "ü",
    "yue" => "üe",
    "yuan" => "üan",
    "yun" => "ün",
    "wu" => "u",
    "wa" => "ua",
    "wo" => "uo",
    "wai" => "uai",
    "wei" => "uei",
    "wan" => "uan",
    "wen" => "uen",
    "wang" => "uang",
    "weng" => "ueng"
  }.freeze

  CONTRACTED = {"iu" => "iou", "ui" => "uei", "un" => "uen"}.freeze
  PALATAL = %w[j q x].freeze
  SIBILANT = %w[z c s].freeze
  RETROFLEX = %w[zh ch sh r].freeze
  LABIAL = %w[b p m f].freeze

  Syllable = Data.define(:initial, :final)

  module_function

  def parse(pinyin)
    text = plain(pinyin)
    return Syllable.new(initial: "", final: ZERO.fetch(text, text)) if ZERO.key?(text) || !text.match?(/\A[a-z]/)

    initial = INITIALS.find { |candidate| text.start_with?(candidate) }
    return Syllable.new(initial: "", final: text) if initial.nil?

    rest = text.delete_prefix(initial)
    rest = PALATAL.include?(initial) ? rest.sub(/\Au/, "ü") : CONTRACTED.fetch(rest, rest)
    rest = "iou" if rest == "iu"
    rest = "-i" if rest == "i" && (SIBILANT + RETROFLEX).include?(initial)
    Syllable.new(initial:, final: rest)
  end

  def plain(pinyin)
    pinyin
      .to_s
      .unicode_normalize(:nfd)
      .downcase
      .gsub("ü", "ü")
      .gsub(/\p{Mn}/, "")
      .gsub("v", "ü")
      .gsub("u:", "ü")
      .strip
  end

  def word(syllables, system:, capital: true, hyphen: false)
    parts = Array(syllables).map { |syllable| system.syllable(syllable) }
    text = hyphen ? parts.join("-") : parts.join
    capital ? text.sub(/\A./, &:upcase) : text
  end

  module Taiwan
    INITIALS = {
      "b" => "б",
      "p" => "п",
      "m" => "м",
      "f" => "ф",
      "d" => "д",
      "t" => "т",
      "n" => "н",
      "l" => "л",
      "g" => "г",
      "k" => "к",
      "h" => "х",
      "j" => "дз",
      "q" => "ч",
      "x" => "щ",
      "zh" => "дж",
      "ch" => "ч",
      "sh" => "ш",
      "r" => "ж",
      "z" => "дз",
      "c" => "ц",
      "s" => "с",
      "" => ""
    }.freeze

    FINALS = {
      "a" => "а",
      "o" => "о",
      "e" => "э",
      "ê" => "э",
      "er" => "эр",
      "ai" => "ай",
      "ei" => "эй",
      "ao" => "ао",
      "ou" => "оу",
      "an" => "ан",
      "en" => "эн",
      "ang" => "ан",
      "eng" => "эн",
      "ong" => "ун",
      "i" => "и",
      "ia" => "я",
      "io" => "ё",
      "ie" => "е",
      "iao" => "яо",
      "iou" => "иу",
      "ian" => "ен",
      "in" => "ин",
      "iang" => "ян",
      "ing" => "ин",
      "iong" => "юн",
      "u" => "у",
      "ua" => "уа",
      "uo" => "уо",
      "uai" => "уай",
      "uei" => "уэй",
      "uan" => "уан",
      "uen" => "ун",
      "uang" => "уан",
      "ueng" => "уэн",
      "ü" => "ю",
      "üe" => "юэ",
      "üan" => "юэн",
      "ün" => "юн"
    }.freeze

    ZERO_FINALS = FINALS.merge("iou" => "ю", "uen" => "уэн").freeze

    HARD_AFTER = {"я" => "а", "ё" => "о", "ю" => "у", "е" => "е", "и" => "и"}.freeze
    APICAL = {"zh" => "и", "ch" => "ы", "sh" => "и", "r" => "и", "z" => "ы", "c" => "ы", "s" => "ы"}.freeze

    module_function

    def syllable(pinyin)
      parsed = Cyrillic.parse(pinyin)
      if parsed.final == "-i"
        return APICAL.fetch(parsed.initial).then { |vowel| INITIALS.fetch(parsed.initial) + vowel }
      end

      return ZERO_FINALS.fetch(parsed.final) if parsed.initial.empty?

      onset = INITIALS.fetch(parsed.initial)
      rime = FINALS.fetch(parsed.final)
      rime = rime.sub(/\A[яёюе]/) { |vowel| HARD_AFTER.fetch(vowel) } if parsed.initial == "x"
      onset + rime
    end
  end

  module Palladius
    INITIALS = {
      "b" => "б",
      "p" => "п",
      "m" => "м",
      "f" => "ф",
      "d" => "д",
      "t" => "т",
      "n" => "н",
      "l" => "л",
      "g" => "г",
      "k" => "к",
      "h" => "х",
      "j" => "цз",
      "q" => "ц",
      "x" => "с",
      "zh" => "чж",
      "ch" => "ч",
      "sh" => "ш",
      "r" => "ж",
      "z" => "цз",
      "c" => "ц",
      "s" => "с",
      "" => ""
    }.freeze

    FINALS = {
      "a" => "а",
      "o" => "о",
      "e" => "э",
      "ê" => "э",
      "er" => "эр",
      "ai" => "ай",
      "ei" => "эй",
      "ao" => "ао",
      "ou" => "оу",
      "an" => "ань",
      "en" => "энь",
      "ang" => "ан",
      "eng" => "эн",
      "ong" => "ун",
      "i" => "и",
      "ia" => "я",
      "io" => "ё",
      "ie" => "е",
      "iao" => "яо",
      "iou" => "ю",
      "ian" => "янь",
      "in" => "инь",
      "iang" => "ян",
      "ing" => "ин",
      "iong" => "юн",
      "u" => "у",
      "ua" => "уа",
      "uo" => "о",
      "uai" => "уай",
      "uei" => "уй",
      "uan" => "уань",
      "uen" => "унь",
      "uang" => "уан",
      "ueng" => "ун",
      "ü" => "юй",
      "üe" => "юэ",
      "üan" => "юань",
      "ün" => "юнь"
    }.freeze

    ZERO_FINALS = FINALS
      .merge(
        "uo" => "во",
        "ua" => "ва",
        "uai" => "вай",
        "uei" => "вэй",
        "uan" => "вань",
        "uen" => "вэнь",
        "uang" => "ван",
        "ueng" => "вэн"
      )
      .freeze

    APICAL = {"zh" => "и", "ch" => "и", "sh" => "и", "r" => "и", "z" => "ы", "c" => "ы", "s" => "ы"}.freeze

    module_function

    def syllable(pinyin)
      parsed = Cyrillic.parse(pinyin)
      if parsed.final == "-i"
        return APICAL.fetch(parsed.initial).then { |vowel| INITIALS.fetch(parsed.initial) + vowel }
      end

      return ZERO_FINALS.fetch(parsed.final) if parsed.initial.empty?
      return INITIALS.fetch(parsed.initial) + "уэй" if parsed.initial == "h" && parsed.final == "uei"

      INITIALS.fetch(parsed.initial) + FINALS.fetch(parsed.final)
    end
  end
end

# frozen_string_literal: true

require_relative "lib/cyrillic"

module Retranscribe
  ROOT = Rails.root.join("data/huayu")
  WRITE = ARGV.include?("--write")
  REPORT = ARGV.find { |arg| arg.start_with?("--report=") }&.delete_prefix("--report=")

  JSON_FILES = %w[
    course_lessons.json
    taiwan_phrases.json
    grammar_lessons.json
    starter_track.json
    reading_stories.json
    taiwan_everyday.json
    medicine.json
    games.json
    taiwan_notices.json
    particles.json
    ru_glosses.json
    exam/novice1.json
    exam/novice2.json
    exam/a1.json
    exam/a2.json
    exam/b1.json
  ]
    .freeze
  READER_GLOB = "reader/*.json"
  JSONL_FILES = %w[sentence_glosses.jsonl collocation_glosses.jsonl tbcl_grammar_examples.jsonl].freeze
  ZH_KEYS = %w[zh text word title].freeze
  HAN = /\p{Han}/
  LETTER = "А-Яа-яЁё"
  NICKNAME_LEADS = %w[小 阿].freeze
  COMPOUND_SURNAMES = %w[歐陽 司馬 諸葛 上官 張簡 范姜].freeze

  CAST = {
    "Дин Даньсюй" => "Дин Дан-щу",
    "Даньсюй" => "Дан-щу",
    "Даньдань" => "Дан-дан",
    "Линь Аньань" => "Лин Ан-ан",
    "Аньань" => "Ан-ан",
    "Чэнь Бохань" => "Чэн Бо-хан",
    "Ханьхань" => "Хан-хан",
    "Ли Юси" => "Ли Ю-щи",
    "Сиси" => "Щи-щи",
    "У Цзясян" => "У Дзя-щан",
    "Сянсян" => "Щан-щан",
    "Хуан Ицзюнь" => "Хуан И-дзюн",
    "Ицзюнь" => "И-дзюн",
    "Маяо" => "Маяу",
    "Сяомэй" => "Щао-мэй"
  }.freeze
  CAST_FILES = %w[course_lessons.json starter_track.json grammar_lessons.json taiwan_phrases.json].freeze
  CAST_SURNAMES = {"Линь" => "Лин", "Чэнь" => "Чэн", "Цзян" => "Дзян"}.freeze

  FAMOUS = %w[
    蔡英文
    賴清德
    馬英九
    陳水扁
    李登輝
    蔣介石
    蔣經國
    孫中山
    孫逸仙
    鄭成功
    柯文哲
    韓國瑜
    侯友宜
    朱立倫
    蘇貞昌
    陳建仁
    宋楚瑜
    連戰
    吳敦義
    王金平
    游錫堃
    林佳龍
    陳其邁
    黃國昌
    蕭美琴
    卓榮泰
    盧秀燕
    蔣萬安
    林飛帆
    王建民
    林書豪
    戴資穎
    周杰倫
    蔡依林
    鄧麗君
    李安
    侯孝賢
    楊德昌
    金城武
    林志玲
    張惠妹
    白先勇
    張愛玲
    胡適
    魯迅
    毛澤東
    習近平
    鄧小平
    孔子
    孟子
    老子
    莊子
    荀子
    墨子
    李白
    杜甫
    蘇軾
    蘇東坡
    王羲之
    秦始皇
    劉備
    曹操
    諸葛亮
    關羽
    岳飛
    包公
    包拯
    林默娘
    成龍
    李小龍
    黃仁勳
    張忠謀
    郭台銘
    唐鳳
    施振榮
    李遠哲
    丁肇中
    楊振寧
    李政道
    吳寶春
    江振誠
    林懷民
    吳念真
    魏德聖
    李國修
    陳之藩
    余光中
    席慕蓉
    龍應台
    林海音
    瓊瑤
    金庸
    三毛
    屈原
    白居易
    王維
    李清照
    陶淵明
    諸葛
    劉銘傳
    沈葆楨
    丘逢甲
    莫那魯道
    蔣渭水
    林獻堂
    賴和
    楊逵
    吳濁流
    李遠
    劉德華
    梁朝偉
    周星馳
    張學友
    王菲
    鄧紫棋
    林俊傑
    陶喆
    王力宏
    五月天
    阿妹
    江蕙
    費玉清
    張雨生
    羅大佑
    李宗盛
    陳綺貞
    陳昇
    伍佰
    吳青峰
    蕭敬騰
    楊丞琳
    郭婞淳
    林昀儒
    李智凱
    李洋
    王齊麟
    莊智淵
    曾雅妮
    盧彥勳
    謝淑薇
    詹詠然
    陳金鋒
    郭泓志
    曹錦輝
    陳偉殷
    王貞治
    楊岱鋼
    王柏融
    宋美齡
    陳誠
    嚴家淦
    謝長廷
    呂秀蓮
    蘇嘉全
    陳菊
    鄭文燦
    林全
    張善政
    江宜樺
    劉兆玄
    吳釗燮
    林鄭月娥
    李嘉誠
    李光耀
    李顯龍
    黃循財
    阿扁
    孫悟空
    豬八戒
    沙悟淨
    唐三藏
    華佗
    關公
    關聖
    宋江
    李娃
    鄭經
    鄭芝龍
    鄭克塽
    袁安
    媽祖
    朱天文
    朱天心
    錢穆
    張衡
    許仙
    鄭和
    秦檜
    曹寅
    曹雪芹
    王莽
    張角
    謝晉元
    蔡元培
    胡蘭成
    汪精衛
    蔣夢麟
    張恨水
    李叔同
    梁實秋
    湯唯
    張雨綺
    鄧超
    羅志祥
    余文樂
    楊千嬅
    吳宗憲
    桂綸鎂
    鈕承澤
    李康生
    陳湘琪
    畢飛宇
    鄧雨賢
    李世民
    史可法
    施耐庵
    王冕
    呂洞賓
    李鴻章
    李經方
    徐悲鴻
    王永慶
    馬端臨
    林黛玉
    賈寶玉
    薛寶釵
    薛蟠
    茅盾
    老舍
    巴金
    旺旺
    集集
    四四南村
    四四
    斯斯
    阿里巴巴
    阿里
    尋秦記
    呂布
    董卓
    辛棄疾
    周公
    莊周
    韓非
    孫子
    孫武
    范仲淹
    歐陽修
    王安石
    司馬遷
    司馬光
    朱熹
    王陽明
    鄭板橋
    林則徐
  ]
    .to_set
    .freeze
  TITLES = %w[
    委員長
    理事長
    董事長
    執行長
    副市長
    副主委
    副總統
    委員
    主委
    召委
    部長
    次長
    議員
    議長
    立委
    市長
    縣長
    區長
    局長
    處長
    署長
    司長
    院長
    館長
    校長
    主任
    主席
    社長
    總統
    老師
    醫師
    教授
    先生
    小姐
    太太
  ]
    .freeze
  HISTORICAL = /[秦漢晉隋唐宋元明清][朝代]|帝|天皇|世祖|太祖|太宗|高宗|[東西]漢|[南北]宋|南唐|後周|[東西]晉|宋末|元初|明末|清初|清末|末年|洪武|年間|抗戰|金國|完顏|白娘子|千歲|王爺|大將公|民國初年|出家|法號|詞牌|填詞|詩人|丞相|宰相|大將|將軍|悍將|謀士|諸侯|刺史|知府|知縣|狀元|進士|科舉|咸陽|夏商|商周|[北東西]魏|西元\d{1,3}年|相傳|傳說|傳奇|神話|演義|西遊記|水滸|三國|春秋|戰國|匈奴|乾隆|康熙|雍正|嘉慶|道光|咸豐|同治|光緒|宣統|明治|大正|昭和|日治|清領|明鄭|鄭氏|鄭軍|延平|西元前|(?<!\d)1[0-8]\d\d年/
  SURNAME_LED = /\A[陳林黃張李王吳劉蔡楊許鄭謝洪郭邱曾廖賴周徐蘇葉莊呂江何蕭羅高潘簡朱鍾游彭詹胡施沈余盧梁趙顏柯翁魏孫戴范方宋鄧杜傅侯曹薛丁卓阮馬董温唐藍石蔣古紀姚連馮歐程湯黎錢袁畢秦]/
  SURNAME_CUE = /(?<=фамилия |фамилии |фамилию |фамилией |фамилиях )/

  Change = Data.define(:file, :zh, :old, :new)

  class Engine
    attr_reader :changes

    def initialize
      @changes = []
      @surnames = surname_table
      @readings = character_readings
      @lexemes = nil
      @common = common_words
      @places = place_names
      @blocked = blocked_words
    end

    def pair(file, zh, ru)
      return ru unless ru.is_a?(String) && zh.is_a?(String) && zh.match?(HAN) && ru.match?(/[А-ЯЁ]/)
      if zh.match?(HISTORICAL) ||
          FAMOUS.any? { |name| name.length > 2 && zh.include?(name) && !name.match?(SURNAME_LED) }
        return ru
      end

      return surname_gloss(file, zh, ru) if zh.length == 1

      result = ru.dup
      famous = FAMOUS.select { |name| zh.include?(name) }
      spans = surname_spans(zh).reject do |index, surname|
        famous.any? { |name| name.start_with?(surname) && zh[index, name.length] == name } ||
          blocked?(zh, index, surname.length)
      end

      spans.each { |index, surname| result = rename_full(file, zh, result, index, surname) }
      spans.each { |index, surname| result = rename_surname(file, zh, result, index, surname) }
      nickname_spans(zh).each do |text|
        next if FAMOUS.include?(text) || @common.include?(text) || @places.include?(text)
        next if text[0] == text[1] && @lexemes.include?(text)

        result = rename_nickname(file, zh, result, text)
      end

      result
    end

    def surname_gloss(file, zh, ru)
      return ru unless @surnames.key?(zh)

      syllables = @surnames.fetch(zh).split
      old = Cyrillic.word(syllables, system: Cyrillic::Palladius)
      new = Cyrillic.word(syllables, system: Cyrillic::Taiwan)
      return ru if old == new

      ru.gsub(/#{SURNAME_CUE.source}#{Regexp.escape(old)}(?![#{LETTER}])/) do |match|
        record(file, zh, match, new)
        new
      end
    end

    def cast(file, text)
      return text unless text.is_a?(String)

      result = text.dup
      CAST.each { |old, new| result = swap(file, "", result, old, new) }
      CAST_SURNAMES.each { |old, new| result = swap_declined(file, "", result, old, new) }
      result
    end

    private

    def surname_table
      rows = JSON.parse(ROOT.join("taiwan_names.json").read).fetch("surnames")
      table = rows.to_h { |row| [row["text"], Cyrillic.plain(row["pinyin"])] }
      COMPOUND_SURNAMES.each do |text|
        lexeme = Lexeme.find_by(text:)
        if lexeme
          table[text] = lexeme.readings["pinyin"].to_s.split.map { |syllable| Cyrillic.plain(syllable) }.join(" ")
        end
      end

      table
    end

    def character_readings
      Lexeme.where(kind: :character).pluck(:text, :readings, :data).to_h do |text, readings, data|
        listed = Array(data&.dig("readings")).map { |entry| entry.is_a?(Hash) ? entry["pinyin"] : entry }
        all = [readings["pinyin"], *listed].compact.flat_map { |pinyin| pinyin.to_s.split }
        [text, all.map { |pinyin| Cyrillic.plain(pinyin) }.select { |pinyin| pinyin.match?(/\A[a-zü]+\z/) }.uniq]
      end
    end

    def lexicon
      @lexicon ||= Lexeme
        .where(kind: %i[word collocation phrase])
        .where("char_length(text) BETWEEN 2 AND 4")
        .pluck(:text, Arel.sql("readings->>'pinyin'"))
    end

    def common_words = lexicon.filter_map { |text, pinyin| text if pinyin.to_s.match?(/\A\p{Ll}/) }.to_set

    def place_names
      places = JSON.parse(ROOT.join("taiwan_places.json").read).flat_map { |row|
        [row["text"], row["text"].sub(/[區市縣鄉鎮村里]\z/, "")]
      }
      names = JSON.parse(ROOT.join("segmentation_names.json").read).fetch("words")
      (places + names + Graded::Levels::NAMES).to_set
    end

    def blocked_words = lexicon_texts.dup.merge(@places)

    def lexicon_texts = @lexemes ||= lexicon.map(&:first).to_set

    def blocked?(zh, index, length)
      (length + 1..length + 3).any? { |size| index + size <= zh.length && @blocked.include?(zh[index, size]) }
    end

    def surname_spans(zh)
      spans = []
      index = 0
      while index < zh.length
        compound = COMPOUND_SURNAMES.find { |text| zh[index, 2] == text && @surnames.key?(text) }
        surname = compound || (@surnames.key?(zh[index]) ? zh[index] : nil)
        spans << [index, surname] if surname
        index += surname ? surname.length : 1
      end

      spans
    end

    def nickname_spans(zh)
      zh
        .chars
        .each_cons(2)
        .with_index
        .filter_map do |(first, second), index|
          next unless first.match?(HAN) && second.match?(HAN)
          next unless first == second || NICKNAME_LEADS.include?(first)
          next if (3..4).any? { |size| @lexemes.include?(zh[index, size]) }

          "#{first}#{second}"
        end
        .uniq
    end

    def surname_forms(surname)
      syllables = @surnames.fetch(surname).split
      [Cyrillic.word(syllables, system: Cyrillic::Palladius), Cyrillic.word(syllables, system: Cyrillic::Taiwan)]
    end

    def rename_full(file, zh, ru, index, surname)
      old_surname, new_surname = surname_forms(surname)
      return ru unless ru.match?(declined(old_surname))

      given_options(zh, index + surname.length).each do |given|
        new_given = Cyrillic.word(given, system: Cyrillic::Taiwan, hyphen: given.size > 1)
        palladius_forms(given).each do |old_given|
          pattern = /#{declined(old_surname).source}\s+#{declined(old_given).source}/
          ru = ru.gsub(pattern) do |match|
            surname_part, given_part = match.split(/\s+/, 2)
            renamed = "#{redecline(surname_part, old_surname, new_surname)} #{redecline(given_part, old_given, new_given)}"
            record(file, zh, match, renamed)
            renamed
          end
        end
      end

      ru
    end

    def rename_surname(file, zh, ru, index, surname)
      old_surname, new_surname = surname_forms(surname)
      if index.positive? && zh[index - 1] == "小"
        pattern = /(?<![#{LETTER}-])Сяо[\s-]#{declined(old_surname).source.delete_prefix("(?<![#{LETTER}-])")}/
        ru = ru.gsub(pattern) do |match|
          renamed = "Щао-#{redecline(match.sub(/\AСяо[\s-]/, ""), old_surname, new_surname).downcase}"
          record(file, zh, match, renamed)
          renamed
        end
      end

      swap_declined(file, zh, ru, old_surname, new_surname)
    end

    def rename_nickname(file, zh, ru, text)
      combos(text.chars).each do |syllables|
        new = Cyrillic.word(syllables, system: Cyrillic::Taiwan, hyphen: true)
        palladius_forms(syllables).each { |old| ru = swap_declined(file, zh, ru, old, new) }
      end

      ru
    end

    def given_options(zh, start)
      title = TITLES.find { |candidate| zh[start, candidate.length] == candidate }
      starts = [start, title && start + title.length].compact
      starts.flat_map { |position| names_at(zh, position) }
    end

    def names_at(zh, start)
      [2, 1].flat_map do |size|
        chars = zh[start, size].to_s.chars
        next [] unless chars.size == size && chars.all? { |char| char.match?(HAN) }

        combos(chars)
      end
    end

    def combos(chars)
      lists = chars.map { |char| Array(@readings[char]).first(4) }
      return [] if lists.any?(&:empty?)

      lists.first.product(*lists.drop(1))
    end

    def palladius_forms(syllables)
      joined = Cyrillic.word(syllables, system: Cyrillic::Palladius)
      return [joined] if syllables.size == 1

      parts = syllables.map { |syllable| Cyrillic::Palladius.syllable(syllable) }
      [joined, "#{parts.first.capitalize}-#{parts.drop(1).join("-")}", parts.map(&:capitalize).join("-")].uniq
    end

    def declined(base)
      stem, endings = stem_and_endings(base)
      alternatives = endings.map { |ending| Regexp.escape(stem + ending) }
      /(?<![#{LETTER}-])(?:#{[Regexp.escape(base), *alternatives].join("|")})(?![#{LETTER}]|-[#{LETTER}])/
    end

    def stem_and_endings(base)
      case base[-1]
      when "ь", "й"
        [base[0..-2], %w[я ю ем ём е]]
      when /[аеёиоуыэюя]/i
        [base, []]
      else
        [base, %w[а у ом е]]
      end
    end

    def redecline(word, old_base, new_base)
      return new_base if word == old_base

      old_stem, = stem_and_endings(old_base)
      ending = word.delete_prefix(old_stem)
      grammatical_case = case ending
      when "я", "а"
        :genitive
      when "ю", "у"
        :dative
      when "ем", "ём", "ом"
        :instrumental
      else
        :prepositional
      end

      decline(new_base, grammatical_case)
    end

    def decline(base, grammatical_case)
      return base if base.match?(/[аеёиоуыэюя]\z/i)

      soft = base.end_with?("й")
      stem = soft ? base[0..-2] : base
      ending = {
        genitive: soft ? "я" : "а",
        dative: soft ? "ю" : "у",
        instrumental: soft ? "ем" : "ом",
        prepositional: "е"
      }.fetch(grammatical_case)
      stem + ending
    end

    def swap(file, zh, text, old, new)
      pattern = /(?<![#{LETTER}-])#{Regexp.escape(old)}(?![#{LETTER}]|-[#{LETTER}])/
      text.gsub(pattern) do |match|
        record(file, zh, match, new)
        new
      end
    end

    def swap_declined(file, zh, text, old, new)
      return text if old == new

      text.gsub(declined(old)) do |match|
        renamed = redecline(match, old, new)
        record(file, zh, match, renamed)
        renamed
      end
    end

    def record(file, zh, old, new)
      @changes << Change.new(file:, zh:, old:, new:) unless old == new
    end
  end

  module Files
    module_function

    def json_format(raw, parsed)
      candidates = {
        "pretty" => -> (data) { JSON.pretty_generate(data) },
        "indent1" => -> (data) { JSON.generate(data, indent: " ", space: " ", object_nl: "\n", array_nl: "\n") },
        "indent2" => -> (data) { JSON.generate(data, indent: "  ", space: " ", object_nl: "\n", array_nl: "\n") }
      }
      candidates.each do |name, dump|
        text = dump.call(parsed)
        return [name, dump, ""] if text == raw
        return [name, dump, "\n"] if "#{text}\n" == raw
      end

      nil
    end

    def walk(node, engine, file, cast:, parent_zh: nil)
      case node
      when Hash
        zh = ZH_KEYS.lazy.map { |key| node[key] }.find { |value| value.is_a?(String) && value.match?(HAN) } ||
          parent_zh
        node.to_h do |key, value|
          if key == "ru" && value.is_a?(String)
            renamed = engine.pair(file, zh.to_s, value)
            [key, cast ? engine.cast(file, renamed) : renamed]
          elsif key == "ru" && cast
            [key, walk_cast(value, engine, file)]
          else
            [key, walk(value, engine, file, cast:, parent_zh: zh)]
          end
        end

      when Array
        node.map { |value| walk(value, engine, file, cast:, parent_zh:) }
      else
        node
      end
    end

    def walk_cast(node, engine, file)
      case node
      when Hash
        node.transform_values { |value| walk_cast(value, engine, file) }
      when Array
        node.map { |value| walk_cast(value, engine, file) }
      when String
        engine.cast(file, node)
      else
        node
      end
    end
  end

  module_function

  def run
    engine = Engine.new
    refused = []

    json_paths.each do |path|
      relative = path.relative_path_from(ROOT).to_s
      raw = path.read
      parsed = JSON.parse(raw)
      format = Files.json_format(raw, parsed)
      next refused << relative if format.nil?

      updated = if relative == "ru_glosses.json"
        parsed.to_h { |zh, ru| [zh, engine.pair(relative, zh, ru)] }
      else
        Files.walk(parsed, engine, relative, cast: CAST_FILES.include?(relative))
      end

      _, dump, tail = format
      path.write(dump.call(updated) + tail) if WRITE && updated != parsed
    end

    JSONL_FILES.each do |name|
      path = ROOT.join(name)
      lines = path.read.split("\n", -1)
      refused << name if lines.reject(&:empty?).any? { |line| JSON.generate(JSON.parse(line)) != line }
      next if refused.include?(name)

      updated = lines.map do |line|
        next line if line.empty?

        row = JSON.parse(line)
        renamed = Files.walk(row, engine, name, cast: false)
        renamed == row ? line : JSON.generate(renamed)
      end

      path.write(updated.join("\n")) if WRITE && updated != lines
    end

    summarize(engine.changes, refused)
  end

  def json_paths
    (JSON_FILES.map { |name| ROOT.join(name) } + ROOT.glob(READER_GLOB)).select(&:exist?)
  end

  def summarize(changes, refused)
    puts("changes: #{changes.size}")
    changes.group_by(&:file).sort.each { |file, rows| puts("  #{file}: #{rows.size}") }
    puts("refused (format not reproduced): #{refused.join(", ")}") if refused.any?
    tally = changes.group_by { |change| [change.old, change.new] }.transform_values(&:size).sort_by { |_, count|
      -count
    }
    puts("distinct: #{tally.size}")
    return unless REPORT

    lines = tally.map do |(old, new), count|
      sample = changes.find { |change| change.old == old }
      [count, old, new, sample.file, sample.zh.to_s.tr("\n", " ")[0, 70]].join("\t")
    end

    File.write(REPORT, lines.join("\n"))
  end
end

Retranscribe.run

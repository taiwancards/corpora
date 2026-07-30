# frozen_string_literal: true

require_relative "corpus"

module OriginFilter
  VARIANTS_USED_IN_TAIWAN = "秘群床峰粽庄晒痴霉虱灶恒昵肴羡痒洒疱".chars.to_set

  MAINLAND_LEXICON = {
    "軟件" => "軟體",
    "信息" => "資訊",
    "質量" => "品質",
    "視頻" => "影片",
    "音頻" => "音訊",
    "打印" => "列印",
    "屏幕" => "螢幕",
    "服務器" => "伺服器",
    "內存" => "記憶體",
    "鼠標" => "滑鼠",
    "博客" => "部落格",
    "互聯網" => "網際網路",
    "激光" => "雷射",
    "硬盤" => "硬碟",
    "出租車" => "計程車",
    "公交車" => "公車",
    "數據庫" => "資料庫",
    "筆記本電腦" => "筆記型電腦",
    "手機號" => "手機號碼",
    "視頻通話" => "視訊通話",
    "方便麵" => "泡麵",
    "空調" => "冷氣",
    "短信" => "簡訊",
    "優盤" => "隨身碟",
    "初中" => "國中",
    "身份證" => "身分證",
    "軟盤" => "磁碟片",
    "臺式機" => "桌上型電腦",
    "光盤" => "光碟",
    "移動電話" => "行動電話",
    "錄像" => "錄影",
    "夜宵" => "宵夜",
    "菠蘿" => "鳳梨",
    "西紅柿" => "番茄",
    "熊貓" => "貓熊",
    "複印" => "影印"
  }.freeze

  CANTONESE = "嘅佢咗喺冇睇嗰乜哋嘢啲攞諗掂唔咁俾嚟啱".chars.to_set
  CONVERTED_ORTHOGRAPHY = "裏着衞".chars.to_set
  WENYAN = "矣哉汝吾".chars.to_set

  FOREIGN_NAMES = {
    "意大利" => "義大利",
    "悉尼" => "雪梨",
    "新西蘭" => "紐西蘭",
    "老撾" => "寮國",
    "沙特" => "沙烏地",
    "奧巴馬" => "歐巴馬",
    "布什" => "布希",
    "戛納" => "坎城",
    "馬爾代夫" => "馬爾地夫"
  }.freeze

  TAIWAN_MARKERS = %w[
    臺灣
    台灣
    中華民國
    民國
    新臺幣
    新台幣
    行政院
    立法院
    監察院
    考試院
    司法院
    捷運
    悠遊卡
    便利商店
    統一發票
    健保
    勞保
    戶政
    里長
    鄉鎮市
    縣市政府
    教育部
    內政部
    衛福部
    陸委會
    僑委會
    國小
    國中
    指考
    學測
    統測
  ]
    .freeze

  TAIWAN_LEXICON = %w[
    資訊
    品質
    影片
    螢幕
    網路
    計程車
    公車
    捷運
    便當
    機車
    腳踏車
    鳳梨
    番茄
    馬鈴薯
    義大利
    紐西蘭
    雪梨
    寮國
    影印
    錄影
    宵夜
    軟體
    硬碟
    光碟
    列印
    滑鼠
    行動電話
    貓熊
    網際網路
    隨身碟
    冷氣
    泡麵
    簡訊
    部落格
    雷射
    伺服器
    記憶體
    資料庫
    身分證
  ]
    .freeze

  TAIWAN_PARTICLES = %w[喔 啦 耶 齁 蛤 欸 咧 嘛 唷 喲].freeze

  TAIWAN_GRAMMAR = /有沒有|沒有沒|有去|有來|有看|有吃|有說|有做|有買|有給|有想|有聽|
    有拿|有寫|有帶|有用|有玩|有到|有過|會不會|要不要|好不好|對不對/x

  PRC_REALIA = %w[
    北京
    上海
    廣州
    深圳
    重慶
    天津
    成都
    武漢
    杭州
    南京
    西安
    瀋陽
    哈爾濱
    蘇州
    青島
    大連
    廈門
    長沙
    鄭州
    昆明
    貴陽
    蘭州
    烏魯木齊
    呼和浩特
    石家莊
    濟南
    合肥
    南昌
    南寧
    中華人民共和國
    中國大陸
    中共
    共產黨
    人民幣
    國務院
    全國人大
    政協
    新華社
    人民日報
    中央電視台
    央視
    微信
    支付寶
    淘寶
    京東
    高考
    戶口
    春運
    城管
    居委會
    省委
    市委書記
    解放軍
    武警
    一帶一路
    兩會
  ]
    .freeze

  MAINLAND_EXCEPTIONS = {
    "視頻" => %w[電視頻道 電視頻率],
    "音頻" => %w[影音頻道],
    "手機號" => %w[手機號碼],
    "網絡" => %w[犯罪網絡 神經網絡 組織網絡 通訊網絡],
    "信息" => %w[可信息]
  }.freeze

  HAN = /[\u{4E00}-\u{9FFF}]/

  Verdict = Data.define(:ok, :reasons, :taiwan_markers, :han, :wenyan_density) do
    def ok? = ok
  end

  module_function

  def opencc_dir = Corpus.corpora("opencc")

  def simplified
    @simplified ||= build_simplified
  end

  def build_simplified
    source = read_table(opencc_dir.join("STCharacters.txt"))
    return Set.new if source.empty?

    target = read_table(opencc_dir.join("TSCharacters.txt")).keys.to_set
    target.merge(source.each_value.to_a.flatten)

    source.keys.reject { |char| target.include?(char) }.to_set - VARIANTS_USED_IN_TAIWAN
  end

  def read_table(path)
    return {} unless path.exist?

    path.each_line.with_object({}) do |line, table|
      parts = line.split
      table[parts.first] = parts.drop(1) if parts.length >= 2
    end
  end

  def han_length(text) = text.unpack("U*").count { |code| code >= 0x4E00 && code <= 0x9FFF }

  def mainland_hits(text)
    MAINLAND_LEXICON.each_key.select do |term|
      probe = MAINLAND_EXCEPTIONS.fetch(term, []).reduce(text) { |memo, allowed| memo.gsub(allowed, "") }
      probe.include?(term)
    end
  end

  def prc_hits(text) = PRC_REALIA.select { |term| text.include?(term) }

  def evidence(text)
    (TAIWAN_LEXICON + TAIWAN_PARTICLES + TAIWAN_MARKERS).sum { |term| text.scan(term).length } +
      text.scan(TAIWAN_GRAMMAR).length
  end

  def inspect_text(text)
    han = han_length(text)
    reasons = []

    mainland = mainland_hits(text)
    reasons << "mainland vocabulary: #{mainland.sort.first(4).join(", ")}" if mainland.any?

    canto = CANTONESE.select { |char| text.include?(char) }
    reasons << "Cantonese particles: #{canto.sort.first(4).join}" if canto.any?

    found = text.chars.select { |char| simplified.include?(char) }
    reasons << "simplified characters: #{found.uniq.sort.first(4).join}" if found.any?

    converted = CONVERTED_ORTHOGRAPHY.select { |char| text.include?(char) }
    reasons << "foreign orthography: #{converted.sort.join}" if converted.any?

    names = FOREIGN_NAMES.each_key.select { |name| text.include?(name) }
    reasons << "mainland place names: #{names.sort.first(3).join(", ")}" if names.any?

    prc = prc_hits(text)
    reasons << "PRC-specific terms: #{prc.sort.first(3).join(", ")}" if prc.any?

    wenyan = WENYAN.sum { |char| text.scan(char).length }
    density = han.zero? ? 0.0 : wenyan.fdiv(han)
    if han >= 8 && wenyan >= 2 && density > 0.05
      reasons << format("literary Chinese density %d%%", (density * 100).round)
    end

    Verdict.new(
      ok: reasons.empty?,
      reasons: reasons,
      taiwan_markers: TAIWAN_MARKERS.select { |marker| text.include?(marker) },
      han: han,
      wenyan_density: density
    )
  end

  def keep?(text) = inspect_text(text).ok
end

#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "lib/corpus"

CANDIDATES = {
  "軟件" => "軟體",
  "硬件" => "硬體",
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
  "軟盤" => "磁碟片",
  "出租車" => "計程車",
  "公交車" => "公車",
  "數據庫" => "資料庫",
  "筆記本電腦" => "筆記型電腦",
  "臺式機" => "桌上型電腦",
  "優盤" => "隨身碟",
  "方便麵" => "泡麵",
  "空調" => "冷氣",
  "短信" => "簡訊",
  "初中" => "國中",
  "身份證" => "身分證",
  "手機號" => "手機號碼",
  "視頻通話" => "視訊通話",
  "宽带" => "寬頻",
  "寬帶" => "寬頻",
  "打車" => "叫車",
  "地鐵" => "捷運",
  "早上好" => "早安",
  "晚上好" => "晚安",
  "土豆" => "馬鈴薯",
  "自行車" => "腳踏車",
  "程序" => "程式",
  "網絡" => "網路",
  "渠道" => "管道",
  "水平" => "水準",
  "項目" => "專案",
  "沙發" => "沙發",
  "公里" => "公里",
  "電腦" => "電腦",
  "冰箱" => "冰箱",
  "高中" => "高中",
  "小學" => "國小",
  "幼兒園" => "幼稚園",
  "警察局" => "警察局",
  "垃圾" => "垃圾"
}.freeze

SOURCES = %w[moj_law ntpc_press moe_concised].freeze
MAX_HITS = 3
MIN_RATIO = 20

blobs = SOURCES.filter_map do |slug|
  path = Corpus.data("corpora/sentences/#{slug}.json")
  Corpus.read_json(path).join if path.exist?
end

abort("no corpora, run extract_all first") if blobs.empty?

corpus = blobs.join
Corpus.report("verification corpus", characters: corpus.length, sources: blobs.size)

counts = Corpus
  .each_slice_parallel(CANDIDATES.keys | CANDIDATES.values) { |slice|
    slice.to_h { |word| [word, corpus.scan(word).length] }
  }
  .reduce(:merge)

accepted, rejected = {}, []

CANDIDATES.each do |china, taiwan|
  cn = counts.fetch(china)
  tw = counts.fetch(taiwan)

  reason = if china == taiwan
    "identical on both sides"
  elsif cn > MAX_HITS
    "occurs in Taiwanese text"
  elsif tw < cn * MIN_RATIO
    "Taiwanese form does not dominate"
  end

  if reason
    rejected << [china, taiwan, cn, tw, reason]
  else
    accepted[china] = {"taiwan" => taiwan, "china_hits" => cn, "taiwan_hits" => tw}
  end
end

Corpus.say("")
Corpus.say("ACCEPTED as reliable markers: #{accepted.size}")
accepted.sort_by { |_, info| -info["taiwan_hits"] }.each do |word, info|
  Corpus.say(
    format("  %-10s -> %-12s %5d against %6d", word, info["taiwan"], info["china_hits"], info["taiwan_hits"])
  )
end

Corpus.say("")
Corpus.say("REJECTED: #{rejected.size}")
rejected.each do |word, _, cn, tw, why|
  Corpus.say(format("  %-10s (%5d against %6d)  %s", word, cn, tw, why))
end

target = Corpus.write_json(Corpus.data("huayu/china_markers.json"), accepted, pretty: true)
Corpus.report("written", markers: accepted.size, path: target.basename)

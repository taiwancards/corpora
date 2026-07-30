#!/usr/bin/env ruby
# frozen_string_literal: true

require "cgi"

require_relative "lib/sentences"
require_relative "lib/http"

include(Sentences)

API = Corpus.env.fetch("YOUTUBE_API_URL", "")
KEY = Corpus.env.fetch("YOUTUBE_API_KEY", "")

abort("YOUTUBE_API_URL and YOUTUBE_API_KEY must be set — see .env.dev") if API.empty? || KEY.empty?

QUERIES = [
  "台灣 美食",
  "台灣 日常",
  "台灣 vlog",
  "夜市 好吃",
  "台北 生活",
  "高雄 旅遊",
  "台灣 綜藝",
  "台劇 好看",
  "手搖飲 推薦",
  "台灣 大學生",
  "租屋 心得",
  "捷運 通勤",
  "台灣 職場",
  "露營 推薦",
  "貓咪 日常",
  "遊戲 實況",
  "開箱 開箱文",
  "台灣 新聞 評論",
  "健身 心得",
  "考試 讀書",
  "機車 推薦",
  "台灣 天氣",
  "便利商店 新品",
  "追劇 心得",
  "寵物 狗狗"
].freeze

QUERIES_TAIWAN = [
  "台灣 文化",
  "台灣 歷史",
  "台灣 民主",
  "台灣 選舉",
  "言論自由",
  "人權 台灣",
  "同婚 台灣",
  "同志遊行",
  "台灣 認同",
  "轉型正義",
  "原住民 文化",
  "客家 文化",
  "台灣 廟會",
  "媽祖 遶境",
  "台灣 傳統",
  "公投 台灣",
  "立法院 質詢",
  "台灣 社會 議題",
  "性別平等",
  "婚姻平權",
  "台灣 獨立",
  "兩岸 關係",
  "台灣 之光",
  "台灣 護照",
  "台灣 價值"
].freeze

QUERIES_HERITAGE = [
  "白色恐怖 歷史",
  "二二八 事件",
  "戒嚴 時期",
  "眷村 生活",
  "原住民 部落",
  "阿美族 文化",
  "排灣族 傳統",
  "台灣 地理",
  "玉山 登山",
  "台灣 廟宇",
  "半導體 台積電",
  "台灣 小吃"
].freeze

QUERIES_LGBT = [
  "同婚 通過",
  "婚姻平權 台灣",
  "同志遊行 台北",
  "同婚 五週年",
  "亞洲第一 同婚",
  "同志 家庭 台灣",
  "跨性別 台灣",
  "出櫃 故事",
  "性別平等 教育",
  "彩虹 台灣",
  "同婚專法",
  "同志 結婚 台灣"
].freeze

CLEAN = [
  [/<[^>]+>/, ""],
  [%r{https?://\S+}, ""],
  [/@[\w\u{4E00}-\u{9FFF}]+/, ""],
  [/\d{1,2}:\d{2}/, ""],
  [/[\u{1F000}-\u{1FAFF}\u{2600}-\u{27BF}]/, ""],
  [/[ \t]+/, " "]
].freeze

SPLIT = /(?<=[。！？!?])|\n/

def call(path, params)
  url = Http.query("#{API}/#{path}", params.merge(key: KEY))

  4.times do |attempt|
    return Http.json(url, retries: 1)
  rescue Net::HTTPClientException => error
    body = error.response.body.to_s
    raise "YouTube quota exhausted" if error.response.code == "403" && body.downcase.include?("quota")
    return nil if %w[403 404].include?(error.response.code)

    sleep(3 * (attempt + 1))
  rescue StandardError
    sleep(3 * (attempt + 1))
  end

  nil
end

def video_ids(queries, per_query: 50)
  found = []

  queries.each do |query|
    data = call(
      "search",
      part: "id",
      type: "video",
      regionCode: "TW",
      relevanceLanguage: "zh-Hant",
      q: query,
      maxResults: per_query,
      order: "relevance"
    )
    next if data.nil?

    found.concat(data.fetch("items", []).filter_map { |item| item.dig("id", "videoId") })
    Corpus.say("  «#{query}»: videos #{found.length}")
  end

  found.uniq
end

def comments(video_id, pages: 2)
  out = []
  token = nil

  pages.times do
    params = {part: "snippet", videoId: video_id, maxResults: 100, textFormat: "plainText", order: "relevance"}
    params[:pageToken] = token if token

    data = call("commentThreads", params)
    break if data.nil?

    data.fetch("items", []).each do |item|
      snippet = item.dig("snippet", "topLevelComment", "snippet")
      out << CGI.unescapeHTML(snippet.fetch("textDisplay", "")) if snippet
    end

    token = data["nextPageToken"]
    break if token.nil?
  end

  out
end

def sentences_of(raw)
  text = CLEAN.reduce(raw) { |memo, (pattern, replacement)| memo.gsub(pattern, replacement) }

  text.split(SPLIT).filter_map { |piece|
    candidate = Corpus.strip(piece)
    candidate if !candidate.empty? && usable?(candidate, min_han: 5, max_han: 60)
  }
end

cap = Integer(ENV.fetch("YOUTUBE_CAP", "200000"))
path = Sentences.out_dir.join("youtube_comments.json")
previous = path.exist? ? Corpus.read_json(path) : []

queries = {"taiwan" => QUERIES_TAIWAN, "heritage" => QUERIES_HERITAGE}.fetch(ENV["YOUTUBE_TOPIC"], QUERIES)
ids = video_ids(queries)
Corpus.say("videos total: #{ids.length}")

out = previous.dup
seen = previous.to_set

ids.each_with_index do |video, index|
  comments(video).each do |raw|
    sentences_of(raw).each { |piece| out << piece if seen.add?(piece) }
  end

  Corpus.say("  #{index + 1}/#{ids.length} videos, sentences #{out.length}") if ((index + 1) % 25).zero?
  break if out.length >= cap
end

write("youtube_comments", out.first(cap))

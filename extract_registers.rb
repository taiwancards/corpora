#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "lib/registers"
require_relative "lib/python_random"

include(Sentences)

SUBTITLE_JUNK = /字幕|翻譯|校對|時間軸|後製|論壇|轉載|壓製|壓制|片源|發佈|訂閱|頻道|@|http|www\.|\d{1,2}:\d{2}:\d{2}|本片|製作組|人人影視|伊甸園/
MARKUP = /\{[^}]*\}|<[^>]*>|\[[^\]]*\]|（[^）]*）|\([^)]*\)/
LEAD = /\A[-–—•[[:space:]]　]+/

WIKI_SENTENCE_MIN = 8
BLOCK_TOLERANCE = Registers::POLICY.block_tolerance

SKIP_TITLES = /\A(Wikipedia|Template|Category|File|Help|Portal|MediaWiki|模板|分類|檔案|幫助|維基百科|Module):/
MODERN = /[的了是在有和]/
BAIHUA = /[的了嗎呢吧著就很說]/

WIKI_STRIP = [
  [/<ref[^>]*>.*?<\/ref>|<ref[^>]*\/>/m, ""],
  [/\{\{.*?\}\}/m, ""],
  [/\{\|.*?\|\}/m, ""],
  [/<!--.*?-->/m, ""],
  [/<[^>]+>/m, ""],
  [/\[\[(?:[^\]|]*\|)?([^\]|]*)\]\]/, "\\1"],
  [/\[\[[^\]]*\]\]/, ""],
  [/'{2,}/, ""],
  [/^[*#:;=].*$/, ""],
  [/-\{.*?\}-/, ""]
].freeze

def clean_line(line) = Corpus.strip(line.gsub(MARKUP, "").sub(LEAD, ""))

def clean_wiki(text) = WIKI_STRIP.reduce(text) { |memo, (pattern, replacement)| memo.gsub(pattern, replacement) }

def collect(lines, cap, min_han: 6, max_han: 60)
  seen = Set.new
  out = []
  lines.each do |raw|
    text = clean_line(raw)
    next if text.empty? || text.match?(SUBTITLE_JUNK)
    next unless usable?(text, min_han:, max_han:)
    next unless seen.add?(text)

    out << text
  end

  thin(out, cap)
end

def wiki_pages(path)
  return to_enum(:wiki_pages, path) unless block_given?

  title = nil
  body = []
  inside = false

  Sentences.each_bz2_line(path) do |line|
    if line.include?("<title>")
      title = Corpus.strip(line.sub(/.*<title>(.*?)<\/title>.*/m, "\\1"))
    elsif line.include?("<text")
      inside = true
      body = [line.include?(">") ? line.split(">", 2)[1] : ""]
      if line.include?("</text>")
        inside = false
        yield title, clean_wiki(body.join.split("</text>").first.to_s)
        body = []
      end
    elsif inside
      if line.include?("</text>")
        inside = false
        body << line.split("</text>").first.to_s
        yield title, clean_wiki(body.join)
        body = []
      else
        body << line
      end
    end
  end
end

def extract_opensubtitles(cap: Integer(ENV.fetch("SUBTITLE_CAP", "300000")))
  path = Corpus.corpora("opus/opensubtitles_zh_TW.txt.gz")
  return Corpus.say("opensubtitles: no file, skipped") unless path.exist?

  cleaned = Sentences
    .each_gz_line(path)
    .lazy
    .map { |raw| clean_line(raw) }
    .reject { |text| text.empty? || text.match?(SUBTITLE_JUNK) }

  write("opensubtitles", collect(Registers.taiwanese_blocks(cleaned), cap))
end

def extract_ted(cap: Integer(ENV.fetch("TED_CAP", "200000")))
  path = Corpus.corpora("opus/ted2020_zh_tw.txt.gz")
  return Corpus.say("ted: no file, skipped") unless path.exist?

  pieces = Sentences.each_gz_line(path).flat_map { |raw|
    TWFilter::Sentences.split(clean_line(raw)).filter_map { |piece|
      text = Corpus.strip(piece)
      text if !text.empty? && shaped?(text)
    }
  }

  seen = Set.new
  out = Registers.taiwanese_blocks(pieces).select { |text| seen.add?(text) }
  write("ted_talks", thin(out, cap))
end

def extract_wikipedia(cap: Integer(ENV.fetch("WIKI_CAP", "250000")))
  path = Corpus.corpora("wiki/zhwiki-1.xml.bz2")
  return Corpus.say("wikipedia: no file, skipped") unless path.exist?

  out = []
  seen = Set.new

  wiki_pages(path) do |title, body|
    next if title.nil? || title.match?(SKIP_TITLES)

    page = TWFilter::Sentences.split(body).filter_map { |piece|
      text = Corpus.strip(piece)
      text if !text.empty? && shaped?(text, min_han: WIKI_SENTENCE_MIN) && text.match?(MODERN)
    }

    Registers.judge(page).each { |text| out << text if seen.add?(text) }
  end

  write("wikipedia_tw", thin(out, cap))
end

def baihua?(text) = text.scan(BAIHUA).length.fdiv([han_length(text), 1].max) >= 0.06

def extract_wikisource_dump(cap: Integer(ENV.fetch("WIKISOURCE_CAP", "200000")))
  path = Corpus.corpora("wikisource_dump/zhwikisource.xml.bz2")
  return Corpus.say("wikisource_dump: no file, skipped") unless path.exist?

  random = Corpus::PythonRandom.new(20260724)
  out = []
  seen = 0

  wiki_pages(path) do |title, body|
    next if title.nil? || title.match?(SKIP_TITLES)

    page = TWFilter::Sentences.split(body).filter_map { |piece|
      text = Corpus.strip(piece)
      text if !text.empty? && shaped?(text) && baihua?(text)
    }

    Registers.judge(page).each do |text|
      seen += 1
      if out.length < cap
        out << text
      else
        index = random.randrange(seen)
        out[index] = text if index < cap
      end
    end
  end

  Corpus.report("wikisource_prose", eligible: seen)
  write("wikisource_prose", out)
end

def extract_web(cap: Integer(ENV.fetch("WEB_CAP", "250000")))
  path = Corpus.corpora("opus/nllb_zh_TW.txt.gz")
  return Corpus.say("web: no file, skipped") unless path.exist?

  write("web_zh_tw", collect(Sentences.each_gz_line(path), cap))
end

EXTRACTORS = {
  "opensubtitles" => -> { extract_opensubtitles },
  "ted_talks" => -> { extract_ted },
  "wikipedia_tw" => -> { extract_wikipedia },
  "wikisource_prose" => -> { extract_wikisource_dump },
  "web_zh_tw" => -> { extract_web }
}.freeze

(ARGV.presence || EXTRACTORS.keys).each do |name|
  step = EXTRACTORS[name] or abort("unknown extractor #{name}")
  Corpus.timed(name) { step.call }
end

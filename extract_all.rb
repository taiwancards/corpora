#!/usr/bin/env ruby
# frozen_string_literal: true

require "csv"
require "rexml/document"
require "rexml/streamlistener"
require "zlib"

require_relative "lib/origin_filter"

SENT_END = /(?<=[。！？])/
TERMINAL = %w[。 ！ ？].freeze
TAG = /<[^>]+>/
SPEAKER = /\A[[:word:]·]{2,20}[：:]/
STAGE_NOTE = /[（(][^）)]{0,30}[）)]/

TEMPLATE = /\{\{[^{}]*\}\}/
LINK = /\[\[(?:[^\]|]*\|)?([^\]|]*)\]\]/
EXTLINK = %r{\[https?://[^\s\]]+\s*([^\]]*)\]}
MARKUP = /'''?|=+|\*+|#+|\|/

PTT_BLOCKLIST = /幹你|幹爆|幹拎|靠北|靠杯|雞掰|機掰|智障|白癡|白痴|廢物|三小|去死|媽的|他媽|你媽|婊|妓|屌|肛|強姦|自殺|做愛|性交|性愛|打炮|約炮|嫖|賣淫|援交|A片|自慰|手淫|吸毒|毒品|強暴|亂倫|勃起|陰莖|陰道|保險套|射精|裸照|情色|色情/

TAIWAN = /臺灣|台灣|臺北|台北|高雄|臺中|台中|臺南|台南|新北|桃園|基隆|新竹|嘉義|苗栗|彰化|南投|雲林|屏東|宜蘭|花蓮|臺東|台東|澎湖|金門|馬祖|墾丁|阿里山|日月潭/
MAINLAND = /北京|上海|廣州|深圳|重慶|成都|武漢|西安|杭州|南京|天津|香港|澳門|廣東|福建|浙江|江蘇|山東|河南|四川|湖南|湖北|遼寧/
MAINLAND_QUOTES = /[“”]/

def own(*parts) = Pathname(ENV.fetch("OWN_CORPORA_DIR") { Corpus.data("corpora").to_s }).join(*parts)

def out_dir = own("sentences")

def han_length(text) = text.unpack("U*").count { |code| code >= 0x4E00 && code <= 0x9FFF }

def usable?(text, min_han: 6, max_han: 60, min_ratio: 0.65)
  han = han_length(text)
  return false unless (min_han..max_han).cover?(han)
  return false if han.fdiv([text.length, 1].max) < min_ratio

  OriginFilter.keep?(text)
end

def terminal?(text) = TERMINAL.any? { |mark| text.end_with?(mark) }

def thin(rows, cap)
  return rows if cap.nil? || rows.length <= cap

  step = rows.length / cap.to_f
  Array.new(cap) { |index| rows[(index * step).to_i] }
end

def write(slug, sentences)
  out_dir.mkpath
  unique = sentences.uniq
  path = Corpus.write_json(out_dir.join("#{slug}.json"), unique)
  Corpus.report(slug, sentences: unique.length)
  unique
end

def pieces_of(line)
  line.split(SENT_END).filter_map { |piece| Corpus.strip(piece).presence }
end

def clean_wikitext(text)
  3.times { text = text.gsub(TEMPLATE, "") }
  text.gsub(LINK, "\\1").gsub(EXTLINK, "\\1").gsub(TAG, "").gsub(MARKUP, "")
end

def scan_parallel(lines, &block)
  Corpus.each_slice_parallel(lines) { |slice| slice.flat_map(&block) }.flatten(1)
end

def extract_law
  path = Corpus.corpora("law/FalV.xml")
  return Corpus.say("law: no file, skipped") unless path.exist?

  document = REXML::Document.new(path.read)
  texts = REXML::XPath.match(document, "//條文內容").filter_map { |node| node.text }

  write(
    "moj_law",
    scan_parallel(texts) { |content|
      content.split("\n").flat_map { |line|
        pieces_of(line)
          .map { |piece|
            piece
              .sub(/\A[一二三四五六七八九十百]+、[[:space:]]*/, "")
              .sub(/\A[（(][^)）]{1,4}[)）][[:space:]]*/, "")
          }
          .select { |piece| terminal?(piece) && usable?(piece) }
      }
    }
  )
end

def extract_common_voice
  out = []

  manifest = Corpus.app_root.join("media/pronunciation/corpus_cv/manifest.json")
  if manifest.exist?
    clips = Corpus.read_json(manifest).fetch("clips", {}).each_value.map { |clip| Corpus.strip(clip["sentence"].to_s) }
    out.concat(scan_parallel(clips) { |s| han_length(s) >= 5 && OriginFilter.keep?(s) ? [s] : [] })
  else
    Corpus.say("common_voice: no manifest, taking the text banks only")
  end

  bank = own("common_voice_txt")
  if bank.directory?
    lines = bank.glob("*.txt").sort.flat_map { |file| file.each_line.map { |line| Corpus.strip(line) } }
    out.concat(scan_parallel(lines) { |s| han_length(s) >= 5 && OriginFilter.keep?(s) ? [s] : [] })
  end

  write("common_voice", out)
end

def extract_ly(limit: Integer(ENV.fetch("LY_LIMIT", "80000")))
  directory = Corpus.corpora("ly")
  return Corpus.say("ly_gov: no directory, skipped") unless directory.directory?

  out = []
  seen = Set.new

  directory.glob("*.csv").sort.each do |file|
    CSV.foreach(file, headers: true, encoding: "bom|utf-8") do |row|
      row["transcript"].to_s.split("\n").each do |line|
        cleaned = Corpus.strip(line).sub(SPEAKER, "").gsub(STAGE_NOTE, "")
        pieces_of(cleaned).each do |piece|
          next unless terminal?(piece) && usable?(piece)
          next unless seen.add?(piece)

          out << piece
          if out.length >= limit
            Corpus.say("ly_gov: hit the #{limit} cap (LY_LIMIT), rest dropped")
            return write("ly_gov", out)
          end
        end
      end
    end
  end

  write("ly_gov", out)
end

def extract_tbcl
  out = []
  directory = Corpus.corpora("tbcl")

  xlsx = directory.join("grammar_points.xlsx")
  if xlsx.exist?
    require "roo"

    sheet = Roo::Excelx.new(xlsx.to_s)
    sheet.default_sheet = sheet.sheets.first
    (2..sheet.last_row).each do |number|
      sheet.row(number).last.to_s.split(/[\n；;]| {2,}/).each do |piece|
        candidate = Corpus.strip(piece)
        out << candidate if han_length(candidate) >= 3 && terminal?(candidate) && OriginFilter.keep?(candidate)
      end
    end
  end

  if directory.directory?
    directory.glob("jieci_*.html").sort.each do |file|
      html = file.read(encoding: "utf-8")
      html.scan(%r{<tr[^>]*>(.*?)</tr>}m).each do |row|
        cells = row.first.scan(%r{<td[^>]*>(.*?)</td>}m).flatten
        next if cells.length < 12

        cells.last.split(%r{<br\s*/?>}).each do |piece|
          candidate = Corpus.strip(piece.gsub(TAG, ""))
          out << candidate if han_length(candidate) >= 3 && terminal?(candidate) && OriginFilter.keep?(candidate)
        end
      end
    end
  end

  write("naer_tbcl", out)
end

def extract_wikisource
  directory = Corpus.corpora("wikisource")
  return Corpus.say("wikisource_tw: no directory, skipped") unless directory.directory?

  bodies = directory.glob("*.txt").sort.map { |file| clean_wikitext(file.read) }

  write(
    "wikisource_tw",
    scan_parallel(bodies) { |body|
      body.split("\n").flat_map { |line| pieces_of(line).select { |piece| terminal?(piece) && usable?(piece) } }
    }
  )
end

def extract_ptt(limit: Integer(ENV.fetch("PTT_LIMIT", "50000")))
  path = Corpus.corpora("ptt/Gossiping-QA-Dataset-2_0.csv")
  return Corpus.say("ptt_gossip: no file, skipped") unless path.exist?

  out = []
  seen = Set.new

  CSV.foreach(path, headers: true, encoding: "utf-8") do |row|
    %w[question answer].each do |field|
      candidate = row[field].to_s.gsub(/[[:space:]]+/, "")
      han = han_length(candidate)
      next unless (6..60).cover?(han)
      next if han.fdiv([candidate.length, 1].max) < 0.8
      next if candidate.match?(PTT_BLOCKLIST)
      next unless OriginFilter.keep?(candidate)
      next unless seen.add?(candidate)

      out << candidate
      if out.length >= limit
        Corpus.say("ptt_gossip: hit the #{limit} cap (PTT_LIMIT), rest dropped")
        return write("ptt_gossip", out)
      end
    end
  end

  write("ptt_gossip", out)
end

def about_taiwan?(title, body)
  return false if title.match?(MAINLAND)
  return true if title.match?(TAIWAN)

  tw = body.scan(TAIWAN).length
  cn = body.scan(MAINLAND).length
  tw >= 5 && tw > cn * 3
end

class WikivoyageListener
  include REXML::StreamListener

  attr_reader :pages

  def initialize
    @pages = []
    @stack = []
    @buffer = +""
    @title = nil
    @ns = nil
    @text = nil
  end

  def tag_start(name, _attributes)
    @stack.push(name)
    @buffer = +""
  end

  def text(value) = @buffer << value

  def tag_end(name)
    case name
    when "title"
      @title = @buffer.dup if @stack.length == 3
    when "ns"
      @ns = @buffer.dup
    when "text"
      @text = @buffer.dup
    when "page"
      @pages << [@title.to_s, @text.to_s] if @ns == "0"
      @title = @ns = @text = nil
    end

    @stack.pop
    @buffer = +""
  end
end

def extract_wikivoyage
  path = Corpus.corpora("wikivoyage/zhwikivoyage.xml.bz2")
  return Corpus.say("wikivoyage: no dump, skipped") unless path.exist?

  xml = IO.popen(["bzip2", "-dc", path.to_s], "rb", &:read)
  listener = WikivoyageListener.new
  REXML::Parsers::StreamParser.new(xml, listener).parse

  wanted = listener.pages.select { |title, body| about_taiwan?(title, body) }

  write(
    "wikivoyage",
    scan_parallel(wanted) { |_, body|
      clean_wikitext(body).split("\n").flat_map { |line|
        pieces_of(line).select { |piece| !piece.match?(MAINLAND_QUOTES) && terminal?(piece) && usable?(piece) }
      }
    }
  )
end

def extract_prepared
  ntpc = Corpus.corpora("ntpc_sentences.json")
  write("ntpc_press", thin(Corpus.read_json(ntpc), Integer(ENV.fetch("NTPC_CAP", "68000")))) if ntpc.exist?

  concised = Corpus.corpora("concised.json")
  return unless concised.exist?

  write(
    "moe_concised",
    Corpus.read_json(concised).flat_map { |entry| entry["senses"].flat_map { |sense| sense["sentences"] } }
  )
end

only = ENV["ONLY"]&.split(",")&.map(&:strip)

STEPS = {
  "prepared" => -> { extract_prepared },
  "law" => -> { extract_law },
  "common_voice" => -> { extract_common_voice },
  "wikivoyage" => -> { extract_wikivoyage },
  "ly" => -> { extract_ly },
  "tbcl" => -> { extract_tbcl },
  "wikisource" => -> { extract_wikisource },
  "ptt" => -> { extract_ptt }
}.freeze

STEPS.each do |name, step|
  next if only && !only.include?(name)

  Corpus.timed(name) { step.call }
end

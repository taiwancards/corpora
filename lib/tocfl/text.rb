# frozen_string_literal: true

require_relative "geometry"

module Tocfl
  module Text
    LABEL = /[(（]\s*([A-F])\s*[)）]/
    LABEL_ONLY = /\A[(（]\s*([A-F])\s*[)）]\z/
    ANCHOR = /\A(\d{1,3})\s*[.．](?!\d)/
    ZHUYIN = /[ㄅ-ㄯㆠ-ㆿˇˉˊˋ˙]/
    TONED = /[āáǎàēéěèīíǐìōóǒòūúǔùǖǘǚǜ]/
    PINYIN_TOKEN = /\A[a-zA-Zāáǎàēéěèīíǐìōóǒòūúǔùǖǘǚǜü']+\z/
    CJK = /[㐀-鿿豈-﫿]/
    PUNCTUATION_START = /\A[，。、；：？！」』）)】,.;:?!]/
    BLANK = "＿＿"
    MISENCODED = /[帄帅頇詴尌爮緐乊亯]/
    MISENCODED_AMBIGUOUS = /付/

    module_function

    def weight(char) = char.ascii_only? ? 0.5 : 1.0

    def split_word(word)
      raw = word.text
      ranges = []
      position = 0
      if (anchor = ANCHOR.match(raw)) && !anchor.post_match.strip.empty?
        ranges << [0, anchor.end(0)]
        position = anchor.end(0)
      end

      while (label = LABEL.match(raw, position))
        ranges << [position, label.begin(0)] unless raw[position...label.begin(0)].strip.empty?
        ranges << [label.begin(0), label.end(0)]
        position = label.end(0)
      end

      ranges << [position, raw.size] unless raw[position..].to_s.strip.empty?
      return [word] if ranges.size <= 1

      cumulative = raw.each_char.each_with_object([0.0]) { |char, sums| sums << (sums.last + weight(char)) }
      unit = word.box.width / [cumulative.last, 0.5].max
      ranges.map do |from, to|
        piece = raw[from...to].strip
        piece = "(#{Regexp.last_match(1)})" if piece.match(LABEL_ONLY)
        box = Box.new(
          word.box.x0 + (cumulative[from] * unit),
          word.box.y0,
          word.box.x0 + (cumulative[to] * unit),
          word.box.y1
        )
        Word.new(page: word.page, box: box, text: piece)
      end
    end

    def residue?(token) = token.match?(ZHUYIN) || (token.match?(PINYIN_TOKEN) && token.match?(TONED))

    def strip_residue(token) = token.gsub(ZHUYIN, "")

    def join(tokens)
      tokens.each_with_object(+"") do |token, out|
        next if token.empty?

        if out.empty? ||
            out.end_with?(BLANK) ||
            token.start_with?(BLANK) ||
            (cjk_edge?(out[-1]) && cjk_edge?(token[0])) ||
            token.match?(PUNCTUATION_START)
          out << token
        else
          out << " " << token
        end
      end
    end

    def cjk_edge?(char) = char.match?(CJK) || char.match?(/[　-〿＀-￯「」『』]/)

    def normalize(text)
      text
        .to_s
        .gsub(/[ \t]+/, " ")
        .gsub(/(?:#{BLANK})+/o, BLANK)
        .gsub(/#{BLANK}\s*([(（]\s*\d+\s*[)）])\s*#{BLANK}/o, "#{BLANK}\\1#{BLANK}")
        .strip
    end

    def problems(text, min: 1, max: 400)
      issues = []
      return ["empty"] if text.nil? || text.strip.empty?

      issues << "annotation residue" if text.match?(ZHUYIN) || text.match?(TONED)
      issues << "length #{text.size}" unless text.size.between?(min, max)
      issues << "replacement character" if text.include?("�")
      issues
    end
  end
end

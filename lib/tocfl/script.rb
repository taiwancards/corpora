# frozen_string_literal: true

require_relative "document"
require_relative "rows"
require_relative "text"

module Tocfl
  class Script
    PART = /\A第\s*[一二三四五六七八九十]+\s*部\s*分|\A[一二三四五六七八九十]\s*、/
    TITLE = /聽力文本|腳本|Script|模擬試題|聽力測驗/i
    INTRO = /\A(以下是|下面是|下面|請聽|接下來|現在請聽|請你)/
    NUMBER = /\A(\d{1,3})\s*[.．、]\s*(.*)\z/
    BARE_NUMBER = /\A(\d{1,3})\s+(\S.*)\z/
    SPEAKER = /\A[（(]?\s*([男女]\d?|[A-Z]|Q)\s*[)）]?\s*[：:]?\s*(.*)\z/
    SPEAKER_SPACED = /\A[（(]?\s*([男女]\d?|Q|提問|問)\s*[)）]?\s*[：:]\s*|\A[（(]?\s*([男女]\d?|Q|提問|問)\s*[)）]?\s+(?=\S)/

    Group = Data.define(:part, :numbers, :lines, :ocr)

    attr_reader :groups, :parts

    def initialize(document)
      @document = document
    end

    def parse
      @groups = []
      @parts = 0
      units = []
      seen = []
      started = false
      lines.each do |line, ocr|
        if line.match?(PART)
          @parts += 1
          units << [:part]
          started = true
          next
        end

        next if line.match?(TITLE) && !started

        started = true
        match = line.match(NUMBER) || line.match(BARE_NUMBER)
        if match && !line.match(NUMBER) && !(seen.empty? ? match[1].to_i == 1 : match[1].to_i == seen.max + 1)
          match = nil
        end

        if match && match[1].to_i.positive? && !seen.include?(match[1].to_i)
          number = match[1].to_i
          rest = speaker(match[2].to_s.strip)
          seen << number
          entry = {number: number, text: rest.empty? ? nil : "#{number}. #{rest}", ocr: ocr}
          last = units.last
          if last &&
              last.first == :cluster &&
              last[1].last[:number] == number -
              1 &&
              last[1].last[:text] &&
              entry[:text]
            last[1] << entry
          else
            units << [:cluster, [entry]]
          end
        elsif match && seen.include?(match[1].to_i)
          units << [:line, "#{match[1].to_i}. #{speaker(match[2].to_s.strip)}", ocr]
        elsif units.last&.first == :cluster &&
            units.last[1].last[:text] &&
            !units.last[1].last[:text].match?(/[。！？?」』：…]\z/) &&
            !speaker_line?(line) &&
            !intro_line?(line) &&
            !line.match?(/\A\([A-F]\)/)
          units.last[1].last[:text] = "#{units.last[1].last[:text]}#{line}"
        else
          units << [:line, line, ocr]
        end
      end

      assemble(units)
      self
    end

    def intro_line?(line) = !speaker_line?(line) && (line.match?(INTRO) || line.match?(/請聽|回答.{0,8}問題/))

    def speaker_line?(line) = line.match?(/\A([男女]\d?|Q|提問|問)：/)

    def assemble(units)
      previous = nil
      pending = []
      part = 0
      flush = lambda do
        previous[:lines].concat(pending) if previous && previous[:preview]
        pending = []
      end

      units.each do |kind, payload, ocr|
        case kind
        when :part
          flush.call
          previous = nil
          part += 1
        when :line
          pending << [payload, ocr]
        when :cluster
          if previous && previous[:preview]
            texts = pending.map(&:first)
            boundary = texts.index { |text| intro_line?(text) && !text.match?(/\A現在請聽/) }
            if boundary
              boundary -= 1 while boundary.positive? &&
                !speaker_line?(texts[boundary - 1]) &&
                !texts[boundary - 1].match?(/\A\d{1,3}\. /) &&
                !texts[boundary - 1].match?(/[。！？」』：…]\z/)
              previous[:lines].concat(pending[0...boundary])
              pending = pending[boundary..]
            else
              previous[:lines].concat(pending)
              pending = []
            end
          end

          lead = pending
          pending = []
          texts = lead.map(&:first)
          introduced = texts.any? { |text| intro_line?(text) }
          entries = payload
          slices = entries.size > 1 && !introduced ? entries.map { |entry| [entry] } : [entries]
          slices.each_with_index do |slice, index|
            group = {
              part: [part, 1].max,
              numbers: slice.map { |entry| entry[:number] },
              lines: (index.zero? ? lead : []) +
                slice.filter_map { |entry| entry[:text] && [entry[:text], entry[:ocr]] },
              preview: index.zero? ? texts.none? { |text| !intro_line?(text) } : true
            }
            @groups << group
            previous = group
          end
        end
      end

      flush.call
      @groups = @groups.map do |group|
        Group.new(
          part: group[:part],
          numbers: group[:numbers],
          lines: tidy(group[:lines].map(&:first)),
          ocr: group[:lines].any?(&:last)
        )
      end
    end

    def for_number(number) = groups.find { |group| group.numbers.include?(number) }

    def transcript(group) = group.lines.join("\n")

    def options(number)
      group = for_number(number)
      return {} unless group

      group.lines.filter_map { |line| line.match(/\A\(([A-F])\)\s*(.+)\z/) }.to_h { |match| [match[1], match[2]] }
    end

    private

    def lines
      (1..@document.page_count).flat_map do |page|
        rows = Rows.build(Rows.tokens(@document.words(page)).reject { |token| token.text.strip.empty? })
        ocr = @document.ocr_page?(page)
        rows.reject { |row| Rows.page_number?(row, @document.page_box(page)) }.map { |row| [row_text(row), ocr] }
      end
    end

    def row_text(row)
      tokens = row.words.map(&:text)
      text = tokens.join(" ")
      Text.normalize(speaker(text))
    end

    def speaker(text)
      text.sub(SPEAKER_SPACED) { "#{Regexp.last_match(1) || Regexp.last_match(2)}：" }
    end

    def tidy(raw)
      raw
        .each_with_object([]) do |line, out|
          if out.any? && continuation?(line, out.last)
            out[-1] = Text.join([out[-1], line.strip])
          else
            out << line.strip
          end
        end
        .map { |line|
          line.gsub(/(?<=\p{Han}|[，。！？、：；」「])\s+(?=\p{Han}|[，。！？、：；」「])/, "")
        }
    end

    def continuation?(line, previous)
      if line.match?(/\A(\d{1,3}\s*[.．]|\([A-F]\)|[（(]?[男女]\d?[)）]?：|Q：|提問：|問：|[A-Z]：)/)
        return false
      end

      return false if line.match?(INTRO) || previous.match?(INTRO)

      !previous.match?(/\A\([A-F]\)/)
    end
  end
end

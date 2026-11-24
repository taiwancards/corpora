# frozen_string_literal: true

require_relative "geometry"
require_relative "text"

module Tocfl
  module Rows
    PAGE_NUMBER = /\A[-–—\s]*(?:第\s*)?\d{1,3}\s*(?:頁)?[-–—\s]*\z|\A\d{1,3}\s*\/\s*\d{1,3}\z/

    module_function

    def build(tokens)
      rows = []
      tokens.sort_by { |token| [token.y0, token.x0] }.each do |token|
        best = nil
        best_overlap = 0
        rows.reverse_each do |row|
          break if row[:y1] < token.y0 - 40

          overlap = [[row[:y1], token.y1].min - [row[:y0], token.y0].max, 0].max
          height = [row[:y1] - row[:y0], token.height].min
          next unless overlap >= 0.5 * height && overlap > best_overlap

          best = row
          best_overlap = overlap
        end

        if best
          best[:tokens] << token
          best[:y0] = [best[:y0], token.y0].min if token.height > 0.6 * (best[:y1] - best[:y0])
          best[:y1] = [best[:y1], token.y1].max if token.height > 0.6 * (best[:y1] - best[:y0])
        else
          rows << {y0: token.y0, y1: token.y1, tokens: [token]}
        end
      end

      rows
        .map { |row| Row.new(page: row[:tokens].first.page, words: merge_labels(row[:tokens].sort_by(&:x0))) }
        .sort_by { |row| [row.y0, row.x0] }
    end

    def merge_labels(tokens)
      merged = []
      index = 0
      while index < tokens.size
        joined = nil
        if tokens[index].text.match?(/\A[(（]\s*[A-F]?\z/)
          [3, 2].each do |span|
            window = tokens[index, span]
            next unless window.size == span
            next unless window.each_cons(2).all? { |a, b| b.x0 - a.x1 < 6 }

            text = window.map(&:text).join
            next unless text.match?(/\A#{Text::LABEL.source}/o)

            joined = [Word.new(page: window.first.page, box: Box.around(window.map(&:box)), text: text), span]
            break
          end
        end

        if joined.nil? &&
            tokens[index].text.match?(/\A\d{1,3}\z/) &&
            tokens[index + 1]&.text&.match?(/\A[.．]/) &&
            tokens[index + 1].x0 -
            tokens[index].x1 < 3
          following = tokens[index + 1]
          joined = [
            Word.new(
              page: tokens[index].page,
              box: Box.around([tokens[index].box, following.box]),
              text: "#{tokens[index].text}#{following.text}"
            ),
            2
          ]
        end

        if joined
          merged.concat(Text.split_word(joined.first))
          index += joined.last
        else
          merged << tokens[index]
          index += 1
        end
      end

      merged
    end

    def tokens(words)
      words.flat_map { |word| Text.split_word(word) }
    end

    def page_number?(row, page_box)
      row.compact_text.match?(PAGE_NUMBER) && (row.y0 > page_box.height - 80 || row.y1 < 50)
    end
  end
end

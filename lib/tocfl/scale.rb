# frozen_string_literal: true

require "open3"

module Tocfl
  class Scale
    BANDED = /\A(?:Table(\d)_)?(Listening|Reading)_([ABC])\.pdf\z/
    NOVICE = "score_table_Novice.pdf"
    ROW = /\A\s*(\d{1,2})\s+(\d{1,3})(?:\s+(\d{1,2})\s+(\d{1,3}))?\s*\z/

    attr_reader :sources

    def initialize(papers_dir)
      @papers_dir = papers_dir
      @tables = {}
      @sources = {}
    end

    def load
      Dir.children(@papers_dir).sort.each do |name|
        if (match = name.match(BANDED))
          set = match[1] ? match[1].to_i : 1
          store(match[3], match[2].downcase, set, name, pairs(name).map(&:first))
        elsif name == NOVICE
          rows = pairs(name)
          store("Novice", "listening", 1, name, rows.map(&:first))
          store("Novice", "reading", 1, name, rows.filter_map(&:last))
        end
      end

      self
    end

    def for(band, skill, set) = @tables.dig(band, skill, set)

    private

    def store(band, skill, set, name, table)
      table = table.compact.sort_by(&:first)
      return if table.empty?
      return unless table.map(&:first) == (1..table.size).to_a
      return unless table.each_cons(2).all? { |(_, low), (_, high)| high >= low }

      ((@tables[band] ||= {})[skill] ||= {})[set] = {
        "max" => table.map(&:last).max,
        "table" => table,
        "thresholds" => nil,
        "source" => name,
        "note" => "official mock-test table; raw 0 is not printed"
      }
    end

    def pairs(name)
      text, _err, status = Open3.capture3("pdftotext", "-layout", File.join(@papers_dir, name), "-")
      return [] unless status.success?

      rows = text.lines.filter_map { |line| line.match(ROW) }
      left = rows.map { |match| [match[1].to_i, match[2].to_i] }
      right = rows.filter_map { |match| match[3] && [match[3].to_i, match[4].to_i] }
      if name == NOVICE
        left.zip(right)
      else
        (left + right).map { |pair| [pair, nil] }
      end
    end
  end
end

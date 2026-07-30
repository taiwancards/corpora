# frozen_string_literal: true

require_relative "origin_filter"

module Sentences
  SENT_END = /(?<=[。！？])/
  TERMINAL = %w[。 ！ ？].freeze

  module_function

  def own(*parts) = Pathname(ENV.fetch("OWN_CORPORA_DIR") { Corpus.data("corpora").to_s }).join(*parts)

  def out_dir = own("sentences")

  def han_length(text) = text.unpack("U*").count { |code| code >= 0x4E00 && code <= 0x9FFF }

  def shaped?(text, min_han: 6, max_han: 60, min_ratio: 0.65)
    han = han_length(text)
    (min_han..max_han).cover?(han) && han.fdiv([text.length, 1].max) >= min_ratio
  end

  def usable?(text, min_han: 6, max_han: 60, min_ratio: 0.65)
    shaped?(text, min_han:, max_han:, min_ratio:) && OriginFilter.keep?(text)
  end

  def terminal?(text) = TERMINAL.any? { |mark| text.end_with?(mark) }

  def pieces_of(line) = line.split(SENT_END).filter_map { |piece| Corpus.strip(piece).presence }

  def thin(rows, cap)
    return rows if cap.nil? || rows.length <= cap

    step = rows.length / cap.to_f
    Array.new(cap) { |index| rows[(index * step).to_i] }
  end

  def write(slug, sentences)
    out_dir.mkpath
    unique = sentences.uniq
    Corpus.write_json(out_dir.join("#{slug}.json"), unique)
    Corpus.report(slug, sentences: unique.length)
    unique
  end

  def each_gz_line(path)
    return to_enum(:each_gz_line, path) unless block_given?

    IO.popen(["gzip", "-dc", path.to_s], "rb") do |io|
      io.set_encoding("utf-8", invalid: :replace, undef: :replace)
      io.each_line { |line| yield line }
    end
  end

  def each_bz2_line(path)
    return to_enum(:each_bz2_line, path) unless block_given?

    IO.popen(["bzip2", "-dc", path.to_s], "rb") do |io|
      io.set_encoding("utf-8", invalid: :replace, undef: :replace)
      io.each_line { |line| yield line }
    end
  end
end

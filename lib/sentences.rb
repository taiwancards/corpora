# frozen_string_literal: true

require_relative "origin_filter"

module Sentences
  POLICY = TWFilter::Policy.corpus

  module_function

  def own(*parts) = Pathname(ENV.fetch("OWN_CORPORA_DIR") { Corpus.data("corpora").to_s }).join(*parts)

  def out_dir = own("sentences")

  def han_length(text) = TWFilter::Han.count(text)

  def shaped?(text, min_han: 6, max_han: 60, min_ratio: 0.65)
    TWFilter::Sentences.shaped?(text, policy: POLICY.with(han_range: (min_han..max_han), min_han_ratio: min_ratio))
  end

  def usable?(text, min_han: 6, max_han: 60, min_ratio: 0.65)
    shaped?(text, min_han:, max_han:, min_ratio:) && OriginFilter.keep?(text)
  end

  def terminal?(text) = TWFilter::Sentences.terminal?(text)

  def pieces_of(line) = TWFilter::Sentences.split(TWFilter.normalize(line), clause: false)

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

  def each_gz_line(path, &) = each_compressed_line(["gzip", "-dc", path.to_s], &)

  def each_bz2_line(path, &) = each_compressed_line(["bzip2", "-dc", path.to_s], &)

  def each_compressed_line(command)
    return to_enum(:each_compressed_line, command) unless block_given?

    IO.popen(command, "rb") do |io|
      io.set_encoding("utf-8", invalid: :replace, undef: :replace)
      io.each_line { |line| yield line }
    end
  end
end

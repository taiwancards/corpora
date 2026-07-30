# frozen_string_literal: true

require_relative "sentences"

module Registers
  SENTENCE_SPLIT = /(?<=[。！？；])/
  BLOCK = 300
  BLOCK_TOLERANCE = 0.0
  EVIDENCE_PER_100 = 1.0

  module_function

  def judge(window, tolerance: BLOCK_TOLERANCE, evidence_per_100: EVIDENCE_PER_100)
    return [] if window.empty?

    verdicts = window.map { |line| OriginFilter.keep?(line) }
    return [] if verdicts.count(false) > tolerance * window.length
    return [] if OriginFilter.evidence(window.join) < evidence_per_100 * window.length / 100

    window.zip(verdicts).filter_map { |line, ok| line if ok }
  end

  def taiwanese_blocks(lines, block: BLOCK)
    return to_enum(:taiwanese_blocks, lines, block:) unless block_given?

    window = []
    lines.each do |line|
      window << line
      next if window.length < block

      judge(window).each { |kept| yield kept }
      window = []
    end

    judge(window).each { |kept| yield kept } if window.any?
  end
end

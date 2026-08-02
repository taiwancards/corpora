# frozen_string_literal: true

require_relative "sentences"

module Registers
  BLOCK = TWFilter::Block::SIZE
  POLICY = TWFilter::Policy.new(han_range: (1..Float::INFINITY), min_han_ratio: 0.0, max_tier: :rare)

  module_function

  def sentence_split(text) = TWFilter::Sentences.split(text, clause: true)

  def judge(window, tolerance: nil, evidence_per_100: nil)
    policy = POLICY
    policy = policy.with(block_tolerance: tolerance) if tolerance
    policy = policy.with(evidence_per_100: evidence_per_100) if evidence_per_100
    TWFilter::Block.judge(window, policy: policy)
  end

  def taiwanese_blocks(lines, block: BLOCK, &) = TWFilter::Block.each_kept(lines, size: block, policy: POLICY, &)
end

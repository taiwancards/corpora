# frozen_string_literal: true

require_relative "test_helper"
require_relative "../lib/origin_filter"

class OriginFilterTest < Minitest::Test
  def test_keeps_ordinary_taiwanese_mandarin
    assert(OriginFilter.keep?("今天天氣很好，我們去公園散步。"))
  end

  def test_counts_han_characters_only
    assert_equal(3, OriginFilter.han_length("台北市 2024"))
    assert_equal(0, OriginFilter.han_length("Taipei 101"))
  end

  def test_rejects_mainland_vocabulary
    verdict = OriginFilter.inspect_text("請把這個信息轉發給所有的同事。")

    refute(verdict.ok?)
    assert(verdict.reasons.any? { |reason| reason.start_with?("mainland") })
  end

  def test_exception_list_protects_legitimate_compounds
    assert_empty(OriginFilter.mainland_hits("電視頻道播出新聞。"))
    refute_empty(OriginFilter.mainland_hits("這個視頻很好看。"))
  end

  def test_rejects_cantonese_particles
    verdict = OriginFilter.inspect_text("你食咗飯未呀，我哋而家去邊度？")

    refute(verdict.ok?)
    assert(verdict.reasons.any? { |reason| reason.start_with?("cantonese") })
  end

  def test_evidence_counts_taiwan_specific_usage
    assert_operator(OriginFilter.evidence("我們搭捷運去，很方便喔。"), :>, 0)
    assert_equal(0, OriginFilter.evidence("ABC"))
  end

  def test_verdict_exposes_the_reasons_it_refused
    verdict = OriginFilter.inspect_text("今天天氣很好。")

    assert(verdict.ok?)
    assert_empty(verdict.reasons)
    assert_equal(6, verdict.han)
  end
end

# frozen_string_literal: true

require_relative "test_helper"
require_relative "../lib/registers"
require_relative "../lib/origin_filter"

class RegistersTest < Minitest::Test
  TAIWANESE = "你有沒有搭過捷運去看那部影片啦？"
  CHINA = "今天天气很好，我们一起去公园散步。"

  def test_judge_returns_nothing_for_an_empty_window
    assert_empty(Registers.judge([]))
  end

  def test_judge_keeps_a_window_of_taiwanese_prose
    window = Array.new(20) { TAIWANESE }

    assert_equal(20, Registers.judge(window).length)
  end

  def test_judge_drops_the_whole_window_when_any_line_fails_at_zero_tolerance
    window = Array.new(19) { TAIWANESE } + [CHINA]

    assert_empty(Registers.judge(window))
  end

  def test_judge_keeps_the_clean_lines_when_tolerance_allows_a_failure
    window = Array.new(19) { TAIWANESE } + [CHINA]
    kept = Registers.judge(window, tolerance: 0.1)

    assert_equal(19, kept.length)
    refute_includes(kept, CHINA)
  end

  def test_judge_drops_a_window_with_too_little_taiwanese_evidence
    window = Array.new(20) { "他說。" }

    assert_empty(Registers.judge(window, evidence_per_100: 100.0))
  end

  def test_taiwanese_blocks_yields_nothing_for_no_lines
    assert_empty(Registers.taiwanese_blocks([], block: 4).to_a)
  end

  def test_taiwanese_blocks_judges_each_full_block_on_its_own
    lines = Array.new(4) { TAIWANESE } + Array.new(4) { CHINA }

    assert_equal(4, Registers.taiwanese_blocks(lines, block: 4).to_a.length)
  end

  def test_taiwanese_blocks_judges_the_trailing_partial_block
    lines = Array.new(6) { TAIWANESE }

    assert_equal(6, Registers.taiwanese_blocks(lines, block: 4).to_a.length)
  end

  def test_taiwanese_blocks_returns_an_enumerator_without_a_block
    assert_kind_of(Enumerator, Registers.taiwanese_blocks([TAIWANESE]))
  end
end

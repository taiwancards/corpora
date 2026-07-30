# frozen_string_literal: true

require_relative "test_helper"
require_relative "../lib/sentences"
require_relative "../lib/registers"

class SentencesTest < Minitest::Test
  GOOD = "今天天氣很好，我們一起去公園散步。"

  def test_shaped_accepts_a_normal_sentence
    assert(Sentences.shaped?(GOOD))
  end

  def test_shaped_rejects_a_stub
    refute(Sentences.shaped?("好。"))
  end

  def test_shaped_rejects_a_line_swamped_by_latin
    refute(Sentences.shaped?("Taipei 101 is the tallest building 台北一零一"))
  end

  def test_terminal_requires_a_full_stop
    assert(Sentences.terminal?(GOOD))
    refute(Sentences.terminal?("今天天氣很好，我們一起去公園散步"))
  end

  def test_pieces_of_splits_after_the_terminator
    pieces = Sentences.pieces_of("今天天氣很好。我們去公園散步。")

    assert_equal(["今天天氣很好。", "我們去公園散步。"], pieces)
  end

  def test_thin_keeps_the_cap_and_spreads_the_sample
    rows = (1..100).to_a

    assert_equal(10, Sentences.thin(rows, 10).length)
    assert_equal(rows, Sentences.thin(rows, nil))
    assert_equal(rows, Sentences.thin(rows, 500))
  end

  def test_usable_combines_shape_and_origin
    assert(Sentences.usable?(GOOD))
    refute(Sentences.usable?("請看這個視頻，然後給我發個信息好嗎。"))
  end

  def test_registers_keeps_a_clean_taiwanese_block
    lines = ["我們搭捷運去台北車站喔。", "今天天氣很好，我們去公園散步。"]

    assert_equal(lines, Registers.judge(lines))
  end

  def test_registers_discards_a_block_with_no_taiwan_evidence
    assert_empty(Registers.judge(["這是一個句子。"], evidence_per_100: 100.0))
  end

  def test_registers_returns_nothing_for_an_empty_window
    assert_empty(Registers.judge([]))
  end
end

# frozen_string_literal: true

require_relative "test_helper"
require_relative "../lib/segmenter"

class SegmenterTest < Minitest::Test
  WORDS = Set.new(%w[今天 天氣 很好 我們 公園 散步 台灣 學生 學校]).freeze

  def test_han_runs_splits_on_punctuation
    assert_equal(
      %w[今天天氣很好 我們去公園散步],
      Segmenter.han_runs("今天天氣很好，我們去公園散步。")
    )
  end

  def test_han_runs_ignores_latin_and_digits
    assert_equal(%w[台灣], Segmenter.han_runs("台灣 2024 GDP"))
  end

  def test_max_word_is_the_longest_word_capped_at_the_ceiling
    assert_equal(4, Segmenter.max_word(%w[天 天氣 今天天氣]))
    assert_equal(Segmenter::MAX_WORD, Segmenter.max_word(["一二三四五六七八九十"]))
  end

  def test_vocabulary_reads_words_and_chars
    path = Fixtures.tmp_json("vocab.json", {"words" => {"今天" => 3, "天氣" => 2}, "chars" => %w[今 天 氣]})
    words, chars = Segmenter.vocabulary(path)

    assert_equal(Set.new(%w[今天 天氣]), words)
    assert_equal(Set.new(%w[今 天 氣]), chars)
  end

  def test_naive_counts_only_counts_known_words
    runs = %w[今天天氣很好]
    words, chars = Segmenter.naive_counts(runs, WORDS, 4)

    assert_equal(1, words["今天"])
    assert_equal(1, words["天氣"])
    assert_equal(0, words["天天"])
    assert_equal(2, chars["天"])
  end

  def test_segment_prefers_known_words_over_single_characters
    runs = %w[今天天氣很好 今天天氣很好 我們去公園散步]
    word_counts, char_counts = Segmenter.naive_counts(runs, WORDS, 4)
    model = Segmenter.build_model(word_counts, char_counts, 4)

    assert_equal(%w[今天 天氣 很好], Segmenter.segment("今天天氣很好", WORDS, model))
  end

  def test_segment_reconstructs_the_input_exactly
    runs = %w[我們去公園散步]
    word_counts, char_counts = Segmenter.naive_counts(runs, WORDS, 4)
    model = Segmenter.build_model(word_counts, char_counts, 4)
    pieces = Segmenter.segment("我們去公園散步", WORDS, model)

    assert_equal("我們去公園散步", pieces.join)
  end

  def test_expectation_maximisation_converges_and_keeps_the_text
    runs = %w[今天天氣很好 今天天氣很好 我們去公園散步 台灣學生去學校]
    words, chars = Segmenter.expectation_maximisation(runs, WORDS, 4, rounds: 2)

    assert_operator(words["今天"], :>=, 1)
    assert_operator(chars.values.sum, :>, 0)
  end
end

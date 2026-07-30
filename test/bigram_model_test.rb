# frozen_string_literal: true

require_relative "test_helper"
require_relative "../lib/bigram_model"

class BigramModelTest < Minitest::Test
  def test_boundaries_are_cumulative_offsets
    assert_equal(Set.new([2, 4, 6]), BigramModel.boundaries(%w[今天 天氣 很好]))
  end

  def test_identical_segmentations_score_one
    gold = %w[今天 天氣 很好]

    assert_in_delta(1.0, BigramModel.score(gold, gold))
  end

  def test_score_is_the_f1_of_boundary_positions
    gold = %w[今天 天氣 很好]
    guessed = %w[今 天 天氣 很好]

    assert_in_delta(0.857, BigramModel.score(gold, guessed), 0.001)
  end

  def test_completely_wrong_split_still_shares_the_final_boundary
    assert_operator(BigramModel.score(%w[今天 天氣], %w[今 天天 氣]), :<, 1.0)
  end

  def test_viterbi_reconstructs_the_input
    words = Set.new(%w[今天 天氣 很好])
    model = BigramModel::Model.new(
      table: {},
      weights: Hash.new(1.0),
      continuation: {"今天" => 0.4, "天氣" => 0.4, "很好" => 0.2},
      unigram: Hash.new(0.01)
    )

    pieces = BigramModel.viterbi("今天天氣很好", words, model, 4, 0.0)

    assert_equal("今天天氣很好", pieces.join)
  end
end

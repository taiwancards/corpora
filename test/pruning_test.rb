# frozen_string_literal: true

require_relative "test_helper"
require_relative "../lib/pruning"

class PruningTest < Minitest::Test
  def test_discount_is_the_kneser_ney_ratio_of_singletons
    bigrams = {%w[今天 天氣] => 1, %w[天氣 很好] => 1, %w[我們 去] => 2}

    assert_in_delta(2 / (2 + (2 * 1)).to_f, Pruning.discounts(bigrams))
  end

  def test_discount_falls_back_when_nothing_is_rare
    assert_in_delta(0.75, Pruning.discounts({%w[a b] => 9}))
  end

  def test_continuation_table_is_a_distribution
    table = Pruning.continuation_table({"天氣" => 3, "很好" => 1})

    assert_in_delta(0.75, table["天氣"])
    assert_in_delta(0.25, table["很好"])
    assert_in_delta(1.0, table.each_value.sum)
  end

  def test_deltas_scores_every_surviving_bigram_and_leaves_mass_for_backoff
    bigrams = {%w[今天 天氣] => 4, %w[今天 很好] => 1}
    history = {"今天" => 5}
    continuation = Pruning.continuation_table({"天氣" => 3, "很好" => 1})

    scored, weights = Pruning.deltas(bigrams, history, continuation, 0.5, 5)

    assert_equal(2, scored.length)
    assert_operator(weights["今天"], :>, 0.0)
    assert_operator(weights["今天"], :<, 1.0)
  end

  def test_deltas_drops_bigrams_the_discount_wipes_out
    bigrams = {%w[今天 天氣] => 1}
    scored, = Pruning.deltas(bigrams, {"今天" => 1}, {"天氣" => 1.0}, 1.0, 1)

    assert_empty(scored)
  end
end

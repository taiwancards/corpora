# frozen_string_literal: true

require_relative "test_helper"
require_relative "../lib/python_random"

class PythonRandomTest < Minitest::Test
  def test_getrandbits_matches_cpython_mersenne_twister
    rng = Corpus::PythonRandom.new(42)
    drawn = Array.new(5) { rng.getrandbits(32) }

    assert_equal([2_746_317_213, 478_163_327, 107_420_369, 3_184_935_163, 1_181_241_943], drawn)
  end

  def test_randrange_matches_cpython
    rng = Corpus::PythonRandom.new(42)
    drawn = Array.new(8) { rng.randrange(100) }

    assert_equal([81, 14, 3, 94, 35, 31, 28, 17], drawn)
  end

  def test_shuffle_matches_cpython
    rng = Corpus::PythonRandom.new(7)
    items = (0...10).to_a

    assert_equal([8, 3, 1, 4, 7, 0, 9, 6, 2, 5], rng.shuffle!(items))
  end

  def test_zero_bits_yields_zero
    assert_equal(0, Corpus::PythonRandom.new(1).getrandbits(0))
  end

  def test_randrange_stays_inside_the_range
    rng = Corpus::PythonRandom.new(99)
    drawn = Array.new(200) { rng.randrange(7) }

    assert_equal([], drawn.reject { |value| (0...7).cover?(value) })
  end

  def test_the_same_seed_replays_the_same_stream
    first = Corpus::PythonRandom.new(2024)
    second = Corpus::PythonRandom.new(2024)

    assert_equal(Array.new(20) { first.randrange(1000) }, Array.new(20) { second.randrange(1000) })
  end
end

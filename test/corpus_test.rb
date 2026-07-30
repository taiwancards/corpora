# frozen_string_literal: true

require_relative "test_helper"
require_relative "../lib/corpus"

class CorpusTest < Minitest::Test
  def test_read_json_round_trips_through_write_json
    Dir.mktmpdir do |dir|
      path = File.join(dir, "nested", "payload.json")
      Corpus.write_json(path, {"words" => %w[今天 天氣], "n" => 2})

      assert_equal({"words" => %w[今天 天氣], "n" => 2}, Corpus.read_json(path))
    end
  end

  def test_write_json_creates_missing_directories
    Dir.mktmpdir do |dir|
      path = Corpus.write_json(File.join(dir, "a", "b", "c.json"), [1, 2, 3])

      assert_path_exists(path.to_s)
    end
  end

  def test_source_refuses_to_guess_a_missing_url
    error = assert_raises(RuntimeError) { Corpus.source("DEFINITELY_NOT_SET_#{Process.pid}") }

    assert_match(/is not set/, error.message)
  end

  def test_user_agent_is_a_header_hash
    header = Corpus.user_agent

    assert_kind_of(Hash, header)
    refute_empty(header.fetch("User-Agent"))
  end

  def test_data_and_corpora_roots_honour_the_environment
    Dir.mktmpdir do |dir|
      previous = ENV["DATA_DIR"]
      ENV["DATA_DIR"] = dir

      assert_equal(File.join(dir, "huayu", "x.json"), Corpus.data("huayu", "x.json").to_s)
    ensure
      previous.nil? ? ENV.delete("DATA_DIR") : ENV["DATA_DIR"] = previous
    end
  end

  def test_string_and_array_presence_helpers
    assert_nil("".presence)
    assert_equal("x", "x".presence)
    assert_nil([].presence)
    assert_equal([1], [1].presence)
  end
end

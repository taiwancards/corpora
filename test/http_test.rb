# frozen_string_literal: true

require_relative "test_helper"
require_relative "../lib/http"

class HttpTest < Minitest::Test
  def test_query_encodes_parameters_onto_a_base_url
    assert_equal(
      "https://example.org/api?page=2&q=%E5%8F%B0%E7%81%A3",
      Http.query("https://example.org/api", {"q" => "台灣", "page" => 2}.sort.to_h)
    )
  end

  def test_query_replaces_an_existing_query_string
    assert_equal("https://example.org/api?b=2", Http.query("https://example.org/api?a=1", {"b" => 2}))
  end

  def test_body_of_reads_a_plain_response_as_utf8
    body = Http.body_of(Stub.new("台灣", nil))

    assert_equal("台灣", body)
    assert_equal(Encoding::UTF_8, body.encoding)
  end

  def test_body_of_inflates_a_gzipped_response
    buffer = StringIO.new(+"", "wb")
    writer = Zlib::GzipWriter.new(buffer)
    writer.write("台灣")
    writer.close

    assert_equal("台灣", Http.body_of(Stub.new(buffer.string, "gzip")))
  end

  class Stub
    def initialize(body, encoding)
      @body = body.dup.force_encoding(Encoding::BINARY)
      @encoding = encoding
    end

    attr_reader :body

    def [](name) = name == "content-encoding" ? @encoding : nil
  end
end

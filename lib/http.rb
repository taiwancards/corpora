# frozen_string_literal: true

require "net/http"
require "uri"
require "stringio"
require "zlib"

require_relative "corpus"

module Http
  RETRIES = 5

  module_function

  def get(url, headers: {}, retries: RETRIES, timeout: 30)
    uri = URI(url)

    retries.times do |attempt|
      response = fetch(uri, headers, timeout)

      case response
      when Net::HTTPSuccess
        return body_of(response)
      when Net::HTTPTooManyRequests
        wait = 30 * (attempt + 1)
        Corpus.say("  429, waiting #{wait}s…")
        sleep(wait)
      else
        response.error!
      end
    end

    raise "429 still failing after #{retries} attempts"
  end

  def json(url, headers: {}, **options) = JSON.parse(get(url, headers: headers, **options))

  def query(base, params)
    uri = URI(base)
    uri.query = URI.encode_www_form(params)
    uri.to_s
  end

  def fetch(uri, headers, timeout)
    Net::HTTP
      .start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: timeout, read_timeout: timeout) do |http|
        http.request(Net::HTTP::Get.new(uri, {"Accept-Encoding" => "gzip"}.merge(headers)))
      end
  end

  def body_of(response)
    body = response.body
    body = Zlib::GzipReader.new(StringIO.new(body)).read if response["content-encoding"].to_s.include?("gzip")
    body.force_encoding("utf-8")
  end
end

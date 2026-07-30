# frozen_string_literal: true

require "minitest/autorun"
require "tmpdir"
require "json"

LIB = File.expand_path("../lib", __dir__)

module Fixtures
  module_function

  def tmp_json(name, payload)
    dir = Dir.mktmpdir("corpora-test")
    path = File.join(dir, name)
    File.write(path, JSON.generate(payload))
    path
  end
end

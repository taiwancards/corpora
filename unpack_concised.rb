#!/usr/bin/env ruby
# frozen_string_literal: true

require "pathname"
require "zip"

directory = Pathname(ARGV.fetch(0))
archive = directory.join("dict_concised.zip")
target = directory.join("dict_concised.xlsx")

def readable(name)
  name.dup.force_encoding("binary").encode("utf-8", "big5")
rescue Encoding::UndefinedConversionError, Encoding::InvalidByteSequenceError
  name
end

Zip::File.open(archive) do |zip|
  entry = zip.find { |candidate|
    name = readable(candidate.name)
    name.end_with?(".xlsx") && !name.include?("欄位")
  }

  abort("no .xlsx inside #{archive}") if entry.nil?

  target.binwrite(entry.get_input_stream.read)
  puts("   -> #{readable(entry.name)}")
end

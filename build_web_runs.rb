#!/usr/bin/env ruby
# frozen_string_literal: true

require "zlib"
require_relative "lib/corpus"

SOURCE = Pathname(Corpus.source(:WEB_CORPUS))
HOST_CAP = Integer(Corpus.env.fetch("WEB_HOST_CAP", "4000"))
MIN_RUN = Integer(Corpus.env.fetch("WEB_MIN_RUN", "2"))
HOST = /"host":"([^"]*)"/
TEXT = /"text":"((?:[^"\\]|\\.)*)"/
HAN_RUN = /[\u{4E00}-\u{9FFF}\u{3400}-\u{4DBF}]+/

abort("WEB_CORPUS does not point at a readable file") unless SOURCE.file?

census = Hash.new(0)
SOURCE.each_line do |line|
  host = HOST.match(line)&.[](1)
  census[host] += 1 if host
end

Corpus.report("census", hosts: census.size, sentences: census.each_value.sum)

kept = 0
runs = 0
chars = 0
target = Corpus.corpora("web_runs.txt")

target.open("w") do |out|
  SOURCE.each_line do |line|
    host = HOST.match(line)&.[](1)
    next if host.nil?

    total = census[host]
    next if total > HOST_CAP && Zlib.crc32(line) % total >= HOST_CAP

    text = TEXT.match(line)&.[](1)
    next if text.nil?

    kept += 1
    text.scan(HAN_RUN) do |run|
      next if run.length < MIN_RUN

      runs += 1
      chars += run.length
      out.puts("#{host}\t#{run}")
    end
  end
end

Corpus.report("sampled", cap: HOST_CAP, sentences: kept, runs: runs, characters: chars)
Corpus.report("written", path: target.basename, megabytes: (target.size / 1024.0 / 1024).round(1))
Corpus.say("next: corpora/build_web_bigrams.rb")

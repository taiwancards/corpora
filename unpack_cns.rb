#!/usr/bin/env ruby
# frozen_string_literal: true

require "zip"
require "fileutils"
require "pathname"

root = Pathname(ARGV.fetch(0))
media = ARGV[1] && Pathname(ARGV[1])

MAPPING_MEMBER = %r{\AUnicode/CNS2UNICODE_.+\.txt\z}

def extract(archive, &)
  Zip::File.open(archive) { |zip| zip.each(&) }
end

mappings = root.join("MapingTables.zip")
if mappings.exist?
  extract(mappings) do |entry|
    next unless entry.name.match?(MAPPING_MEMBER)

    target = root.join(File.basename(entry.name).tr(" ", "_"))
    target.binwrite(entry.get_input_stream.read)
    warn("unpack_cns: #{target.basename}")
  end
end

voice = root.join("Voice.zip")
if media && voice.exist?
  media.mkpath
  extract(voice) do |entry|
    payload = entry.get_input_stream.read
    if entry.name.downcase.end_with?(".txt")
      media.join("syllables.txt").binwrite(payload)
      next
    end

    speaker = File.basename(entry.name, ".zip")
    directory = media.join("audio", speaker)
    directory.mkpath
    Zip::File.open_buffer(payload) do |inner|
      inner.each { |clip| directory.join(File.basename(clip.name)).binwrite(clip.get_input_stream.read) }
    end

    warn("unpack_cns: #{speaker} #{directory.children.length} clips")
  end
end

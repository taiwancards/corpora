# frozen_string_literal: true

require "digest"
require "json"
require "open3"
require "tmpdir"

module Tocfl
  class Audio
    LONG_SILENCE = 3.0
    Clip = Data.define(:path, :name, :seconds, :sha256, :silences) do
      def internal_silences = silences.reject { |from, to| from < 0.3 || to > seconds - 0.3 }

      def trailing_silence
        last = silences.max_by(&:last)
        last && last.last >= seconds - 0.3 ? seconds - last.first : 0.0
      end

      def repeated?
        gaps = internal_silences.select { |from, to| to - from >= LONG_SILENCE }
        return false if gaps.empty?

        longest = gaps.max_by { |from, to| to - from }
        speech_end = seconds - trailing_silence
        first = longest.first
        second = speech_end - longest.last
        first.positive? && second >= 0.8 && (first / second).between?(0.4, 4.0)
      end
    end

    CACHE = File.join(Dir.tmpdir, "tocfl-audio.json")

    def self.cache
      @cache ||= File.exist?(CACHE) ? JSON.parse(File.read(CACHE)) : {}
    end

    def self.save
      File.write(CACHE, JSON.generate(cache))
    end

    attr_reader :root, :folder

    def initialize(media_root, folder)
      @root = media_root
      @folder = folder
    end

    def directory = File.join(root, folder)

    def exist? = File.directory?(directory)

    def names
      return [] unless exist?

      Dir.glob(File.join(directory, "**", "*.mp3")).map { |file| file.delete_prefix("#{directory}/") }.sort
    end

    def clips
      @clips ||= begin
        list = names
        mutex = Mutex.new
        results = {}
        queue = Queue.new
        list.each { |name| queue << name }
        workers = Array.new(8) do
          Thread.new do
            loop do
              name = begin
                queue.pop(true)
              rescue ThreadError
                break
              end

              clip = probe(name)
              mutex.synchronize { results[name] = clip }
            end
          end
        end

        workers.each(&:join)
        list.map { |name| results.fetch(name) }
      end
    end

    def self.stem(name) = File.basename(name).sub(/(\.mp3)+\z/i, "")

    private

    def probe(name)
      file = File.join(directory, name)
      key = "#{file}:#{File.size(file)}:#{File.mtime(file).to_i}"
      row = self.class.cache[key] ||= measure(file)
      Clip.new(
        path: name,
        name: self.class.stem(name),
        seconds: row["seconds"],
        sha256: row["sha256"],
        silences: row["silences"]
      )
    end

    def measure(file)
      seconds, = Open3.capture2("ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", file)
      _out, log, = Open3.capture3(
        "ffmpeg",
        "-nostdin",
        "-hide_banner",
        "-i",
        file,
        "-af",
        "silencedetect=n=-40dB:d=1.5",
        "-f",
        "null",
        "-"
      )
      starts = log.scan(/silence_start: ([\d.]+)/).flatten.map(&:to_f)
      ends = log.scan(/silence_end: ([\d.]+)/).flatten.map(&:to_f)
      total = seconds.to_f
      silences = starts.each_with_index.map { |from, index| [from.round(2), (ends[index] || total).round(2)] }
      {"seconds" => total.round(2), "sha256" => Digest::SHA256.file(file).hexdigest, "silences" => silences}
    end
  end
end

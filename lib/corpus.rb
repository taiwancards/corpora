# frozen_string_literal: true

require "json"
require "set"
require "etc"
require "pathname"

class String
  def presence = empty? ? nil : self
end

class Array
  def presence = empty? ? nil : self
end

module Corpus
  HAN = /\A[\u{4E00}-\u{9FFF}\u{3400}-\u{4DBF}]+\z/
  HAN_CHAR = /[\u{4E00}-\u{9FFF}\u{3400}-\u{4DBF}]/
  ASSIGNMENT = /\A([A-Z0-9_]+)=(.*)\z/

  module_function

  def app_root = Pathname(__dir__).parent.parent

  def env
    return ENV if @loaded

    @loaded = true
    path = app_root.join(".env")
    return ENV unless path.exist?

    path.each_line do |line|
      key, value = line.strip.match(ASSIGNMENT)&.captures
      next unless key

      ENV[key] ||= value.sub(/\A"(.*)"\z/m, "\\1").sub(/\A'(.*)'\z/m, "\\1")
    end

    ENV
  end

  def source(key)
    env[key.to_s].to_s.presence || raise("#{key} is not set — see .env.dev")
  end

  def user_agent = {"User-Agent" => env.fetch("CORPUS_USER_AGENT", "TaiwanCards/1.0")}

  def corpora_root
    Pathname(ENV.fetch("CORPORA_DIR") { app_root.join("dict_and_corpora/corpora").to_s })
  end

  def data_root
    Pathname(ENV.fetch("DATA_DIR") { app_root.join("data").to_s })
  end

  def corpora(*parts) = corpora_root.join(*parts)

  def data(*parts) = data_root.join(*parts)

  def read_json(path)
    JSON.parse(Pathname(path).read)
  end

  def write_json(path, payload, pretty: false)
    target = Pathname(path)
    target.dirname.mkpath
    target.write(pretty ? indented(payload) : dump(payload))
    target
  end

  INDENTED = JSON::State.new(indent: " ", space: " ", object_nl: "\n", array_nl: "\n").freeze

  def float_literal(value)
    return value.to_json unless value.finite?

    text = value.to_s
    text.sub(/\.0e/, "e")
  end

  def indented(payload) = JSON.generate(payload, INDENTED)

  def dump(payload)
    buffer = +""
    emit(payload, buffer)
    buffer
  end

  def emit(value, buffer)
    case value
    when Hash
      buffer << "{"
      first = true
      value.each do |key, nested|
        buffer << ", " unless first
        first = false
        buffer << key.to_s.to_json << ": "
        emit(nested, buffer)
      end

      buffer << "}"
    when Array
      buffer << "["
      value.each_with_index do |nested, index|
        buffer << ", " if index.positive?
        emit(nested, buffer)
      end

      buffer << "]"
    when Float
      buffer << float_literal(value)
    else
      buffer << value.to_json
    end
  end

  def cores
    return ENV["TWP_CORES"].to_i.clamp(1, 1024) if ENV["TWP_CORES"].to_i.positive?

    levels = Etc.nprocessors
    return levels unless RbConfig::CONFIG["host_os"].include?("darwin")

    count = `sysctl -n hw.nperflevels 2>/dev/null`.to_i
    return levels if count.zero?

    fast = (0...count).sum do |index|
      name = `sysctl -n hw.perflevel#{index}.name 2>/dev/null`.strip
      name.casecmp?("Efficiency") ? 0 : `sysctl -n hw.perflevel#{index}.physicalcpu 2>/dev/null`.to_i
    end

    fast.positive? ? fast : levels
  end

  def each_slice_parallel(items, workers: cores)
    pool = [workers, items.length].min
    return [yield(items)] if pool <= 1

    readers = items.each_slice((items.length / pool.to_f).ceil).map do |slice|
      reader, writer = IO.pipe
      pid = fork do
        reader.close
        writer.binmode
        payload = Marshal.dump(yield(slice))
        writer.write([payload.bytesize].pack("Q"))
        writer.write(payload)
        writer.close
        exit!(0)
      end

      writer.close
      [pid, reader]
    end

    results = readers.map do |_, reader|
      reader.binmode
      size = reader.read(8)&.unpack1("Q").to_i
      body = size.positive? ? reader.read(size) : nil
      reader.close
      body ? Marshal.load(body) : nil
    end

    readers.each { |pid, _| Process.waitpid(pid) }
    results.compact
  end

  def merge_counts(tables)
    tables.each_with_object(Hash.new(0)) do |table, total|
      table.each { |key, value| total[key] += value }
    end
  end

  SPACE_EDGE = /\A[[:space:]]+|[[:space:]]+\z/

  def strip(text) = text.to_s.gsub(SPACE_EDGE, "")

  def blank?(text) = strip(text).empty?

  def python_round(value) = value.round(half: :even)

  def combinations(total, taken)
    return 0 if taken.negative? || taken > total

    (1..taken).reduce(1) { |memo, step| memo * (total - step + 1) / step }
  end

  def say(text) = warn(text)

  def report(label, **stats)
    line = stats.map { |key, value| "#{key} #{value.is_a?(Integer) ? format("%d", value) : value}" }.join(", ")
    say(format("%-28s %s", label, line))
  end

  def timed(label)
    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    result = yield
    say(format("%-28s %.1fs", label, Process.clock_gettime(Process::CLOCK_MONOTONIC) - started))
    result
  end
end

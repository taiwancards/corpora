# frozen_string_literal: true

module Forked
  def self.workers = Integer(ENV.fetch("TWC_WORKERS", "1"))

  def self.shards(size)
    count = [workers, size].min.clamp(1..)
    Array.new(count) { |index| (index...size).step(count).to_a }
  end

  def self.map(size)
    return [yield((0...size).to_a)] if workers <= 1

    jobs = shards(size).map do |shard|
      reader, writer = IO.pipe
      pid = fork do
        reader.close
        payload = Marshal.dump(yield(shard))
        writer.write([payload.bytesize].pack("Q"), payload)
        writer.close
        exit!(0)
      end
      writer.close
      [pid, reader]
    end

    jobs.map do |pid, reader|
      length = reader.read(8).unpack1("Q")
      payload = reader.read(length)
      reader.close
      Process.wait(pid)
      Marshal.load(payload)
    end
  end
end

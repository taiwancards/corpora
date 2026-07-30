# frozen_string_literal: true

module Corpus
  class PythonRandom
    N = 624
    M = 397
    MATRIX_A = 0x9908b0df
    UPPER_MASK = 0x80000000
    LOWER_MASK = 0x7fffffff
    MASK32 = 0xffffffff

    def initialize(seed)
      @state = Array.new(N, 0)
      @index = N + 1
      init_by_array(key_from(seed))
    end

    def getrandbits(bits)
      return 0 if bits.zero?
      return genrand >> (32 - bits) if bits <= 32

      result = 0
      shift = 0
      while bits.positive?
        take = bits < 32 ? bits : 32
        word = genrand
        word >>= (32 - take) if take < 32
        result |= word << shift
        shift += take
        bits -= take
      end

      result
    end

    def randrange(limit)
      return 0 if limit <= 1

      bits = limit.bit_length
      loop do
        value = getrandbits(bits)
        return value if value < limit
      end
    end

    def shuffle!(items)
      (items.length - 1).downto(1) do |i|
        j = randrange(i + 1)
        items[i], items[j] = items[j], items[i]
      end

      items
    end

    private

    def key_from(seed)
      value = seed.abs
      return [0] if value.zero?

      key = []
      while value.positive?
        key << (value & MASK32)
        value >>= 32
      end

      key
    end

    def init_genrand(seed)
      @state[0] = seed & MASK32
      (1...N).each do |i|
        @state[i] = (1812433253 * (@state[i - 1] ^ (@state[i - 1] >> 30)) + i) & MASK32
      end

      @index = N
    end

    def init_by_array(key)
      init_genrand(19650218)
      i = 1
      j = 0
      k = [N, key.length].max

      k.downto(1) do
        @state[i] = ((@state[i] ^ ((@state[i - 1] ^ (@state[i - 1] >> 30)) * 1664525)) + key[j] + j) & MASK32
        i += 1
        j += 1
        if i >= N
          @state[0] = @state[N - 1]
          i = 1
        end

        j = 0 if j >= key.length
      end

      (N - 1).downto(1) do
        @state[i] = ((@state[i] ^ ((@state[i - 1] ^ (@state[i - 1] >> 30)) * 1566083941)) - i) & MASK32
        i += 1
        if i >= N
          @state[0] = @state[N - 1]
          i = 1
        end
      end

      @state[0] = UPPER_MASK
    end

    def genrand
      if @index >= N
        N.times do |i|
          y = (@state[i] & UPPER_MASK) | (@state[(i + 1) % N] & LOWER_MASK)
          @state[i] = @state[(i + M) % N] ^ (y >> 1) ^ (y.odd? ? MATRIX_A : 0)
        end

        @index = 0
      end

      y = @state[@index]
      @index += 1
      y ^= y >> 11
      y ^= (y << 7) & 0x9d2c5680
      y ^= (y << 15) & 0xefc60000
      (y ^ (y >> 18)) & MASK32
    end
  end
end

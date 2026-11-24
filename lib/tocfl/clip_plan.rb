# frozen_string_literal: true

require_relative "audio"

module Tocfl
  class ClipPlan
    OPENING = /\A0-\d+\z/
    INTRO = /\A(\d)-(?:0{2,}|intro)(?:[-_]?(\d))?(?:\D.*)?\z/i
    SHARED = /\A(\d)-(\d{1,3})-0\z/
    ITEM = /\A(\d)-(\d{1,3})(?:-1)?\z/
    SEQUENTIAL = /\A\d{3}\z/

    attr_reader :opening, :closing, :intros, :timelines, :problems, :scheme

    def initialize(clips, part_groups)
      @clips = clips
      @part_groups = part_groups
      @opening = []
      @closing = []
      @intros = Hash.new { |hash, key| hash[key] = [] }
      @timelines = {}
      @problems = []
    end

    def build
      named || sequential
      self
    end

    private

    def numbers = @part_groups.flatten(1).flatten.sort

    def order_key(clip)
      parts = clip.name.scan(/\d+/).map(&:to_i)
      [parts, clip.name]
    end

    def named
      return false if @clips.empty? || @clips.any? { |clip| clip.name.match?(SEQUENTIAL) }

      items = {}
      shared = {}
      intros = Hash.new { |hash, key| hash[key] = [] }
      opening = []
      unknown = []
      @clips.sort_by { |clip| order_key(clip) }.each do |clip|
        name = clip.name
        if name.match?(OPENING)
          opening << clip
        elsif (match = name.match(SHARED))
          shared[match[2].to_i] = clip
        elsif (match = name.match(INTRO))
          intros[match[1].to_i] << clip
        elsif (match = name.match(ITEM)) && match[2].to_i.positive?
          items[match[2].to_i] = clip
        else
          unknown << clip
        end
      end

      unless items.keys.sort == numbers && unknown.empty?
        @problems <<
          "named clips do not match the item numbers (#{items.size} item clips, #{unknown.size} unknown); using clip order"
        return false
      end

      @scheme = "named"
      @opening = opening
      part_count = @part_groups.size
      intros.each do |part, list|
        if part > part_count
          @closing.concat(list)
        else
          @intros[part].concat(list)
        end
      end

      @part_groups.each do |groups|
        groups.each do |group|
          line = []
          line << {clip: shared[group.first], n: nil} if shared[group.first]
          group.each { |number| line << {clip: items.fetch(number), n: number} }
          @timelines[group.first] = line
        end
      end

      shared.each_key { |number|
        unless @timelines.key?(number) && @timelines[number].first[:n].nil?
          @problems << "shared clip for #{number} is not the start of a group"
        end
      }
      true
    end

    def sequential
      @scheme = "sequential"
      list = @clips.sort_by { |clip| order_key(clip) }
      @opening << list.shift if list.first && list.first.seconds < 15 && list.size > expected_count(false)
      @closing << list.pop if list.last && list.last.seconds < 15 && list.size > expected_count(false)
      unless list.size == expected_count(true) || list.size == expected_count(false)
        @problems <<
          "#{list.size} clips in order, expected #{expected_count(true)} with shared dialogue clips or #{expected_count(false)} without"
        return
      end

      with_shared = list.size == expected_count(true)
      @part_groups.each_with_index do |groups, index|
        @intros[index + 1] << list.shift
        groups.each do |group|
          line = []
          line << {clip: list.shift, n: nil} if with_shared && group.size > 1
          group.each { |number| line << {clip: list.shift, n: number} }
          @timelines[group.first] = line
        end
      end

      @intros.each { |part, clips|
        clips.each { |clip|
          @problems << "part #{part} intro clip #{clip.name} lasts only #{clip.seconds}s" if clip.seconds < 20
        }
      }
    end

    def expected_count(with_shared)
      @part_groups.sum { |groups| 1 + groups.sum { |group| group.size + (with_shared && group.size > 1 ? 1 : 0) } }
    end
  end
end

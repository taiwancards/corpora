# frozen_string_literal: true

module Tocfl
  Box = Data.define(:x0, :y0, :x1, :y1) do
    def self.around(boxes)
      boxes = boxes.compact
      return nil if boxes.empty?

      new(boxes.map(&:x0).min, boxes.map(&:y0).min, boxes.map(&:x1).max, boxes.map(&:y1).max)
    end

    def width = x1 - x0

    def height = y1 - y0

    def area = width * height

    def center_x = (x0 + x1) / 2.0

    def center_y = (y0 + y1) / 2.0

    def pad(by) = Box.new(x0 - by, y0 - by, x1 + by, y1 + by)

    def clip(other) = Box.new([x0, other.x0].max, [y0, other.y0].max, [x1, other.x1].min, [y1, other.y1].min)

    def empty? = width <= 0 || height <= 0

    def overlap_x(other) = [[x1, other.x1].min - [x0, other.x0].max, 0].max

    def overlap_y(other) = [[y1, other.y1].min - [y0, other.y0].max, 0].max

    def intersects?(other) = overlap_x(other).positive? && overlap_y(other).positive?

    def contains_center?(other) = other.center_x.between?(x0, x1) && other.center_y.between?(y0, y1)

    def to_a = [x0, y0, x1, y1].map { |value| value.round(1) }
  end

  Word = Data.define(:page, :box, :text) do
    def x0 = box.x0

    def x1 = box.x1

    def y0 = box.y0

    def y1 = box.y1

    def height = box.height
  end

  Row = Data.define(:page, :words) do
    def box = Box.around(words.map(&:box))

    def x0 = box.x0

    def x1 = box.x1

    def y0 = box.y0

    def y1 = box.y1

    def height = box.height

    def text = words.map(&:text).join(" ")

    def compact_text = words.map(&:text).join
  end
end
